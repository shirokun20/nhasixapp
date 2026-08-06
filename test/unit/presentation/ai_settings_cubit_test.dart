import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/presentation/cubits/ai_settings/ai_settings_cubit.dart';

import 'fakes.dart';

void main() {
  late FakeAiProviderRepository providerRepo;
  late FakeAiPreferencesRepository prefsRepo;
  late AiSettingsCubit cubit;

  setUp(() {
    providerRepo = FakeAiProviderRepository();
    prefsRepo = FakeAiPreferencesRepository();
    cubit = AiSettingsCubit(
      providerRepository: providerRepo,
      preferencesRepository: prefsRepo,
      providerFactory: FakeAiProviderFactory(),
      cacheRepository: FakeCacheRepository(),
      logger: Logger(level: Level.off),
    );
  });

  tearDown(() => cubit.close());

  test('loads providers with Zen built-in always present', () async {
    await pumpEventQueue();
    final state = cubit.state;
    expect(state, isA<AiSettingsLoaded>());
    final loaded = state as AiSettingsLoaded;
    expect(loaded.providers.any((p) => p.id == 'zen-builtin'), true);
    expect(loaded.providers.length, 1); // zen only by default
  });

  test('addProvider then deleteProvider: Zen cannot be deleted', () async {
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
    expect(loaded.providers.length, 2);

    await cubit.deleteProvider('zen-builtin');
    await pumpEventQueue();
    loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.providers.any((p) => p.id == 'zen-builtin'), true);
    expect(loaded.providers.length, 2); // Zen survives delete

    await cubit.deleteProvider('p1');
    await pumpEventQueue();
    loaded = cubit.state as AiSettingsLoaded;
    expect(loaded.providers.any((p) => p.id == 'p1'), false);
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
}
