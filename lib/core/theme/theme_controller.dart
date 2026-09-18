import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod StateNotifier for managing app theme mode persistence.
class ThemeController extends StateNotifier<ThemeMode> {
  static const _themePrefKey = 'user_theme_mode';

  ThemeController() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePrefKey);
      if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[savedThemeIndex];
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, mode.index);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(nextMode);
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(),
);
