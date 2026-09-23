import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class FarmerDashboardState extends Equatable {
  final DashboardStats stats;
  final List<ProduceModel> recentProduce;
  final List<OfferModel> recentOffers;
  final List<MarketPriceModel> marketHighlights;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const FarmerDashboardState({
    this.stats = const DashboardStats(),
    this.recentProduce = const [],
    this.recentOffers = const [],
    this.marketHighlights = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  FarmerDashboardState copyWith({
    DashboardStats? stats,
    List<ProduceModel>? recentProduce,
    List<OfferModel>? recentOffers,
    List<MarketPriceModel>? marketHighlights,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FarmerDashboardState(
      stats: stats ?? this.stats,
      recentProduce: recentProduce ?? this.recentProduce,
      recentOffers: recentOffers ?? this.recentOffers,
      marketHighlights: marketHighlights ?? this.marketHighlights,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        stats,
        recentProduce,
        recentOffers,
        marketHighlights,
        isLoading,
        isRefreshing,
        errorMessage,
      ];
}

class FarmerDashboardNotifier extends StateNotifier<FarmerDashboardState> {
  final FarmerRepository _repository;
  RealtimeChannel? _offersChannel;
  RealtimeChannel? _produceChannel;
  RealtimeChannel? _pricesChannel;
  String? _currentFarmerId;

  FarmerDashboardNotifier(this._repository) : super(const FarmerDashboardState());

  Future<void> loadDashboardData(String farmerId) async {
    final isSameUser = _currentFarmerId == farmerId;
    final hasData = state.stats.totalProduce > 0 || state.recentProduce.isNotEmpty;
    _currentFarmerId = farmerId;

    if (!isSameUser || !hasData) {
      state = state.copyWith(isLoading: true, clearError: true);
      await _fetchData(farmerId);
    } else if (state.isLoading) {
      await _fetchData(farmerId);
    }

    _setupRealtime(farmerId);
  }

  Future<void> refreshDashboard() async {
    if (_currentFarmerId == null) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    await _fetchData(_currentFarmerId!);
    state = state.copyWith(isRefreshing: false);
  }

  Future<void> _fetchData(String farmerId) async {
    AppLogger.info('FarmerDashboardNotifier fetching dashboard for $farmerId');

    // Fetch Stats
    final statsRes = await _repository.getFarmerDashboardStats(farmerId);

    // Fetch Produce
    final produceRes = await _repository.getFarmerProduce(farmerId);

    // Fetch Offers
    final offersRes = await _repository.getOffersForFarmer(farmerId);

    // Fetch Market Prices
    final marketRes = await _repository.getMarketPrices();

    String? error;
    DashboardStats stats = state.stats;
    List<ProduceModel> produce = state.recentProduce;
    List<OfferModel> offers = state.recentOffers;
    List<MarketPriceModel> market = state.marketHighlights;

    statsRes.fold(
      (f) => error = f.message,
      (data) => stats = data,
    );

    produceRes.fold(
      (f) => error ??= f.message,
      (data) => produce = data,
    );

    offersRes.fold(
      (f) => error ??= f.message,
      (data) => offers = data,
    );

    marketRes.fold(
      (f) => error ??= f.message,
      (data) => market = data,
    );

    state = state.copyWith(
      stats: stats,
      recentProduce: produce,
      recentOffers: offers,
      marketHighlights: market,
      isLoading: false,
      errorMessage: error,
    );
  }

  void _setupRealtime(String farmerId) {
    if (_offersChannel != null && _produceChannel != null && _pricesChannel != null && _currentFarmerId == farmerId) {
      return; // Realtime channels already initialized
    }
    _cleanupRealtime();

    try {
      _offersChannel = _repository.subscribeToFarmerOffers(farmerId, (newOffer) {
        AppLogger.info('Realtime new offer notification received: ${newOffer.id}');
        refreshDashboard();
      });

      _produceChannel = _repository.subscribeToProduceChanges(farmerId, () {
        AppLogger.info('Realtime produce change notification received');
        refreshDashboard();
      });

      _pricesChannel = _repository.subscribeToMarketPrices(() {
        AppLogger.info('Realtime market price change notification received');
        refreshDashboard();
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe to realtime changes: $e');
    }
  }

  void reset() {
    _cleanupRealtime();
    _currentFarmerId = null;
    state = const FarmerDashboardState();
  }

  void _cleanupRealtime() {
    _offersChannel?.unsubscribe();
    _offersChannel = null;

    _produceChannel?.unsubscribe();
    _produceChannel = null;

    _pricesChannel?.unsubscribe();
    _pricesChannel = null;
  }

  @override
  void dispose() {
    _cleanupRealtime();
    super.dispose();
  }
}
