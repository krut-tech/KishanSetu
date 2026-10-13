import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';

/// Tiny on-device cache of the signed-in user's profile.
///
/// It lets the app route a returning user straight to their home screen on
/// launch (no spinner, works offline) while the fresh profile is fetched in
/// the background. All operations are best-effort and never throw.
class ProfileCache {
  ProfileCache._();

  static const String _prefix = 'cached_profile_v1_';

  static Future<UserProfile?> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$userId');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final profile = UserProfile.fromMap(map);
      return profile.id == userId ? profile : null;
    } catch (e) {
      AppLogger.warning('ProfileCache.read failed: $e');
      return null;
    }
  }

  static Future<void> write(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix${profile.id}',
        jsonEncode(profile.toCacheMap()),
      );
    } catch (e) {
      AppLogger.warning('ProfileCache.write failed: $e');
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$userId');
    } catch (e) {
      AppLogger.warning('ProfileCache.clear failed: $e');
    }
  }
}
