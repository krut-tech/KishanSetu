import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';

void main() {
  group('UserProfile Model Unit Tests', () {
    test('creates UserProfile from map correctly', () {
      final map = {
        'id': 'user-123',
        'role': 'farmer',
        'full_name': 'Ramesh Patel',
        'phone': '9876543210',
        'language': 'gu',
        'state': 'Gujarat',
        'district': 'Anand',
        'village': 'Vadtal',
        'land_size_acres': 10.5,
        'primary_crop': 'Wheat',
        'is_profile_complete': true,
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 'user-123');
      expect(profile.role, UserRole.farmer);
      expect(profile.fullName, 'Ramesh Patel');
      expect(profile.district, 'Anand');
      expect(profile.landSizeAcres, 10.5);
      expect(profile.isProfileComplete, isTrue);
    });

    test('parses and serializes optional shared map coordinates', () {
      final profile = UserProfile.fromMap({
        'id': 'map-user',
        'role': 'farmer',
        'full_name': 'Map Farmer',
        'latitude': 22.3039,
        'longitude': 70.8022,
      });

      expect(profile.latitude, 22.3039);
      expect(profile.longitude, 70.8022);
      expect(profile.toMap()['latitude'], 22.3039);
      expect(profile.toMap()['longitude'], 70.8022);
    });

    test('converts UserProfile to map correctly', () {
      const profile = UserProfile(
        id: 'user-456',
        role: UserRole.buyer,
        fullName: 'Agro Traders',
        companyName: 'Patel Agro Exports',
        businessType: 'Wholesaler',
        isProfileComplete: true,
      );

      final map = profile.toMap();

      expect(map['id'], 'user-456');
      expect(map['role'], 'buyer');
      expect(map['company_name'], 'Patel Agro Exports');
      expect(map['is_profile_complete'], isTrue);
    });
  });
}
