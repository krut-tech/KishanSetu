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
      expect(UpdateService.isVersionNewer('v1.0.11+11', '1.0.11+11'), isFalse);
    });

    test('Identifies older version as NOT newer', () {
      expect(UpdateService.isVersionNewer('v1.0.10', '1.0.11+11'), isFalse);
      expect(UpdateService.isVersionNewer('v1.0.0', '1.0.1+1'), isFalse);
    });

    test('Identifies multiple releases per day with build number increment as newer', () {
      expect(UpdateService.isVersionNewer('v1.0.11+12', '1.0.11+11'), isTrue);
      expect(UpdateService.isVersionNewer('1.0.11+15', '1.0.11+12'), isTrue);
      expect(UpdateService.isVersionNewer('v1.0.11-13', '1.0.11+11'), isTrue);
      expect(UpdateService.isVersionNewer('v1.0.11.14', '1.0.11+11'), isTrue);
    });

    test('Identifies higher semver with lower build number as newer', () {
      expect(UpdateService.isVersionNewer('v1.0.12+1', '1.0.11+99'), isTrue);
      expect(UpdateService.isVersionNewer('v1.1.0+1', '1.0.99+999'), isTrue);
    });

    test('Identifies same tag with no build number vs installed with build number as NOT newer', () {
      expect(UpdateService.isVersionNewer('v1.0.11', '1.0.11+11'), isFalse);
    });
  });
}
