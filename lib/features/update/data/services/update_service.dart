import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/update/domain/models/app_update_info.dart';

/// Interacts with GitHub API to check for published app updates.
class UpdateService {
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/krut-tech/KishanSetu/releases/latest';

  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Queries GitHub releases, compares current version with latest release,
  /// and returns [AppUpdateInfo] if a newer release with asset `app-release.apk` exists.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersionStr =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      AppLogger.info('Checking for update... Installed: $installedVersionStr');

      final response = await _client.get(
        Uri.parse(_latestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'KishanSetu-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        AppLogger.warning(
          'GitHub releases API returned HTTP ${response.statusCode}',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final body = json['body'] as String? ?? '';
      final assets = json['assets'] as List<dynamic>? ?? [];

      if (tagName.isEmpty) {
        AppLogger.warning('GitHub release payload missing tag_name');
        return null;
      }

      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final assetName = asset['name'] as String? ?? '';
          if (assetName == 'app-release.apk') {
            apkAsset = asset;
            break;
          }
        }
      }

      if (apkAsset == null) {
        AppLogger.info(
          'Latest GitHub release ($tagName) found, but no app-release.apk asset attached.',
        );
        return null;
      }

      final downloadUrl = apkAsset['browser_download_url'] as String? ?? '';
      final sizeBytes = apkAsset['size'] as int?;

      if (downloadUrl.isEmpty) {
        AppLogger.warning('Asset app-release.apk lacks browser_download_url');
        return null;
      }

      final hasNewerVersion = isVersionNewer(tagName, installedVersionStr);
      AppLogger.info(
        'Version check result: Latest tag=$tagName, Installed=$installedVersionStr, Newer=$hasNewerVersion',
      );

      if (hasNewerVersion) {
        return AppUpdateInfo(
          installedVersion: installedVersionStr,
          latestVersion: tagName,
          releaseNotes: body,
          downloadUrl: downloadUrl,
          apkFileName: 'app-release.apk',
          apkSizeBytes: sizeBytes,
        );
      }
    } catch (e) {
      AppLogger.warning('Update check completed without update (offline or timeout): $e');
    }
    return null;
  }

  /// Compares [latestTag] against [installedVersion].
  /// Returns true if [latestTag] is strictly newer than [installedVersion].
  static bool isVersionNewer(String latestTag, String installedVersion) {
    final cleanLatest = latestTag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanInstalled = installedVersion.trim().replaceFirst(RegExp(r'^[vV]'), '');

    final latestParsed = _parseVersionComponents(cleanLatest);
    final installedParsed = _parseVersionComponents(cleanInstalled);

    for (int i = 0; i < 4; i++) {
      if (latestParsed[i] > installedParsed[i]) return true;
      if (latestParsed[i] < installedParsed[i]) return false;
    }

    return false;
  }

  /// Parses version into `[major, minor, patch, buildNumber]`.
  static List<int> _parseVersionComponents(String versionStr) {
    final splitPlus = versionStr.split('+');
    final semverPart = splitPlus[0];
    final buildPart = splitPlus.length > 1 ? int.tryParse(splitPlus[1]) ?? 0 : 0;

    final semverNums = semverPart
        .split('.')
        .map((s) => int.tryParse(RegExp(r'\d+').firstMatch(s)?.group(0) ?? '') ?? 0)
        .toList();

    while (semverNums.length < 3) {
      semverNums.add(0);
    }

    return [semverNums[0], semverNums[1], semverNums[2], buildPart];
  }
}
