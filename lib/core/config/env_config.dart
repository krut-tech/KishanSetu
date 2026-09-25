import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Loads and provides environment configuration safely.
class EnvConfig {
  EnvConfig._();

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      AppLogger.info('Environment variables loaded successfully from .env.');
    } catch (e) {
      try {
        await dotenv.load(fileName: '.env.example');
        AppLogger.info('Environment variables loaded from .env.example fallback.');
      } catch (e2) {
        AppLogger.warning('Failed to load environment configuration files, using default fallbacks: $e2');
      }
    }
  }

  // NOTE: no hardcoded Supabase URL fallback here on purpose. Falling back to
  // a real project URL when .env/.env.example fail to load would silently
  // point the app at an unintended backend with no visible warning.
  // SupabaseService.init() already treats an empty URL/key as a hard error
  // and surfaces a clear "Failed to initialize backend services" message via
  // AppBootstrapNotifier, which is the correct failure mode here.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get appEnv =>
      dotenv.get('APP_ENV', fallback: 'development');

  static bool get isProduction => appEnv == 'production';
}
