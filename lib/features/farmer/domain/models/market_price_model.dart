import 'package:equatable/equatable.dart';

/// Market price domain model mapping Supabase market_prices table.
class MarketPriceModel extends Equatable {
  final String id;
  final String produceName;
  final String? category;
  final String marketName;
  final String? location;
  final double price;
  final String unit;
  final DateTime? priceDate;
  final String trend; // 'up', 'down', 'stable'
  final String? source;
  final DateTime? createdAt;

  const MarketPriceModel({
    required this.id,
    required this.produceName,
    this.category,
    required this.marketName,
    this.location,
    required this.price,
    required this.unit,
    this.priceDate,
    this.trend = 'stable',
    this.source,
    this.createdAt,
  });

  factory MarketPriceModel.fromMap(Map<String, dynamic> map) {
    return MarketPriceModel(
      id: map['id'] as String,
      produceName: (map['produce_name'] as String?) ?? '',
      category: map['category'] as String?,
      marketName: (map['market_name'] as String?) ?? '',
      location: map['location'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'quintal',
      priceDate: map['price_date'] != null
          ? DateTime.tryParse(map['price_date'] as String)
          : null,
      trend: (map['trend'] as String?) ?? 'stable',
      source: map['source'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'produce_name': produceName,
      if (category != null) 'category': category,
      'market_name': marketName,
      if (location != null) 'location': location,
      'price': price,
      'unit': unit,
      if (priceDate != null) 'price_date': priceDate!.toIso8601String().split('T').first,
      'trend': trend,
      if (source != null) 'source': source,
    };
  }

  MarketPriceModel copyWith({
    String? id,
    String? produceName,
    String? category,
    String? marketName,
    String? location,
    double? price,
    String? unit,
    DateTime? priceDate,
    String? trend,
    String? source,
    DateTime? createdAt,
  }) {
    return MarketPriceModel(
      id: id ?? this.id,
      produceName: produceName ?? this.produceName,
      category: category ?? this.category,
      marketName: marketName ?? this.marketName,
      location: location ?? this.location,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      priceDate: priceDate ?? this.priceDate,
      trend: trend ?? this.trend,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        produceName,
        category,
        marketName,
        location,
        price,
        unit,
        priceDate,
        trend,
        source,
        createdAt,
      ];
}
