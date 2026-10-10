import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/update/data/services/apk_installer_service.dart';
import 'package:farmer_market_app/features/update/data/services/update_service.dart';
import 'package:farmer_market_app/features/update/domain/models/app_update_info.dart';
import 'package:farmer_market_app/features/update/presentation/controllers/update_controller.dart';

class MockUpdateService implements UpdateService {
  AppUpdateInfo? mockInfo;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    return mockInfo;
  }
}

class MockApkInstallerService implements ApkInstallerService {
  bool canInstall = false;
  bool openSettingsCalled = false;
  bool installApkCalled = false;
  String? installedPath;

  @override
  Future<bool> canRequestPackageInstalls() async {
    return canInstall;
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> installApk(String filePath) async {
    installApkCalled = true;
    installedPath = filePath;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUpdateService mockUpdateService;
  late MockApkInstallerService mockInstallerService;
  late UpdateNotifier notifier;

  setUp(() {
    mockUpdateService = MockUpdateService();
    mockInstallerService = MockApkInstallerService();
    notifier = UpdateNotifier(
      updateService: mockUpdateService,
      installerService: mockInstallerService,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('UpdateNotifier State Transitions', () {
    test('Initial state is idle', () {
      expect(notifier.state.status, UpdateStatus.idle);
      expect(notifier.state.downloadProgress, 0.0);
    });

    test('checkForUpdate sets status to available when update exists', () async {
      mockUpdateService.mockInfo = const AppUpdateInfo(
        installedVersion: '1.0.11+11',
        latestVersion: 'v1.0.11+12',
        releaseNotes: 'New bug fixes',
        downloadUrl: 'https://example.com/app-release.apk',
        apkFileName: 'app-release.apk',
      );

      final result = await notifier.checkForUpdate();

      expect(result, isNotNull);
      expect(notifier.state.status, UpdateStatus.available);
      expect(notifier.state.updateInfo?.latestVersion, 'v1.0.11+12');
    });

    test('checkForUpdate sets status to idle when no update exists', () async {
      mockUpdateService.mockInfo = null;

      final result = await notifier.checkForUpdate();

      expect(result, isNull);
      expect(notifier.state.status, UpdateStatus.idle);
    });

    test('triggerInstall moves to permissionRequired when canRequestPackageInstalls is false', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_app-release.apk');
      // Create a dummy file > 1MB
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.canInstall = false;

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.permissionRequired);
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('recheckPermissionAndInstall moves from permissionRequired to installing when permission granted', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_app-release.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.permissionRequired,
      );

      mockInstallerService.canInstall = true;

      await notifier.recheckPermissionAndInstall();

      expect(mockInstallerService.installApkCalled, isTrue);
      expect(mockInstallerService.installedPath, tempFile.path);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('onAppResumed rechecks permission when status is permissionRequired', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_app-release.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.permissionRequired,
      );

      mockInstallerService.canInstall = true;

      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // Allow async execution
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockInstallerService.installApkCalled, isTrue);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}
