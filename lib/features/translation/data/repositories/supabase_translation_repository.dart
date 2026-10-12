import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:farmer_market_app/core/logging/app_logger.dart';
import 'package:farmer_market_app/features/translation/domain/repositories/translation_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTranslationRepository implements TranslationRepository {
  final SupabaseClient? _supabase;
  final SharedPreferences? _prefs;

  /// In-memory cache for fast lookup during session: `${textHash}_${targetLang}` -> translatedText
  final Map<String, String> _memoryCache = {};

  /// In-flight requests map to prevent duplicate concurrent network calls
  final Map<String, Future<String>> _inFlightRequests = {};

  static const String _prefPrefix = 'tr_cache_';

  SupabaseTranslationRepository({
    SupabaseClient? supabase,
    SharedPreferences? prefs,
  })  : _supabase = supabase,
        _prefs = prefs {
    _loadLocalCacheFromPrefs();
  }

  void _loadLocalCacheFromPrefs() {
    if (_prefs == null) return;
    try {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefPrefix));
      for (final key in keys) {
        final cacheKey = key.substring(_prefPrefix.length);
        final val = _prefs!.getString(key);
        if (val != null) {
          _memoryCache[cacheKey] = val;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load local translation cache from prefs: $e');
    }
  }

  String _computeHash(String text) {
    final bytes = utf8.encode(text.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  String _buildCacheKey(String hash, String targetLang) => '${hash}_$targetLang';

  @override
  Future<String> translateText({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    // Do not translate short numbers/currencies/identifiers
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) return text;

    final target = targetLang.toLowerCase();
    final hash = _computeHash(trimmed);
    final cacheKey = _buildCacheKey(hash, target);

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Check SharedPreferences cache
    if (_prefs != null) {
      final cachedVal = _prefs!.getString('$_prefPrefix$cacheKey');
      if (cachedVal != null && cachedVal.isNotEmpty) {
        _memoryCache[cacheKey] = cachedVal;
        return cachedVal;
      }
    }

    // 3. Deduplicate in-flight requests
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    final future = _executeTranslation(
      text: trimmed,
      targetLang: target,
      sourceLang: sourceLang,
      cacheKey: cacheKey,
    );

    _inFlightRequests[cacheKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<String> _executeTranslation({
    required String text,
    required String targetLang,
    required String sourceLang,
    required String cacheKey,
  }) async {
    if (_supabase == null) return text;

    try {
      final response = await _supabase!.functions.invoke(
        'translate-text',
        body: {
          'text': text,
          'target_lang': targetLang,
          'source_lang': sourceLang,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.status == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('translated_text')) {
          final translated = (data['translated_text'] as String?)?.trim() ?? text;
          if (translated.isNotEmpty) {
            _saveToCache(cacheKey, translated);
            return translated;
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Translation Edge Function failed: $e. Falling back to original text.');
    }

    return text;
  }

  void _saveToCache(String cacheKey, String translated) {
    _memoryCache[cacheKey] = translated;
    if (_prefs != null) {
      _prefs!.setString('$_prefPrefix$cacheKey', translated).catchError((_) => false);
    }
  }

  @override
  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final result = <String, String>{};
    final unCached = <String>[];

    for (final text in texts) {
      if (text.trim().isEmpty) continue;
      final hash = _computeHash(text);
      final cacheKey = _buildCacheKey(hash, targetLang);
      if (_memoryCache.containsKey(cacheKey)) {
        result[text] = _memoryCache[cacheKey]!;
      } else {
        unCached.add(text);
      }
    }

    if (unCached.isEmpty) return result;

    if (_supabase == null) {
      for (final text in unCached) {
        result[text] = text;
      }
      return result;
    }

    try {
      final response = await _supabase!.functions.invoke(
        'translate-text',
        body: {
          'texts': unCached,
          'target_lang': targetLang,
          'source_lang': sourceLang,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.status == 200 && response.data != null && response.data is Map) {
        final map = response.data['translations'];
        if (map is Map) {
          map.forEach((orig, trans) {
            if (orig is String && trans is String && trans.trim().isNotEmpty) {
              result[orig] = trans;
              final hash = _computeHash(orig);
              _saveToCache(_buildCacheKey(hash, targetLang), trans);
            }
          });
        }
      }
    } catch (e) {
      AppLogger.warning('Batch translation failed: $e');
    }

    for (final text in unCached) {
      result.putIfAbsent(text, () => text);
    }

    return result;
  }

  @override
  void clearLocalCache() {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefPrefix)).toList();
      for (final key in keys) {
        _prefs!.remove(key);
      }
    }
  }
}
