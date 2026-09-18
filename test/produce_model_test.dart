import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';

void main() {
  group('ProduceModel Unit Tests', () {
    test('creates ProduceModel from map correctly', () {
      final map = {
        'id': 'produce-123',
        'farmer_id': 'farmer-456',
        'name': 'Sharbati Wheat',
        'category': 'Cereals',
        'quantity': 50.0,
        'unit': 'quintal',
        'expected_price': 2450.0,
        'status': 'active',
        'location': 'Anand, Gujarat',
        'description': 'Grade A quality',
        'created_at': '2025-01-01T10:00:00Z',
      };

      final model = ProduceModel.fromMap(map);

      expect(model.id, 'produce-123');
      expect(model.farmerId, 'farmer-456');
      expect(model.name, 'Sharbati Wheat');
      expect(model.category, 'Cereals');
      expect(model.quantity, 50.0);
      expect(model.expectedPrice, 2450.0);
      expect(model.status, 'active');
    });

    test('converts ProduceModel to map correctly', () {
      const model = ProduceModel(
        id: 'produce-123',
        farmerId: 'farmer-456',
        name: 'Desi Chana',
        category: 'Pulses',
        quantity: 25.0,
        unit: 'quintal',
        expectedPrice: 5100.0,
        status: 'active',
      );

      final map = model.toMap();

      expect(map['id'], 'produce-123');
      expect(map['farmer_id'], 'farmer-456');
      expect(map['name'], 'Desi Chana');
      expect(map['quantity'], 25.0);
      expect(map['expected_price'], 5100.0);
    });

    test('copyWith updates fields correctly', () {
      const model = ProduceModel(
        id: '1',
        farmerId: 'f1',
        name: 'Rice',
        category: 'Cereals',
        quantity: 10,
        unit: 'kg',
        expectedPrice: 100,
      );

      final updated = model.copyWith(quantity: 20, expectedPrice: 120);

      expect(updated.quantity, 20);
      expect(updated.expectedPrice, 120);
      expect(updated.name, 'Rice');
    });
  });
}
