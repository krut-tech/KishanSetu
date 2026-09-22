import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';

abstract class NotificationRepository {
  Future<AppResult<List<NotificationModel>>> getNotifications();
  Future<AppResult<void>> markAsRead(String notificationId);
  Future<AppResult<void>> markAllAsRead();
  Stream<List<Map<String, dynamic>>> getNotificationStream(String userId);
}
