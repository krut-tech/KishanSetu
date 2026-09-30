import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/buyer/domain/models/subscription_model.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';

class SubscriptionState extends Equatable {
  final List<SubscriptionModel> subscriptions;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  SubscriptionState copyWith({
    List<SubscriptionModel>? subscriptions,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [subscriptions, isLoading, isSubmitting, errorMessage, successMessage];
}

class SubscriptionController extends StateNotifier<SubscriptionState> {
  final BuyerRepository _repository;

  SubscriptionController(this._repository) : super(const SubscriptionState());

  Future<void> fetch(String buyerId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final result = await _repository.getSubscriptions(buyerId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (subs) => state = state.copyWith(isLoading: false, subscriptions: subs),
    );
  }

  Future<bool> create(SubscriptionModel subscription) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    final result = await _repository.createSubscription(subscription);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
      (created) {
        state = state.copyWith(
          isSubmitting: false,
          subscriptions: [...state.subscriptions, created],
          successMessage: 'Recurring order set up!',
        );
        return true;
      },
    );
  }

  Future<bool> updateStatus(String subscriptionId, String status) async {
    final result = await _repository.updateSubscriptionStatus(subscriptionId, status);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          subscriptions: state.subscriptions
              .map((s) => s.id == subscriptionId ? s.copyWith(status: status) : s)
              .toList(),
        );
        return true;
      },
    );
  }
}
