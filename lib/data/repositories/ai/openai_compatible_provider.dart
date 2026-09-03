import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/ai_translation.dart';
import '../../../domain/repositories/ai_translation_repositories.dart';

/// OpenAI-compatible `/chat/completions` provider. Covers OpenCode Go
/// (all 23 models), OpenAI, OpenRouter, Zen free models, and Custom endpoints.
class OpenAICompatibleProvider implements AiTranslationProvider {
  OpenAICompatibleProvider({
    required this.config,
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  @override
  final AiProviderConfig config;
  final Dio _dio;
  final Logger _logger;

  /// Full image fallback path — AI returns percentage coordinates.
  static const String fullImagePrompt = '''
Translate the manga/manhwa page image into {lang}.
Return STRICT JSON (no markdown, no comments) in this exact shape:
[{{"x": <left %>, "y": <top %>, "w": <width %>, "h": <height %>, "translated": "..."}}]
Rules:
- Return coordinates as PERCENTAGES (0-100) of the image size.
- "translated" = translation in {lang}. Use "SKIP" for sound-effect-only text.
- Keep honorifics (-san, -kun, -chan) as-is.
- {style}
- {sfxRule}
''';

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
  }) async {
    final isMosaic = bubbles.isNotEmpty;
    final prompt = isMosaic
        ? buildMosaicPrompt(targetLang, style, skipSfx, readingDirection)
        : fullImagePrompt
            .replaceAll('{lang}', targetLang)
            .replaceAll('{style}', style.instruction)
            .replaceAll('{sfxRule}', sfxRule(skipSfx));

    final base64 = base64Encode(image);
    final payload = {
      'model': config.model,
      'temperature': 0.3,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64'},
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    };

    final response = await _post(payload);

    final content = _extractContent(response);

    if (isMosaic) {
      final parsed = _parseJson(content);
      return _mapMosaicResult(parsed, bubbles, targetLang);
    }
    return _mapFullImageResult(content, imageWidth, imageHeight, targetLang);
  }

  String buildMosaicPrompt(
    String targetLang,
    TranslationStyle style,
    bool skipSfx, [
    String readingDirection = 'left-to-right',
  ]) {
    return '''
Translate the manga/manhwa image. Each bubble has a red number ID on its left.
Reading order: bubbles numbered $readingDirection, top-to-bottom.
Return STRICT JSON (no markdown, no comments) with numeric string keys:
{"1": {"original": "<text in bubble>", "reading": "<latin reading>", "translated": "<translation>"}, "2": "SKIP", ...}
Rules:
- Map each number to the text inside that bubble, in reading order.
- "original" = the exact text inside the bubble (for learning/glossary).
- "reading" = Latin reading of the original text: romaji for Japanese, romanization for Korean/Chinese/other scripts (helps pronunciation). Empty if original is already Latin.
- "translated" = the translation into $targetLang.
- SKIP if a bubble is a sound effect (ドドド, バキ, etc.).
- Keep honorifics (-san, -kun, -chan) as-is.
- Return ALL visible IDs.
- Style: ${style.instruction}
${sfxRule(skipSfx)}
''';
  }

  String sfxRule(bool skipSfx) {
    return skipSfx
        ? 'Return "SKIP" for any bubble containing only sound effects (ドドド, バキ, ガシャン, etc.).'
        : 'Translate ALL bubbles including sound effects (no SKIP for SFX).';
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> payload) async {
    final baseUrl = config.baseUrl ?? config.type.defaultBaseUrl;
    if (baseUrl == null) {
      throw const AiTranslationException('No base URL configured');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    try {
      final res = await _dio.post(
        baseUrl,
        data: payload,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      if (res.statusCode == 429) {
        _logger.w('${config.displayName}: rate limited (429)');
        throw const AiTranslationException('Rate limited', isRateLimited: true);
      }
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        _logger.w('${config.displayName}: rate limited (429)');
        throw const AiTranslationException('Rate limited', isRateLimited: true);
      }
      final msg = e.response?.data?.toString() ?? e.message ?? 'Request failed';
      _logger.e('${config.displayName}: request failed: $msg');
      throw AiTranslationException('Provider error: $msg');
    }
  }

  /// Extracts assistant text content from OpenAI-style response.
  String _extractContent(Map<String, dynamic> response) {
    final choices = response['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) return '';
    final message = choices.first as Map<String, dynamic>;
    final content = message['message']?['content'];
    if (content is String) return content;
    // Some providers return content as a list of parts
    if (content is List) {
      return content
          .map((part) => (part as Map<String, dynamic>)['text'])
          .whereType<String>()
          .join();
    }
    return '';
  }

  /// Extracts the first JSON object/array from model text output.
  Map<String, dynamic> _parseJson(String content) {
    final text = content.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) {
      throw const AiTranslationException('Model did not return JSON');
    }
    try {
      return Map<String, dynamic>.from(
          jsonDecode(text.substring(start, end + 1)) as Map);
    } catch (e) {
      throw AiTranslationException('Failed to parse model JSON: $e');
    }
  }

  PageTranslation _mapMosaicResult(
    Map<String, dynamic> parsed,
    List<BubbleBoxLike> bubbles,
    String lang,
  ) {
    final out = <BubbleTranslation>[];
    for (var i = 0; i < bubbles.length; i++) {
      final box = bubbles[i];
      final raw = parsed['${i + 1}'];
      // New format: {"original": ..., "translated": ...}. Old: plain string.
      String? translated;
      String original = '';
      String reading = '';
      if (raw is Map) {
        translated = raw['translated']?.toString().trim();
        original = raw['original']?.toString().trim() ?? '';
        reading = raw['reading']?.toString().trim() ?? '';
      } else if (raw != null) {
        translated = raw.toString().trim();
      }
      if (translated == null ||
          translated.isEmpty ||
          translated.toUpperCase() == 'SKIP') {
        continue;
      }
      out.add(BubbleTranslation(
        rect: Rect.fromLTWH(
          box.x.toDouble(),
          box.y.toDouble(),
          box.w.toDouble(),
          box.h.toDouble(),
        ),
        original: original,
        translated: translated,
        reading: reading,
      ));
    }
    return PageTranslation(bubbles: out, detectedLang: lang);
  }

  PageTranslation _mapFullImageResult(
    String content,
    int imageWidth,
    int imageHeight,
    String lang,
  ) {
    final start = content.indexOf('[');
    final end = content.lastIndexOf(']');
    if (start == -1 || end <= start) {
      throw const AiTranslationException(
          'Full-image fallback: model did not return a coordinate array');
    }
    final list = jsonDecode(content.substring(start, end + 1)) as List<dynamic>;
    final out = <BubbleTranslation>[];
    for (final item in list.cast<Map<String, dynamic>>()) {
      final translated = (item['translated'] as String? ?? '').trim();
      if (translated.isEmpty || translated.toUpperCase() == 'SKIP') continue;
      final x = (item['x'] as num).toDouble() / 100.0 * imageWidth;
      final y = (item['y'] as num).toDouble() / 100.0 * imageHeight;
      final w = (item['w'] as num).toDouble() / 100.0 * imageWidth;
      final h = (item['h'] as num).toDouble() / 100.0 * imageHeight;
      out.add(BubbleTranslation(
        rect: Rect.fromLTWH(x, y, w, h),
        original: '',
        translated: translated,
      ));
    }
    return PageTranslation(
        bubbles: out, detectedLang: lang, usedFallback: true);
  }

  @override
  Future<void> validate() async {
    // Minimal test: 1-token completion
    final payload = {
      'model': config.model,
      'max_tokens': 1,
      'messages': [
        {'role': 'user', 'content': 'ping'},
      ],
    };
    await _post(payload);
  }
}
