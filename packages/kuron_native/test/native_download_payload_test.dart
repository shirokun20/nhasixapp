import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/src/native_download_payload.dart';

void main() {
  group('NativeDownloadPage', () {
    test('toJson includes required fields', () {
      const page = NativeDownloadPage(
        pageNumber: 1,
        url: 'https://example.com/img/001.webp',
      );
      final json = page.toJson();
      expect(json['pageNumber'], 1);
      expect(json['url'], 'https://example.com/img/001.webp');
      expect(json.containsKey('headers'), isFalse); // empty → omitted
    });

    test('toJson includes headers and referer', () {
      const page = NativeDownloadPage(
        pageNumber: 3,
        url: 'https://cdn.example.com/003.jpg',
        headers: {'X-Token': 'abc'},
        referer: 'https://example.com/',
      );
      final json = page.toJson();
      expect(json['headers'], {'X-Token': 'abc'});
      expect(json['referer'], 'https://example.com/');
    });

    test('fromJson roundtrip', () {
      const original = NativeDownloadPage(
        pageNumber: 7,
        url: 'https://cdn.test/007.png',
        headers: {'Authorization': 'Bearer x'},
        referer: 'https://ref.test/',
        filenameHint: 'chapter_1_007',
        mimeHint: 'image/png',
      );
      final roundtripped = NativeDownloadPage.fromJson(
        original.toJson().cast<String, Object?>(),
      );
      expect(roundtripped.pageNumber, original.pageNumber);
      expect(roundtripped.url, original.url);
      expect(roundtripped.headers, original.headers);
      expect(roundtripped.referer, original.referer);
      expect(roundtripped.filenameHint, original.filenameHint);
      expect(roundtripped.mimeHint, original.mimeHint);
    });
  });

  group('NativeDownloadPayload', () {
    NativeDownloadPayload buildPayload({
      Map<String, String> pageHeaders = const {},
      Map<String, String> globalHeaders = const {},
    }) {
      return NativeDownloadPayload(
        contentId: 'content-001',
        sourceId: 'hitomi',
        destinationPath: '/sdcard/Download/nhasix/hitomi/content-001',
        pages: [
          NativeDownloadPage(
            pageNumber: 1,
            url: 'https://cdn.hitomi.la/001.webp',
            headers: pageHeaders,
          ),
          NativeDownloadPage(
            pageNumber: 2,
            url: 'https://cdn.hitomi.la/002.webp',
            headers: pageHeaders,
          ),
        ],
        globalHeaders: globalHeaders,
        title: 'Test Gallery',
        totalPages: 2,
      );
    }

    test('imageUrls returns only non-empty urls in order', () {
      final payload = buildPayload();
      expect(payload.imageUrls, [
        'https://cdn.hitomi.la/001.webp',
        'https://cdn.hitomi.la/002.webp',
      ]);
    });

    test('toChannelMap includes both v1 and v2 fields', () {
      final payload = buildPayload();
      final map = payload.toChannelMap();

      // v1 backward compat
      expect(map['imageUrls'], isA<List<String>>());
      expect((map['imageUrls'] as List<String>).length, 2);

      // v2 per-page payload
      expect(map.containsKey('perPagePayload'), isTrue);
      final decoded = jsonDecode(map['perPagePayload'] as String) as List;
      expect(decoded.length, 2);
      expect((decoded.first as Map)['pageNumber'], 1);
    });

    test('toChannelMap encodes globalHeaders as JSON string', () {
      final payload = buildPayload(
        globalHeaders: {'Referer': 'https://hitomi.la/'},
      );
      final map = payload.toChannelMap();
      expect(map.containsKey('headers'), isTrue);
      final decoded = jsonDecode(map['headers'] as String) as Map;
      expect(decoded['Referer'], 'https://hitomi.la/');
    });

    test('toChannelMap omits headers key when globalHeaders empty', () {
      final payload = buildPayload();
      final map = payload.toChannelMap();
      expect(map.containsKey('headers'), isFalse);
    });

    test('toChannelMap per-page headers are embedded in perPagePayload', () {
      final payload = buildPayload(pageHeaders: {'X-Gallery-Token': 'tok123'});
      final map = payload.toChannelMap();
      final pages = (jsonDecode(map['perPagePayload'] as String) as List)
          .cast<Map>();
      for (final page in pages) {
        expect((page['headers'] as Map)['X-Gallery-Token'], 'tok123');
      }
    });

    test('totalPages falls back to page count', () {
      final payload = NativeDownloadPayload(
        contentId: 'c1',
        sourceId: 's1',
        destinationPath: '/tmp',
        pages: [
          const NativeDownloadPage(pageNumber: 1, url: 'https://a.test/1.jpg'),
        ],
      );
      final map = payload.toChannelMap();
      expect(map['totalPages'], 1);
    });

    test('legacy v1: empty perPagePayload encodes empty array', () {
      final payload = NativeDownloadPayload(
        contentId: 'c1',
        sourceId: 's1',
        destinationPath: '/tmp',
        pages: const [],
      );
      final map = payload.toChannelMap();
      final decoded = jsonDecode(map['perPagePayload'] as String) as List;
      expect(decoded, isEmpty);
      expect((map['imageUrls'] as List<String>), isEmpty);
    });
  });
}
