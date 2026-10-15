import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_offer_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/screens/buyer_offers_screen.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'login_flow_test.dart';

class MockBuyerRepositoryForRegression implements BuyerRepository {
  final List<OfferModel> storedOffers;

  MockBuyerRepositoryForRegression(this.storedOffers);

  @override
  Future<AppResult<List<OfferModel>>> getBuyerOffers(
    String buyerId, {
    String? status,
  }) async {
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return right(storedOffers);
    }
    final target = status.toLowerCase();
    final filtered = storedOffers.where((o) {
      final s = o.status.toLowerCase();
      if (target == 'cancelled') return s == 'cancelled' || s == 'canceled';
      return s == target;
    }).toList();
    return right(filtered);
  }

  @override
  Future<AppResult<List<ProduceModel>>> getMarketplaceProduce({
    String? searchQuery,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async =>
      right(const []);

  @override
  Future<AppResult<ProduceModel>> getProduceDetails(String produceId) async =>
      left(const DatabaseFailure('Not implemented'));

  @override
  Future<AppResult<OfferModel>> makeOffer(OfferModel offer) async =>
      right(offer);

  @override
  Future<AppResult<OfferModel>> updateOffer(OfferModel offer) async =>
      right(offer);

  @override
  Future<AppResult<OfferModel>> cancelOffer(
          String offerId, String buyerId) async =>
      left(const DatabaseFailure('Not implemented'));

  @override
  Future<AppResult<OfferModel>> respondToCounterOffer(
          String offerId, String buyerId, String status) async =>
      left(const DatabaseFailure('Not implemented'));

  @override
  Future<AppResult<OfferModel?>> getExistingOfferForProduce(
          String buyerId, String produceId) async =>
      right(null);

  @override
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(
          String offerId) async =>
      right(const []);

  @override
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(
          String buyerId) async =>
      right(const BuyerDashboardStats());

  @override
  supabase.RealtimeChannel subscribeToMarketplaceProduce(
          void Function() onProduceChange) =>
      throw UnimplementedError();

  @override
  supabase.RealtimeChannel subscribeToBuyerOffers(
          String buyerId, void Function(OfferModel offer) onOfferEvent) =>
      throw UnimplementedError();

  @override
  supabase.RealtimeChannel subscribeToProduceDetails(String produceId,
          void Function(ProduceModel? produce) onProduceChange) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleWheatOfferDeclined = OfferModel(
    id: 'offer-wheat-declined-1',
    produceId: 'produce-wheat-1',
    farmerId: 'farmer-101',
    buyerId: 'buyer-202',
    offeredPrice: 2100,
    quantity: 10,
    status: 'rejected',
    produceName: 'Sharbati Wheat',
    farmerName: 'Ramesh Patel',
    produceUnit: 'quintal',
    message: 'Price too low',
  );

  final sampleRiceOfferPending = OfferModel(
    id: 'offer-rice-pending-2',
    produceId: 'produce-rice-2',
    farmerId: 'farmer-102',
    buyerId: 'buyer-202',
    offeredPrice: 3200,
    quantity: 5,
    status: 'pending',
    produceName: 'Basmati Rice',
    farmerName: 'Suresh Kumar',
    produceUnit: 'quintal',
  );

  group('Buyer Dashboard & My Offers Flow Regression Audit Tests', () {
    test('1. BuyerOfferController default filter is Pending, not All', () {
      final mockRepo = MockBuyerRepositoryForRegression([
        sampleWheatOfferDeclined,
        sampleRiceOfferPending,
      ]);

      final controller = BuyerOfferController(mockRepo);
      expect(controller.state.selectedStatus, equals('Pending'));
    });

    testWidgets(
        '2. My Offers UI default filter is Pending and does NOT contain All chip option',
        (tester) async {
      final mockRepo = MockBuyerRepositoryForRegression([
        sampleWheatOfferDeclined,
        sampleRiceOfferPending,
      ]);

      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.getProfileResult = right(const UserProfile(
        id: 'buyer-202',
        fullName: 'Test Buyer',
        role: UserRole.buyer,
        isProfileComplete: true,
      ));

      final container = ProviderContainer(
        overrides: [
          buyerRepositoryProvider.overrideWithValue(mockRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
      );
      addTearDown(container.dispose);

      // Authenticate fake user in AuthNotifier
      final authNotifier = container.read(authNotifierProvider.notifier);
      authNotifier.signIn('buyer@example.com', 'Password123!');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BuyerOffersScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "All" chip filter is NOT displayed
      expect(find.widgetWithText(FilterChip, 'All'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'All Offers'), findsNothing);

      // Verify the expected status chips exist
      expect(find.widgetWithText(FilterChip, 'Pending'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Accepted'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Rejected'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Countered'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cancelled'), findsOneWidget);

      // Verify Pending is selected by default and displays Pending offer
      final pendingChip =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Pending'));
      expect(pendingChip.selected, isTrue);
      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('Sharbati Wheat'), findsNothing);
    });

    testWidgets(
        '3. Declined wheat offer remains Rejected on refresh and does not revert to Pending',
        (tester) async {
      final mockRepo = MockBuyerRepositoryForRegression([
        sampleWheatOfferDeclined,
        sampleRiceOfferPending,
      ]);

      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.getProfileResult = right(const UserProfile(
        id: 'buyer-202',
        fullName: 'Test Buyer',
        role: UserRole.buyer,
        isProfileComplete: true,
      ));

      final container = ProviderContainer(
        overrides: [
          buyerRepositoryProvider.overrideWithValue(mockRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(authNotifierProvider.notifier);
      authNotifier.signIn('buyer@example.com', 'Password123!');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BuyerOffersScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Rejected" filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'Rejected'));
      await tester.pumpAndSettle();

      // Verify Sharbati Wheat offer is listed with Rejected status
      expect(find.text('Sharbati Wheat'), findsOneWidget);
      expect(find.textContaining('Rejected'), findsWidgets);

      // Perform refresh via Controller
      await container
          .read(buyerOfferControllerProvider.notifier)
          .fetchOffers('buyer-202');
      await tester.pumpAndSettle();

      // Verify that after refresh, filter remains "Rejected" and wheat offer is still shown as Rejected
      expect(find.text('Sharbati Wheat'), findsOneWidget);
      expect(
          container.read(buyerOfferControllerProvider).selectedStatus,
          equals('Rejected'));
    });

    testWidgets(
        '4. Opening BuyerOffersScreen with targetOfferId and initialStatus opens Rejected tab and highlights offer',
        (tester) async {
      final mockRepo = MockBuyerRepositoryForRegression([
        sampleWheatOfferDeclined,
        sampleRiceOfferPending,
      ]);

      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.getProfileResult = right(const UserProfile(
        id: 'buyer-202',
        fullName: 'Test Buyer',
        role: UserRole.buyer,
        isProfileComplete: true,
      ));

      final container = ProviderContainer(
        overrides: [
          buyerRepositoryProvider.overrideWithValue(mockRepo),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(authNotifierProvider.notifier);
      authNotifier.signIn('buyer@example.com', 'Password123!');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: BuyerOffersScreen(
                targetOfferId: 'offer-wheat-declined-1',
                initialStatus: 'rejected',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that Rejected filter is active and Sharbati Wheat is displayed
      final rejectedChip =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Rejected'));
      expect(rejectedChip.selected, isTrue);
      expect(find.text('Sharbati Wheat'), findsOneWidget);
    });

    test('5. PushNotificationService resolves deep link for offer_rejected with offerId & status',
        () {
      final data = {
        'type': 'offer_rejected',
        'related_id': 'offer-wheat-declined-1',
      };

      final route = PushNotificationService.resolveRouteFromData(data);
      expect(
        route,
        equals('/offers?offerId=offer-wheat-declined-1&status=rejected'),
      );
    });
  });
}
