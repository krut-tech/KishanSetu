import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/config/env_config.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';

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
  List<Object?> get props => [isLoading, isInitialized, errorMessage, technicalError];
}

class AppBootstrapListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Manages application initialization sequence (env config, backend services, session restore).
class AppBootstrapNotifier extends StateNotifier<AppBootstrapState> {
  final Ref _ref;
  final AppBootstrapListenable bootstrapListenable = AppBootstrapListenable();

  AppBootstrapNotifier(this._ref) : super(const AppBootstrapState()) {
    AppLogger.info('AppBootstrapNotifier constructed -> starting initialize()');
    initialize();
  }

  @override
  set state(AppBootstrapState value) {
    super.state = value;
    bootstrapListenable.notify();
  }

  Future<void> initialize() async {
    state = const AppBootstrapState(isLoading: true);
    try {
      AppLogger.info('App bootstrap: Loading environment configuration...');
      await EnvConfig.init();

      AppLogger.info('App bootstrap: Initializing Supabase backend...');
      await SupabaseService.init();

      // Refresh Riverpod network providers with initialized Supabase client
      _ref.invalidate(supabaseClientProvider);

      AppLogger.info('App bootstrap: Initializing AuthNotifier session...');
      _ref.read(authNotifierProvider).initSession();

      AppLogger.info('App bootstrap completed successfully.');
      state = const AppBootstrapState(
        isLoading: false,
        isInitialized: true,
      );
    } catch (e, stackTrace) {
      AppLogger.error('App bootstrap initialization failed: $e', e, stackTrace);
      state = AppBootstrapState(
        isLoading: false,
        isInitialized: false,
        errorMessage: 'Failed to initialize backend services. Please check connection and try again.',
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
