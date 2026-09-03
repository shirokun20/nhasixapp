import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/domain/repositories/ai_translation_repositories.dart';
import 'package:nhasixapp/presentation/cubits/ai_settings/ai_settings_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeAiProviderRepository providerRepo;
  late FakeAiPreferencesRepository prefsRepo;
  late FakeAiModelCatalogRepository catalogRepo;
  late AiSettingsCubit cubit;

  setUp(() {
    providerRepo = FakeAiProviderRepository();
    prefsRepo = FakeAiPreferencesRepository();
    catalogRepo = FakeAiModelCatalogRepository();
    cubit = AiSettingsCubit(
      providerRepository: providerRepo,
      preferencesRepository: prefsRepo,
      providerFactory: FakeAiProviderFactory(),
      cacheRepository: FakeCacheRepository(),
      modelCatalog: catalogRepo,
      logger: Logger(level: Level.off),
    );
  });

  tearDown(() async {
    await pumpEventQueue();
    await cubit.close();
  });

  test('loads providers empty when none stored (no built-in)', () async {
    await pumpEventQueue();
    final state = cubit.state;
    expect(state, isA<AiSettingsLoaded>());
    final loaded = state as AiSettingsLoaded;
    expect(loaded.providers, isEmpty);
  });

  test('addProvider then deleteProvider', () async {
    await pumpEventQueue();
    final newProvider = AiProviderConfig(
      id: 'p1',
      displayName: 'Gemini Key 1',
      type: AiProviderType.gemini,
      model: 'gemini-2.5-flash',
      apiKey: 'key',
    );
    await cubit.addProvider(newProvider);
    await pumpEventQueue();
    var loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.providers.length, 1);
    expect(loaded.providers.any((p) => p.id == 'p1'), true);

    await cubit.addProvider(AiProviderConfig(
      id: 'p2',
      displayName: 'OpenAI',
      type: AiProviderType.openAi,
      model: 'gpt-4o',
      apiKey: 'k2',
    ));
    await pumpEventQueue();
    loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.providers.length, 2);

    await cubit.deleteProvider('p1');
    await pumpEventQueue();
    loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.providers.any((p) => p.id == 'p1'), false);
    expect(loaded.providers.length, 1);
  });

  test('setDefault marks the right provider active', () async {
    await pumpEventQueue();
    await cubit.addProvider(AiProviderConfig(
      id: 'p1',
      displayName: 'Go',
      type: AiProviderType.openCodeGo,
      model: 'kimi-k2.6',
      apiKey: 'k',
    ));
    await pumpEventQueue();
    await cubit.setDefault('p1');
    await pumpEventQueue();
    final loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.activeProvider?.id, 'p1');
  });

  test('setTargetLanguage / setTranslationStyle update state', () async {
    await pumpEventQueue();
    await cubit.setTargetLanguage('Japanese');
    await cubit.setTranslationStyle(TranslationStyle.action);
    final loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.targetLang, 'Japanese');
    expect(loaded.style, TranslationStyle.action);
  });

  test('fetchModels delegates to catalog', () async {
    await pumpEventQueue();
    catalogRepo.models = [
      const AiModelOption(id: 'model-a', isVision: true),
      const AiModelOption(id: 'model-b', isVision: null),
    ];
    final models = await cubit.fetchModels(type: AiProviderType.zen);
    expect(models.length, 2);
    expect(models.first.id, 'model-a');
  });

  test('fetchModels throws on failure (no fallback)', () async {
    await pumpEventQueue();
    catalogRepo.shouldThrow = true;
    expect(() => cubit.fetchModels(type: AiProviderType.openRouter),
        throwsA(isA<AiTranslationException>()));
  });
}
