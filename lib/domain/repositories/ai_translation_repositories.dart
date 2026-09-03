import 'dart:typed_data';

import '../entities/ai_translation.dart';

/// Errors surfaced by AI providers with retry semantics.
class AiTranslationException implements Exception {
  const AiTranslationException(this.message, {this.isRateLimited = false});

  final String message;
  final bool isRateLimited;

  @override
  String toString() => 'AiTranslationException: $message';
}

/// AI provider that translates page images.
abstract interface class AiTranslationProvider {
  /// Translates the page (mosaic or full image) and returns overlay results.
  ///
  /// [bubbles] in original image pixel coords — used to build the mosaic.
  /// When [bubbles] is empty, the full image is sent and the provider must
  /// return bubbles with absolute pixel rects, mapped from percentage
  /// coordinates using [imageWidth]/[imageHeight] of the ORIGINAL page.
  /// [readingDirection] is how [bubbles] were ordered — the source dialect
  /// (manga vs manhwa) determines right-to-left vs left-to-right, and the
  /// prompt tells the model the reading flow so dialogue context follows it.
  Future<PageTranslation> translatePage({
    required Uint8List image,
    required int imageWidth,
    required int imageHeight,
    required List<BubbleBoxLike> bubbles,
    required String targetLang,
    required TranslationStyle style,
    bool skipSfx = true,
    String readingDirection = 'left-to-right',
  });

  /// Sends a minimal test request to validate the API key.
  Future<void> validate();

  AiProviderConfig get config;
}

/// Persists provider configurations (BYOK keys).
abstract interface class AiProviderRepository {
  Future<List<AiProviderConfig>> getProviders();
  Future<void> saveProvider(AiProviderConfig provider);
  Future<void> deleteProvider(String id);
  Future<void> setDefault(String id);
  Future<AiProviderConfig?> getDefault();
}

/// Lists available models per provider type for the settings LOV.
///
/// Live-only: no curated lists. Throws [AiTranslationException] when the
/// fetch fails so the UI shows error + retry + manual entry. `custom`
/// always throws (manual entry only). Implementations must never persist
/// results and must never log API keys.
abstract interface class AiModelCatalogRepository {
  Future<List<AiModelOption>> getModels({
    required AiProviderType type,
    String? apiKey,
  });
}

/// Caches page translations keyed by deterministic content/page hash.
abstract interface class TranslationCacheRepository {
  Future<PageTranslation?> get(String key);
  Future<void> put(String key, PageTranslation result,
      {String? contentId, int? pageIndex});
  Future<void> clear();
}

/// User preferences for translation (target language, style).
abstract interface class AiPreferencesRepository {
  Future<String> getTargetLanguage();
  Future<void> setTargetLanguage(String language);
  Future<TranslationStyle> getTranslationStyle();
  Future<void> setTranslationStyle(TranslationStyle style);
  Future<bool> isPrivacyAcknowledged();
  Future<void> setPrivacyAcknowledged();
  Future<bool> getSkipSfx();
  Future<void> setSkipSfx(bool value);
  Future<bool> isAiTutorialSeen();
  Future<void> markAiTutorialSeen();
}
