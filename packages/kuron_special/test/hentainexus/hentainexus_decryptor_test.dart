import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/src/hentainexus/hentainexus_decryptor.dart';

void main() {
  group('HentaiNexusDecryptor', () {
    test('throws when decrypted seed is too short', () {
      final encrypted = base64Encode(utf8.encode('short-seed'));

      expect(
        () => HentaiNexusDecryptor.decrypt(
          encrypted: encrypted,
        ),
        throwsFormatException,
      );
    });

    test('extractImageUrls parses image entries from decrypted payload', () {
      const payload = '''
[
  {"type": "image", "image": "https://cdn.example/1.webp"},
  {"type": "image", "image": "https://cdn.example/2.webp"},
  {"type": "ignored", "image": "https://cdn.example/skip.webp"}
]
''';

      final urls = HentaiNexusDecryptor.extractImageUrls(payload);

      expect(urls, <String>[
        'https://cdn.example/1.webp',
        'https://cdn.example/2.webp',
      ]);
    });

    test('extractImageUrls keeps backward compatibility for url/spread', () {
      const payload = '''
[
  {"type": "url", "url": "https://cdn.example/1.webp"},
  {"type": "spread", "url": "https://cdn.example/2.webp", "nextLink": "https://cdn.example/3.webp"},
  {"type": "ignored", "url": "https://cdn.example/skip.webp"}
]
''';

      final urls = HentaiNexusDecryptor.extractImageUrls(payload);

      expect(urls, <String>[
        'https://cdn.example/1.webp',
        'https://cdn.example/2.webp',
        'https://cdn.example/3.webp',
      ]);
    });

    test('extractImageUrls supports object-shaped payloads', () {
      const payload = '''
{
  "pages": [
    {"src": "https://images.hentainexus.com/v2/demo/001.png.thumb.jpg"},
    {"image": "https://images.hentainexus.com/v2/demo/002.png"}
  ]
}
''';

      final urls = HentaiNexusDecryptor.extractImageUrls(payload);

      expect(urls, <String>[
        'https://images.hentainexus.com/v2/demo/001.png',
        'https://images.hentainexus.com/v2/demo/002.png',
      ]);
    });

    test('extractImageUrls prefers webp over avif for the same page', () {
      const payload = '''
[
  {
    "image_avif": "https://images.hentainexus.com/v2/demo/001.avif",
    "image_webp": "https://images.hentainexus.com/v2/demo/001.webp"
  },
  {
    "image_avif": "https://images.hentainexus.com/v2/demo/002.avif",
    "image_webp": "https://images.hentainexus.com/v2/demo/002.webp"
  }
]
''';

      final urls = HentaiNexusDecryptor.extractImageUrls(payload);

      expect(urls, <String>[
        'https://images.hentainexus.com/v2/demo/001.webp',
        'https://images.hentainexus.com/v2/demo/002.webp',
      ]);
    });

    test('extractImageUrlsFromHtml normalizes thumb urls and dedupes', () {
      const html = '''
<img src="https://images.hentainexus.com/v2/demo/001.png.thumb.jpg">
<img data-src="https://images.hentainexus.com/v2/demo/001.png.thumb.jpg">
<img src="https://images.hentainexus.com/v2/demo/002.webp">
''';

      final urls = HentaiNexusDecryptor.extractImageUrlsFromHtml(html);

      expect(urls, <String>[
        'https://images.hentainexus.com/v2/demo/001.png',
        'https://images.hentainexus.com/v2/demo/002.webp',
      ]);
    });
  });
}
