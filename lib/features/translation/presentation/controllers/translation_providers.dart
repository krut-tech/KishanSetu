import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/network/supabase_client_provider.dart';
import 'package:farmer_market_app/core/localization/locale_controller.dart';
import 'package:farmer_market_app/features/translation/data/repositories/supabase_translation_repository.dart';
import 'package:farmer_market_app/features/translation/domain/repositories/translation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SupabaseTranslationRepository(
    supabase: supabase,
    prefs: prefs,
  );
});

/// Family provider to translate dynamic string for current app locale.
final dynamicTranslationProvider =
    FutureProvider.family<String, String>((ref, text) async {
  if (text.trim().isEmpty) return text;
  final locale = ref.watch(localeControllerProvider);
  final repository = ref.watch(translationRepositoryProvider);
  return repository.translateText(
    text: text,
    targetLang: locale.languageCode,
  );
});
