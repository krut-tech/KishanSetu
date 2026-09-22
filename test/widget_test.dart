import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthState;
import 'package:fpdart/fpdart.dart';
import 'package:farmer_market_app/app.dart';
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/auth/presentation/screens/login_screen.dart';

class FakeRealtimeChannel extends RealtimeChannel {
  FakeRealtimeChannel() : super('fake_channel', RealtimeClient('https://fake.supabase.co'));

  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    return this;
  }

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<sb.AuthState>.broadcast();

  @override
  Stream<sb.AuthState> get onAuthStateChanges => _controller.stream;

  @override
  User? get currentUser => null;

  @override
  Future<AppResult<AuthResponse>> signIn(
      {required String email, required String password}) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<bool>> signInWithGoogle() async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<void>> signOut() async {
    return const Right(null);
  }

  @override
  Future<AppResult<AuthResponse>> signUp(
      {required String email,
      required String password,
      required String fullName,
      required UserRole role,
      String? phone}) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail(String email) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  Future<AppResult<void>> resetPassword(String newPassword) async {
    return const Left(UnknownFailure('Not implemented in fake'));
  }

  @override
  RealtimeChannel subscribeToProfile(String userId, void Function(UserProfile profile) onProfileChange) {
    return FakeRealtimeChannel();
  }
}

class FakeAppBootstrapNotifier extends AppBootstrapNotifier {
  FakeAppBootstrapNotifier(super.ref);

  @override
  Future<void> initialize() async {
    state = const AppBootstrapState(isLoading: false, isInitialized: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App initializes and routes to LoginScreen',
      (WidgetTester tester) async {
    final fakeAuthRepo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          appBootstrapProvider
              .overrideWith((ref) => FakeAppBootstrapNotifier(ref)),
        ],
        child: const FarmerMarketApp(),
      ),
    );

    // Initial pump for app loading
    await tester.pump();

    // Pump frames to allow go_router to redirect from Splash to Login
    await tester.pumpAndSettle();

    expect(find.byType(FarmerMarketApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
