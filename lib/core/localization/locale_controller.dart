import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_market_app/core/constants/app_constants.dart';

/// Riverpod controller for managing and persisting user's selected language.
class LocaleController extends StateNotifier<Locale> {
  static const _localePrefKey = 'user_selected_locale';

  LocaleController() : super(const Locale(AppConstants.localeEnglish)) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localePrefKey);
      if (languageCode != null && _isSupported(languageCode)) {
        state = Locale(languageCode);
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    if (!_isSupported(languageCode)) return;
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefKey, languageCode);
    } catch (_) {}
  }

  bool _isSupported(String code) {
    return code == AppConstants.localeEnglish ||
        code == AppConstants.localeHindi ||
        code == AppConstants.localeGujarati;
  }
}

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(),
);
