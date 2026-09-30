import 'package:equatable/equatable.dart';

/// A buyer's bulk requirement request that farmers can respond to with a quote.
class RfqModel extends Equatable {
  final String id;
  final String buyerId;
  final String produceName;
  final String? category;
  final double quantityNeeded;
  final String unit;
  final double? targetPrice;
  final String? deliveryLocation;
  final DateTime? neededBy;
  final String status; // open, closed, fulfilled
  final DateTime? createdAt;
  final int? responseCount;
  final String? buyerName;

  const RfqModel({
    required this.id,
    required this.buyerId,
    required this.produceName,
    this.category,
    required this.quantityNeeded,
    this.unit = 'kg',
    this.targetPrice,
    this.deliveryLocation,
    this.neededBy,
    this.status = 'open',
    this.createdAt,
    this.responseCount,
    this.buyerName,
  });

  factory RfqModel.fromMap(Map<String, dynamic> map) {
    String? buyerName;
    if (map['buyer_profile'] is Map) {
      buyerName = (map['buyer_profile'] as Map<String, dynamic>)['full_name'] as String?;
    }
    int? responseCount;
    final responses = map['rfq_responses'];
    if (responses is List) {
      responseCount = responses.length;
    } else if (responses is Map && responses['count'] != null) {
      responseCount = (responses['count'] as num).toInt();
    }

    return RfqModel(
      id: map['id'] as String,
      buyerId: map['buyer_id'] as String,
      produceName: (map['produce_name'] as String?) ?? '',
      category: map['category'] as String?,
      quantityNeeded: (map['quantity_needed'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'kg',
      targetPrice: (map['target_price'] as num?)?.toDouble(),
      deliveryLocation: map['delivery_location'] as String?,
      neededBy: map['needed_by'] != null ? DateTime.tryParse(map['needed_by'] as String) : null,
      status: (map['status'] as String?) ?? 'open',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      responseCount: responseCount,
      buyerName: buyerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'buyer_id': buyerId,
      'produce_name': produceName,
      if (category != null) 'category': category,
      'quantity_needed': quantityNeeded,
      'unit': unit,
      if (targetPrice != null) 'target_price': targetPrice,
      if (deliveryLocation != null) 'delivery_location': deliveryLocation,
      if (neededBy != null)
        'needed_by':
            '${neededBy!.year.toString().padLeft(4, '0')}-${neededBy!.month.toString().padLeft(2, '0')}-${neededBy!.day.toString().padLeft(2, '0')}',
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        buyerId,
        produceName,
        category,
        quantityNeeded,
        unit,
        targetPrice,
        deliveryLocation,
        neededBy,
        status,
        createdAt,
        responseCount,
        buyerName,
      ];
}
