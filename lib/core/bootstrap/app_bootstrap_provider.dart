import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/config/env_config.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/update/presentation/controllers/update_controller.dart';

/// Immutable state representing application bootstrap/initialization.
class AppBootstrapState extends Equatable {
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final String? technicalError;

  const AppBootstrapState({
    this.isLoading = true,
    this.isInitialized = false,
    this.errorMessage,
    this.technicalError,
  });

  bool get hasError => errorMessage != null;

  @override
  List<Object?> get props =>
      [isLoading, isInitialized, errorMessage, technicalError];
}

class AppBootstrapListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Manages application initialization sequence (env config, backend services, session restore).
///
/// Startup is deliberately fast and bounded:
///  * Env + Supabase (local session restore) are the only hard requirements.
///  * Push (Firebase) setup and session/profile restore run **in parallel**,
///    each with its own timeout, so a slow network can never freeze the splash.
class AppBootstrapNotifier extends StateNotifier<AppBootstrapState> {
  final Ref _ref;
  final AppBootstrapListenable bootstrapListenable = AppBootstrapListenable();

  static const Duration _pushTimeout = Duration(seconds: 6);
  static const Duration _sessionTimeout = Duration(seconds: 14);

  AppBootstrapNotifier(this._ref) : super(const AppBootstrapState()) {
    AppLogger.info('AppBootstrapNotifier constructed -> starting initialize()');
    initialize();
  }

  @override
  set state(AppBootstrapState value) {
    super.state = value;
    bootstrapListenable.notify();
  }

  Future<void> _initPush() async {
    try {
      await PushNotificationService().initialize().timeout(_pushTimeout);
    } catch (pushErr, stackTrace) {
      // Push is optional: the app keeps working with in-app notifications.
      AppLogger.error(
          'PushNotificationService init skipped during bootstrap: $pushErr',
          pushErr,
          stackTrace);
    }
  }

  Future<void> _initSession() async {
    try {
      await _ref
          .read(authNotifierProvider)
          .initSession()
          .timeout(_sessionTimeout);
    } on TimeoutException catch (e) {
      // The auth notifier keeps working in the background. If the profile
      // eventually fails to load the router shows the retry screen.
      AppLogger.warning('Session restore is taking long, continuing: $e');
    }
  }

  Future<void> initialize() async {
    state = const AppBootstrapState(isLoading: true);
    try {
      AppLogger.info('App bootstrap: Initializing EnvConfig...');
      await EnvConfig.init();

      AppLogger.info('App bootstrap: Initializing SupabaseService...');
      await SupabaseService.init();

      // Refresh Riverpod network providers with initialized Supabase client
      _ref.invalidate(supabaseClientProvider);

      AppLogger.info(
          'App bootstrap: Initializing Push + restoring session in parallel...');
      await Future.wait<void>([_initPush(), _initSession()]);

      AppLogger.info('App bootstrap completed successfully.');
      state = const AppBootstrapState(
        isLoading: false,
        isInitialized: true,
      );

      // Asynchronously trigger update check without blocking startup
      _ref.read(updateNotifierProvider.notifier).checkForUpdate();
    } catch (e, stackTrace) {
      AppLogger.error('App bootstrap initialization failed: $e', e, stackTrace);
      state = AppBootstrapState(
        isLoading: false,
        isInitialized: false,
        errorMessage:
            'Failed to initialize backend services. Please check connection and try again.',
        technicalError: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    bootstrapListenable.dispose();
    super.dispose();
  }
}

/// Riverpod provider for application bootstrap state.
final appBootstrapProvider =
    StateNotifierProvider<AppBootstrapNotifier, AppBootstrapState>((ref) {
  return AppBootstrapNotifier(ref);
});
