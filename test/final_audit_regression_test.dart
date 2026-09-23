import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';
import 'package:farmer_market_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_notifier.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/produce_controller.dart';

class StubAuthRepo implements AuthRepository {
  @override
  Stream<AuthState> get onAuthStateChanges => const Stream.empty();
  @override
  User? get currentUser => null;
  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async => left(const ServerFailure('stub'));
  @override
  Future<AppResult<void>> resetPassword(String newPassword) async => right(null);
  @override
  Future<AppResult<void>> sendPasswordResetEmail(String email) async => right(null);
  @override
  Future<AppResult<AuthResponse>> signIn({required String email, required String password}) async => left(const ServerFailure('stub'));
  @override
  Future<AppResult<bool>> signInWithGoogle() async => right(true);
  @override
  Future<AppResult<void>> signOut() async => right(null);
  @override
  Future<AppResult<AuthResponse>> signUp({required String email, required String password, required String fullName, required UserRole role, String? phone}) async => left(const ServerFailure('stub'));
  @override
  RealtimeChannel subscribeToProfile(String userId, void Function(UserProfile? profile) onProfileChange) => throw UnimplementedError();
  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) async => left(const ServerFailure('stub'));
}

class StubNotificationRepo implements NotificationRepository {
  @override
  Stream<List<Map<String, dynamic>>> getNotificationStream(String userId) => const Stream.empty();
  @override
  Future<AppResult<List<NotificationModel>>> getNotifications() async => right([]);
  @override
  Future<AppResult<void>> markAllAsRead() async => right(null);
  @override
  Future<AppResult<void>> markAsRead(String notificationId) async => right(null);
}

class StubFarmerRepo implements FarmerRepository {
  @override
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return right(produce);
  }
  @override
  Future<AppResult<void>> deleteProduce(String produceId) async => right(null);
  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async => right(const DashboardStats());
  @override
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(String farmerId, {String? status, String? searchQuery}) async => right([]);
  @override
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({String? produceName, String? category, String? marketName, String? sortBy}) async => right([]);
  @override
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(String offerId) async => right([]);
  @override
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(String farmerId, {String? status}) async => right([]);
  @override
  RealtimeChannel subscribeToFarmerOffers(String farmerId, void Function(OfferModel offer) onNewOffer) => throw UnimplementedError();
  @override
  RealtimeChannel subscribeToMarketPrices(void Function() onChange) => throw UnimplementedError();
  @override
  RealtimeChannel subscribeToProduceChanges(String farmerId, void Function() onChange) => throw UnimplementedError();
  @override
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status) async => left(const ServerFailure('stub'));
  @override
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce) async => right(produce);
}

void main() {
  group('Final Audit Regression Tests', () {
    test('AuthNotifier triggers onSignOutCallback when unauthenticated', () async {
      bool callbackFired = false;
      final notifier = AuthNotifier(
        StubAuthRepo(),
        onSignOutCallback: () {
          callbackFired = true;
        },
      );
      
      await notifier.signOut();

      expect(callbackFired, isTrue, reason: 'Sign-out callback must fire to invalidate providers');
    });

    test('NotificationNotifier disposes cleanly without leaking AuthSubscription', () {
      final notifier = NotificationNotifier(StubNotificationRepo(), null);
      expect(() => notifier.dispose(), returnsNormally);
    });

    test('ProduceController ignores state updates if disposed (unmounted)', () async {
      final notifier = ProduceController(StubFarmerRepo());
      
      final mockProduce = ProduceModel(
        id: '1',
        farmerId: 'f1',
        name: 'Apples',
        category: 'Fruits',
        quantity: 10,
        unit: 'kg',
        expectedPrice: 100,
        status: 'active',
        location: 'Farm',
      );

      // Fire and forget
      final future = notifier.addProduce(mockProduce);
      
      // Dispose immediately (simulating navigation away)
      notifier.dispose();

      final result = await future;

      // Because it was unmounted before the async operation finished, it should safely return false
      // and NOT throw a StateError from trying to update `state`.
      expect(result, isFalse);
    });
  });
}
