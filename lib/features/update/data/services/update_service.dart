import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/update/domain/models/app_update_info.dart';

/// Interacts with GitHub API to check for published app updates.
class UpdateService {
  static const String _releasesUrl =
      'https://api.github.com/repos/krut-tech/KishanSetu/releases';

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
        Uri.parse(_releasesUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'KishanSetu-App',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        AppLogger.warning(
          'GitHub releases API returned HTTP ${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        AppLogger.warning(
            'GitHub releases API returned unexpected format (possibly rate limited): $decoded');
        return null;
      }
      final releases = decoded;

      Map<String, dynamic>? targetRelease;
      Map<String, dynamic>? targetApkAsset;

      for (final release in releases) {
        if (release is Map<String, dynamic>) {
          if (release['draft'] == true) continue;

          final tagName = release['tag_name'] as String? ?? '';
          if (!isVersionNewer(tagName, installedVersionStr)) {
            continue;
          }

          final assets = release['assets'] as List<dynamic>? ?? [];
          for (final asset in assets) {
            if (asset is Map<String, dynamic>) {
              if (asset['name'] == 'app-release.apk') {
                targetRelease = release;
                targetApkAsset = asset;
                break;
              }
            }
          }
          if (targetRelease != null) break;
        }
      }

      if (targetRelease == null || targetApkAsset == null) {
        AppLogger.info(
            'No newer GitHub release found with an app-release.apk asset.');
        return null;
      }

      final tagName = targetRelease['tag_name'] as String? ?? '';
      final body = targetRelease['body'] as String? ?? '';
      final downloadUrl =
          targetApkAsset['browser_download_url'] as String? ?? '';
      final sizeBytes = targetApkAsset['size'] as int?;

      if (downloadUrl.isEmpty) {
        AppLogger.warning('Asset app-release.apk lacks browser_download_url');
        return null;
      }

      AppLogger.info(
        'Version check result: Found newer update tag=$tagName for installed=$installedVersionStr',
      );

      return AppUpdateInfo(
        installedVersion: installedVersionStr,
        latestVersion: tagName,
        releaseNotes: body,
        downloadUrl: downloadUrl,
        apkFileName: 'app-release.apk',
        apkSizeBytes: sizeBytes,
      );
    } catch (e) {
      AppLogger.warning(
          'Update check completed without update (offline or timeout): $e');
    }
    return null;
  }

  /// Compares [latestTag] against [installedVersion].
  /// Returns true if [latestTag] is strictly newer than [installedVersion].
  static bool isVersionNewer(String latestTag, String installedVersion) {
    final cleanLatest = latestTag.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanInstalled =
        installedVersion.trim().replaceFirst(RegExp(r'^[vV]'), '');

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
    final clean = versionStr.trim().replaceFirst(RegExp(r'^[vV]'), '');
    int buildPart = 0;
    String mainPart = clean;

    if (clean.contains('+')) {
      final parts = clean.split('+');
      mainPart = parts[0];
      buildPart =
          int.tryParse(RegExp(r'\d+').firstMatch(parts[1])?.group(0) ?? '') ??
              0;
    } else if (clean.contains('-')) {
      final parts = clean.split('-');
      mainPart = parts[0];
      if (parts.length > 1) {
        buildPart =
            int.tryParse(RegExp(r'^\d+').firstMatch(parts[1])?.group(0) ?? '') ??
                0;
      }
    }

    final semverNums = mainPart
        .split('.')
        .map((s) => int.tryParse(RegExp(r'\d+').firstMatch(s)?.group(0) ?? '') ?? 0)
        .toList();

    int major = semverNums.isNotEmpty ? semverNums[0] : 0;
    int minor = semverNums.length > 1 ? semverNums[1] : 0;
    int patch = semverNums.length > 2 ? semverNums[2] : 0;
    if (buildPart == 0 && semverNums.length > 3) {
      buildPart = semverNums[3];
    }

    return [major, minor, patch, buildPart];
  }
}
