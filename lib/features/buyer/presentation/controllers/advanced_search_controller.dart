import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/buyer/domain/models/search_produce_model.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';

class AdvancedSearchState extends Equatable {
  final List<SearchProduceModel> results;
  final bool isLoading;
  final String? errorMessage;
  final String query;
  final String category;
  final List<String> qualityTags;
  final DateTime? harvestAfter;
  final DateTime? harvestBefore;
  final double? minPrice;
  final double? maxPrice;
  final double? radiusKm;
  final bool hasSearched;

  const AdvancedSearchState({
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.query = '',
    this.category = 'All',
    this.qualityTags = const [],
    this.harvestAfter,
    this.harvestBefore,
    this.minPrice,
    this.maxPrice,
    this.radiusKm,
    this.hasSearched = false,
  });

  AdvancedSearchState copyWith({
    List<SearchProduceModel>? results,
    bool? isLoading,
    String? errorMessage,
    String? query,
    String? category,
    List<String>? qualityTags,
    DateTime? harvestAfter,
    DateTime? harvestBefore,
    double? minPrice,
    double? maxPrice,
    double? radiusKm,
    bool? hasSearched,
    bool clearError = false,
    bool clearHarvestAfter = false,
    bool clearHarvestBefore = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return AdvancedSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      query: query ?? this.query,
      category: category ?? this.category,
      qualityTags: qualityTags ?? this.qualityTags,
      harvestAfter: clearHarvestAfter ? null : (harvestAfter ?? this.harvestAfter),
      harvestBefore: clearHarvestBefore ? null : (harvestBefore ?? this.harvestBefore),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      radiusKm: radiusKm ?? this.radiusKm,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  @override
  List<Object?> get props => [
        results,
        isLoading,
        errorMessage,
        query,
        category,
        qualityTags,
        harvestAfter,
        harvestBefore,
        minPrice,
        maxPrice,
        radiusKm,
        hasSearched,
      ];
}

class AdvancedSearchController extends StateNotifier<AdvancedSearchState> {
  final BuyerRepository _repository;
  double? _lat;
  double? _lng;

  AdvancedSearchController(this._repository) : super(const AdvancedSearchState());

  void setLocation(double? lat, double? lng) {
    _lat = lat;
    _lng = lng;
  }

  Future<void> search() async {
    state = state.copyWith(isLoading: true, clearError: true, hasSearched: true);
    final result = await _repository.advancedSearchProduce(
      query: state.query,
      category: state.category,
      qualityTags: state.qualityTags,
      harvestAfter: state.harvestAfter,
      harvestBefore: state.harvestBefore,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      lat: _lat,
      lng: _lng,
      radiusKm: state.radiusKm,
    );
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (results) => state = state.copyWith(isLoading: false, results: results),
    );
  }

  void updateFilters({
    String? query,
    String? category,
    List<String>? qualityTags,
    DateTime? harvestAfter,
    DateTime? harvestBefore,
    double? minPrice,
    double? maxPrice,
    double? radiusKm,
    bool clearHarvestAfter = false,
    bool clearHarvestBefore = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    state = state.copyWith(
      query: query,
      category: category,
      qualityTags: qualityTags,
      harvestAfter: harvestAfter,
      harvestBefore: harvestBefore,
      minPrice: minPrice,
      maxPrice: maxPrice,
      radiusKm: radiusKm,
      clearHarvestAfter: clearHarvestAfter,
      clearHarvestBefore: clearHarvestBefore,
      clearMinPrice: clearMinPrice,
      clearMaxPrice: clearMaxPrice,
    );
  }

  void reset() {
    state = const AdvancedSearchState();
  }
}
