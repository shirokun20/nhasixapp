import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/repositories/ai/model_json_parser.dart';
import 'package:nhasixapp/data/repositories/ai/openai_compatible_provider.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:nhasixapp/domain/repositories/ai_translation_repositories.dart';

void main() {
  group('ModelJsonParser.parseMosaicJson', () {
    test('clean JSON passes through untouched', () {
      final out = ModelJsonParser.parseMosaicJson(
          '{"1": {"original": "x", "reading": "", "translated": "y"}}');
      expect(out['1']['translated'], 'y');
    });

    test('markdown-fenced JSON is unwrapped', () {
      final out = ModelJsonParser.parseMosaicJson(
          '```json\n{"1": {"original": "x", "reading": "", "translated": "y"}}\n```');
      expect(out['1']['translated'], 'y');
    });

    test('echoed ... marker is repaired', () {
      final out = ModelJsonParser.parseMosaicJson(
          '{"1": {"original": "x", "reading": "", "translated": "y"}, "2": "SKIP", ...}');
      expect(out['1']['translated'], 'y');
      expect(out['2'], 'SKIP');
    });

    test('trailing commas are repaired', () {
      final out = ModelJsonParser.parseMosaicJson(
          '{"1": {"original": "x", "reading": "", "translated": "y",},}');
      expect(out['1']['translated'], 'y');
    });

    test('chatter with braces does not shift extraction', () {
      final out = ModelJsonParser.parseMosaicJson(
          'Here is {the translation}: {"1": {"original": "x", "reading": "", "translated": "y"}} done.');
      expect(out['1']['translated'], 'y');
    });

    test('legit ellipsis inside strings is preserved', () {
      final out = ModelJsonParser.parseMosaicJson(
          '{"1": {"original": "tunggu...", "reading": "", "translated": "Wait..."}}');
      expect(out['1']['translated'], 'Wait...');
    });

    test('garbage throws a user-actionable error', () {
      expect(
        () => ModelJsonParser.parseMosaicJson('sorry, cannot help'),
        throwsA(isA<AiTranslationException>().having(
            (e) => e.message, 'message', contains('unusable response'))),
      );
    });
  });

  group('ModelJsonParser.parseJsonArray', () {
    test('clean and fenced arrays parse', () {
      expect(ModelJsonParser.parseJsonArray('[{"x": 1}]'), hasLength(1));
      expect(
          ModelJsonParser.parseJsonArray('```\n[{"x": 1}]\n```'), hasLength(1));
    });
  });

  group('ModelJsonParser.looksLikePlaceholder', () {
    test('detects echoed placeholders in any language', () {
      expect(ModelJsonParser.looksLikePlaceholder('<terjemahan>'), true);
      expect(ModelJsonParser.looksLikePlaceholder('<bacaan latin>'), true);
      expect(ModelJsonParser.looksLikePlaceholder('<translation 1>'), true);
      expect(ModelJsonParser.looksLikePlaceholder('...'), true);
      expect(ModelJsonParser.looksLikePlaceholder('  <teks>  '), true);
    });

    test('accepts real translations', () {
      expect(ModelJsonParser.looksLikePlaceholder('Halo dunia'), false);
      expect(ModelJsonParser.looksLikePlaceholder('Wait...'), false);
      expect(ModelJsonParser.looksLikePlaceholder('<3'), false);
      expect(ModelJsonParser.looksLikePlaceholder('a < b and c > d'), false);
      expect(
          ModelJsonParser.looksLikePlaceholder('Dia <pahlawan> sejati'), false);
    });
  });

  group('template-echo end to end (OpenAI-compatible)', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
    });

    OpenAICompatibleProvider makeProvider(String modelText) {
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'choices': [
              {
                'message': {'content': modelText}
              }
            ]
          },
        ));
      }));
      return OpenAICompatibleProvider(
        config: AiProviderConfig(
          id: 't',
          displayName: 'Test',
          type: AiProviderType.openAi,
          model: 'm',
          apiKey: 'k',
          isDefault: true,
        ),
        dio: dio,
        logger: Logger(level: Level.off),
      );
    }

    test('full echo throws a friendly error, not a FormatException dump',
        () async {
      // The exact reported shape: placeholders + literal ... marker.
      final provider = makeProvider(
          '{"1": {"original": "senpai", "reading": "<bacaan latin>", "translated": "<terjemahan>"}, "2": "SKIP", ...}');
      expect(
        () => provider.translatePage(
          image: Uint8List(4),
          imageWidth: 100,
          imageHeight: 100,
          bubbles: const [
            BubbleBoxLike(0, 0, 10, 10),
            BubbleBoxLike(20, 20, 10, 10),
          ],
          targetLang: 'Indonesian',
          style: TranslationStyle.natural,
        ),
        throwsA(isA<AiTranslationException>().having(
            (e) => e.message, 'message', contains('echoed the format'))),
      );
    });

    test('partial echo still yields the real bubbles', () async {
      final provider = makeProvider(
          '{"1": {"original": "x", "reading": "", "translated": "nyata"}, "2": {"original": "y", "reading": "", "translated": "<terjemahan>"}}');
      final result = await provider.translatePage(
        image: Uint8List(4),
        imageWidth: 100,
        imageHeight: 100,
        bubbles: const [
          BubbleBoxLike(0, 0, 10, 10),
          BubbleBoxLike(20, 20, 10, 10),
        ],
        targetLang: 'Indonesian',
        style: TranslationStyle.natural,
      );
      expect(result.bubbles, hasLength(1));
      expect(result.bubbles.first.translated, 'nyata');
    });

    test('legit all-SKIP still returns empty without throwing', () async {
      final provider = makeProvider('{"1": "SKIP", "2": "SKIP"}');
      final result = await provider.translatePage(
        image: Uint8List(4),
        imageWidth: 100,
        imageHeight: 100,
        bubbles: const [
          BubbleBoxLike(0, 0, 10, 10),
          BubbleBoxLike(20, 20, 10, 10),
        ],
        targetLang: 'Indonesian',
        style: TranslationStyle.natural,
      );
      expect(result.bubbles, isEmpty);
    });
  });
}
