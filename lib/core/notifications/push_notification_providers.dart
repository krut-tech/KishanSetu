import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';

/// Provider exposing singleton instance of [PushNotificationService].
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
