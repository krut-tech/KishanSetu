import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_response_model.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';

class RfqState extends Equatable {
  final List<RfqModel> myRfqs;
  final List<RfqResponseModel> selectedRfqResponses;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const RfqState({
    this.myRfqs = const [],
    this.selectedRfqResponses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  RfqState copyWith({
    List<RfqModel>? myRfqs,
    List<RfqResponseModel>? selectedRfqResponses,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RfqState(
      myRfqs: myRfqs ?? this.myRfqs,
      selectedRfqResponses: selectedRfqResponses ?? this.selectedRfqResponses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        myRfqs,
        selectedRfqResponses,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}

class RfqController extends StateNotifier<RfqState> {
  final BuyerRepository _repository;

  RfqController(this._repository) : super(const RfqState());

  Future<void> fetchMyRfqs(String buyerId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _repository.getMyRfqs(buyerId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (rfqs) => state = state.copyWith(isLoading: false, myRfqs: rfqs),
    );
  }

  Future<bool> createRfq(RfqModel rfq) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final result = await _repository.createRfq(rfq);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        state = state.copyWith(
          isSubmitting: false,
          myRfqs: [created, ...state.myRfqs],
          successMessage: 'RFQ posted! Farmers can now send you quotes.',
        );
        return true;
      },
    );
  }

  Future<void> closeRfq(String rfqId) async {
    final result = await _repository.closeRfq(rfqId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) => state = state.copyWith(
        myRfqs: state.myRfqs
            .map((r) => r.id == rfqId
                ? RfqModel(
                    id: r.id,
                    buyerId: r.buyerId,
                    produceName: r.produceName,
                    category: r.category,
                    quantityNeeded: r.quantityNeeded,
                    unit: r.unit,
                    targetPrice: r.targetPrice,
                    deliveryLocation: r.deliveryLocation,
                    neededBy: r.neededBy,
                    status: 'closed',
                    createdAt: r.createdAt,
                    responseCount: r.responseCount,
                    buyerName: r.buyerName,
                  )
                : r)
            .toList(),
      ),
    );
  }

  Future<void> fetchResponses(String rfqId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getRfqResponses(rfqId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (responses) => state = state.copyWith(isLoading: false, selectedRfqResponses: responses),
    );
  }

  Future<bool> acceptResponse(String responseId, String rfqId) async {
    final result = await _repository.acceptRfqResponse(responseId);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchResponses(rfqId);
        fetchMyRfqs(state.myRfqs.firstWhere((r) => r.id == rfqId, orElse: () => state.myRfqs.first).buyerId);
        return true;
      },
    );
  }

  Future<bool> rejectResponse(String responseId, String rfqId) async {
    final result = await _repository.rejectRfqResponse(responseId);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchResponses(rfqId);
        return true;
      },
    );
  }
}
