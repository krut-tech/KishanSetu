import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/update/data/services/apk_installer_service.dart';
import 'package:farmer_market_app/features/update/data/services/update_service.dart';
import 'package:farmer_market_app/features/update/domain/models/app_update_info.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  permissionRequired,
  installing,
  error,
}

class UpdateState extends Equatable {
  final UpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final double downloadProgress;
  final String? downloadedApkPath;
  final String? errorMessage;
  final bool hasShownPopup;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.downloadedApkPath,
    this.errorMessage,
    this.hasShownPopup = false,
  });

  bool get isDownloading => status == UpdateStatus.downloading;

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdateInfo? updateInfo,
    double? downloadProgress,
    String? downloadedApkPath,
    bool clearDownloadedApkPath = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? hasShownPopup,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedApkPath: clearDownloadedApkPath
          ? null
          : (downloadedApkPath ?? this.downloadedApkPath),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      hasShownPopup: hasShownPopup ?? this.hasShownPopup,
    );
  }

  @override
  List<Object?> get props => [
        status,
        updateInfo,
        downloadProgress,
        downloadedApkPath,
        errorMessage,
        hasShownPopup,
      ];
}

class UpdateNotifier extends StateNotifier<UpdateState>
    with WidgetsBindingObserver {
  final UpdateService _updateService;
  final ApkInstallerService _installerService;
  final Future<PackageInfo> Function() _getPackageInfo;

  UpdateNotifier({
    UpdateService? updateService,
    ApkInstallerService? installerService,
    Future<PackageInfo> Function()? getPackageInfo,
  })  : _updateService = updateService ?? UpdateService(),
        _installerService = installerService ?? ApkInstallerService(),
        _getPackageInfo = getPackageInfo ?? PackageInfo.fromPlatform,
        super(const UpdateState()) {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onAppResumed();
    }
  }

  /// Handles app resume events:
  /// 1. Rechecks install permissions if permission was requested.
  /// 2. Verifies installed package version after returning from system package installer.
  Future<void> onAppResumed() async {
    if (state.status == UpdateStatus.permissionRequired) {
      AppLogger.info(
        'App resumed while permission required. Rechecking install permission...',
      );
      await recheckPermissionAndInstall();
    } else if (state.status == UpdateStatus.installing ||
        state.status == UpdateStatus.downloaded) {
      AppLogger.info(
        'App resumed after package installer attempt. Verifying installed package version...',
      );
      await verifyInstalledVersionAndHandleResult();
    }
  }

  /// Verifies whether the update was successfully installed after returning from installer.
  Future<void> verifyInstalledVersionAndHandleResult() async {
    final info = state.updateInfo;
    if (info == null) return;

    try {
      final packageInfo = await _getPackageInfo();
      final installedVersionStr =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      final targetVersion = info.latestVersion;
      final isStillNewer =
          UpdateService.isVersionNewer(targetVersion, installedVersionStr);

      if (!isStillNewer) {
        AppLogger.info(
          'Update verification success! Installed version ($installedVersionStr) is up to date with target $targetVersion.',
        );

        final apkPath = state.downloadedApkPath;
        if (apkPath != null && apkPath.isNotEmpty) {
          try {
            final file = File(apkPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            AppLogger.warning('Failed to delete downloaded APK after update: $e');
          }
        }

        state = state.copyWith(
          status: UpdateStatus.idle,
          clearDownloadedApkPath: true,
          clearErrorMessage: true,
        );
      } else {
        AppLogger.warning(
          'Update verification: installed version ($installedVersionStr) is still older than target $targetVersion.',
        );

        final path = state.downloadedApkPath;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            final validation = await _installerService.verifyApk(path);
            if (!validation.isValid &&
                validation.errorCode == 'SIGNATURE_MISMATCH') {
              state = state.copyWith(
                status: UpdateStatus.error,
                errorMessage:
                    'Signing key mismatch: The downloaded update is signed with the KisanSetu Release key, which does not match this installed build (e.g. local Debug build). Please uninstall the current app or install a matching release build.',
              );
              return;
            } else if (!validation.isValid) {
              state = state.copyWith(
                status: UpdateStatus.error,
                errorMessage: validation.errorMessage ??
                    'Downloaded APK file is invalid or corrupted. Please redownload.',
              );
              return;
            }
          }
        }

        state = state.copyWith(
          status: UpdateStatus.downloaded,
          errorMessage:
              'Installation was not completed. Tap Retry to launch the installer again.',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to verify installed package version on resume: $e');
    }
  }

  /// Checks if install permission is now granted and triggers installation of downloaded APK.
  Future<void> recheckPermissionAndInstall() async {
    final path = state.downloadedApkPath;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!await file.exists() || await file.length() < 1000000) {
      AppLogger.warning(
        'Downloaded APK is missing or invalid when rechecking on resume.',
      );
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Downloaded APK file is missing or incomplete.',
      );
      return;
    }

    final canInstall = await _installerService.canRequestPackageInstalls();
    if (canInstall) {
      AppLogger.info(
        'Install permission granted on resume. Proceeding with installation.',
      );
      state = state.copyWith(
        status: UpdateStatus.downloaded,
        clearErrorMessage: true,
      );
      await triggerInstall();
    }
  }

  /// Checks for update via GitHub API asynchronously.
  Future<AppUpdateInfo?> checkForUpdate({bool isManual = false}) async {
    if (state.isDownloading) return state.updateInfo;

    state = state.copyWith(
      status: UpdateStatus.checking,
      clearErrorMessage: true,
    );

    final updateInfo = await _updateService.checkForUpdate();

    if (updateInfo != null) {
      state = state.copyWith(
        status: UpdateStatus.available,
        updateInfo: updateInfo,
        hasShownPopup: isManual ? true : state.hasShownPopup,
      );
      return updateInfo;
    } else {
      state = state.copyWith(
        status: UpdateStatus.idle,
      );
      return null;
    }
  }

  /// Downloads the APK release asset and triggers installation.
  Future<void> downloadAndInstallApk() async {
    final info = state.updateInfo;
    if (info == null || info.downloadUrl.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Invalid download URL',
      );
      return;
    }

    // Check if the downloaded APK already exists and is complete
    final existingPath = state.downloadedApkPath;
    if (existingPath != null && existingPath.isNotEmpty) {
      final existingFile = File(existingPath);
      if (await existingFile.exists()) {
        final actualSize = await existingFile.length();
        final expectedSize = info.apkSizeBytes;
        if (actualSize >= 1000000 &&
            (expectedSize == null ||
                expectedSize == 0 ||
                actualSize == expectedSize)) {
          AppLogger.info(
              'Found complete previously downloaded APK at: $existingPath');
          state = state.copyWith(
            status: UpdateStatus.downloaded,
            downloadProgress: 1.0,
            clearErrorMessage: true,
          );
          await triggerInstall();
          return;
        }
      }
    }

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
      clearErrorMessage: true,
    );

    try {
      final extCacheDirs = await getExternalCacheDirectories();
      final tempDir = (extCacheDirs != null && extCacheDirs.isNotEmpty)
          ? extCacheDirs.first
          : await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/${info.apkFileName}');

      if (await apkFile.exists()) {
        try {
          await apkFile.delete();
        } catch (_) {}
      }

      AppLogger.info('Starting APK download from: ${info.downloadUrl}');

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(info.downloadUrl));
        final response =
            await client.send(request).timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          state = state.copyWith(
            status: UpdateStatus.error,
            errorMessage: 'Download failed with HTTP ${response.statusCode}',
          );
          return;
        }

        final contentLength = response.contentLength ?? 0;
        final sink = apkFile.openWrite();
        int downloaded = 0;

        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 15))) {
          downloaded += chunk.length;
          sink.add(chunk);
          if (contentLength > 0) {
            final progress = (downloaded / contentLength).clamp(0.0, 1.0);
            state = state.copyWith(downloadProgress: progress);
          }
        }

        await sink.flush();
        await sink.close();

        // Validate the downloaded file size
        final actualSize = await apkFile.length();
        if (contentLength > 0 && actualSize != contentLength) {
          throw Exception(
              'Download incomplete. Expected $contentLength bytes but got $actualSize.');
        } else if (actualSize < 1000000) {
          // APK should reasonably be > 1MB
          throw Exception('Downloaded file is too small to be a valid APK.');
        }
      } finally {
        client.close();
      }

      AppLogger.info('APK downloaded successfully to: ${apkFile.path}');

      state = state.copyWith(
        status: UpdateStatus.downloaded,
        downloadProgress: 1.0,
        downloadedApkPath: apkFile.path,
        clearErrorMessage: true,
      );

      await triggerInstall();
    } catch (e, stackTrace) {
      AppLogger.error('APK download error: $e', e, stackTrace);
      try {
        final extCacheDirs = await getExternalCacheDirectories();
        final tempDir = (extCacheDirs != null && extCacheDirs.isNotEmpty)
            ? extCacheDirs.first
            : await getTemporaryDirectory();
        final apkFile = File('${tempDir.path}/${info.apkFileName}');
        if (await apkFile.exists()) {
          await apkFile.delete();
        }
      } catch (_) {}

      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Failed to download update: ${e.toString()}',
      );
    }
  }

  /// Triggers installation if permission is granted, else moves state to permissionRequired.
  Future<void> triggerInstall() async {
    final path = state.downloadedApkPath;
    if (path == null || path.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Downloaded file not found. Please redownload.',
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage:
            'Downloaded APK file no longer exists. Please redownload.',
      );
      return;
    }

    final actualSize = await file.length();
    final expectedSize = state.updateInfo?.apkSizeBytes;
    if (expectedSize != null &&
        expectedSize > 0 &&
        actualSize != expectedSize) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage:
            'Downloaded APK file is incomplete ($actualSize / $expectedSize bytes). Please redownload.',
      );
      return;
    } else if (actualSize < 1000000) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage:
            'Downloaded APK file is invalid or corrupted. Please redownload.',
      );
      return;
    }

    // Pre-verify APK compatibility & signing certificate natively
    final validation = await _installerService.verifyApk(path);
    AppLogger.info(
      'APK validation result: isValid=${validation.isValid}, code=${validation.errorCode}, '
      'installedVersionCode=${validation.installedVersionCode}, apkVersionCode=${validation.apkVersionCode}, '
      'installedCert=${validation.installedCertSha256}, apkCert=${validation.apkCertSha256}',
    );

    if (!validation.isValid) {
      final String userMsg;
      switch (validation.errorCode) {
        case 'SIGNATURE_MISMATCH':
          userMsg =
              'Signing key mismatch: The downloaded update is signed with the KisanSetu Release key, which does not match this installed build (e.g. local Debug build). Please uninstall the current app or install a matching release build.';
          break;
        case 'CORRUPTED_APK':
          userMsg =
              'Download corrupted: The downloaded file is not a valid Android package. Please redownload.';
          break;
        case 'PACKAGE_NAME_MISMATCH':
          userMsg =
              'Invalid update package: The downloaded APK is not for KisanSetu. Please redownload.';
          break;
        case 'VERSION_DOWNGRADE':
          userMsg =
              'Version mismatch: The downloaded update version is not newer than the currently installed version.';
          break;
        case 'INSUFFICIENT_STORAGE':
          userMsg =
              'Insufficient storage: Not enough free space to install the update. Free up space and try again.';
          break;
        case 'PERMISSION_DENIED':
          state = state.copyWith(
            status: UpdateStatus.permissionRequired,
            clearErrorMessage: true,
          );
          return;
        default:
          userMsg = validation.errorMessage ??
              'APK validation failed (${validation.errorCode}). Please redownload.';
      }

      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: userMsg,
      );
      return;
    }

    final canInstall = await _installerService.canRequestPackageInstalls();
    if (!canInstall) {
      AppLogger.info('REQUEST_INSTALL_PACKAGES permission not granted yet');
      state = state.copyWith(
        status: UpdateStatus.permissionRequired,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.installing,
      clearErrorMessage: true,
    );

    try {
      final success = await _installerService.installApk(path);

      if (!success) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'Failed to open package installer.',
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error(
          'PlatformException launching installer: ${e.code} - ${e.message}');
      final String msg = (e.code == 'SIGNATURE_MISMATCH')
          ? 'Signing key mismatch: The downloaded update is signed with the KisanSetu Release key, which does not match this installed build (e.g. local Debug build). Please uninstall the current app or install a matching release build.'
          : (e.message ?? 'Failed to open package installer.');
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: msg,
      );
    } catch (e) {
      AppLogger.error('Error launching installer: $e');
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Error launching package installer: $e',
      );
    }
  }

  /// Guides user to Android Settings for unknown app installation permission.
  Future<void> openSettings() async {
    await _installerService.openInstallPermissionSettings();
  }

  /// Marks that the update popup dialog has been presented to prevent duplicate popups.
  void markPopupShown() {
    state = state.copyWith(hasShownPopup: true);
  }

  /// User clicked "Later"
  void dismissUpdate() {
    state = state.copyWith(hasShownPopup: true);
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});
