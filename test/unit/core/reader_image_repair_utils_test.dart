import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/reader_image_repair_utils.dart';

void main() {
  group('reader_image_repair_utils', () {
    test('infers extension from content type before sniffing bytes', () {
      final extension = inferImageExtension(
        bytes: const <int>[0x47, 0x49, 0x46, 0x38],
        contentType: 'image/png; charset=binary',
      );

      expect(extension, 'png');
    });

    test('infers extension from image bytes when content type is missing', () {
      final extension = inferImageExtension(
        bytes: const <int>[
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
        ],
      );

      expect(extension, 'webp');
    });

    test('does not infer image extension from html bytes alone', () {
      final extension = inferImageExtension(
        bytes: '<html><body>error</body></html>'.codeUnits,
      );

      expect(extension, isNull);
    });

    test('builds replacement path with repaired extension', () {
      final repairedPath = buildReplacementImagePath(
        currentImagePath: '/downloads/ehentai/images/014.jpg',
        extension: 'png',
      );

      expect(repairedPath, '/downloads/ehentai/images/014.png');
    });

    test('extracts E-Hentai image URL from reader HTML', () {
      const html = '''
      <html>
        <body>
          <img id="img" src="https://ehgt.org/example/14.webp" />
        </body>
      </html>
      ''';

      final imageUrl = extractEhentaiImageUrlFromHtml(
        html,
        'https://e-hentai.org/s/example/123-14',
      );

      expect(imageUrl, 'https://ehgt.org/example/14.webp');
    });

    test('extracts E-Hentai image URL using config-defined selector', () {
      const html = '''
      <html>
        <body>
          <div class="reader-stage">
            <img class="page-image" data-src="/images/14.webp" />
          </div>
        </body>
      </html>
      ''';

      final imageUrl = extractEhentaiImageUrlFromHtml(
        html,
        'https://e-hentai.org/s/example/123-14',
        rawConfig: <String, dynamic>{
          'scraper': <String, dynamic>{
            'selectors': <String, dynamic>{
              'detail': <String, dynamic>{
                'imageUrls': <String, dynamic>{
                  'mode': 'ehentai_page_fetch',
                  'imageSelector': '.page-image',
                },
              },
            },
          },
        },
      );

      expect(imageUrl, 'https://e-hentai.org/images/14.webp');
    });

    test('detects manual source-page repair support from config', () {
      expect(
        supportsSourcePageManualRepair(<String, dynamic>{
          'scraper': <String, dynamic>{
            'selectors': <String, dynamic>{
              'detail': <String, dynamic>{
                'imageUrls': <String, dynamic>{
                  'mode': 'page_fetch',
                  'imageSelector': '.page-image',
                },
              },
            },
          },
        }),
        isTrue,
      );
    });

    test('does not enable manual source-page repair for reader-only configs',
        () {
      expect(
        supportsSourcePageManualRepair(<String, dynamic>{
          'scraper': <String, dynamic>{
            'selectors': <String, dynamic>{
              'reader': <String, dynamic>{
                'images': <String, dynamic>{
                  'selector': 'img',
                  'attribute': 'src',
                },
              },
            },
          },
        }),
        isFalse,
      );
    });

    test('detects local reader image paths', () {
      expect(
          isLocalReaderImagePath('/storage/emulated/0/Download/1.jpg'), isTrue);
      expect(isLocalReaderImagePath('file:///tmp/test.webp'), isTrue);
      expect(isLocalReaderImagePath('https://ehgt.org/test/1.jpg'), isFalse);
    });
  });
}
