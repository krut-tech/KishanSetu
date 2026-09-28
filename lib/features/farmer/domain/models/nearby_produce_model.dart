import 'package:equatable/equatable.dart';

/// Result row of the find_nearby_produce RPC.
class NearbyProduceModel extends Equatable {
  final String id;
  final String farmerId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double expectedPrice;
  final String? location;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const NearbyProduceModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expectedPrice,
    this.location,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory NearbyProduceModel.fromMap(Map<String, dynamic> map) {
    return NearbyProduceModel(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      name: (map['name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'kg',
      expectedPrice: (map['expected_price'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        name,
        category,
        quantity,
        unit,
        expectedPrice,
        location,
        latitude,
        longitude,
        distanceKm,
      ];
}
