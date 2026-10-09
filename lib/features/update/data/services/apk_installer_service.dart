import 'package:flutter/services.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Wraps native Android MethodChannel calls for package installation & permissions.
class ApkInstallerService {
  static const MethodChannel _channel =
      MethodChannel('com.farmermarket.farmer_market_app/apk_installer');

  /// Checks if the app has permission to request package installs (API 26+).
  Future<bool> canRequestPackageInstalls() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return result ?? false;
    } catch (e) {
      AppLogger.error('Failed to check canRequestPackageInstalls: $e');
      return false;
    }
  }

  /// Opens Android Settings screen to manage unknown app sources for KisanSetu.
  Future<bool> openInstallPermissionSettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } catch (e) {
      AppLogger.error('Failed to open install permission settings: $e');
      return false;
    }
  }

  /// Passes [filePath] to Android Intent handler to trigger system Package Installer.
  Future<bool> installApk(String filePath) async {
    try {
      AppLogger.info('Triggering Android package installer for: $filePath');
      final result = await _channel.invokeMethod<bool>(
        'installApk',
        {'filePath': filePath},
      );
      return result ?? false;
    } catch (e) {
      AppLogger.error('Failed to trigger installApk: $e');
      return false;
    }
  }
}
