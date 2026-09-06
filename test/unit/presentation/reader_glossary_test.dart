import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/cohere_translation_provider.dart';
import 'package:nhasixapp/data/repositories/ai/fallback_image_handler.dart';
import 'package:nhasixapp/data/repositories/ai/gemini_translation_provider.dart';
import 'package:nhasixapp/data/repositories/ai/openai_compatible_provider.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/domain/entities/glossary.dart';
import 'package:nhasixapp/domain/entities/reader_settings_entity.dart';
import 'package:nhasixapp/domain/repositories/ai_translation_repositories.dart';
import 'package:nhasixapp/presentation/cubits/reader/reader_translation_cubit.dart';

import 'fakes.dart';

GlossaryEntry entry(String src, String dst, int ts) => GlossaryEntry(
      id: 'g-$src-$ts',
      sourceText: src,
      translatedText: dst,
      contentId: 'c1',
      pageIndex: 0,
      timestamp: ts,
    );

AiProviderConfig testConfig(AiProviderType type) => AiProviderConfig(
      id: 'test-${type.name}',
      displayName: 'Test',
      type: type,
      model: 'test-model',
      apiKey: 'k',
      isDefault: true,
    );

void main() {
  group('selectRelevantGlossaryEntries', () {
    test('matches case-insensitive substrings', () {
      final entries = [
        entry('senpai', 'kakak senior', 3),
        entry('arigatou', 'terima kasih', 2),
        entry('unrelated', 'tak terkait', 4),
      ];
      final out = ReaderTranslationCubit.selectRelevantGlossaryEntries(
        entries,
        ['Yoroshiku, SENPAI!', 'Arigatou gozaimasu'],
      );
      expect(out.map((e) => e.sourceText),
          ['senpai', 'arigatou']); // timestamp desc
    });

    test('at most five entries, most recent first', () {
      final entries = [
        for (var i = 0; i < 7; i++) entry('term$i', 'arti$i', i),
      ];
      final out = ReaderTranslationCubit.selectRelevantGlossaryEntries(
        entries,
        ['this page mentions term0 term1 term2 term3 term4 term5 term6'],
      );
      expect(out.length, 5);
      expect(out.map((e) => e.sourceText),
          ['term6', 'term5', 'term4', 'term3', 'term2']);
    });

    test('no match leaves prompt unchanged (empty selection)', () {
      final entries = [entry('senpai', 'kakak senior', 1)];
      final out = ReaderTranslationCubit.selectRelevantGlossaryEntries(
        entries,
        ['hello world'],
      );
      expect(out, isEmpty);
    });

    test('empty entries or texts select nothing', () {
      expect(
          ReaderTranslationCubit.selectRelevantGlossaryEntries([], ['senpai']),
          isEmpty);
      expect(
          ReaderTranslationCubit.selectRelevantGlossaryEntries(
              [entry('senpai', 'kakak senior', 1)], []),
          isEmpty);
    });
  });

  group('buildGlossaryBlock', () {
    test('renders Glossary lines', () {
      final block = ReaderTranslationCubit.buildGlossaryBlock([
        entry('senpai', 'kakak senior', 2),
        entry('arigatou', 'terima kasih', 1),
      ]);
      expect(block, contains('Glossary:'));
      expect(block, contains('"senpai" -> "kakak senior"'));
      expect(block, contains('"arigatou" -> "terima kasih"'));
    });
  });

  group('provider mosaic prompts', () {
    late Dio dio;
    late Logger logger;

    setUp(() {
      dio = Dio();
      logger = Logger(level: Level.off);
    });

    test('OpenAI prompt embeds glossary; unchanged without it', () {
      final provider = OpenAICompatibleProvider(
        config: testConfig(AiProviderType.openAi),
        dio: dio,
        logger: logger,
      );
      const glossary = 'Glossary:\n"senpai" -> "kakak senior"';
      final withGlossary = provider.buildMosaicPrompt('Indonesian',
          TranslationStyle.natural, true, 'left-to-right', glossary);
      expect(withGlossary, contains('"senpai" -> "kakak senior"'));

      final plain = provider.buildMosaicPrompt(
          'Indonesian', TranslationStyle.natural, true);
      expect(plain, isNot(contains('Glossary')));
    });

    test('Gemini mosaic request carries glossary in the same call', () async {
      String? capturedPrompt;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        final data = options.data as Map<String, dynamic>;
        final contents = data['contents'] as List<dynamic>;
        final parts =
            (contents.first as Map<String, dynamic>)['parts'] as List<dynamic>;
        capturedPrompt =
            (parts.last as Map<String, dynamic>)['text'] as String?;
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          '{"1": {"original": "x", "reading": "", "translated": "y"}}'
                    }
                  ]
                }
              }
            ],
          },
        ));
      }));
      final provider = GeminiTranslationProvider(
        config: testConfig(AiProviderType.gemini),
        dio: dio,
        logger: logger,
      );
      await provider.translatePage(
        image: Uint8List.fromList([1, 2, 3]),
        imageWidth: 100,
        imageHeight: 100,
        bubbles: const [BubbleBoxLike(0, 0, 10, 10)],
        targetLang: 'Indonesian',
        style: TranslationStyle.natural,
        glossaryContext: 'Glossary:\n"senpai" -> "kakak senior"',
      );
      expect(capturedPrompt, contains('"senpai" -> "kakak senior"'));
    });

    test('Cohere mosaic request carries glossary in the same call', () async {
      String? capturedPrompt;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        final data = options.data as Map<String, dynamic>;
        final messages = data['messages'] as List<dynamic>;
        final content = (messages.first as Map<String, dynamic>)['content']
            as List<dynamic>;
        capturedPrompt =
            (content.first as Map<String, dynamic>)['text'] as String?;
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'message': {
              'content': [
                {
                  'text':
                      '{"1": {"original": "x", "reading": "", "translated": "y"}}'
                }
              ]
            }
          },
        ));
      }));
      final provider = CohereTranslationProvider(
        config: testConfig(AiProviderType.cohere),
        dio: dio,
        logger: logger,
      );
      await provider.translatePage(
        image: Uint8List.fromList([1, 2, 3]),
        imageWidth: 100,
        imageHeight: 100,
        bubbles: const [BubbleBoxLike(0, 0, 10, 10)],
        targetLang: 'Indonesian',
        style: TranslationStyle.natural,
        glossaryContext: 'Glossary:\n"arigatou" -> "terima kasih"',
      );
      expect(capturedPrompt, contains('"arigatou" -> "terima kasih"'));
    });
  });

  group('cubit glossary + mosaic tier propagation', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('kuron_native'),
        (MethodCall call) async {
          if (call.method == 'detectBubbles') {
            return [
              {'x': 10, 'y': 10, 'w': 50, 'h': 30, 'confidence': 0.9},
            ];
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('kuron_native'), null);
    });

    test('low tier reaches builder and glossary reaches provider once',
        () async {
      final provider = FakeProvider(FakeAiProviderRepository.testProvider);
      final mosaicBuilder = FakeMosaicBuilder();
      final preferences = FakeAiPreferencesRepository()
        ..mosaicQuality = MosaicQuality.low;
      final cubit = ReaderTranslationCubit(
        providerRepository: FakeAiProviderRepository(withVisionProvider: true),
        providerFactory: _RecordingFactory(provider),
        preferencesRepository: preferences,
        cacheRepository: FakeCacheRepository(),
        mosaicBuilder: mosaicBuilder,
        fallbackHandler: FallbackImageHandler(),
        glossaryRepository: FakeGlossaryRepository([
          entry('senpai', 'kakak senior', 2),
          entry('arigatou', 'terima kasih', 1),
        ]),
        heavyRunner: syncHeavyRunner,
        logger: Logger(level: Level.off),
      );
      addTearDown(cubit.close);

      await cubit.translatePage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageWidth: 100,
        imageHeight: 100,
        contentId: 'c1',
        pageIndex: 0,
        imageUrl: 'u1',
        readingMode: ReadingMode.singlePage,
        imageUrlCount: 1,
      );
      await pumpEventQueue();

      expect(cubit.state, isA<ReaderTranslationTranslated>());
      expect(mosaicBuilder.lastQuality, MosaicQuality.low);
      expect(provider.translateCalls, 1); // no extra AI requests
      expect(
          provider.lastGlossaryContext, contains('"senpai" -> "kakak senior"'));
    });
  });
}

class _RecordingFactory extends FakeAiProviderFactory {
  _RecordingFactory(this.provider);

  final FakeProvider provider;

  @override
  AiTranslationProvider create(AiProviderConfig config) => provider;
}
