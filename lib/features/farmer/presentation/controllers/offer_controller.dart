import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class OfferState extends Equatable {
  final List<OfferModel> offers;
  final bool isLoading;
  final bool isSubmitting;
  final String selectedStatus; // 'All', 'pending', 'accepted', 'rejected'
  final String? errorMessage;
  final String? successMessage;

  const OfferState({
    this.offers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedStatus = 'All',
    this.errorMessage,
    this.successMessage,
  });

  OfferState copyWith({
    List<OfferModel>? offers,
    bool? isLoading,
    bool? isSubmitting,
    String? selectedStatus,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OfferState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        offers,
        isLoading,
        isSubmitting,
        selectedStatus,
        errorMessage,
        successMessage,
      ];
}

class OfferController extends StateNotifier<OfferState> {
  final FarmerRepository _repository;
  RealtimeChannel? _offersChannel;

  OfferController(this._repository) : super(const OfferState());

  Future<void> fetchOffers(String farmerId, {String? status}) async {
    state = state.copyWith(
      isLoading: true,
      selectedStatus: status ?? state.selectedStatus,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _repository.getOffersForFarmer(
      farmerId,
      status: state.selectedStatus == 'All' ? null : state.selectedStatus,
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
          offers: data,
        );
      },
    );

    _setupRealtime(farmerId);
  }

  void _setupRealtime(String farmerId) {
    if (_offersChannel != null) return;
    try {
      _offersChannel = _repository.subscribeToFarmerOffers(farmerId, (_) {
        AppLogger.info('Realtime offer event in OfferController -> refreshing');
        fetchOffers(farmerId);
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe in OfferController: $e');
    }
  }

  Future<bool> respondToOffer(String offerId, String newStatus) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    AppLogger.info('OfferController responding to offer $offerId with status: $newStatus');

    final result = await _repository.updateOfferStatus(offerId, newStatus);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (updatedOffer) {
        final updatedList = state.offers
            .map((o) => o.id == updatedOffer.id ? updatedOffer : o)
            .toList();
        state = state.copyWith(
          isSubmitting: false,
          offers: updatedList,
          successMessage: 'Offer marked as ${newStatus.toUpperCase()}!',
        );
        return true;
      },
    );
  }

  @override
  void dispose() {
    _offersChannel?.unsubscribe();
    super.dispose();
  }
}
