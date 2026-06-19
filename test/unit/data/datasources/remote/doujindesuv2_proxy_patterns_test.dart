import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoujinDesu v2 ProxyPatterns Type Safety', () {
    test('proxyPatterns from JSON decode is List<dynamic>, not List<String>',
        () {
      const jsonString = '''
      {
        "api": {
          "images": {
            "mode": "direct",
            "items": "\$.data.chapter.images[*]",
            "urlPath": "\$",
            "proxyUrl": "https://v2.doujindesu.fun/api/image-proxy?url={url}",
            "proxyPatterns": ["desu.photos", "cdn.doujindesu"]
          }
        }
      }
      ''';

      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      final imagesCfg = config['api']['images'] as Map<String, dynamic>;

      // ❌ This will FAIL with type cast error
      expect(
        () => imagesCfg['proxyPatterns'] as List<String>,
        throwsA(isA<TypeError>()),
      );

      // ✅ This is the CORRECT way
      final proxyPatterns = (imagesCfg['proxyPatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      expect(proxyPatterns, isA<List<String>>());
      expect(proxyPatterns, ['desu.photos', 'cdn.doujindesu']);
    });

    test('proxyPatterns safe cast handles empty list', () {
      const jsonString = '''
      {
        "api": {
          "images": {
            "proxyPatterns": []
          }
        }
      }
      ''';

      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      final imagesCfg = config['api']['images'] as Map<String, dynamic>;

      final proxyPatterns = (imagesCfg['proxyPatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      expect(proxyPatterns, isEmpty);
    });

    test('proxyPatterns safe cast handles null', () {
      const jsonString = '''
      {
        "api": {
          "images": {
            "mode": "direct"
          }
        }
      }
      ''';

      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      final imagesCfg = config['api']['images'] as Map<String, dynamic>;

      final proxyPatterns = (imagesCfg['proxyPatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      expect(proxyPatterns, isEmpty);
    });

    test('proxyPatterns works with actual doujindesuv2-config.json structure',
        () {
      final configJson = {
        'api': {
          'images': {
            'mode': 'direct',
            'items': '\$.data.chapter.images[*]',
            'urlPath': '\$',
            'proxyUrl': 'https://v2.doujindesu.fun/api/image-proxy?url={url}',
            'proxyPatterns': ['desu.photos']
          }
        }
      };

      final imagesCfg = configJson['api']!['images'] as Map<String, dynamic>;

      // Safe cast (correct way)
      final proxyPatterns = (imagesCfg['proxyPatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      expect(proxyPatterns, ['desu.photos']);
      expect(proxyPatterns, isA<List<String>>());
    });
  });
}
