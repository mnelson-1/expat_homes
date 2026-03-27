import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../constants/user_profile_options.dart';

/// Incoming-message translation using **ML Kit on-device** only (English, French, Swahili).
///
/// Maps [UserProfile.preferredLanguage] to a [TranslateLanguage] target. Unknown labels
/// leave text unchanged. Firestore message bodies are never modified.
///
/// Language ID is fallible (short text, `und`, or misclassification). When the
/// identified source equals the viewer's target language, we still try other
/// supported source languages so e.g. French text is not left untranslated for
/// an English viewer.
class MessageTranslationService {
  MessageTranslationService._();
  static final MessageTranslationService instance =
      MessageTranslationService._();

  final Map<String, String> _cache = {};

  static const List<TranslateLanguage> _supportedLanguages = [
    TranslateLanguage.english,
    TranslateLanguage.french,
    TranslateLanguage.swahili,
  ];

  String _cacheKey({
    required String messageId,
    required bool enabled,
    required String prefLang,
    required String text,
  }) =>
      '${messageId}_${enabled ? 1 : 0}_${prefLang}_${text.hashCode}';

  /// Clears memoized lines (e.g. when the user flips the translate toggle).
  void clearCache() => _cache.clear();

  /// Translate [text] for an **incoming** bubble when [translationEnabled] is true.
  Future<String> translateIncoming({
    required String text,
    required String messageId,
    required String preferredLanguageLabel,
    required bool translationEnabled,
  }) async {
    final trimmed = text.trim();
    if (!translationEnabled || trimmed.isEmpty) return text;
    if (kIsWeb) return text;

    final key = _cacheKey(
      messageId: messageId,
      enabled: translationEnabled,
      prefLang: preferredLanguageLabel,
      text: text,
    );
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final out = await _translateCore(trimmed, preferredLanguageLabel);
      _cache[key] = out;
      return out;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MessageTranslationService: $e\n$st');
      }
      return text;
    }
  }

  Future<String> _translateCore(String text, String preferredLabel) async {
    final target = _mlKitTargetFromLabel(preferredLabel);
    if (target == null) return text;

    TranslateLanguage? identified;
    try {
      final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.35);
      String sourceTag;
      try {
        sourceTag = await languageIdentifier.identifyLanguage(text);
      } finally {
        await languageIdentifier.close();
      }
      if (sourceTag.isNotEmpty && sourceTag != 'und') {
        final primary = _primaryBcp(sourceTag);
        identified = _mapPrimaryToSupported(primary);
      }
    } catch (_) {
      // Identification failed; rely on source fallbacks below.
    }

    final tried = <String>{};
    Future<String?> tryPair(TranslateLanguage source) async {
      if (source.bcpCode == target.bcpCode) return null;
      final key = '${source.bcpCode}->${target.bcpCode}';
      if (tried.contains(key)) return null;
      tried.add(key);
      try {
        return await _translateWithModels(text, source, target);
      } catch (_) {
        return null;
      }
    }

    // Prefer ML Kit's guess when it disagrees with the target.
    if (identified != null && identified.bcpCode != target.bcpCode) {
      final primary = await tryPair(identified);
      if (primary != null && !_sameNormalized(primary, text)) {
        return primary;
      }
    }

    // Same-language early exit from ID is often wrong (`und`→en, FR misread as EN).
    for (final src in _supportedLanguages) {
      if (src.bcpCode == target.bcpCode) continue;
      if (identified != null && src.bcpCode == identified.bcpCode) {
        continue;
      }
      final out = await tryPair(src);
      if (out != null && !_sameNormalized(out, text)) {
        return out;
      }
    }

    return text;
  }

  Future<String?> _translateWithModels(
    String text,
    TranslateLanguage source,
    TranslateLanguage target,
  ) async {
    if (source.bcpCode == target.bcpCode) return null;

    final modelManager = OnDeviceTranslatorModelManager();
    for (final lang in <TranslateLanguage>[source, target]) {
      final code = lang.bcpCode;
      if (!await modelManager.isModelDownloaded(code)) {
        final ok = await modelManager.downloadModel(code);
        if (!ok) return null;
      }
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return await translator.translateText(text);
    } finally {
      await translator.close();
    }
  }

  bool _sameNormalized(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  TranslateLanguage? _mlKitTargetFromLabel(String label) {
    switch (label.trim().toLowerCase()) {
      case 'english':
        return TranslateLanguage.english;
      case 'french':
        return TranslateLanguage.french;
      case 'swahili':
        return TranslateLanguage.swahili;
      default:
        return null;
    }
  }

  String _primaryBcp(String tag) {
    final t = tag.toLowerCase().trim();
    final idx = t.indexOf('-');
    if (idx <= 0) return t;
    return t.substring(0, idx);
  }

  /// Only treat ID as useful when it maps to a language we can translate.
  TranslateLanguage? _mapPrimaryToSupported(String primary) {
    switch (primary) {
      case 'en':
        return TranslateLanguage.english;
      case 'fr':
        return TranslateLanguage.french;
      case 'sw':
        return TranslateLanguage.swahili;
      default:
        return null;
    }
  }

  /// Precomputes thread-list preview text per supported language for Firestore
  /// (`conversations.lastMessageTranslations`). Call when updating [lastMessage].
  static Future<Map<String, String>> buildLastMessageTranslationsForFirestore({
    required String preview,
    required String conversationId,
  }) async {
    final trimmed = preview.trim();
    if (trimmed.isEmpty) return {};
    if (kIsWeb) {
      return {for (final l in kPreferredLanguages) l: preview};
    }
    final svc = MessageTranslationService.instance;
    final hash = trimmed.hashCode;
    final futures = kPreferredLanguages.map((lang) async {
      try {
        final t = await svc.translateIncoming(
          text: trimmed,
          messageId: 'fs_preview_${conversationId}_${lang}_$hash',
          preferredLanguageLabel: lang,
          translationEnabled: true,
        );
        return MapEntry(lang, t);
      } catch (_) {
        return MapEntry(lang, trimmed);
      }
    });
    final entries = await Future.wait(futures);
    return Map<String, String>.fromEntries(entries);
  }
}

