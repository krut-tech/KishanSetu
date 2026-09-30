import 'package:equatable/equatable.dart';

/// A buyer's recurring order against a specific farmer's produce listing.
class SubscriptionModel extends Equatable {
  final String id;
  final String buyerId;
  final String farmerId;
  final String produceId;
  final double quantity;
  final String frequency; // weekly, biweekly, monthly
  final DateTime nextDeliveryDate;
  final String status; // active, paused, cancelled
  final DateTime? createdAt;
  final String? produceName;
  final String? unit;
  final String? farmerName;

  const SubscriptionModel({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.produceId,
    required this.quantity,
    required this.frequency,
    required this.nextDeliveryDate,
    this.status = 'active',
    this.createdAt,
    this.produceName,
    this.unit,
    this.farmerName,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    String? produceName;
    String? unit;
    if (map['produce'] is Map) {
      final p = map['produce'] as Map<String, dynamic>;
      produceName = p['name'] as String?;
      unit = p['unit'] as String?;
    }
    String? farmerName;
    if (map['farmer_profile'] is Map) {
      farmerName = (map['farmer_profile'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return SubscriptionModel(
      id: map['id'] as String,
      buyerId: map['buyer_id'] as String,
      farmerId: map['farmer_id'] as String,
      produceId: map['produce_id'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      frequency: (map['frequency'] as String?) ?? 'weekly',
      nextDeliveryDate: DateTime.parse(map['next_delivery_date'] as String),
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      produceName: produceName,
      unit: unit,
      farmerName: farmerName,
    );
  }

  Map<String, dynamic> toMap() {
    final d = nextDeliveryDate;
    final dateStr =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'produce_id': produceId,
      'quantity': quantity,
      'frequency': frequency,
      'next_delivery_date': dateStr,
      'status': status,
    };
  }

  SubscriptionModel copyWith({String? status, DateTime? nextDeliveryDate}) {
    return SubscriptionModel(
      id: id,
      buyerId: buyerId,
      farmerId: farmerId,
      produceId: produceId,
      quantity: quantity,
      frequency: frequency,
      nextDeliveryDate: nextDeliveryDate ?? this.nextDeliveryDate,
      status: status ?? this.status,
      createdAt: createdAt,
      produceName: produceName,
      unit: unit,
      farmerName: farmerName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        buyerId,
        farmerId,
        produceId,
        quantity,
        frequency,
        nextDeliveryDate,
        status,
        createdAt,
        produceName,
        unit,
        farmerName,
      ];
}
