import 'package:equatable/equatable.dart';

/// A farmer's quote submitted against an open [RfqModel].
class RfqResponseModel extends Equatable {
  final String id;
  final String rfqId;
  final String farmerId;
  final double offeredPrice;
  final double offeredQuantity;
  final String? message;
  final String status; // pending, accepted, rejected
  final DateTime? createdAt;
  final String? farmerName;
  final String? farmerDistrict;

  const RfqResponseModel({
    required this.id,
    required this.rfqId,
    required this.farmerId,
    required this.offeredPrice,
    required this.offeredQuantity,
    this.message,
    this.status = 'pending',
    this.createdAt,
    this.farmerName,
    this.farmerDistrict,
  });

  factory RfqResponseModel.fromMap(Map<String, dynamic> map) {
    String? farmerName;
    String? farmerDistrict;
    if (map['farmer_profile'] is Map) {
      final f = map['farmer_profile'] as Map<String, dynamic>;
      farmerName = f['full_name'] as String?;
      farmerDistrict = f['district'] as String?;
    }

    return RfqResponseModel(
      id: map['id'] as String,
      rfqId: map['rfq_id'] as String,
      farmerId: map['farmer_id'] as String,
      offeredPrice: (map['offered_price'] as num?)?.toDouble() ?? 0.0,
      offeredQuantity: (map['offered_quantity'] as num?)?.toDouble() ?? 0.0,
      message: map['message'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      farmerName: farmerName,
      farmerDistrict: farmerDistrict,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rfq_id': rfqId,
      'farmer_id': farmerId,
      'offered_price': offeredPrice,
      'offered_quantity': offeredQuantity,
      if (message != null) 'message': message,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        rfqId,
        farmerId,
        offeredPrice,
        offeredQuantity,
        message,
        status,
        createdAt,
        farmerName,
        farmerDistrict,
      ];
}
