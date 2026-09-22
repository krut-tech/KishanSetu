import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_dashboard_notifier.dart';

class FakeRealtimeChannel extends RealtimeChannel {
  FakeRealtimeChannel() : super('fake_channel', RealtimeClient('https://fake.supabase.co'));
  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus status, Object? error)? callback, Duration? timeout]) {
    return this;
  }
  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class MockFarmerRepository implements FarmerRepository {
  @override
  Future<AppResult<ProduceModel>> addProduce(ProduceModel produce) async {
    return right(produce);
  }

  @override
  Future<AppResult<void>> deleteProduce(String produceId) async {
    return right(null);
  }

  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async {
    return right(const DashboardStats(
      totalProduce: 3,
      activeListings: 2,
      pendingOffers: 1,
      acceptedOffers: 0,
      soldProduce: 1,
      draftProduce: 0,
    ));
  }

  @override
  Future<AppResult<List<ProduceModel>>> getFarmerProduce(
    String farmerId, {
    String? status,
    String? searchQuery,
  }) async {
    return right([
      ProduceModel(
        id: 'p1',
        farmerId: farmerId,
        name: 'Wheat',
        category: 'Cereals',
        quantity: 50,
        unit: 'quintal',
        expectedPrice: 2450,
      ),
    ]);
  }

  @override
  Future<AppResult<List<MarketPriceModel>>> getMarketPrices({
    String? produceName,
    String? category,
    String? marketName,
    String? sortBy,
  }) async {
    return right([
      const MarketPriceModel(
        id: 'm1',
        produceName: 'Wheat',
        marketName: 'Anand APMC',
        price: 2450,
        unit: 'quintal',
      ),
    ]);
  }

  @override
  Future<AppResult<List<OfferModel>>> getOffersForFarmer(
    String farmerId, {
    String? status,
  }) async {
    return right([
      OfferModel(
        id: 'o1',
        produceId: 'p1',
        farmerId: farmerId,
        buyerId: 'b1',
        offeredPrice: 2400,
        quantity: 50,
      ),
    ]);
  }

  @override
  Future<AppResult<List<OfferHistoryModel>>> getOfferHistory(String offerId) async {
    return right([]);
  }

  @override
  RealtimeChannel subscribeToFarmerOffers(
    String farmerId,
    void Function(OfferModel offer) onNewOffer,
  ) {
    return FakeRealtimeChannel();
  }

  @override
  RealtimeChannel subscribeToProduceChanges(
    String farmerId,
    void Function() onChange,
  ) {
    return FakeRealtimeChannel();
  }

  @override
  RealtimeChannel subscribeToMarketPrices(
    void Function() onChange,
  ) {
    return FakeRealtimeChannel();
  }

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
  Future<AppResult<ProduceModel>> updateProduce(ProduceModel produce) async {
    return right(produce);
  }
}

void main() {
  group('FarmerDashboardNotifier Unit Tests', () {
    test('loads dashboard state correctly with mock repository', () async {
      final repo = MockFarmerRepository();
      final notifier = FarmerDashboardNotifier(repo);

      await notifier.loadDashboardData('farmer-123');

      final state = notifier.state;

      expect(state.isLoading, isFalse);
      expect(state.stats.activeListings, equals(2));
      expect(state.stats.pendingOffers, equals(1));
      expect(state.recentProduce.length, equals(1));
      expect(state.recentProduce.first.name, equals('Wheat'));
      expect(state.marketHighlights.length, equals(1));
      expect(state.recentOffers.length, equals(1));
    });
  });
}
