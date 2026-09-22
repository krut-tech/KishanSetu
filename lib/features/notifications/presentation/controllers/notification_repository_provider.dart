import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:farmer_market_app/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) {
    return const UninitializedNotificationRepository();
  }
  return NotificationRepositoryImpl(supabaseClient);
});
