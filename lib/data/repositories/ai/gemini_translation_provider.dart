import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/ai_translation.dart';
import '../../../domain/repositories/ai_translation_repositories.dart';

/// Google Gemini REST provider (`generateContent`).
class GeminiTranslationProvider implements AiTranslationProvider {
  GeminiTranslationProvider({
    required this.config,
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  @override
  final AiProviderConfig config;
  final Dio _dio;
  final Logger _logger;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

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
    final isMosaic = bubbles.isNotEmpty;
    final prompt = isMosaic
        ? _mosaicPrompt(targetLang, style, skipSfx)
        : _fullImagePrompt(targetLang, style, skipSfx);

    final base64 = base64Encode(image);
    final payload = {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64,
              },
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3},
    };

    final url =
        '$_baseUrl/${config.model}:generateContent?key=${config.apiKey ?? ''}';
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      final res = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      if (res.statusCode == 429) {
        throw const AiTranslationException('Rate limited', isRateLimited: true);
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      final text = _extractText(data);

      if (isMosaic) {
        return _mapMosaicResult(_parseJson(text), bubbles, targetLang);
      }
      return _mapFullImageResult(text, imageWidth, imageHeight, targetLang);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const AiTranslationException('Rate limited',
            isRateLimited: true);
      }
      final msg = e.response?.data?.toString() ?? e.message ?? 'Request failed';
      _logger.e('${config.displayName}: request failed: $msg');
      throw AiTranslationException('Gemini error: $msg');
    }
  }

  String _mosaicPrompt(
    String targetLang,
    TranslationStyle style,
    bool skipSfx,
  ) {
    final sfxRule = skipSfx
        ? 'Return "SKIP" for any bubble containing only sound effects (ドドド, バキ, ガシャン, etc.).'
        : 'Translate ALL bubbles including sound effects (no SKIP for SFX).';
    return '''
Translate the manga image. Each bubble has a red number ID on its left.
Return STRICT JSON (no markdown, no comments) with numeric string keys:
{"1": {"original": "<text in bubble>", "reading": "<latin reading>", "translated": "<translation>"}, "2": "SKIP", ...}
Rules:
- Map each number to the text inside that bubble.
- "original" = the exact text inside the bubble (for learning/glossary).
- "reading" = Latin reading of the original text: romaji for Japanese, romanization for Korean/Chinese/other (helps pronunciation). Empty if original is already Latin.
- "translated" = the translation into $targetLang.
- SKIP if a bubble contains only sound effects (ドドド, バキ, etc.).
- Keep honorifics (-san, -kun, -chan) as-is.
- Return ALL visible IDs.
- Style: ${style.instruction}
$sfxRule
''';
  }

  String _fullImagePrompt(
    String targetLang,
    TranslationStyle style,
    bool skipSfx,
  ) {
    return '''
Translate the manga/manhwa page image into $targetLang.
Return STRICT JSON (no markdown, no comments) in this exact shape:
[{"x": <left %>, "y": <top %>, "w": <width %>, "h": <height %>, "translated": "..."}]
Rules:
- Return coordinates as PERCENTAGES (0-100) of the image size.
- "translated" = translation in $targetLang. Use "SKIP" for sound-effect-only text.
- Keep honorifics (-san, -kun, -chan) as-is.
- Style: ${style.instruction}
${skipSfx ? 'Return "SKIP" for any bubble containing only sound effects.' : 'Translate ALL bubbles including sound effects.'}
''';
  }

  String _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return '';
    final parts = (candidates.first as Map<String, dynamic>)['content']
            ?['parts'] as List<dynamic>? ??
        [];
    return parts
        .map((p) => (p as Map<String, dynamic>)['text'])
        .whereType<String>()
        .join();
  }

  Map<String, dynamic> _parseJson(String text) {
    final trimmed = text.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end <= start) {
      throw const AiTranslationException('Model did not return JSON');
    }
    try {
      return Map<String, dynamic>.from(
          jsonDecode(trimmed.substring(start, end + 1)) as Map);
    } catch (e) {
      throw AiTranslationException('Failed to parse model JSON: $e');
    }
  }

  PageTranslation _mapFullImageResult(
    String text,
    int imageWidth,
    int imageHeight,
    String lang,
  ) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end <= start) {
      throw const AiTranslationException(
          'Full-image fallback: model did not return a coordinate array');
    }
    final list = jsonDecode(text.substring(start, end + 1)) as List<dynamic>;
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
      if (translated == null || translated.isEmpty ||
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

  @override
  Future<void> validate() async {
    final url =
        '$_baseUrl/${config.model}:generateContent?key=${config.apiKey ?? ''}';
    try {
      await _dio.post(
        url,
        data: {
          'contents': [
            {'parts': [{'text': 'ping'}]},
          ],
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw const AiTranslationException('Rate limited', isRateLimited: true);
      }
      throw AiTranslationException(
          'Gemini validation failed: ${e.response?.data?.toString() ?? e.message}');
    }
  }
}
