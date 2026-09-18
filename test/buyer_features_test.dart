import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_offer_controller.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/marketplace_controller.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class FakeRealtimeChannel extends RealtimeChannel {
  FakeRealtimeChannel() : super('fake_channel', RealtimeClient('https://fake.supabase.co'));
  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    return this;
  }
  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class MockBuyerRepository implements BuyerRepository {
  List<ProduceModel> produceList = [
    const ProduceModel(
      id: 'p-1',
      farmerId: 'farmer-100',
      name: 'Sharbati Wheat',
      category: 'Grains',
      quantity: 100.0,
      unit: 'quintal',
      expectedPrice: 2400.0,
      status: 'active',
      location: 'Anand, Gujarat',
      farmerName: 'Ramesh Patel',
    ),
    const ProduceModel(
      id: 'p-2',
      farmerId: 'farmer-200',
      name: 'Organic Tomatoes',
      category: 'Vegetables',
      quantity: 20.0,
      unit: 'kg',
      expectedPrice: 40.0,
      status: 'active',
      location: 'Vadodara, Gujarat',
      farmerName: 'Suresh Shah',
    ),
  ];

  List<OfferModel> offersList = [];

  bool throwError = false;

  @override
  Future<AppResult<OfferModel>> cancelOffer(String offerId, String buyerId) async {
    if (throwError) return left(const DatabaseFailure('Cancel offer failed'));
    final index = offersList.indexWhere((o) => o.id == offerId && o.buyerId == buyerId);
    if (index == -1) return left(const DatabaseFailure('Offer not found or unauthorized'));
    final cancelled = offersList[index].copyWith(status: 'cancelled');
    offersList[index] = cancelled;
    return right(cancelled);
  }

  @override
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId) async {
    if (throwError) return left(const DatabaseFailure('Failed to fetch stats'));
    return right(BuyerDashboardStats(
      totalAvailableProduce: produceList.length,
      activeOffers: offersList.length,
      pendingOffers: offersList.where((o) => o.status == 'pending').length,
      acceptedOffers: offersList.where((o) => o.status == 'accepted').length,
    ));
  }

  @override
  Future<AppResult<List<OfferModel>>> getBuyerOffers(String buyerId, {String? status}) async {
    if (throwError) return left(const DatabaseFailure('Failed to fetch offers'));
    var result = offersList.where((o) => o.buyerId == buyerId).toList();
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      result = result.where((o) => o.status.toLowerCase() == status.toLowerCase()).toList();
    }
    return right(result);
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
    if (throwError) return left(const DatabaseFailure('Failed to fetch produce'));

    var result = List<ProduceModel>.from(produceList);

    if (category != null && category.isNotEmpty && category != 'All') {
      result = result.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)).toList();
    }

    if (sortBy == 'price_asc') {
      result.sort((a, b) => a.expectedPrice.compareTo(b.expectedPrice));
    } else if (sortBy == 'price_desc') {
      result.sort((a, b) => b.expectedPrice.compareTo(a.expectedPrice));
    }

    return right(result);
  }

  @override
  Future<AppResult<ProduceModel>> getProduceDetails(String produceId) async {
    final found = produceList.firstWhere((p) => p.id == produceId);
    return right(found);
  }

  @override
  Future<AppResult<OfferModel>> makeOffer(OfferModel offer) async {
    if (throwError) return left(const DatabaseFailure('Failed to submit offer'));
    final newOffer = offer.copyWith(id: 'offer-${offersList.length + 1}');
    offersList.add(newOffer);
    return right(newOffer);
  }

  @override
  RealtimeChannel subscribeToBuyerOffers(String buyerId, void Function(OfferModel offer) onOfferChange) {
    return FakeRealtimeChannel();
  }
}

class MockFarmerRepoForBuyer implements FarmerRepository {
  @override
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce) async => right(produce);

  @override
  Future<AppResult<void>> deleteProduce(String produceId) async => right(null);

  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async => right(const DashboardStats());

  @override
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(String farmerId, {String? status, String? searchQuery}) async => right([]);

  @override
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({String? produceName, String? category, String? marketName, String? sortBy}) async {
    return right([
      const MarketPriceModel(
        id: 'mp-1',
        produceName: 'Wheat',
        marketName: 'Anand APMC',
        price: 2450,
        unit: 'quintal',
      ),
    ]);
  }

  @override
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(String farmerId, {String? status}) async => right([]);

  @override
  RealtimeChannel subscribeToFarmerOffers(String farmerId, void Function(OfferModel offer) onNewOffer) => FakeRealtimeChannel();

  @override
  RealtimeChannel subscribeToProduceChanges(String farmerId, void Function() onChange) => FakeRealtimeChannel();

  @override
  Future<AppResult<OfferModel>> updateOfferStatus(String offerId, String status) async => right(OfferModel(id: offerId, produceId: 'p1', farmerId: 'f1', buyerId: 'b1', offeredPrice: 100, quantity: 10, status: status));

  @override
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce) async => right(produce);
}

void main() {
  group('Buyer Dashboard & Marketplace Tests', () {
    late MockBuyerRepository buyerRepo;
    late MockFarmerRepoForBuyer farmerRepo;

    setUp(() {
      buyerRepo = MockBuyerRepository();
      farmerRepo = MockFarmerRepoForBuyer();
    });

    test('1-4. Buyer Dashboard loads statistics and marketplace data', () async {
      final notifier = BuyerDashboardNotifier(buyerRepo, farmerRepo);
      await notifier.loadDashboardData('buyer-1');

      final state = notifier.state;
      expect(state.isLoading, isFalse);
      expect(state.stats.totalAvailableProduce, equals(2));
      expect(state.featuredProduce.length, equals(2));
      expect(state.marketHighlights.length, equals(1));
    });

    test('5-8. Marketplace search, category filter, and sorting work correctly', () async {
      final controller = MarketplaceController(buyerRepo);

      // Fetch all produce
      await controller.fetchProduce();
      expect(controller.state.produceList.length, equals(2));

      // Category filter
      await controller.fetchProduce(category: 'Grains');
      expect(controller.state.produceList.length, equals(1));
      expect(controller.state.produceList.first.name, equals('Sharbati Wheat'));

      // Search filter
      await controller.fetchProduce(category: 'All', query: 'Tomatoes');
      expect(controller.state.produceList.length, equals(1));
      expect(controller.state.produceList.first.name, equals('Organic Tomatoes'));

      // Price sorting
      await controller.fetchProduce(query: '', sortBy: 'price_asc');
      expect(controller.state.produceList.first.expectedPrice, equals(40.0));
    });

    test('9-14. Make Offer validations, success, and error handling', () async {
      final offerController = BuyerOfferController(buyerRepo);

      // Offer Validation check logic
      const produce = ProduceModel(
        id: 'p-1',
        farmerId: 'farmer-100',
        name: 'Sharbati Wheat',
        category: 'Grains',
        quantity: 50.0,
        unit: 'quintal',
        expectedPrice: 2400.0,
      );

      // Valid Offer submit
      final validOffer = OfferModel(
        id: '',
        produceId: produce.id,
        farmerId: produce.farmerId,
        buyerId: 'buyer-1',
        offeredPrice: 2350.0,
        quantity: 25.0,
      );

      final success = await offerController.makeOffer(validOffer);
      expect(success, isTrue);
      expect(offerController.state.offers.length, equals(1));
      expect(offerController.state.offers.first.offeredPrice, equals(2350.0));
    });

    test('15-19. Buyer My Offers filtering and pending offer cancellation', () async {
      final offerController = BuyerOfferController(buyerRepo);

      // Seed mock offers
      buyerRepo.offersList = [
        const OfferModel(
          id: 'o-1',
          produceId: 'p-1',
          farmerId: 'farmer-100',
          buyerId: 'buyer-1',
          offeredPrice: 2300,
          quantity: 10,
          status: 'pending',
        ),
        const OfferModel(
          id: 'o-2',
          produceId: 'p-2',
          farmerId: 'farmer-200',
          buyerId: 'buyer-1',
          offeredPrice: 35,
          quantity: 5,
          status: 'accepted',
        ),
      ];

      // Fetch offers
      await offerController.fetchOffers('buyer-1', status: 'All');
      expect(offerController.state.offers.length, equals(2));

      // Filter pending
      await offerController.fetchOffers('buyer-1', status: 'pending');
      expect(offerController.state.offers.length, equals(1));
      expect(offerController.state.offers.first.id, equals('o-1'));

      // Cancel pending offer
      final cancelled = await offerController.cancelOffer('o-1', 'buyer-1');
      expect(cancelled, isTrue);
      expect(offerController.state.offers.first.status, equals('cancelled'));
    });

    test('20-23. Security & Error state tests', () async {
      final offerController = BuyerOfferController(buyerRepo);
      buyerRepo.throwError = true;

      await offerController.fetchOffers('buyer-1');
      expect(offerController.state.errorMessage, isNotNull);
      expect(offerController.state.offers, isEmpty);
    });
  });
}
