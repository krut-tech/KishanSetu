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
        createdAt,
        updatedAt,
        farmerName,
        farmerDistrict,
      ];
}
