import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';
import 'package:farmer_market_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_repository_provider.dart';

class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final String? errorMessage;
  
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, notifications, errorMessage];
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final SupabaseClient? _supabaseClient;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  String? _currentUserId;

  NotificationNotifier(this._repository, this._supabaseClient) : super(const NotificationState()) {
    _init();
  }

  void _init() {
    final initialUserId = _supabaseClient?.auth.currentUser?.id;
    if (initialUserId != null) {
      _currentUserId = initialUserId;
      _setupStream(initialUserId);
    }

    _authSubscription = _supabaseClient?.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      final session = event.session;
      final userId = session?.user.id;
      
      if (userId != null && (userId != _currentUserId || _streamSubscription == null)) {
        _currentUserId = userId;
        _setupStream(userId);
      } else if (userId == null) {
        _currentUserId = null;
        _streamSubscription?.cancel();
        state = const NotificationState();
      }
    });
  }

  void _setupStream(String userId) {
    _streamSubscription?.cancel();
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    _streamSubscription = _repository.getNotificationStream(userId).listen(
      (data) {
        final notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();
            
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
        );
      },
      onError: (error) {
        AppLogger.error('Notification stream error', error);
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load notifications in real-time',
        );
      },
    );
  }

  Future<void> refresh() async {
    if (_currentUserId == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getNotifications();
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (notifications) {
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
        );
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final result = await _repository.markAsRead(id);
    result.fold(
      (failure) {
        AppLogger.error('Failed to mark notification $id as read: ${failure.message}');
      },
      (_) {
        // We let the realtime stream handle the update on UI
        // But optimistic update can be done here.
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
        }).toList();
        state = state.copyWith(notifications: updatedNotifications);
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result = await _repository.markAllAsRead();
    result.fold(
      (failure) {
        AppLogger.error('Failed to mark all as read: ${failure.message}');
      },
      (_) {
        final updatedNotifications = state.notifications.map((n) {
          return n.copyWith(isRead: true);
        }).toList();
        state = state.copyWith(notifications: updatedNotifications);
      },
    );
  }

  void reset() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentUserId = null;
    state = const NotificationState();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return NotificationNotifier(repository, supabaseClient);
});
