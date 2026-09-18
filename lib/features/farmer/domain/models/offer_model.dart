import 'package:equatable/equatable.dart';

/// Offer domain model mapping Supabase offers table.
class OfferModel extends Equatable {
  final String id;
  final String produceId;
  final String farmerId;
  final String buyerId;
  final double offeredPrice;
  final double quantity;
  final String status; // 'pending', 'accepted', 'rejected', 'countered', 'cancelled'
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional joined data
  final String? buyerName;
  final String? buyerCompany;
  final String? farmerName;
  final String? produceName;
  final String? produceUnit;
  final String? produceCategory;
  final double? produceExpectedPrice;
  final String? produceLocation;

  const OfferModel({
    required this.id,
    required this.produceId,
    required this.farmerId,
    required this.buyerId,
    required this.offeredPrice,
    required this.quantity,
    this.status = 'pending',
    this.message,
    this.createdAt,
    this.updatedAt,
    this.buyerName,
    this.buyerCompany,
    this.farmerName,
    this.produceName,
    this.produceUnit,
    this.produceCategory,
    this.produceExpectedPrice,
    this.produceLocation,
  });

  factory OfferModel.fromMap(Map<String, dynamic> map) {
    String? bName;
    String? bCompany;
    if (map['buyer_profile'] is Map) {
      final buyerMap = map['buyer_profile'] as Map<String, dynamic>;
      bName = buyerMap['full_name'] as String?;
      bCompany = buyerMap['company_name'] as String?;
    } else if (map['buyer'] is Map) {
      final buyerMap = map['buyer'] as Map<String, dynamic>;
      bName = buyerMap['full_name'] as String?;
      bCompany = buyerMap['company_name'] as String?;
    }

    String? fName;
    if (map['farmer_profile'] is Map) {
      final farmerMap = map['farmer_profile'] as Map<String, dynamic>;
      fName = farmerMap['full_name'] as String?;
    } else if (map['farmer'] is Map) {
      final farmerMap = map['farmer'] as Map<String, dynamic>;
      fName = farmerMap['full_name'] as String?;
    }

    String? pName;
    String? pUnit;
    String? pCategory;
    double? pExpectedPrice;
    String? pLocation;
    if (map['produce'] is Map) {
      final produceMap = map['produce'] as Map<String, dynamic>;
      pName = produceMap['name'] as String?;
      pUnit = produceMap['unit'] as String?;
      pCategory = produceMap['category'] as String?;
      pExpectedPrice = (produceMap['expected_price'] as num?)?.toDouble();
      pLocation = produceMap['location'] as String?;
    }

    return OfferModel(
      id: map['id'] as String,
      produceId: map['produce_id'] as String,
      farmerId: map['farmer_id'] as String,
      buyerId: map['buyer_id'] as String,
      offeredPrice: (map['offered_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] as String?) ?? 'pending',
      message: map['message'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      buyerName: bName ?? map['buyer_name'] as String?,
      buyerCompany: bCompany ?? map['buyer_company'] as String?,
      farmerName: fName ?? map['farmer_name'] as String?,
      produceName: pName ?? map['produce_name'] as String?,
      produceUnit: pUnit ?? map['produce_unit'] as String?,
      produceCategory: pCategory ?? map['produce_category'] as String?,
      produceExpectedPrice: pExpectedPrice ?? (map['produce_expected_price'] as num?)?.toDouble(),
      produceLocation: pLocation ?? map['produce_location'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'produce_id': produceId,
      'farmer_id': farmerId,
      'buyer_id': buyerId,
      'offered_price': offeredPrice,
      'quantity': quantity,
      'status': status,
      if (message != null) 'message': message,
    };
  }

  OfferModel copyWith({
    String? id,
    String? produceId,
    String? farmerId,
    String? buyerId,
    double? offeredPrice,
    double? quantity,
    String? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? buyerName,
    String? buyerCompany,
    String? farmerName,
    String? produceName,
    String? produceUnit,
    String? produceCategory,
    double? produceExpectedPrice,
    String? produceLocation,
  }) {
    return OfferModel(
      id: id ?? this.id,
      produceId: produceId ?? this.produceId,
      farmerId: farmerId ?? this.farmerId,
      buyerId: buyerId ?? this.buyerId,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerName: buyerName ?? this.buyerName,
      buyerCompany: buyerCompany ?? this.buyerCompany,
      farmerName: farmerName ?? this.farmerName,
      produceName: produceName ?? this.produceName,
      produceUnit: produceUnit ?? this.produceUnit,
      produceCategory: produceCategory ?? this.produceCategory,
      produceExpectedPrice: produceExpectedPrice ?? this.produceExpectedPrice,
      produceLocation: produceLocation ?? this.produceLocation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        produceId,
        farmerId,
        buyerId,
        offeredPrice,
        quantity,
        status,
        message,
        createdAt,
        updatedAt,
        buyerName,
        buyerCompany,
        farmerName,
        produceName,
        produceUnit,
        produceCategory,
        produceExpectedPrice,
        produceLocation,
      ];
}
