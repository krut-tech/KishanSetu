import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';

class BuyerOfferState extends Equatable {
  final List<OfferModel> offers;
  final bool isLoading;
  final bool isSubmitting;
  final String selectedStatus; // 'All', 'pending', 'accepted', 'rejected', 'cancelled'
  final String? errorMessage;
  final String? successMessage;

  const BuyerOfferState({
    this.offers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedStatus = 'All',
    this.errorMessage,
    this.successMessage,
  });

  BuyerOfferState copyWith({
    List<OfferModel>? offers,
    bool? isLoading,
    bool? isSubmitting,
    String? selectedStatus,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BuyerOfferState(
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

class BuyerOfferController extends StateNotifier<BuyerOfferState> {
  final BuyerRepository _repository;
  RealtimeChannel? _offersChannel;

  BuyerOfferController(this._repository) : super(const BuyerOfferState());

  Future<void> fetchOffers(String buyerId, {String? status}) async {
    state = state.copyWith(
      isLoading: true,
      selectedStatus: status ?? state.selectedStatus,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _repository.getBuyerOffers(
      buyerId,
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

    _setupRealtime(buyerId);
  }

  void _setupRealtime(String buyerId) {
    if (_offersChannel != null) return;
    try {
      _offersChannel = _repository.subscribeToBuyerOffers(buyerId, (_) {
        AppLogger.info('Realtime offer event in BuyerOfferController -> refreshing');
        fetchOffers(buyerId);
      });
    } catch (e) {
      AppLogger.warning('Failed to subscribe in BuyerOfferController: $e');
    }
  }

  Future<bool> makeOffer(OfferModel offer) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    final result = await _repository.makeOffer(offer);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (newOffer) {
        final updatedList = [newOffer, ...state.offers];
        state = state.copyWith(
          isSubmitting: false,
          offers: updatedList,
          successMessage: 'Offer submitted successfully!',
        );
        return true;
      },
    );
  }

  Future<bool> cancelOffer(String offerId, String buyerId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    final result = await _repository.cancelOffer(offerId, buyerId);

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
            .map((o) => o.id == offerId ? updatedOffer : o)
            .toList();
        state = state.copyWith(
          isSubmitting: false,
          offers: updatedList,
          successMessage: 'Offer cancelled successfully!',
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
