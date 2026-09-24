import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    AppLogger.info('Handling FCM background message: ${message.messageId}, data: ${message.data}');
  } catch (e, stack) {
    AppLogger.error('Error in FCM background handler', e, stack);
  }
}

/// Core service managing Android Push Notifications, FCM token lifecycle,
/// local foreground notifications, and tap-to-navigate routing.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  String? _lastSyncedToken;
  String? _lastSyncedUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Holds a pending route to navigate to if app was launched via notification from terminated state.
  static String? pendingInitialRoute;

  /// Android notification channel configuration.
  static const String channelId = 'kisansetu_notifications';
  static const String channelName = 'KisanSetu Notifications';
  static const String channelDescription =
      'Notifications for offers, produce listings, and market price updates.';

  /// Function callback for route navigation.
  static void Function(String route)? onNavigate;

  bool get isInitialized => _isInitialized;

  /// Initializes FCM, Flutter Local Notifications, and foreground/background listeners.
  Future<void> initialize({void Function(String route)? navigateCallback}) async {
    if (navigateCallback != null) {
      onNavigate = navigateCallback;
    }

    if (_isInitialized) {
      AppLogger.info('PushNotificationService already initialized.');
      return;
    }

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      AppLogger.info('Initializing PushNotificationService...');

      // Initialize Firebase App
      await Firebase.initializeApp();

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize Local Notifications for foreground heads-up display
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInitSettings);

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            AppLogger.info('Foreground local notification tapped with payload: $payload');
            _handleRouteNavigation(payload);
          }
        },
      );

      // Create high-importance notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
      }

      // Configure foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Received FCM foreground message: ${message.messageId}');
        _showForegroundLocalNotification(message);
      });

      // Listen for notification taps when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('App opened from background via FCM notification tap: ${message.data}');
        final route = resolveRouteFromData(message.data);
        _handleRouteNavigation(route);
      });

      // Check if app was opened from terminated state via notification tap
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App launched from terminated state via FCM notification tap: ${initialMessage.data}');
        final route = resolveRouteFromData(initialMessage.data);
        pendingInitialRoute = route;
      }

      _isInitialized = true;
      _initCompleter?.complete();
      AppLogger.info('PushNotificationService initialized successfully.');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize PushNotificationService: $e', e, stack);
      _initCompleter?.completeError(e, stack);
      _initCompleter = null;
      // Safe fallback: App will continue working with in-app notifications
    }
  }

  /// Display a local heads-up notification when app is in foreground.
  void _showForegroundLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'KisanSetu Notification';
    final body = notification?.body ?? data['body'] ?? '';
    final route = resolveRouteFromData(data);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    final notificationId = (data['notification_id'] ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode;

    _localNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: route,
    );
  }

  /// Resolves target route from FCM payload data.
  static String resolveRouteFromData(Map<String, dynamic> data) {
    if (data.containsKey('route') && (data['route'] as String).trim().isNotEmpty) {
      return (data['route'] as String).trim();
    }

    final type = (data['type'] as String?)?.toLowerCase() ?? '';
    switch (type) {
      case 'new_offer':
      case 'offer_accepted':
      case 'offer_rejected':
      case 'counter_offer':
      case 'offer_updated':
      case 'offer_cancelled':
        return '/offers';
      case 'produce':
      case 'produce_interest':
        return '/my-produce';
      case 'market_price':
      case 'market_price_update':
        return '/market-prices';
      default:
        return '/notifications';
    }
  }

  /// Triggers route navigation callback if present, or stores pending route.
  static void _handleRouteNavigation(String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      pendingInitialRoute = route;
    }
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+ / iOS.
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      AppLogger.info('Notification permission status: ${settings.authorizationStatus}');
      return granted;
    } catch (e, stack) {
      AppLogger.error('Error requesting notification permission: $e', e, stack);
      return false;
    }
  }

  /// Syncs FCM device push token to Supabase `public.user_devices` table.
  Future<void> syncDeviceToken(
    String userId,
    SupabaseClient supabaseClient, {
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await requestNotificationPermission();

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.warning('FCM token is null or empty. Skipping token sync.');
        return;
      }

      if (_lastSyncedToken == token && _lastSyncedUserId == userId) {
        AppLogger.info('FCM device token already synced for user: $userId');
        return;
      }

      AppLogger.info('Syncing FCM device token to Supabase user_devices for user: $userId');

      await supabaseClient.from('user_devices').upsert(
        {
          'user_id': userId,
          'push_token': token,
          'platform': 'android',
          'device_id': deviceId,
          'app_version': appVersion ?? '1.0.0+1',
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'push_token',
      );

      _lastSyncedToken = token;
      _lastSyncedUserId = userId;

      // Subscribe to token refresh
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        AppLogger.info('FCM token refreshed. Updating Supabase user_devices...');
        try {
          await supabaseClient.from('user_devices').upsert(
            {
              'user_id': userId,
              'push_token': newToken,
              'platform': 'android',
              'device_id': deviceId,
              'app_version': appVersion ?? '1.0.0+1',
              'is_active': true,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'push_token',
          );
          _lastSyncedToken = newToken;
        } catch (e) {
          AppLogger.error('Failed to update refreshed FCM token in Supabase: $e');
        }
      });
    } catch (e, stack) {
      AppLogger.error('Failed to sync device push token to Supabase: $e', e, stack);
    }
  }

  /// Deactivates FCM device push token in Supabase on logout.
  Future<void> deactivateDeviceToken(String userId, SupabaseClient supabaseClient) async {
    try {
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      final token = _lastSyncedToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.info('Deactivating FCM push token in Supabase for user: $userId');
        await supabaseClient.from('user_devices').update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('push_token', token).eq('user_id', userId);
      }
    } catch (e, stack) {
      AppLogger.error('Error deactivating device token on logout: $e', e, stack);
    } finally {
      _lastSyncedToken = null;
      _lastSyncedUserId = null;
    }
  }
}
