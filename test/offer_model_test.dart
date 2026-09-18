import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';

void main() {
  group('OfferModel Unit Tests', () {
    test('creates OfferModel from map correctly', () {
      final map = {
        'id': 'offer-1',
        'produce_id': 'p-1',
        'farmer_id': 'f-1',
        'buyer_id': 'b-1',
        'offered_price': 2400.0,
        'quantity': 50.0,
        'status': 'pending',
        'message': 'Interested in buying full batch',
        'buyer_profile': {
          'full_name': 'Agro Procurement Ltd',
          'company_name': 'Patel Agro Exports',
        },
        'produce': {
          'name': 'Sharbati Wheat',
          'unit': 'quintal',
        },
      };

      final offer = OfferModel.fromMap(map);

      expect(offer.id, 'offer-1');
      expect(offer.offeredPrice, 2400.0);
      expect(offer.quantity, 50.0);
      expect(offer.status, 'pending');
      expect(offer.buyerName, 'Agro Procurement Ltd');
      expect(offer.buyerCompany, 'Patel Agro Exports');
      expect(offer.produceName, 'Sharbati Wheat');
      expect(offer.produceUnit, 'quintal');
    });
  });
}
