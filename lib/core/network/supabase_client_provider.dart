import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/config/env_config.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Central service for initializing and providing Supabase client instance.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;

    final url = EnvConfig.supabaseUrl;
    final anonKey = EnvConfig.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      const msg = 'Supabase URL or Anon Key is missing in environment configuration.';
      AppLogger.warning(msg);
      throw Exception(msg);
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        debug: !EnvConfig.isProduction,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Supabase connection timed out after 8s. Please check network connection.');
        },
      );
      _initialized = true;
      AppLogger.info('Supabase initialized successfully.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Supabase: $e', e, stackTrace);
      rethrow;
    }
  }

  static SupabaseClient? get client {
    if (!_initialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return Supabase.instance.client;
  }
}

/// Provider to access SupabaseClient instance across repositories. Returns null before Supabase is initialized.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.client;
});
