import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/config/env_config.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';

class _AllowAllHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowAllHttpOverrides();

  late SupabaseAuthRepository repository;
  late SupabaseClient client;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EnvConfig.init();

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );

    client = Supabase.instance.client;
    repository = SupabaseAuthRepository(client);
  });

  tearDownAll(() async {
    await repository.signOut();
  });

  bool isLiveConfigured() {
    return !EnvConfig.supabaseUrl.contains('your-project.supabase.co') &&
        EnvConfig.supabaseAnonKey.isNotEmpty &&
        EnvConfig.supabaseAnonKey != 'your-supabase-anon-key';
  }

  group('REAL Runtime Supabase Auth & Profile Integration Verification', () {
    const farmerEmail = 'farmer_test@gmail.com';
    const farmerPassword = 'Farmer@12345';
    const buyerEmail = 'buyer_test@gmail.com';
    const buyerPassword = 'Buyer@12345';

    test('STEP 3A: Login, Role Selection & Profile Setup for FARMER', () async {
      if (!isLiveConfigured()) return;

      // 1. Sign In
      final signInResult = await repository.signIn(
        email: farmerEmail,
        password: farmerPassword,
      );

      expect(signInResult.isRight(), isTrue,
          reason: 'Farmer SignIn should succeed');
      final authResponse =
          signInResult.getOrElse((_) => throw Exception('Failed'));
      expect(authResponse.user, isNotNull,
          reason: 'Auth user should be returned');
      final userId = authResponse.user!.id;

      // 2. Fetch Profile created by DB Trigger
      final initialProfileResult = await repository.getUserProfile(userId);
      expect(initialProfileResult.isRight(), isTrue);
      final initialProfile =
          initialProfileResult.getOrElse((_) => throw Exception('Failed'));
      expect(initialProfile.id, equals(userId));
      expect(initialProfile.fullName, equals('Ramesh Farmer Test'));

      // 3. Select Role
      final roleSelectedProfile =
          initialProfile.copyWith(role: UserRole.farmer);
      final updateRoleResult =
          await repository.updateUserProfile(roleSelectedProfile);
      expect(updateRoleResult.isRight(), isTrue);
      final updatedRoleProfile =
          updateRoleResult.getOrElse((_) => throw Exception('Failed'));
      expect(updatedRoleProfile.role, equals(UserRole.farmer));

      // 4. Complete Profile
      final completedFarmerProfile = updatedRoleProfile.copyWith(
        state: 'Gujarat',
        district: 'Anand',
        village: 'Vasad',
        landSizeAcres: 5.5,
        primaryCrop: 'Wheat',
        isProfileComplete: true,
      );

      final completeProfileResult =
          await repository.updateUserProfile(completedFarmerProfile);
      expect(completeProfileResult.isRight(), isTrue);
      final savedFarmerProfile =
          completeProfileResult.getOrElse((_) => throw Exception('Failed'));

      expect(savedFarmerProfile.isProfileComplete, isTrue);
      expect(savedFarmerProfile.state, equals('Gujarat'));
      expect(savedFarmerProfile.district, equals('Anand'));
      expect(savedFarmerProfile.village, equals('Vasad'));
      expect(savedFarmerProfile.landSizeAcres, equals(5.5));
      expect(savedFarmerProfile.primaryCrop, equals('Wheat'));

      // Sign Out
      await repository.signOut();
    });

    test('STEP 3B: Login, Role Selection & Profile Setup for BUYER', () async {
      if (!isLiveConfigured()) return;
      // 1. Sign In
      final signInResult = await repository.signIn(
        email: buyerEmail,
        password: buyerPassword,
      );

      expect(signInResult.isRight(), isTrue,
          reason: 'Buyer SignIn should succeed');
      final authResponse =
          signInResult.getOrElse((_) => throw Exception('Failed'));
      expect(authResponse.user, isNotNull);
      final userId = authResponse.user!.id;

      // 2. Fetch Profile
      final initialProfileResult = await repository.getUserProfile(userId);
      expect(initialProfileResult.isRight(), isTrue);

      // 3. Select Role
      final roleSelectedProfile = UserProfile(
        id: userId,
        fullName: 'Suresh Buyer Test',
        phone: '9876543211',
        role: UserRole.buyer,
      );
      final updateRoleResult =
          await repository.updateUserProfile(roleSelectedProfile);
      expect(updateRoleResult.isRight(), isTrue);

      // 4. Complete Profile
      final completedBuyerProfile = roleSelectedProfile.copyWith(
        companyName: 'Agri Procurement Corp',
        gstNumber: '24ABCDE1234F1Z5',
        businessType: 'Agricultural Buyer',
        buyingCapacityQuintals: 500.0,
        state: 'Gujarat',
        district: 'Anand',
        village: 'Anand',
        isProfileComplete: true,
      );

      final completeProfileResult =
          await repository.updateUserProfile(completedBuyerProfile);
      expect(completeProfileResult.isRight(), isTrue);
      final savedBuyerProfile =
          completeProfileResult.getOrElse((_) => throw Exception('Failed'));

      expect(savedBuyerProfile.isProfileComplete, isTrue);
      expect(savedBuyerProfile.role, equals(UserRole.buyer));
      expect(savedBuyerProfile.companyName, equals('Agri Procurement Corp'));
      expect(savedBuyerProfile.gstNumber, equals('24ABCDE1234F1Z5'));
      expect(savedBuyerProfile.businessType, equals('Agricultural Buyer'));
      expect(savedBuyerProfile.buyingCapacityQuintals, equals(500.0));

      // Sign Out
      await repository.signOut();
    });

    test('STEP 4 & 5: Login, Session Verification, Password Update & SignOut',
        () async {
      if (!isLiveConfigured()) return;
      // Login as Farmer
      final signInResult =
          await repository.signIn(email: farmerEmail, password: farmerPassword);
      expect(signInResult.isRight(), isTrue);
      expect(repository.currentUser, isNotNull);

      final profileResult =
          await repository.getUserProfile(repository.currentUser!.id);
      expect(profileResult.isRight(), isTrue);
      final profile = profileResult.getOrElse((_) => throw Exception('Failed'));
      expect(profile.role, equals(UserRole.farmer));
      expect(profile.isProfileComplete, isTrue);

      // Test Password Update while authenticated
      final updatePasswordResult =
          await repository.resetPassword('NewTestPassword123!');
      expect(updatePasswordResult.isRight(), isTrue);

      // Revert Password back to farmerPassword
      await repository.resetPassword(farmerPassword);

      // Sign Out
      await repository.signOut();
      expect(repository.currentUser, isNull);
    });

    test('STEP 6: Send Password Reset Email Request', () async {
      if (!isLiveConfigured()) return;
      final resetResult = await repository.sendPasswordResetEmail(farmerEmail);
      resetResult.fold(
        (failure) {
          final msg = failure.message.toLowerCase();

          final isRateLimit = msg.contains('rate limit') ||
              msg.contains('too many requests') ||
              msg.contains('too many login attempts');

          if (isRateLimit) {
            AppLogger.info(
                'Password reset request encountered expected rate limit response: ${failure.message}');
            return;
          }

          fail(
              'Unexpected authentication/server/configuration error: ${failure.message}');
        },
        (_) => AppLogger.info(
            'Password reset email request accepted by Auth API for $farmerEmail.'),
      );
    });
  });
}
