import 'package:equatable/equatable.dart';

/// Result row of the search_produce RPC used by advanced search & filters.
class SearchProduceModel extends Equatable {
  final String id;
  final String farmerId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double expectedPrice;
  final String? location;
  final List<String> qualityTags;
  final DateTime? harvestDate;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const SearchProduceModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expectedPrice,
    this.location,
    this.qualityTags = const [],
    this.harvestDate,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  factory SearchProduceModel.fromMap(Map<String, dynamic> map) {
    return SearchProduceModel(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      name: (map['name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'kg',
      expectedPrice: (map['expected_price'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] as String?,
      qualityTags: (map['quality_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      harvestDate: map['harvest_date'] != null ? DateTime.tryParse(map['harvest_date'] as String) : null,
      imageUrls: (map['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
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
        qualityTags,
        harvestDate,
        imageUrls,
        latitude,
        longitude,
        distanceKm,
      ];
}
