import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:farmer_market_app/core/bootstrap/app_bootstrap_provider.dart';
import 'package:farmer_market_app/core/routing/app_router.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';

import 'login_flow_test.dart';

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

  Widget createTestApp() {
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

  group('Notification Center Navigation Tests', () {
    testWidgets('1. Farmer Dashboard AppBar NotificationBadgeIcon opens Notification Center', (tester) async {
      final fakeUser = FakeUser(id: 'farmer-nav-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'farmer-nav-1',
          fullName: 'Farmer Nav',
          role: UserRole.farmer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'farmer@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Farmer Dashboard'), findsOneWidget);

      final badgeIcon = find.byType(NotificationBadgeIcon);
      expect(badgeIcon, findsOneWidget);

      await tester.tap(badgeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('2. Farmer Dashboard Header Bell opens Notification Center', (tester) async {
      final fakeUser = FakeUser(id: 'farmer-nav-2');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'farmer-nav-2',
          fullName: 'Farmer Header Nav',
          role: UserRole.farmer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'farmer@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Farmer Dashboard'), findsOneWidget);

      final headerBell = find.byIcon(Icons.notifications_none_rounded);
      expect(headerBell, findsOneWidget);

      await tester.tap(headerBell);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('3. Buyer Dashboard AppBar NotificationBadgeIcon opens Notification Center', (tester) async {
      final fakeUser = FakeUser(id: 'buyer-nav-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'buyer-nav-1',
          fullName: 'Buyer Nav',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'buyer@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Buyer Dashboard'), findsOneWidget);

      final badgeIcon = find.byType(NotificationBadgeIcon);
      expect(badgeIcon, findsOneWidget);

      await tester.tap(badgeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('4. Buyer Dashboard Header Bell opens Notification Center', (tester) async {
      final fakeUser = FakeUser(id: 'buyer-nav-2');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'tok', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'buyer-nav-2',
          fullName: 'Buyer Header Nav',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextField);
      await tester.enterText(emailFields.at(0), 'buyer@example.com');
      await tester.enterText(emailFields.at(1), 'Password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Buyer Dashboard'), findsOneWidget);

      final headerBell = find.byIcon(Icons.notifications_outlined).last;
      await tester.tap(headerBell);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });
  });
}
