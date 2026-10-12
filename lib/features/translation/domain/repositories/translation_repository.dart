/// Provider-independent abstract contract for dynamic text translation.
abstract class TranslationRepository {
  /// Translates a single [text] to [targetLang] ('en', 'hi', 'gu').
  ///
  /// Returns the translated text, or the original [text] on error/offline.
  Future<String> translateText({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  });

  /// Translates a list of [texts] in a single request.
  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'auto',
  });

  /// Clears the in-memory/local cache.
  void clearLocalCache();
}
