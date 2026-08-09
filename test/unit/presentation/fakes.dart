import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:nhasixapp/data/repositories/ai/ai_provider_factory.dart';
import 'package:nhasixapp/data/repositories/ai/mosaic_builder.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/domain/repositories/ai_translation_repositories.dart';

/// Runs CPU-bound image prep synchronously on the caller isolate — the test
/// counterpart of `HeavyRunner` (production uses `Isolate.run`). fake-async
/// `testWidgets` cannot await real isolate replies, so tests inject this to
/// avoid hanging while still exercising the full pipeline state machine.
Future<T> syncHeavyRunner<T>(FutureOr<T> Function() compute) async => compute();

/// In-memory provider repository with Zen built-in semantics.
class FakeAiProviderRepository implements AiProviderRepository {
  /// A default vision-capable provider for pipeline tests.
  static final testProvider = AiProviderConfig(
    id: 'go-test',
    displayName: 'Go',
    type: AiProviderType.openCodeGo,
    model: 'kimi-k2.6',
    apiKey: 'k',
    isDefault: true,
  );

  FakeAiProviderRepository({bool withVisionProvider = false})
      : _providers = [
          if (withVisionProvider) testProvider,
          AiProviderConfig(
            id: 'zen-builtin',
            displayName: 'Zen (Free)',
            type: AiProviderType.zen,
            model: 'deepseek-v4-flash-free',
            isDefault: !withVisionProvider,
          ),
        ];

  final List<AiProviderConfig> _providers;

  /// Replaces provider list with exactly [provider] (for pipeline tests).
  void addOnly(AiProviderConfig provider) {
    _providers
      ..clear()
      ..add(provider);
  }

  void addNoProviders() => _providers.clear();

  @override
  Future<AiProviderConfig?> getDefault() async {
    for (final p in _providers) {
      if (p.isDefault) return p;
    }
    return _providers.isEmpty ? null : _providers.first;
  }

  @override
  Future<List<AiProviderConfig>> getProviders() async {
    return List.of(_providers);
  }

  @override
  Future<void> saveProvider(AiProviderConfig provider) async {
    final idx = _providers.indexWhere((p) => p.id == provider.id);
    if (idx == -1) {
      _providers.add(provider);
    } else {
      _providers[idx] = provider;
    }
  }

  @override
  Future<void> deleteProvider(String id) async {
    if (id == 'zen-builtin') return; // Zen cannot be deleted
    _providers.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> setDefault(String id) async {
    for (var i = 0; i < _providers.length; i++) {
      _providers[i] = _providers[i].copyWith(isDefault: _providers[i].id == id);
    }
  }
}

class FakeAiPreferencesRepository implements AiPreferencesRepository {
  String lang = 'Indonesian';
  TranslationStyle style = TranslationStyle.natural;
  bool ack = false;

  @override
  Future<String> getTargetLanguage() async => lang;

  @override
  Future<void> setTargetLanguage(String language) async => lang = language;

  @override
  Future<TranslationStyle> getTranslationStyle() async => style;

  @override
  Future<void> setTranslationStyle(TranslationStyle s) async => style = s;

  @override
  Future<bool> isPrivacyAcknowledged() async => ack;

  @override
  Future<void> setPrivacyAcknowledged() async => ack = true;

  bool skipSfx = true;

  @override
  Future<bool> getSkipSfx() async => skipSfx;

  @override
  Future<void> setSkipSfx(bool value) async => skipSfx = value;

  bool aiTutorialSeen = false;

  @override
  Future<bool> isAiTutorialSeen() async => aiTutorialSeen;

  @override
  Future<void> markAiTutorialSeen() async => aiTutorialSeen = true;
}

class FakeCacheRepository implements TranslationCacheRepository {
  final Map<String, PageTranslation> _store = {};

  @override
  Future<PageTranslation?> get(String key) async => _store[key];

  @override
  Future<void> put(String key, PageTranslation result,
      {String? contentId, int? pageIndex}) async {
    _store[key] = result;
  }

  @override
  Future<void> clear() async => _store.clear();
}

class FakeAiProviderFactory implements AiProviderFactory {
  @override
  AiTranslationProvider create(AiProviderConfig config) {
    return FakeProvider(config);
  }
}

class FakeProvider implements AiTranslationProvider {
  FakeProvider(this.config);

  @override
  final AiProviderConfig config;

  @override
  Future<PageTranslation> translatePage({
    required Uint8List image,
    required int imageWidth,
    required int imageHeight,
    required List<BubbleBoxLike> bubbles,
    required String targetLang,
    required TranslationStyle style,
    bool skipSfx = true,
  }) async {
    return PageTranslation(
      bubbles: [
        for (var i = 0; i < bubbles.length; i++)
          BubbleTranslation(
            rect: Rect.fromLTWH(
              bubbles[i].x.toDouble(),
              bubbles[i].y.toDouble(),
              bubbles[i].w.toDouble(),
              bubbles[i].h.toDouble(),
            ),
            original: '',
            translated: 'T$i',
          ),
      ],
    );
  }

  @override
  Future<void> validate() async {}
}

/// Mosaic builder stub — returns minimal bytes (ONNX + provider are mocked).
class FakeMosaicBuilder extends MosaicBuilder {
  @override
  Uint8List buildMosaic(Uint8List pageImage, List<BubbleBoxLike> bubbles) {
    return Uint8List(4);
  }
}
