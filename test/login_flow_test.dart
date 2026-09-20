import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/routing/app_router.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/login_screen.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/register_screen.dart';
import 'package:farmer_market_app/features/home/presentation/buyer_home_screen.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';

class FakeRealtimeChannel extends supabase.RealtimeChannel {
  FakeRealtimeChannel() : super('fake_channel', supabase.RealtimeClient('https://fake.supabase.co'));
  @override
  supabase.RealtimeChannel subscribe([void Function(supabase.RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    return this;
  }
  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class FakeUser extends supabase.User {
  FakeUser({required super.id})
      : super(
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
}

class FakeAuthRepository implements AuthRepository {
  AppResult<supabase.AuthResponse>? signInResult;
  AppResult<supabase.AuthResponse>? signUpResult;
  AppResult<UserProfile>? getProfileResult;
  AppResult<UserProfile>? updateProfileResult;

  UserRole? lastSignUpRole;
  String? lastSignUpEmail;
  String? lastSignUpFullName;
  UserProfile? savedProfile;
  Duration? asyncDelay;
  supabase.User? _activeUser;
  AppResult<bool>? googleSignInResult;

  void reset() {
    signInResult = null;
    signUpResult = null;
    getProfileResult = null;
    updateProfileResult = null;
    googleSignInResult = null;
    _activeUser = null;
    lastSignUpRole = null;
    lastSignUpEmail = null;
    lastSignUpFullName = null;
    savedProfile = null;
    asyncDelay = null;
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChanges => const Stream.empty();

  @override
  supabase.User? get currentUser => _activeUser;

  @override
  Future<AppResult<supabase.AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    if (asyncDelay != null) {
      await Future.delayed(asyncDelay!);
    }
    if (signInResult != null && signInResult!.isRight()) {
      _activeUser = signInResult!.getOrElse((_) => throw Exception()).user;
    }
    return signInResult ?? left(const AuthFailure('Invalid email or password. Please check your credentials and try again.'));
  }

  @override
  Future<AppResult<bool>> signInWithGoogle() async {
    if (asyncDelay != null) {
      await Future.delayed(asyncDelay!);
    }
    if (googleSignInResult != null && googleSignInResult!.isLeft()) {
      return googleSignInResult!;
    }
    final userId = getProfileResult?.fold((_) => 'google-user-1', (p) => p.id) ?? 'google-user-1';
    _activeUser = FakeUser(id: userId);
    return right(true);
  }

  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async {
    if (savedProfile != null) return right(savedProfile!);
    return getProfileResult ?? right(UserProfile(id: userId, fullName: 'Test User'));
  }

  @override
  Future<AppResult<supabase.AuthResponse>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    if (asyncDelay != null) {
      await Future.delayed(asyncDelay!);
    }
    lastSignUpEmail = email;
    lastSignUpFullName = fullName;
    lastSignUpRole = role;

    if (signUpResult != null) return signUpResult!;

    final fakeUser = FakeUser(id: 'user-123');
    final response = supabase.AuthResponse(
      session: supabase.Session(
        accessToken: 'fake_token',
        tokenType: 'bearer',
        user: fakeUser,
      ),
      user: fakeUser,
    );
    return right(response);
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail(String email) async {
    return right(null);
  }

  @override
  Future<AppResult<void>> resetPassword(String newPassword) async {
    return right(null);
  }

  @override
  Future<AppResult<void>> signOut() async {
    savedProfile = null;
    _activeUser = null;
    return right(null);
  }

  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) async {
    savedProfile = profile;
    if (updateProfileResult != null) return updateProfileResult!;
    return right(profile);
  }
}

class MockFarmerRepository implements FarmerRepository {
  @override
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce) async => right(produce);

  @override
  Future<AppResult<void>> deleteProduce(String produceId) async => right(null);

  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async {
    return right(const DashboardStats(
      totalProduce: 1,
      activeListings: 1,
      pendingOffers: 0,
      acceptedOffers: 0,
      soldProduce: 0,
      draftProduce: 0,
    ));
  }

  @override
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(
    String farmerId, {
    String? status,
    String? searchQuery,
  }) async => right([]);

  @override
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({
    String? produceName,
    String? category,
    String? marketName,
    String? sortBy,
  }) async => right([]);

  @override
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(
    String farmerId, {
    String? status,
  }) async => right([]);

  @override
  supabase.RealtimeChannel subscribeToFarmerOffers(
    String farmerId,
    void Function(OfferModel offer) onNewOffer,
  ) => FakeRealtimeChannel();

  @override
  supabase.RealtimeChannel subscribeToProduceChanges(
    String farmerId,
    void Function() onChange,
  ) => FakeRealtimeChannel();

  @override
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status) async {
    return right(OfferModel(
      id: offerId,
      produceId: 'p1',
      farmerId: 'f1',
      buyerId: 'b1',
      offeredPrice: 2400,
      quantity: 50,
      status: status,
    ));
  }

  @override
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce) async => right(produce);
}

class MockBuyerRepository implements BuyerRepository {
  @override
  Future<AppResult<OfferModel>> cancelOffer(String offerId, String buyerId) async {
    return right(OfferModel(id: offerId, produceId: 'p1', farmerId: 'f1', buyerId: buyerId, offeredPrice: 100, quantity: 10, status: 'cancelled'));
  }

  @override
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId) async {
    return right(const BuyerDashboardStats(
      totalAvailableProduce: 2,
      activeOffers: 1,
      pendingOffers: 1,
      acceptedOffers: 0,
    ));
  }

  @override
  Future<AppResult<List<OfferModel>>> getBuyerOffers(String buyerId, {String? status}) async {
    return right([
      OfferModel(
        id: 'o1',
        produceId: 'p1',
        farmerId: 'f1',
        buyerId: buyerId,
        offeredPrice: 2400,
        quantity: 50,
      ),
    ]);
  }

  @override
  Future<AppResult<List<ProduceModel>>> getMarketplaceProduce({
    String? searchQuery,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    return right([
      const ProduceModel(
        id: 'p1',
        farmerId: 'f1',
        name: 'Wheat',
        category: 'Grains',
        quantity: 50,
        unit: 'quintal',
        expectedPrice: 2450,
      ),
    ]);
  }

  @override
  Future<AppResult<ProduceModel>> getProduceDetails(String produceId) async {
    return right(const ProduceModel(
      id: 'p1',
      farmerId: 'f1',
      name: 'Wheat',
      category: 'Grains',
      quantity: 50,
      unit: 'quintal',
      expectedPrice: 2450,
    ));
  }

  @override
  Future<AppResult<OfferModel>> makeOffer(OfferModel offer) async {
    return right(offer);
  }

  @override
  supabase.RealtimeChannel subscribeToBuyerOffers(String buyerId, void Function(OfferModel offer) onOfferChange) {
    return FakeRealtimeChannel();
  }
}

class MockAppBootstrapNotifier extends AppBootstrapNotifier {
  MockAppBootstrapNotifier(super.ref) {
    state = const AppBootstrapState(isLoading: false, isInitialized: true);
  }

  @override
  Future<void> initialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;
  late MockFarmerRepository mockFarmerRepository;
  late MockBuyerRepository mockBuyerRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeAuthRepository.reset();
    mockFarmerRepository = MockFarmerRepository();
    mockBuyerRepository = MockBuyerRepository();
  });

  Widget createLoginScreenTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
        ],
        home: LoginScreen(),
      ),
    );
  }

  Widget createRegisterScreenTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
        ],
        home: RegisterScreen(),
      ),
    );
  }

  Widget createFullAppTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        farmerRepositoryProvider.overrideWithValue(mockFarmerRepository),
        buyerRepositoryProvider.overrideWithValue(mockBuyerRepository),
        appBootstrapProvider.overrideWith((ref) => MockAppBootstrapNotifier(ref)),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
          );
        },
      ),
    );
  }

  group('Registration Flow & Role Selection Tests', () {
    testWidgets('1. Account Type is required on Register screen', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Test Farmer');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'farmer@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');
      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please select an account type'), findsOneWidget);
    });

    testWidgets('2. Farmer can be selected in Account Type dropdown', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      expect(dropdown, findsOneWidget);

      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final farmerItem = find.text('Farmer').last;
      await tester.tap(farmerItem);
      await tester.pumpAndSettle();

      expect(find.text('Farmer'), findsWidgets);
    });

    testWidgets('3. Buyer can be selected in Account Type dropdown', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final buyerItem = find.text('Buyer').last;
      await tester.tap(buyerItem);
      await tester.pumpAndSettle();

      expect(find.text('Buyer'), findsWidgets);
    });

    testWidgets('4. Selected role is passed to registration logic', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Ramesh Farmer');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'ramesh@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Farmer').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.lastSignUpRole, UserRole.farmer);
      expect(fakeAuthRepository.lastSignUpEmail, 'ramesh@example.com');
      expect(fakeAuthRepository.lastSignUpFullName, 'Ramesh Farmer');
    });

    testWidgets('5. Farmer registration stores role = farmer', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Farmer One');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'farmer1@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Farmer').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.savedProfile, isNotNull);
      expect(fakeAuthRepository.savedProfile!.role, equals(UserRole.farmer));
    });

    testWidgets('6. Buyer registration stores role = buyer', (tester) async {
      await tester.pumpWidget(createRegisterScreenTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Buyer One');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'buyer1@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buyer').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.savedProfile, isNotNull);
      expect(fakeAuthRepository.savedProfile!.role, equals(UserRole.buyer));
    });

    testWidgets('7. Farmer registration redirects to Farmer Profile', (tester) async {
      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      // Navigate to Register Screen
      final registerLink = find.text("Don't have an account? Register");
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Farmer New');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'farmernew@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Farmer').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect to be on Farmer Profile Setup screen
      expect(find.text('Farmer Profile Setup'), findsOneWidget);
    });

    testWidgets('8. Buyer registration redirects to Buyer Profile', (tester) async {
      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final registerLink = find.text("Don't have an account? Register");
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Full Name'), 'Buyer New');
      await tester.enterText(find.widgetWithText(AppTextField, 'Email Address'), 'buyernew@example.com');
      await tester.enterText(find.widgetWithText(AppTextField, 'Phone Number'), '9876543210');

      final dropdown = find.byType(DropdownButtonFormField<UserRole>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buyer').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'Password123');
      await tester.enterText(find.widgetWithText(AppTextField, 'Confirm Password'), 'Password123');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Expect to be on Buyer Profile Setup screen
      expect(find.text('Buyer Profile Setup'), findsOneWidget);
    });
  });

  group('Login Flow & Error Handling Tests', () {
    testWidgets('9. Successful Farmer login routes correctly to Farmer Dashboard', (tester) async {
      final fakeUser = FakeUser(id: 'farmer-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'farmer-1',
          fullName: 'Farmer Verified',
          role: UserRole.farmer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'farmer@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Farmer Dashboard'), findsOneWidget);
    });

    testWidgets('10. Successful Buyer login routes correctly to Buyer Dashboard', (tester) async {
      final fakeUser = FakeUser(id: 'buyer-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'buyer-1',
          fullName: 'Buyer Verified',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'buyer@example.com');
      await tester.enterText(fields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Buyer Dashboard'), findsOneWidget);
    });

    testWidgets('11. Invalid credentials show an error on Login Screen', (tester) async {
      fakeAuthRepository.signInResult = left(
        const AuthFailure('Invalid email or password. Please check your credentials and try again.'),
      );

      await tester.pumpWidget(createLoginScreenTest());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'test@example.com');
      await tester.enterText(emailFields.at(1), 'WrongPassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Invalid email or password. Please check your credentials and try again.'), findsWidgets);
    });

    testWidgets('12. Failed login does not clear the email/password fields', (tester) async {
      fakeAuthRepository.signInResult = left(
        const AuthFailure('Invalid email or password. Please check your credentials and try again.'),
      );

      await tester.pumpWidget(createLoginScreenTest());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'myemail@domain.com');
      await tester.enterText(emailFields.at(1), 'MySecretPassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('myemail@domain.com'), findsOneWidget);
      expect(find.text('MySecretPassword'), findsOneWidget);
    });

    testWidgets('13. Loading state works correctly during authentication', (tester) async {
      fakeAuthRepository.asyncDelay = const Duration(milliseconds: 500);

      await tester.pumpWidget(createLoginScreenTest());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'test@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump(); // Start frame for loading state

      // Verify progress indicator is rendered inside login button
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle(); // Finish async call
    });

    testWidgets('14. Authenticated user with incomplete profile goes to profile-completion flow', (tester) async {
      final fakeUser = FakeUser(id: 'farmer-incomplete');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'farmer-incomplete',
          fullName: 'Farmer Incomplete',
          role: UserRole.farmer,
          isProfileComplete: false,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'incomplete@example.com');
      await tester.enterText(fields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Farmer Profile Setup'), findsOneWidget);
    });
  });

  group('Google Login Flow Tests', () {
    testWidgets('15. Google Sign In button is visible on Login Screen', (tester) async {
      await tester.pumpWidget(createLoginScreenTest());
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('16. Existing Google Farmer with complete profile routes directly to Farmer Dashboard', (tester) async {
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'google-farmer-complete',
          fullName: 'Google Farmer',
          role: UserRole.farmer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      // Tap Google Login
      final googleBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      // Directly on Farmer Dashboard
      expect(find.text('Farmer Dashboard'), findsOneWidget);
    });

    testWidgets('17. Existing Google Buyer with complete profile routes directly to Buyer Dashboard', (tester) async {
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'google-buyer-complete',
          fullName: 'Google Buyer',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final googleBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      // Directly on Buyer Dashboard
      expect(find.text('Buyer Dashboard'), findsOneWidget);
    });

    testWidgets('18. New Google user routes to Complete Profile screen and completes Farmer Profile', (tester) async {
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'google-new-farmer',
          fullName: 'New Google User',
          isProfileComplete: false,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      // Tap Google Sign In
      final googleBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      // Complete Profile screen should be shown
      expect(find.text('Complete Your Profile'), findsWidgets);
      expect(find.text('🌾 Farmer'), findsOneWidget);
      expect(find.text('🏢 Buyer'), findsOneWidget);

      // Select Farmer role
      await tester.tap(find.text('🌾 Farmer'));
      await tester.pumpAndSettle();

      // Tap Continue
      final continueBtn = find.text('Continue →');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 fields
      expect(find.text('Complete Your Farmer Profile'), findsOneWidget);

      final phoneField = find.widgetWithText(AppTextField, 'Phone Number');
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '9876543210');

      final districtField = find.widgetWithText(AppTextField, 'District');
      await tester.ensureVisible(districtField);
      await tester.enterText(districtField, 'Anand');

      final villageField = find.widgetWithText(AppTextField, 'Village');
      await tester.ensureVisible(villageField);
      await tester.enterText(villageField, 'Vadtal');

      final cropField = find.widgetWithText(AppTextField, 'Primary Crop');
      await tester.ensureVisible(cropField);
      await tester.enterText(cropField, 'Wheat');

      // Submit
      final saveBtn = find.text('Save & Continue');
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verified saved profile has role = farmer and isProfileComplete = true
      expect(fakeAuthRepository.savedProfile, isNotNull);
      expect(fakeAuthRepository.savedProfile!.role, equals(UserRole.farmer));
      expect(fakeAuthRepository.savedProfile!.isProfileComplete, isTrue);

      // Router automatically redirects to Farmer Dashboard
      expect(find.text('Farmer Dashboard'), findsOneWidget);
    });

    testWidgets('19. New Google user routes to Complete Profile screen and completes Buyer Profile', (tester) async {
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'google-new-buyer',
          fullName: 'New Buyer User',
          isProfileComplete: false,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      final googleBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Complete Your Profile'), findsWidgets);

      // Select Buyer role
      await tester.tap(find.text('🏢 Buyer'));
      await tester.pumpAndSettle();

      // Tap Continue
      final continueBtn = find.text('Continue →');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify Step 2 fields
      expect(find.text('Complete Your Buyer Profile'), findsOneWidget);

      final phoneField = find.widgetWithText(AppTextField, 'Phone Number');
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '9876543210');

      final companyField = find.widgetWithText(AppTextField, 'Company / Business Name');
      await tester.ensureVisible(companyField);
      await tester.enterText(companyField, 'Patel Agro');

      final districtField = find.widgetWithText(AppTextField, 'District');
      await tester.ensureVisible(districtField);
      await tester.enterText(districtField, 'Anand');

      // Submit
      final saveBtnBuyer = find.text('Save & Continue');
      await tester.ensureVisible(saveBtnBuyer);
      await tester.pumpAndSettle();
      await tester.tap(saveBtnBuyer);
      await tester.pumpAndSettle();

      // Verified saved profile has role = buyer and isProfileComplete = true
      expect(fakeAuthRepository.savedProfile, isNotNull);
      expect(fakeAuthRepository.savedProfile!.role, equals(UserRole.buyer));
      expect(fakeAuthRepository.savedProfile!.isProfileComplete, isTrue);

      // Router automatically redirects to Buyer Dashboard
      expect(find.text('Buyer Dashboard'), findsOneWidget);
    });

    testWidgets('20. Google login error shows friendly error message', (tester) async {
      fakeAuthRepository.googleSignInResult = left(
        const AuthFailure('Google Sign-In failed. Please try again.'),
      );

      await tester.pumpWidget(createLoginScreenTest());
      await tester.pumpAndSettle();

      final googleBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Google Sign-In failed. Please try again.'), findsWidgets);
    });

    testWidgets('21. Buyer user attempting to navigate to /add-produce is blocked and redirected to Buyer Dashboard', (tester) async {
      final fakeUser = FakeUser(id: 'buyer-security-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'buyer-security-1',
          fullName: 'Buyer Security Test',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createFullAppTest());
      await tester.pumpAndSettle();

      // Login as Buyer
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'buyer@example.com');
      await tester.enterText(fields.at(1), 'Password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Buyer Dashboard'), findsOneWidget);

      // Attempt to navigate to farmer /add-produce
      final container = tester.element(find.byType(BuyerHomeScreen).first);
      final router = GoRouter.of(container);
      router.go(RouteNames.addProduce);
      await tester.pumpAndSettle();

      // Should be redirected back to Buyer Dashboard
      expect(find.text('Buyer Dashboard'), findsOneWidget);
      expect(find.text('Add Produce Listing'), findsNothing);
    });
  });
}
