import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/dispute_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/repositories/trust_safety_repository.dart';

class DisputeState extends Equatable {
  final List<DisputeModel> myDisputes;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const DisputeState({
    this.myDisputes = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  DisputeState copyWith({
    List<DisputeModel>? myDisputes,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DisputeState(
      myDisputes: myDisputes ?? this.myDisputes,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [myDisputes, isLoading, isSubmitting, errorMessage, successMessage];
}

class DisputeController extends StateNotifier<DisputeState> {
  final TrustSafetyRepository _repository;

  DisputeController(this._repository) : super(const DisputeState());

  Future<void> fetch(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMyDisputes(userId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (disputes) => state = state.copyWith(isLoading: false, myDisputes: disputes),
    );
  }

  Future<bool> file(DisputeModel dispute) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final result = await _repository.fileDispute(dispute);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        state = state.copyWith(
          isSubmitting: false,
          myDisputes: [created, ...state.myDisputes],
          successMessage: 'Report submitted. Our team will review it.',
        );
        return true;
      },
    );
  }
}
