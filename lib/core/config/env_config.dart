import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Loads and provides environment configuration safely.
class EnvConfig {
  EnvConfig._();

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      AppLogger.info('Environment variables loaded successfully.');
    } catch (e) {
      AppLogger.warning('Failed to load .env file, using default values: $e');
    }
  }

  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: 'https://dpbuhtverikgcaieucdp.supabase.co');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get appEnv =>
      dotenv.get('APP_ENV', fallback: 'development');

  static bool get isProduction => appEnv == 'production';
}
