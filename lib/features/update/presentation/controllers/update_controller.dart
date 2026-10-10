import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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
    String? errorMessage,
    bool? hasShownPopup,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedApkPath: downloadedApkPath ?? this.downloadedApkPath,
      errorMessage: errorMessage ?? this.errorMessage,
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

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService;
  final ApkInstallerService _installerService;

  UpdateNotifier({
    UpdateService? updateService,
    ApkInstallerService? installerService,
  })  : _updateService = updateService ?? UpdateService(),
        _installerService = installerService ?? ApkInstallerService(),
        super(const UpdateState());

  /// Checks for update via GitHub API asynchronously.
  Future<AppUpdateInfo?> checkForUpdate({bool isManual = false}) async {
    if (state.isDownloading) return state.updateInfo;

    state = state.copyWith(
      status: UpdateStatus.checking,
      errorMessage: null,
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

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
      errorMessage: null,
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
        final response = await client.send(request).timeout(const Duration(seconds: 30));

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

        await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
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
          throw Exception('Download incomplete. Expected $contentLength bytes but got $actualSize.');
        } else if (actualSize < 1000000) { // APK should reasonably be > 1MB
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
        errorMessage: 'Downloaded file not found',
      );
      return;
    }

    final canInstall = await _installerService.canRequestPackageInstalls();
    if (!canInstall) {
      AppLogger.info('REQUEST_INSTALL_PACKAGES permission not granted yet');
      state = state.copyWith(status: UpdateStatus.permissionRequired);
      return;
    }

    state = state.copyWith(status: UpdateStatus.installing);
    final success = await _installerService.installApk(path);

    if (!success) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: 'Failed to open package installer',
      );
    } else {
      // Revert to downloaded state after launching the installer so the user
      // can retry if they cancelled the installation.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && state.status == UpdateStatus.installing) {
          state = state.copyWith(status: UpdateStatus.downloaded);
        }
      });
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
