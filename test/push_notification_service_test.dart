import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'login_flow_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationService Route Resolution & Payload Parsing Tests', () {
    test('1. Resolves explicit route when provided in FCM payload data', () {
      final data = {
        'notification_id': 'n-101',
        'type': 'new_offer',
        'related_id': 'offer-1',
        'route': '/add-produce',
      };

      final route = PushNotificationService.resolveRouteFromData(data);
      expect(route, equals('/add-produce'));
    });

    test('2. Resolves /offers for new_offer type when route is absent', () {
      final data = {
        'notification_id': 'n-102',
        'type': 'new_offer',
        'related_id': 'offer-2',
      };

      final route = PushNotificationService.resolveRouteFromData(data);
      expect(route, equals('/offers'));
    });

    test('3. Resolves /offers for offer_accepted, offer_rejected, counter_offer, offer_updated, offer_cancelled', () {
      final dataAccepted = {'type': 'offer_accepted'};
      final dataRejected = {'type': 'offer_rejected'};
      final dataCounter = {'type': 'counter_offer'};
      final dataUpdated = {'type': 'offer_updated'};
      final dataCancelled = {'type': 'offer_cancelled'};

      expect(PushNotificationService.resolveRouteFromData(dataAccepted), equals('/offers'));
      expect(PushNotificationService.resolveRouteFromData(dataRejected), equals('/offers'));
      expect(PushNotificationService.resolveRouteFromData(dataCounter), equals('/offers'));
      expect(PushNotificationService.resolveRouteFromData(dataUpdated), equals('/offers'));
      expect(PushNotificationService.resolveRouteFromData(dataCancelled), equals('/offers'));
    });

    test('4. Resolves /my-produce for produce and produce_interest types', () {
      final dataInterest = {'type': 'produce_interest'};
      final dataProduce = {'type': 'produce'};

      expect(PushNotificationService.resolveRouteFromData(dataInterest), equals('/my-produce'));
      expect(PushNotificationService.resolveRouteFromData(dataProduce), equals('/my-produce'));
    });

    test('5. Resolves /market-prices for market_price and market_price_update types', () {
      final dataUpdate = {'type': 'market_price_update'};
      final dataPrice = {'type': 'market_price'};

      expect(PushNotificationService.resolveRouteFromData(dataUpdate), equals('/market-prices'));
      expect(PushNotificationService.resolveRouteFromData(dataPrice), equals('/market-prices'));
    });

    test('6. Resolves fallback /notifications for unknown or missing type', () {
      final dataUnknown = {'type': 'custom_unknown'};
      final dataEmpty = <String, dynamic>{};

      expect(PushNotificationService.resolveRouteFromData(dataUnknown), equals('/notifications'));
      expect(PushNotificationService.resolveRouteFromData(dataEmpty), equals('/notifications'));
    });

    test('7. Triggers onNavigate callback or stores pendingInitialRoute', () {
      String? navigatedRoute;
      PushNotificationService.onNavigate = (route) {
        navigatedRoute = route;
      };

      final data = {'type': 'new_offer', 'route': '/notifications'};
      final resolved = PushNotificationService.resolveRouteFromData(data);

      PushNotificationService.onNavigate?.call(resolved);
      expect(navigatedRoute, equals('/notifications'));

      // Test pending initial route storage when onNavigate is temporarily null
      PushNotificationService.onNavigate = null;
      PushNotificationService.pendingInitialRoute = '/offers';
      expect(PushNotificationService.pendingInitialRoute, equals('/offers'));

      // Cleanup
      PushNotificationService.pendingInitialRoute = null;
    });
  });

  group('AuthNotifier & Push Token Lifecycle Integration Tests', () {
    late FakeAuthRepository fakeAuthRepository;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeAuthRepository.reset();
    });

    test('8. AuthNotifier triggers profile fetch and authenticates user cleanly', () async {
      final fakeUser = FakeUser(id: 'push-user-1');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'token', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'push-user-1',
          fullName: 'Farmer Push',
          role: UserRole.farmer,
          isProfileComplete: true,
        ),
      );

      final authNotifier = AuthNotifier(fakeAuthRepository);
      final success = await authNotifier.signIn('farmer@example.com', 'Pass123!');

      expect(success, isTrue);
      expect(authNotifier.state.isAuthenticated, isTrue);
      expect(authNotifier.state.user?.id, equals('push-user-1'));

      authNotifier.dispose();
    });

    test('9. AuthNotifier signOut deactivates session and resets state', () async {
      final fakeUser = FakeUser(id: 'push-user-2');
      fakeAuthRepository.signInResult = right(
        supabase.AuthResponse(
          session: supabase.Session(accessToken: 'token', tokenType: 'bearer', user: fakeUser),
          user: fakeUser,
        ),
      );
      fakeAuthRepository.getProfileResult = right(
        const UserProfile(
          id: 'push-user-2',
          fullName: 'Buyer Push',
          role: UserRole.buyer,
          isProfileComplete: true,
        ),
      );

      final authNotifier = AuthNotifier(fakeAuthRepository);
      await authNotifier.signIn('buyer@example.com', 'Pass123!');
      expect(authNotifier.state.isAuthenticated, isTrue);

      await authNotifier.signOut();

      expect(authNotifier.state.isAuthenticated, isFalse);
      expect(authNotifier.state.user, isNull);

      authNotifier.dispose();
    });
  });
}
