import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

class MarketplaceState extends Equatable {
  final List<ProduceModel> produceList;
  final bool isLoading;
  final String searchQuery;
  final String selectedCategory;
  final String selectedLocation;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy; // 'newest', 'price_asc', 'price_desc', 'quantity_desc'
  final String? errorMessage;

  const MarketplaceState({
    this.produceList = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedLocation = '',
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
    this.errorMessage,
  });

  MarketplaceState copyWith({
    List<ProduceModel>? produceList,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    String? selectedLocation,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? errorMessage,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearError = false,
  }) {
    return MarketplaceState(
      produceList: produceList ?? this.produceList,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy: sortBy ?? this.sortBy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        produceList,
        isLoading,
        searchQuery,
        selectedCategory,
        selectedLocation,
        minPrice,
        maxPrice,
        sortBy,
        errorMessage,
      ];
}

class MarketplaceController extends StateNotifier<MarketplaceState> {
  final BuyerRepository _repository;
  RealtimeChannel? _marketplaceChannel;
  int _requestVersion = 0;

  MarketplaceController(this._repository) : super(const MarketplaceState());

  Future<void> fetchProduce({
    String? query,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    final requestVersion = ++_requestVersion;
    final nextSearchQuery = query ?? state.searchQuery;
    final nextCategory = category ?? state.selectedCategory;
    final nextLocation = location ?? state.selectedLocation;
    final nextMinPrice = minPrice ?? state.minPrice;
    final nextMaxPrice = maxPrice ?? state.maxPrice;
    final nextSortBy = sortBy ?? state.sortBy;

    state = state.copyWith(
      isLoading: true,
      searchQuery: nextSearchQuery,
      selectedCategory: nextCategory,
      selectedLocation: nextLocation,
      minPrice: nextMinPrice,
      maxPrice: nextMaxPrice,
      sortBy: nextSortBy,
      clearError: true,
    );

    final result = await _repository.getMarketplaceProduce(
      searchQuery: nextSearchQuery,
      category: nextCategory.toLowerCase() == 'all' ? null : nextCategory,
      location: nextLocation,
      minPrice: nextMinPrice,
      maxPrice: nextMaxPrice,
      sortBy: nextSortBy,
    );

    // Rapid search/category taps can complete network calls out of order.
    // Ignore stale responses so an older query cannot overwrite the latest UI.
    if (!mounted || requestVersion != _requestVersion) return;

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
          produceList: data,
        );
      },
    );

    _setupRealtime();
  }

  void _setupRealtime() {
    if (_marketplaceChannel != null) return;
    try {
      _marketplaceChannel = _repository.subscribeToMarketplaceProduce(() {
        AppLogger.info(
            'Realtime marketplace produce change event in MarketplaceController -> refreshing');
        fetchProduce();
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe in MarketplaceController: $e');
    }
  }

  void resetFilters() {
    state = const MarketplaceState();
    fetchProduce();
  }

  void reset() {
    _requestVersion++;
    _marketplaceChannel?.unsubscribe();
    _marketplaceChannel = null;
    state = const MarketplaceState();
  }

  @override
  void dispose() {
    _marketplaceChannel?.unsubscribe();
    super.dispose();
  }
}
