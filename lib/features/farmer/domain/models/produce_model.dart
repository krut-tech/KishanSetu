import 'package:equatable/equatable.dart';

/// Produce domain model mapping Supabase produce table.
class ProduceModel extends Equatable {
  final String id;
  final String farmerId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double expectedPrice;
  final String status; // 'active', 'pending', 'sold', 'draft', 'archived'
  final String? location;
  final String? description;
  final List<String> imageUrls;
  final List<String> qualityTags;
  final double? lowStockThreshold;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? farmerName;
  final String? farmerDistrict;

  const ProduceModel({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expectedPrice,
    this.status = 'active',
    this.location,
    this.description,
    this.imageUrls = const [],
    this.qualityTags = const [],
    this.lowStockThreshold,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.farmerName,
    this.farmerDistrict,
  });

  factory ProduceModel.fromMap(Map<String, dynamic> map) {
    String? fName;
    String? fDistrict;
    if (map['farmer_profile'] is Map) {
      final fMap = map['farmer_profile'] as Map<String, dynamic>;
      fName = fMap['full_name'] as String?;
      fDistrict = fMap['district'] as String?;
    } else if (map['farmer'] is Map) {
      final fMap = map['farmer'] as Map<String, dynamic>;
      fName = fMap['full_name'] as String?;
      fDistrict = fMap['district'] as String?;
    }

    return ProduceModel(
      id: map['id'] as String,
      farmerId: map['farmer_id'] as String,
      name: (map['name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'kg',
      expectedPrice: (map['expected_price'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] as String?) ?? 'active',
      location: map['location'] as String?,
      description: map['description'] as String?,
      imageUrls: (map['image_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      qualityTags: (map['quality_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      farmerName: fName ?? map['farmer_name'] as String?,
      farmerDistrict: fDistrict ?? map['farmer_district'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'farmer_id': farmerId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expected_price': expectedPrice,
      'status': status,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      'image_urls': imageUrls,
      'quality_tags': qualityTags,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  ProduceModel copyWith({
    String? id,
    String? farmerId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? expectedPrice,
    String? status,
    String? location,
    String? description,
    List<String>? imageUrls,
    List<String>? qualityTags,
    double? lowStockThreshold,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmerName,
    String? farmerDistrict,
  }) {
    return ProduceModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      status: status ?? this.status,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      qualityTags: qualityTags ?? this.qualityTags,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmerName: farmerName ?? this.farmerName,
      farmerDistrict: farmerDistrict ?? this.farmerDistrict,
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
        status,
        location,
        description,
        imageUrls,
        qualityTags,
        lowStockThreshold,
        latitude,
        longitude,
        createdAt,
        updatedAt,
        farmerName,
        farmerDistrict,
      ];
}
