import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/ai_provider_factory.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/domain/repositories/ai_translation_repositories.dart';
import 'package:nhasixapp/presentation/cubits/ai_settings/ai_settings_cubit.dart';

import '../unit/presentation/fakes.dart';

class _ThrowingProviderFactory implements AiProviderFactory {
  @override
  AiTranslationProvider create(AiProviderConfig config) {
    return _ThrowingProvider(config);
  }
}

class _ThrowingProvider implements AiTranslationProvider {
  _ThrowingProvider(this.config);

  @override
  final AiProviderConfig config;

  @override
  Future<void> validate() async {
    throw const AiTranslationException('bad key');
  }

  @override
  Future<PageTranslation> translatePage({
    required Uint8List image,
    required int imageWidth,
    required int imageHeight,
    required List<BubbleBoxLike> bubbles,
    required String targetLang,
    required TranslationStyle style,
    bool skipSfx = true,
    String readingDirection = 'left-to-right',
  }) {
    throw UnimplementedError();
  }
}

void main() {
  final provider = FakeAiProviderRepository.testProvider;

  test('validateProvider maps success to null', () async {
    final cubit = AiSettingsCubit(
      providerRepository: FakeAiProviderRepository(),
      preferencesRepository: FakeAiPreferencesRepository(),
      providerFactory: FakeAiProviderFactory(),
      cacheRepository: FakeCacheRepository(),
      modelCatalog: FakeAiModelCatalogRepository(),
      logger: Logger(level: Level.off),
    );
    await pumpEventQueue();
    final result = await cubit.validateProvider(provider);
    expect(result, isNull);
    await cubit.close();
  });

  test('validateProvider maps failure to error message', () async {
    final cubit = AiSettingsCubit(
      providerRepository: FakeAiProviderRepository(),
      preferencesRepository: FakeAiPreferencesRepository(),
      providerFactory: _ThrowingProviderFactory(),
      cacheRepository: FakeCacheRepository(),
      modelCatalog: FakeAiModelCatalogRepository(),
      logger: Logger(level: Level.off),
    );
    await pumpEventQueue();
    final result = await cubit.validateProvider(provider);
    expect(result, 'bad key');
    await cubit.close();
  });
}
