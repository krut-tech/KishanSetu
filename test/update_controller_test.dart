import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  ApkValidationResult validationResult = const ApkValidationResult(
    isValid: true,
    errorCode: 'NONE',
  );

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
  Future<ApkValidationResult> verifyApk(String filePath) async {
    return validationResult;
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

    test('checkForUpdate sets status to available when update exists',
        () async {
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

    test(
        'triggerInstall detects signature mismatch from verifyApk and displays signature mismatch message',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_sig.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'SIGNATURE_MISMATCH',
        errorMessage: 'Signing key mismatch',
        installedCertSha256: 'AAAA1111',
        apkCertSha256: 'BBBB2222',
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('Signing key mismatch'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'triggerInstall detects corrupted APK from verifyApk and displays download corrupted message',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_corrupt.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'CORRUPTED_APK',
        errorMessage: 'Corrupted APK file',
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('Download corrupted'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'triggerInstall detects package name mismatch from verifyApk',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_pkg.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'PACKAGE_NAME_MISMATCH',
        errorMessage: 'Package name mismatch',
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('Invalid update package'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'triggerInstall detects version downgrade from verifyApk',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_ver.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'VERSION_DOWNGRADE',
        errorMessage: 'Version downgrade',
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('Version mismatch'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'triggerInstall detects insufficient storage from verifyApk',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_storage.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'INSUFFICIENT_STORAGE',
        errorMessage: 'Insufficient storage',
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('Insufficient storage'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'triggerInstall moves to permissionRequired when canRequestPackageInstalls is false',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_perm.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: true,
        errorCode: 'NONE',
      );
      mockInstallerService.canInstall = false;

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.permissionRequired);
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'recheckPermissionAndInstall moves from permissionRequired to installing when permission granted',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_recheck.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.permissionRequired,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: true,
        errorCode: 'NONE',
      );
      mockInstallerService.canInstall = true;

      await notifier.recheckPermissionAndInstall();

      expect(mockInstallerService.installApkCalled, isTrue);
      expect(mockInstallerService.installedPath, tempFile.path);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('onAppResumed rechecks permission when status is permissionRequired',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_resume.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.permissionRequired,
      );

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: true,
        errorCode: 'NONE',
      );
      mockInstallerService.canInstall = true;

      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockInstallerService.installApkCalled, isTrue);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test(
        'onAppResumed verifies update success when installed version matches target on resume',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_success.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      final testNotifier = UpdateNotifier(
        updateService: mockUpdateService,
        installerService: mockInstallerService,
        getPackageInfo: () async => FakePackageInfo(
          version: '1.2.0',
          buildNumber: '10200',
        ),
      );

      testNotifier.state = testNotifier.state.copyWith(
        status: UpdateStatus.installing,
        updateInfo: const AppUpdateInfo(
          installedVersion: '1.0.11+11',
          latestVersion: 'v1.2.0+10200',
          releaseNotes: 'Update 1.2.0',
          downloadUrl: 'https://example.com/app-release.apk',
          apkFileName: 'app-release.apk',
        ),
        downloadedApkPath: tempFile.path,
      );

      await testNotifier.onAppResumed();

      expect(testNotifier.state.status, UpdateStatus.idle);
      expect(testNotifier.state.downloadedApkPath, isNull);
      expect(await tempFile.exists(), isFalse);

      testNotifier.dispose();
    });

    test(
        'onAppResumed reports signature mismatch when installed version remains older on resume and verifyApk flags signature mismatch',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_app-release_resumefail.apk');
      await tempFile.writeAsBytes(List.filled(1000005, 0));

      mockInstallerService.validationResult = const ApkValidationResult(
        isValid: false,
        errorCode: 'SIGNATURE_MISMATCH',
        errorMessage: 'Signing key mismatch',
      );

      final testNotifier = UpdateNotifier(
        updateService: mockUpdateService,
        installerService: mockInstallerService,
        getPackageInfo: () async => FakePackageInfo(
          version: '1.0.11',
          buildNumber: '11',
        ),
      );

      testNotifier.state = testNotifier.state.copyWith(
        status: UpdateStatus.installing,
        updateInfo: const AppUpdateInfo(
          installedVersion: '1.0.11+11',
          latestVersion: 'v1.2.0+10200',
          releaseNotes: 'Update 1.2.0',
          downloadUrl: 'https://example.com/app-release.apk',
          apkFileName: 'app-release.apk',
        ),
        downloadedApkPath: tempFile.path,
      );

      await testNotifier.onAppResumed();

      expect(testNotifier.state.status, UpdateStatus.error);
      expect(testNotifier.state.errorMessage, contains('Signing key mismatch'));
      expect(await tempFile.exists(), isTrue);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      testNotifier.dispose();
    });

    test(
        'triggerInstall rejects invalid or incomplete APK files (<1MB)',
        () async {
      final tempFile =
          File('${Directory.systemTemp.path}/test_small_apk.apk');
      await tempFile.writeAsBytes(List.filled(500, 0));

      notifier.state = notifier.state.copyWith(
        downloadedApkPath: tempFile.path,
        status: UpdateStatus.downloaded,
      );

      await notifier.triggerInstall();

      expect(notifier.state.status, UpdateStatus.error);
      expect(notifier.state.errorMessage, contains('invalid or corrupted'));
      expect(mockInstallerService.installApkCalled, isFalse);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}

class FakePackageInfo implements PackageInfo {
  @override
  final String appName = 'KisanSetu';
  @override
  final String packageName = 'com.farmermarket.farmer_market_app';
  @override
  final String version;
  @override
  final String buildNumber;
  @override
  final String buildSignature = '';
  @override
  final String? installerStore = null;
  @override
  final DateTime? installTime = null;
  @override
  final DateTime? updateTime = null;
  @override
  Map<String, dynamic> get data => {
        'appName': appName,
        'packageName': packageName,
        'version': version,
        'buildNumber': buildNumber,
        'buildSignature': buildSignature,
      };

  FakePackageInfo({required this.version, required this.buildNumber});
}
