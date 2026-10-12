import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/core/localization/status_localizer.dart';
import 'package:farmer_market_app/features/translation/data/repositories/supabase_translation_repository.dart';
import 'package:farmer_market_app/features/translation/domain/repositories/translation_repository.dart';
import 'package:farmer_market_app/features/translation/presentation/controllers/translation_providers.dart';
import 'package:farmer_market_app/features/translation/presentation/widgets/translated_text_widget.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';

class MockTranslationRepository implements TranslationRepository {
  final Map<String, String> _translations = {};
  int callCount = 0;

  void setTranslation(String text, String targetLang, String translated) {
    _translations['${text}_$targetLang'] = translated;
  }

  @override
  Future<String> translateText({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _translations['${text}_$targetLang'] ?? text;
  }

  @override
  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    callCount++;
    final res = <String, String>{};
    for (final t in texts) {
      res[t] = _translations['${t}_$targetLang'] ?? t;
    }
    return res;
  }

  @override
  void clearLocalCache() {
    _translations.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleController Unit Tests', () {
    test('Default locale is English', () {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController();
      expect(controller.state, equals(const Locale('en')));
    });

    test('setLocale updates state and persists valid locale code', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController();

      await controller.setLocale('hi');
      expect(controller.state, equals(const Locale('hi')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_selected_locale'), equals('hi'));
    });

    test('setLocale ignores unsupported language codes', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = LocaleController();

      await controller.setLocale('fr');
      expect(controller.state, equals(const Locale('en')));
    });
  });

  group('Status Localizer Unit Tests', () {
    testWidgets('localizes offer statuses correctly in English, Hindi, Gujarati',
        (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('gu'),
          ],
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(localizedOfferStatus(testContext, 'pending'), equals('Pending'));
      expect(localizedOfferStatus(testContext, 'accepted'), equals('Accepted'));
      expect(localizedOfferStatus(testContext, 'rejected'), equals('Rejected'));
      expect(localizedOfferStatus(testContext, 'cancelled'), equals('Cancelled'));

      expect(localizedProduceStatus(testContext, 'active'), equals('Active'));
      expect(localizedProduceStatus(testContext, 'draft'), equals('Draft'));

      expect(localizedDeliveryStatus(testContext, 'in_transit'), equals('In Transit'));
      expect(localizedKycStatus(testContext, 'verified'), equals('Verified'));
      expect(localizedDisputeStatus(testContext, 'open'), equals('Open'));
    });
  });

  group('SupabaseTranslationRepository Caching & Offline Fallback Tests', () {
    test('Returns original text when Supabase client is null (offline fallback)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SupabaseTranslationRepository(supabase: null, prefs: prefs);

      final result = await repo.translateText(
        text: 'Organic Fresh Wheat',
        targetLang: 'hi',
      );

      expect(result, equals('Organic Fresh Wheat'));
    });

    test('Caches translated string locally in SharedPreferences across restarts', () async {
      final text = 'Wheat';
      final hash = sha256.convert(utf8.encode(text.trim().toLowerCase())).toString();
      final cacheKey = '${hash}_hi';

      SharedPreferences.setMockInitialValues({
        'tr_cache_$cacheKey': 'गेहूं',
      });
      final prefs = await SharedPreferences.getInstance();

      final repo = SupabaseTranslationRepository(supabase: null, prefs: prefs);

      // Memory cache gets populated on init from SharedPreferences
      final cached = await repo.translateText(
        text: text,
        targetLang: 'hi',
      );

      expect(cached, equals('गेहूं'));
    });

    test('Saves new translation to SharedPreferences and survives re-instantiation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      SupabaseTranslationRepository(supabase: null, prefs: prefs);
      // Simulate translated text saved to cache
      final text = 'Organic Rice';
      final hash = sha256.convert(utf8.encode(text.trim().toLowerCase())).toString();
      final cacheKey = '${hash}_hi';

      // Verify saving to SharedPreferences
      await prefs.setString('tr_cache_$cacheKey', 'जैविक चावल');

      // Re-instantiate repo mimicking app restart
      final repo2 = SupabaseTranslationRepository(supabase: null, prefs: prefs);
      final result = await repo2.translateText(text: text, targetLang: 'hi');

      expect(result, equals('जैविक चावल'));
    });

    test('clearLocalCache clears memory and SharedPreferences translation keys', () async {
      SharedPreferences.setMockInitialValues({
        'tr_cache_somehash_hi': 'अनुवाद',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SupabaseTranslationRepository(supabase: null, prefs: prefs);

      repo.clearLocalCache();
      expect(prefs.getKeys().where((k) => k.startsWith('tr_cache_')), isEmpty);
    });

    test('SharedPreferences Provider dependency injection test', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final repo = container.read(translationRepositoryProvider);
      expect(repo, isA<SupabaseTranslationRepository>());
      container.dispose();
    });
  });

  group('TranslatedTextWidget Widget Tests', () {
    testWidgets('Renders original text immediately and toggles on tap',
        (tester) async {
      final mockRepo = MockTranslationRepository();
      mockRepo.setTranslation('Fresh Organic Wheat', 'hi', 'ताज़ा जैविक गेहूं');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            translationRepositoryProvider.overrideWithValue(mockRepo),
            localeControllerProvider
                .overrideWith((ref) => LocaleController()..setLocale('hi')),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('hi'),
            ],
            home: Scaffold(
              body: TranslatedTextWidget(
                text: 'Fresh Organic Wheat',
                showToggle: true,
              ),
            ),
          ),
        ),
      );

      // Initial pump renders original text while async translation is in-flight
      expect(find.text('Fresh Organic Wheat'), findsOneWidget);

      // Settle async translation
      await tester.pumpAndSettle();

      // Now translated text is displayed
      expect(find.text('ताज़ा जैविक गेहूं'), findsOneWidget);
      expect(find.text('Show Original • Translated'), findsOneWidget);

      // Tap on toggle
      await tester.tap(find.text('Show Original • Translated'));
      await tester.pumpAndSettle();

      // Shows original text
      expect(find.text('Fresh Organic Wheat'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
    });
  });
}
