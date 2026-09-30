import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/features/buyer/domain/models/wishlist_item_model.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';

class WishlistState extends Equatable {
  final List<WishlistItemModel> items;
  final bool isLoading;
  final String? errorMessage;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WishlistState copyWith({
    List<WishlistItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool contains(String produceId) => items.any((i) => i.produce.id == produceId);

  @override
  List<Object?> get props => [items, isLoading, errorMessage];
}

class WishlistController extends StateNotifier<WishlistState> {
  final BuyerRepository _repository;

  WishlistController(this._repository) : super(const WishlistState());

  Future<void> fetch(String buyerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getWishlist(buyerId);
    if (!mounted) return;
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (items) => state = state.copyWith(isLoading: false, items: items),
    );
  }

  Future<bool> add({required String buyerId, required String produceId}) async {
    final result = await _repository.addToWishlist(buyerId: buyerId, produceId: produceId);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetch(buyerId);
        return true;
      },
    );
  }

  Future<bool> remove(String wishlistId, String buyerId) async {
    final result = await _repository.removeFromWishlist(wishlistId);
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(items: state.items.where((i) => i.id != wishlistId).toList());
        return true;
      },
    );
  }
}
