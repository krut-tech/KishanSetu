import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';
import 'package:farmer_market_app/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final SupabaseClient _supabaseClient;

  NotificationRepositoryImpl(this._supabaseClient);

  @override
  Future<AppResult<List<NotificationModel>>> getNotifications() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final List<dynamic> data = response;
      final notifications = data
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(notifications);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch notifications', e, stackTrace);
      return Left(DatabaseFailure('Failed to fetch notifications: $e'));
    }
  }

  @override
  Future<AppResult<void>> markAsRead(String notificationId) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      await _supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark notification as read', e, stackTrace);
      return Left(DatabaseFailure('Failed to mark notification as read: $e'));
    }
  }

  @override
  Future<AppResult<void>> markAllAsRead() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      await _supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark all notifications as read', e, stackTrace);
      return Left(DatabaseFailure('Failed to mark all notifications as read: $e'));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getNotificationStream(String userId) {
    return _supabaseClient
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}

/// A safe fallback repository implementation used when Supabase backend client is unavailable/uninitialized.
class UninitializedNotificationRepository implements NotificationRepository {
  const UninitializedNotificationRepository();

  @override
  Future<AppResult<List<NotificationModel>>> getNotifications() async {
    return const Right([]);
  }

  @override
  Future<AppResult<void>> markAsRead(String notificationId) async {
    return const Right(null);
  }

  @override
  Future<AppResult<void>> markAllAsRead() async {
    return const Right(null);
  }

  @override
  Stream<List<Map<String, dynamic>>> getNotificationStream(String userId) {
    return Stream.value(<Map<String, dynamic>>[]);
  }
}
