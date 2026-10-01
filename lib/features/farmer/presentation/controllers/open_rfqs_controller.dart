import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_model.dart';
import 'package:farmer_market_app/features/buyer/domain/models/rfq_response_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';

class OpenRfqsState extends Equatable {
  final List<RfqModel> rfqs;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const OpenRfqsState({
    this.rfqs = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  OpenRfqsState copyWith({
    List<RfqModel>? rfqs,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OpenRfqsState(
      rfqs: rfqs ?? this.rfqs,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [rfqs, isLoading, isSubmitting, errorMessage, successMessage];
}

/// Lets a farmer browse open buyer RFQs and submit a quote against one.
class OpenRfqsController extends StateNotifier<OpenRfqsState> {
  final FarmerRepository _repository;

  OpenRfqsController(this._repository) : super(const OpenRfqsState());

  Future<void> fetch({String? produceName}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _repository.getOpenRfqs(produceName: produceName);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (rfqs) => state = state.copyWith(isLoading: false, rfqs: rfqs),
    );
  }

  Future<bool> sendQuote(RfqResponseModel response) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final result = await _repository.respondToRfq(response);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isSubmitting: false, successMessage: 'Quote sent to buyer!');
        return true;
      },
    );
  }
}
