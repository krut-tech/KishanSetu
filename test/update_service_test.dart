import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/update/data/services/update_service.dart';

void main() {
  group('UpdateService.isVersionNewer', () {
    test('Identifies standard semver bump as newer', () {
      expect(UpdateService.isVersionNewer('v1.0.11', '1.0.10+10'), isTrue);
      expect(UpdateService.isVersionNewer('v1.1.0', '1.0.11+11'), isTrue);
      expect(UpdateService.isVersionNewer('v2.0.0', '1.1.0+100'), isTrue);
    });

    test('Identifies identical version as NOT newer', () {
      expect(UpdateService.isVersionNewer('v1.0.11', '1.0.11+11'), isFalse);
      expect(UpdateService.isVersionNewer('1.0.11', '1.0.11+0'), isFalse);
    });

    test('Identifies older version as NOT newer', () {
      expect(UpdateService.isVersionNewer('v1.0.10', '1.0.11+11'), isFalse);
      expect(UpdateService.isVersionNewer('v1.0.0', '1.0.1+1'), isFalse);
    });

    test('Identifies same patch but higher build number as newer', () {
      // If github tag has +build format (rare but possible)
      expect(UpdateService.isVersionNewer('v1.0.11+12', '1.0.11+11'), isTrue);
    });

    test('Identifies same tag with no build number vs installed with build number', () {
      // Installed app is 1.0.11+11, tag is just v1.0.11. App is considered equal or newer, so tag is NOT newer.
      expect(UpdateService.isVersionNewer('v1.0.11', '1.0.11+11'), isFalse);
    });
  });
}
