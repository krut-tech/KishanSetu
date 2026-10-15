import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';

/// Represents the result of an APK compatibility, integrity, and signature verification.
class ApkValidationResult extends Equatable {
  final bool isValid;
  final String errorCode;
  final String? errorMessage;
  final int? installedVersionCode;
  final int? apkVersionCode;
  final String? installedCertSha256;
  final String? apkCertSha256;

  const ApkValidationResult({
    required this.isValid,
    required this.errorCode,
    this.errorMessage,
    this.installedVersionCode,
    this.apkVersionCode,
    this.installedCertSha256,
    this.apkCertSha256,
  });

  @override
  List<Object?> get props => [
        isValid,
        errorCode,
        errorMessage,
        installedVersionCode,
        apkVersionCode,
        installedCertSha256,
        apkCertSha256,
      ];
}

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

  /// Verifies APK compatibility, integrity, package name, version, and signing certificate match.
  Future<ApkValidationResult> verifyApk(String filePath) async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('verifyApk', {'filePath': filePath});
      if (result == null) {
        return const ApkValidationResult(
          isValid: false,
          errorCode: 'VERIFICATION_NULL',
          errorMessage: 'Native APK verification returned null.',
        );
      }

      return ApkValidationResult(
        isValid: result['valid'] == true,
        errorCode: result['errorCode'] as String? ?? 'UNKNOWN',
        errorMessage: result['errorMessage'] as String?,
        installedVersionCode: (result['installedVersionCode'] as num?)?.toInt(),
        apkVersionCode: (result['apkVersionCode'] as num?)?.toInt(),
        installedCertSha256: result['installedCertSha256'] as String?,
        apkCertSha256: result['apkCertSha256'] as String?,
      );
    } catch (e) {
      AppLogger.error('Failed to verify APK natively: $e');
      return ApkValidationResult(
        isValid: false,
        errorCode: 'VERIFICATION_ERROR',
        errorMessage: 'Failed to verify APK: $e',
      );
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
    } on PlatformException catch (e) {
      AppLogger.error(
          'PlatformException in installApk: code=${e.code}, message=${e.message}, details=${e.details}');
      rethrow;
    } catch (e) {
      AppLogger.error('Failed to trigger installApk: $e');
      return false;
    }
  }
}
