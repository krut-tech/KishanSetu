import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class BuyerDashboardState extends Equatable {
  final bool isLoading;
  final BuyerDashboardStats stats;
  final List<ProduceModel> featuredProduce;
  final List<MarketPriceModel> marketHighlights;
  final List<OfferModel> recentOffers;
  final String? errorMessage;

  const BuyerDashboardState({
    this.isLoading = false,
    this.stats = const BuyerDashboardStats(),
    this.featuredProduce = const [],
    this.marketHighlights = const [],
    this.recentOffers = const [],
    this.errorMessage,
  });

  BuyerDashboardState copyWith({
    bool? isLoading,
    BuyerDashboardStats? stats,
    List<ProduceModel>? featuredProduce,
    List<MarketPriceModel>? marketHighlights,
    List<OfferModel>? recentOffers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BuyerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      featuredProduce: featuredProduce ?? this.featuredProduce,
      marketHighlights: marketHighlights ?? this.marketHighlights,
      recentOffers: recentOffers ?? this.recentOffers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        stats,
        featuredProduce,
        marketHighlights,
        recentOffers,
        errorMessage,
      ];
}

class BuyerDashboardNotifier extends StateNotifier<BuyerDashboardState> {
  final BuyerRepository _buyerRepository;
  final FarmerRepository _farmerRepository;

  RealtimeChannel? _offersChannel;
  String? _currentBuyerId;

  BuyerDashboardNotifier(this._buyerRepository, this._farmerRepository)
      : super(const BuyerDashboardState());

  Future<void> loadDashboardData(String buyerId) async {
    final isSameUser = _currentBuyerId == buyerId;
    final hasData = state.featuredProduce.isNotEmpty || state.recentOffers.isNotEmpty;
    _currentBuyerId = buyerId;

    if (!isSameUser || !hasData) {
      state = state.copyWith(isLoading: true, clearError: true);
      AppLogger.info('BuyerDashboardNotifier loading dashboard for buyer: $buyerId');
      await _fetchData(buyerId);
    } else if (state.isLoading) {
      await _fetchData(buyerId);
    }

    _setupRealtimeSubscription(buyerId);
  }

  Future<void> refreshDashboard() async {
    if (_currentBuyerId != null) {
      await _fetchData(_currentBuyerId!);
    }
  }

  Future<void> _fetchData(String buyerId) async {
    // 1. Stats
    final statsRes = await _buyerRepository.getBuyerDashboardStats(buyerId);
    BuyerDashboardStats stats = state.stats;
    statsRes.fold((f) => null, (data) => stats = data);

    // 2. Featured Produce (active produce)
    final produceRes = await _buyerRepository.getMarketplaceProduce(
      sortBy: 'newest',
    );
    List<ProduceModel> produce = state.featuredProduce;
    produceRes.fold((f) => null, (data) => produce = data.take(5).toList());

    // 3. Market Price Highlights
    final pricesRes = await _farmerRepository.getMarketPrices(sortBy: 'date_desc');
    List<MarketPriceModel> prices = state.marketHighlights;
    pricesRes.fold((f) => null, (data) => prices = data.take(4).toList());

    // 4. Recent Buyer Offers
    final offersRes = await _buyerRepository.getBuyerOffers(buyerId);
    List<OfferModel> offers = state.recentOffers;
    offersRes.fold((f) => null, (data) => offers = data.take(5).toList());

    state = state.copyWith(
      isLoading: false,
      stats: stats,
      featuredProduce: produce,
      marketHighlights: prices,
      recentOffers: offers,
    );
  }

  void _setupRealtimeSubscription(String buyerId) {
    if (_offersChannel != null && _currentBuyerId == buyerId) {
      return; // Already subscribed
    }
    try {
      _offersChannel?.unsubscribe();
      _offersChannel = _buyerRepository.subscribeToBuyerOffers(buyerId, (_) {
        AppLogger.info('Realtime offer event triggered -> refreshing buyer dashboard');
        refreshDashboard();
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe to buyer realtime changes: $e');
    }
  }

  @override
  void dispose() {
    _offersChannel?.unsubscribe();
    super.dispose();
  }
}
