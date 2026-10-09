import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class MarketPriceState extends Equatable {
  final List<MarketPriceModel> prices;
  final bool isLoading;
  final String searchQuery;
  final String selectedCategory;
  final String selectedMarket;
  final String sortBy; // 'date_desc', 'price_asc', 'price_desc'
  final String? errorMessage;

  const MarketPriceState({
    this.prices = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedMarket = '',
    this.sortBy = 'date_desc',
    this.errorMessage,
  });

  MarketPriceState copyWith({
    List<MarketPriceModel>? prices,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    String? selectedMarket,
    String? sortBy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MarketPriceState(
      prices: prices ?? this.prices,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      sortBy: sortBy ?? this.sortBy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        prices,
        isLoading,
        searchQuery,
        selectedCategory,
        selectedMarket,
        sortBy,
        errorMessage,
      ];
}

class MarketPriceController extends StateNotifier<MarketPriceState> {
  final FarmerRepository _repository;
  RealtimeChannel? _marketPriceChannel;
  Timer? _realtimeDebounce;

  MarketPriceController(this._repository) : super(const MarketPriceState());

  Future<void> fetchMarketPrices({
    String? produceName,
    String? category,
    String? marketName,
    String? sortBy,
    // When true and prices are already on screen, refresh in the background
    // without flipping to the loading shimmer (used for Realtime refreshes).
    bool silent = false,
  }) async {
    state = state.copyWith(
      isLoading: silent && state.prices.isNotEmpty ? state.isLoading : true,
      searchQuery: produceName ?? state.searchQuery,
      selectedCategory: category ?? state.selectedCategory,
      selectedMarket: marketName ?? state.selectedMarket,
      sortBy: sortBy ?? state.sortBy,
      clearError: true,
    );

    final result = await _repository.getMarketPrices(
      produceName: state.searchQuery,
      category: state.selectedCategory == 'All' ? null : state.selectedCategory,
      marketName: state.selectedMarket.isEmpty ? null : state.selectedMarket,
      sortBy: state.sortBy,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (data) {
        state = state.copyWith(
          isLoading: false,
          prices: data,
        );
      },
    );

    _setupRealtime();
  }

  void _setupRealtime() {
    if (_marketPriceChannel != null) return;
    try {
      _marketPriceChannel = _repository.subscribeToMarketPrices(() {
        // A price sync upserts hundreds of rows at once and Realtime emits
        // one event per row; coalesce them into a single refresh instead of
        // refetching (and flashing the loading shimmer) for every event.
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(seconds: 2), () {
          AppLogger.info('Realtime market price change -> refreshing (debounced)');
          fetchMarketPrices(silent: true);
        });
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe in MarketPriceController: $e');
    }
  }

  void reset() {
    _realtimeDebounce?.cancel();
    _marketPriceChannel?.unsubscribe();
    _marketPriceChannel = null;
    state = const MarketPriceState();
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _marketPriceChannel?.unsubscribe();
    super.dispose();
  }
}
