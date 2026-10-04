import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/dispute_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/kyc_document_model.dart';
import 'package:farmer_market_app/features/trust_safety/domain/repositories/trust_safety_repository.dart';

class AdminState extends Equatable {
  final List<UserProfile> users;
  final List<KycDocumentModel> kycQueue;
  final List<ProduceModel> listings;
  final List<DisputeModel> disputes;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AdminState({
    this.users = const [],
    this.kycQueue = const [],
    this.listings = const [],
    this.disputes = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminState copyWith({
    List<UserProfile>? users,
    List<KycDocumentModel>? kycQueue,
    List<ProduceModel>? listings,
    List<DisputeModel>? disputes,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminState(
      users: users ?? this.users,
      kycQueue: kycQueue ?? this.kycQueue,
      listings: listings ?? this.listings,
      disputes: disputes ?? this.disputes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [users, kycQueue, listings, disputes, isLoading, errorMessage, successMessage];
}

/// Drives the Admin Panel: user management, KYC review, listing moderation, disputes.
class AdminController extends StateNotifier<AdminState> {
  final TrustSafetyRepository _repository;

  AdminController(this._repository) : super(const AdminState());

  Future<void> fetchUsers({String? role, String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.adminGetUsers(role: role, search: search);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (users) => state = state.copyWith(isLoading: false, users: users),
    );
  }

  Future<bool> setAccountStatus(String userId, String status, {String? reason}) async {
    final result = await _repository.adminSetAccountStatus(userId, status, reason: reason);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          users: state.users
              .map((u) => u.id == userId ? u.copyWith(accountStatus: status) : u)
              .toList(),
          successMessage: 'Account status updated.',
        );
        return true;
      },
    );
  }

  Future<void> fetchKycQueue({String status = 'pending'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.adminGetKycQueue(status: status);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (queue) => state = state.copyWith(isLoading: false, kycQueue: queue),
    );
  }

  Future<bool> reviewKyc(String documentId, String status, {String? rejectionReason}) async {
    final result = await _repository.adminReviewKyc(documentId, status, rejectionReason: rejectionReason);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          kycQueue: state.kycQueue.where((d) => d.id != documentId).toList(),
          successMessage: 'KYC reviewed.',
        );
        return true;
      },
    );
  }

  Future<void> fetchListings({String? moderationStatus}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.adminGetProduceForModeration(moderationStatus: moderationStatus);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (listings) => state = state.copyWith(isLoading: false, listings: listings),
    );
  }

  Future<bool> moderateProduce(String produceId, String status, {String? note}) async {
    final result = await _repository.adminModerateProduce(produceId, status, note: note);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          listings: state.listings
              .map((p) => p.id == produceId ? p.copyWith(status: p.status) : p)
              .where((p) => status != 'removed' || p.id != produceId)
              .toList(),
          successMessage: 'Listing moderated.',
        );
        return true;
      },
    );
  }

  Future<void> fetchDisputes({String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.adminGetDisputes(status: status);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (disputes) => state = state.copyWith(isLoading: false, disputes: disputes),
    );
  }

  Future<bool> resolveDispute(String disputeId, String status, {String? resolutionNote}) async {
    final result = await _repository.adminResolveDispute(disputeId, status, resolutionNote: resolutionNote);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          disputes: state.disputes.map((d) {
            if (d.id != disputeId) return d;
            return DisputeModel(
              id: d.id,
              reporterId: d.reporterId,
              reportedUserId: d.reportedUserId,
              relatedOrderId: d.relatedOrderId,
              relatedOfferId: d.relatedOfferId,
              type: d.type,
              description: d.description,
              status: status,
              resolutionNote: resolutionNote,
              createdAt: d.createdAt,
              resolvedAt: DateTime.now(),
              reporterName: d.reporterName,
              reportedUserName: d.reportedUserName,
            );
          }).toList(),
          successMessage: 'Dispute updated.',
        );
        return true;
      },
    );
  }
}
