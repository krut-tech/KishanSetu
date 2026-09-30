import 'package:equatable/equatable.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

/// A saved produce listing on a buyer's wishlist.
class WishlistItemModel extends Equatable {
  final String id; // wishlists.id (needed to remove)
  final ProduceModel produce;
  final DateTime? createdAt;

  const WishlistItemModel({
    required this.id,
    required this.produce,
    this.createdAt,
  });

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    return WishlistItemModel(
      id: map['id'] as String,
      produce: ProduceModel.fromMap(map['produce'] as Map<String, dynamic>),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [id, produce, createdAt];
}
