import 'package:equatable/equatable.dart';

/// Holds metadata about an available application update retrieved from GitHub Releases.
class AppUpdateInfo extends Equatable {
  final String installedVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String apkFileName;
  final int? apkSizeBytes;

  const AppUpdateInfo({
    required this.installedVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.apkFileName,
    this.apkSizeBytes,
  });

  @override
  List<Object?> get props => [
        installedVersion,
        latestVersion,
        releaseNotes,
        downloadUrl,
        apkFileName,
        apkSizeBytes,
      ];
}
