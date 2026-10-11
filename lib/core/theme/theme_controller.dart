import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod StateNotifier for managing app theme mode persistence.
/// Theme changes are applied immediately; preference writes are serialized so
/// rapid taps cannot make an older write win over the latest selection.
class ThemeController extends StateNotifier<ThemeMode> {
  static const _themePrefKey = 'user_theme_mode';

  bool _userChangedTheme = false;
  Future<void> _persistQueue = Future<void>.value();

  ThemeController() : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePrefKey);
      // Do not let a slow preference read overwrite a choice made meanwhile.
      if (!_userChangedTheme &&
          savedThemeIndex != null &&
          savedThemeIndex >= 0 &&
          savedThemeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[savedThemeIndex];
      }
    } catch (_) {
      // Theme persistence is best-effort; the app remains usable.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    if (state == mode) return Future<void>.value();

    _userChangedTheme = true;
    state = mode; // Apply instantly; never wait for disk I/O to repaint.
    _persistQueue = _persistQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themePrefKey, mode.index);
      } catch (_) {
        // A failed preference write must not freeze or revert the UI.
      }
    });
    return _persistQueue;
  }

  Future<void> toggleTheme() {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    return setThemeMode(nextMode);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(),
);
