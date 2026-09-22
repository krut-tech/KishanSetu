import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class ProduceState extends Equatable {
  final List<ProduceModel> produceList;
  final bool isLoading;
  final bool isSubmitting;
  final String? selectedStatus;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const ProduceState({
    this.produceList = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedStatus,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  ProduceState copyWith({
    List<ProduceModel>? produceList,
    bool? isLoading,
    bool? isSubmitting,
    String? selectedStatus,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    bool clearStatus = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProduceState(
      produceList: produceList ?? this.produceList,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        produceList,
        isLoading,
        isSubmitting,
        selectedStatus,
        searchQuery,
        errorMessage,
        successMessage,
      ];
}

class ProduceController extends StateNotifier<ProduceState> {
  final FarmerRepository _repository;
  RealtimeChannel? _produceChannel;
  String? _currentFarmerId;

  ProduceController(this._repository) : super(const ProduceState());

  Future<void> fetchProduce(String farmerId, {String? status, String? query}) async {
    _currentFarmerId = farmerId;
    state = state.copyWith(
      isLoading: true,
      selectedStatus: status ?? state.selectedStatus,
      searchQuery: query ?? state.searchQuery,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _repository.getFarmerProduce(
      farmerId,
      status: state.selectedStatus,
      searchQuery: state.searchQuery,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (list) {
        state = state.copyWith(
          isLoading: false,
          produceList: list,
        );
      },
    );

    _setupRealtime(farmerId);
  }

  void _setupRealtime(String farmerId) {
    if (_produceChannel != null) return;
    try {
      _produceChannel = _repository.subscribeToProduceChanges(farmerId, () {
        AppLogger.info('Realtime produce change event in ProduceController -> refreshing');
        if (_currentFarmerId != null) {
          fetchProduce(_currentFarmerId!);
        }
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe in ProduceController: $e');
    }
  }

  Future<bool> addProduce(ProduceModel produce) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    AppLogger.info('ProduceController adding produce: ${produce.name}');

    final result = await _repository.addProduce(produce);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (newProduce) {
        final updatedList = [newProduce, ...state.produceList];
        state = state.copyWith(
          isSubmitting: false,
          produceList: updatedList,
          successMessage: 'Produce listed successfully!',
        );
        return true;
      },
    );
  }

  Future<bool> updateProduce(ProduceModel produce) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    final result = await _repository.updateProduce(produce);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (updatedProduce) {
        final updatedList = state.produceList
            .map((p) => p.id == updatedProduce.id ? updatedProduce : p)
            .toList();
        state = state.copyWith(
          isSubmitting: false,
          produceList: updatedList,
          successMessage: 'Produce updated successfully!',
        );
        return true;
      },
    );
  }

  Future<bool> deleteProduce(String produceId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    final result = await _repository.deleteProduce(produceId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        final updatedList = state.produceList.where((p) => p.id != produceId).toList();
        state = state.copyWith(
          isSubmitting: false,
          produceList: updatedList,
          successMessage: 'Produce deleted successfully!',
        );
        return true;
      },
    );
  }

  @override
  void dispose() {
    _produceChannel?.unsubscribe();
    super.dispose();
  }
}
