import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/kyc_document_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/repositories/trust_safety_repository.dart';

class KycState extends Equatable {
  final KycDocumentModel? document;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const KycState({
    this.document,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  KycState copyWith({
    KycDocumentModel? document,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return KycState(
      document: document ?? this.document,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [document, isLoading, isSubmitting, errorMessage, successMessage];
}

class KycController extends StateNotifier<KycState> {
  final TrustSafetyRepository _repository;

  KycController(this._repository) : super(const KycState());

  Future<void> fetch(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMyLatestKycDocument(userId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (doc) => state = state.copyWith(isLoading: false, document: doc),
    );
  }

  Future<bool> submit({
    required String userId,
    required String documentType,
    required String documentNumber,
    required dynamic file, // io.File, kept dynamic here to avoid importing dart:io in state logic
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    final uploadResult = await _repository.uploadKycFile(userId: userId, file: file);
    if (!mounted) return false;

    return uploadResult.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (storagePath) async {
        final docResult = await _repository.submitKycDocument(KycDocumentModel(
          id: '',
          userId: userId,
          documentType: documentType,
          documentNumber: documentNumber,
          documentUrl: storagePath,
        ));
        if (!mounted) return false;
        return docResult.fold(
          (failure) {
            state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
            return false;
          },
          (doc) {
            state = state.copyWith(
              isSubmitting: false,
              document: doc,
              successMessage: 'Submitted for verification!',
            );
            return true;
          },
        );
      },
    );
  }
}
