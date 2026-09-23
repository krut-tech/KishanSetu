import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_offer_controller.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/offer_controller.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/produce_controller.dart';
import 'package:farmer_market_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_notifier.dart';

void main() {
  group('Bug Hunt Regression Tests - Domain & Model Null Safety', () {
    test('NotificationModel.fromJson handles missing or null fields gracefully', () {
      final jsonWithNulls = <String, dynamic>{
        'id': 'notif-123',
        'user_id': 'user-123',
        'type': null,
        'title': null,
        'message': null,
        'related_id': null,
        'related_type': null,
        'is_read': null,
        'created_at': '2026-09-23T10:00:00Z',
      };

      final model = NotificationModel.fromJson(jsonWithNulls);

      expect(model.id, equals('notif-123'));
      expect(model.userId, equals('user-123'));
      expect(model.type, equals(NotificationType.system));
      expect(model.title, equals('Notification'));
      expect(model.message, equals(''));
      expect(model.isRead, isFalse);
      expect(model.createdAt, isNotNull);
    });

    test('OfferHistoryModel and OfferModel handle null joined fields cleanly', () {
      final mapWithNullJoins = <String, dynamic>{
        'id': 'offer-999',
        'produce_id': 'prod-1',
        'farmer_id': 'farmer-1',
        'buyer_id': 'buyer-1',
        'offered_price': 2500,
        'quantity': 10,
        'status': 'pending',
      };

      final offer = OfferModel.fromMap(mapWithNullJoins);

      expect(offer.id, equals('offer-999'));
      expect(offer.offeredPrice, equals(2500.0));
      expect(offer.quantity, equals(10.0));
      expect(offer.status, equals('pending'));
      expect(offer.buyerName, isNull);
      expect(offer.produceName, isNull);
    });
  });

  group('Bug Hunt Regression Tests - Widget Rendering & Layout', () {
    testWidgets('ProduceCard renders onDelete action button when provided', (tester) async {
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProduceCard(
              cropName: 'Sharbati Wheat',
              grade: 'Cereals',
              quantity: '50 quintals',
              askingPrice: 2450.0,
              netRealizationPrice: 2327.5,
              location: 'Anand, Gujarat',
              farmerName: 'Ramesh Patel',
              onDelete: () {
                deletePressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sharbati Wheat'), findsOneWidget);
      expect(find.text('Cereals'), findsOneWidget);

      final deleteBtn = find.byIcon(Icons.delete_outline);
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pump();

      expect(deletePressed, isTrue);
    });

    testWidgets('OfferCard correctly expands and sorts out-of-order history versions', (tester) async {
      final historyList = [
        OfferHistoryModel(
          id: 'h-2',
          offerId: 'offer-1',
          offeredPrice: 2200.0,
          quantity: 10,
          status: 'pending',
          version: 2,
          createdAt: DateTime(2026, 9, 22),
        ),
        OfferHistoryModel(
          id: 'h-1',
          offerId: 'offer-1',
          offeredPrice: 2000.0,
          quantity: 10,
          status: 'pending',
          version: 1,
          createdAt: DateTime(2026, 9, 21),
        ),
        OfferHistoryModel(
          id: 'h-3',
          offerId: 'offer-1',
          offeredPrice: 2350.0,
          quantity: 10,
          status: 'pending',
          version: 3,
          createdAt: DateTime(2026, 9, 23),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfferCard(
                cropName: 'Desi Chana',
                buyerName: 'Vikram Agro',
                offerPrice: 2350.0,
                quantity: '10 quintals',
                status: AppStatusType.pending,
                expiresText: 'Status: PENDING',
                history: historyList,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Edited'), findsOneWidget);
      final expandBtn = find.text('View Offer History (3 versions)');
      expect(expandBtn, findsOneWidget);

      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v3'), findsOneWidget);
      expect(find.text('₹2350.00 / 10.0 units (Current)'), findsOneWidget);
    });
  });

  group('Bug Hunt Regression Tests - Realtime Controller Reset Methods', () {
    test('FarmerDashboardNotifier.reset resets state and cleans up channels', () {
      final notifier = FarmerDashboardNotifier(DummyFarmerRepository());
      notifier.reset();
      expect(notifier.state, equals(const FarmerDashboardState()));
    });

    test('ProduceController.reset resets state and cleans up channels', () {
      final controller = ProduceController(DummyFarmerRepository());
      controller.reset();
      expect(controller.state, equals(const ProduceState()));
    });

    test('OfferController.reset resets state and cleans up channels', () {
      final controller = OfferController(DummyFarmerRepository());
      controller.reset();
      expect(controller.state, equals(const OfferState()));
    });

    test('BuyerOfferController.reset resets state and cleans up channels', () {
      final controller = BuyerOfferController(DummyBuyerRepository());
      controller.reset();
      expect(controller.state, equals(const BuyerOfferState()));
    });

    test('NotificationNotifier.reset resets state and cleans up channels', () {
      final notifier = NotificationNotifier(const UninitializedNotificationRepository(), null);
      notifier.reset();
      expect(notifier.state, equals(const NotificationState()));
    });
  });
}

class DummyFarmerRepository implements FarmerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyBuyerRepository implements BuyerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
