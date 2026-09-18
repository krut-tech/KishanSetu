import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';

void main() {
  group('MarketPriceModel Unit Tests', () {
    test('creates MarketPriceModel from map correctly', () {
      final map = {
        'id': 'mp-1',
        'produce_name': 'Wheat',
        'category': 'Cereals',
        'market_name': 'Anand APMC',
        'location': 'Anand, Gujarat',
        'price': 2450.0,
        'unit': 'quintal',
        'price_date': '2025-01-01',
        'trend': 'up',
        'source': 'Government Mandi',
      };

      final price = MarketPriceModel.fromMap(map);

      expect(price.id, 'mp-1');
      expect(price.produceName, 'Wheat');
      expect(price.marketName, 'Anand APMC');
      expect(price.price, 2450.0);
      expect(price.trend, 'up');
    });
  });
}
