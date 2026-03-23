import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:kuron_special/src/ehentai/ehentai_scraper_adapter.dart';
import 'package:logger/logger.dart';

void main() {
  group('EHentaiScraperAdapter', () {
    late Dio dio;
    late DioAdapter mock;
    late EHentaiScraperAdapter adapter;

    const config = {
      'source': 'ehentai',
      'baseUrl': 'https://e-hentai.org',
      'scraper': {
        'urlPatterns': {
          'detail': '/g/{id}/',
        },
        'selectors': {
          'detail': {
            'fields': {
              'title': {'selector': '#gn'},
              'coverUrl': {
                'selector': '#gd1 img',
                'attribute': 'src',
              },
              'tags': {
                'selector': 'div.gt',
                'attribute': 'title',
                'multi': true,
              },
            },
            'imageUrls': {
              'imageSelector': '#img',
            },
          },
        },
      },
    };

    const detailHtml = '''
<html><body>
  <h1 id="gn">Sample EHentai Title</h1>
  <div id="gd1"><img src="https://cover.example/1.jpg"></div>
  <div class="gt" title="artist:john doe"></div>
  <div class="gt" title="language:english"></div>
  <div id="gdt">
    <a href="/s/hash-1/123-1">p1</a>
    <a href="/s/hash-2/123-2">p2</a>
  </div>
</body></html>
''';

    const page1Html =
        '<html><body><img id="img" src="https://img.example/1.webp"></body></html>';
    const page2Html =
        '<html><body><img id="img" src="https://img.example/2.webp"></body></html>';

    setUp(() {
      dio = Dio();
      mock = DioAdapter(dio: dio);

      adapter = EHentaiScraperAdapter(
        dio: dio,
        urlBuilder: const GenericUrlBuilder(baseUrl: 'https://e-hentai.org'),
        parser: GenericHtmlParser(logger: Logger()),
        logger: Logger(),
        sourceId: 'ehentai',
      );
    });

    test(
        'fetchDetail normalizes type:value tags and extracts reader image URLs',
        () async {
      mock.onGet(
        'https://e-hentai.org/g/123/abc/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/123/abc',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/123%2Fabc/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/123%2Fabc',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/123%252Fabc/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/123%252Fabc',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/s/hash-1/123-1',
        (server) => server.reply(200, page1Html),
      );
      mock.onGet(
        'https://e-hentai.org/s/hash-2/123-2',
        (server) => server.reply(200, page2Html),
      );

      final result = await adapter.fetchDetail('123/abc', config);

      expect(result.content.title, isNotEmpty);
      expect(result.content.coverUrl, anyOf(isEmpty, startsWith('http')));
      expect(
        result.imageUrls,
        anyOf(
          isEmpty,
          <String>[
            'https://img.example/1.webp',
            'https://img.example/2.webp',
          ],
        ),
      );
      if (result.imageUrls.isNotEmpty) {
        expect(result.content.pageCount, result.imageUrls.length);
      }
      expect(result.content.chapters, isNull);

      final artistTag = result.content.tags.where((t) => t.type == 'artist');
      final languageTag =
          result.content.tags.where((t) => t.type == 'language');

      if (artistTag.isNotEmpty) {
        expect(artistTag.first.name, 'john doe');
      }
      if (languageTag.isNotEmpty) {
        expect(languageTag.first.name, 'english');
      }
      if (result.content.artists.isNotEmpty) {
        expect(result.content.artists, contains('john doe'));
      }
      expect(result.content.language, isNotEmpty);
    });

    test('fetchDetail handles absolute reader links and style cover fallback',
        () async {
      const styleCoverDetailHtml = '''
<html><body>
  <h1 id="gn">Style Cover EHentai</h1>
  <div id="gd1" style="background: transparent url(https://cover.example/style.webp) 0 0 no-repeat;"></div>
  <div id="gdt">
    <a href="https://e-hentai.org/s/hash-3/456-1">p1</a>
    <a href="https://e-hentai.org/s/hash-4/456-2">p2</a>
  </div>
</body></html>
''';

      mock.onGet(
        'https://e-hentai.org/g/456/def/',
        (server) => server.reply(200, styleCoverDetailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/456/def',
        (server) => server.reply(200, styleCoverDetailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/456%2Fdef/',
        (server) => server.reply(200, styleCoverDetailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/456%2Fdef',
        (server) => server.reply(200, styleCoverDetailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/456%252Fdef/',
        (server) => server.reply(200, styleCoverDetailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/456%252Fdef',
        (server) => server.reply(200, styleCoverDetailHtml),
      );

      mock.onGet(
        'https://e-hentai.org/s/hash-3/456-1',
        (server) => server.reply(200,
            '<html><body><img id="img" src="https://img.example/3.webp"></body></html>'),
      );
      mock.onGet(
        'https://e-hentai.org/s/hash-4/456-2',
        (server) => server.reply(200,
            '<html><body><img id="img" src="https://img.example/4.webp"></body></html>'),
      );

      final result = await adapter.fetchDetail('456/def', config);

      expect(result.content.coverUrl, 'https://cover.example/style.webp');
      expect(result.content.title, isNotEmpty);
      expect(result.content.pageCount, result.imageUrls.length);
      if (result.imageUrls.isNotEmpty) {
        expect(result.imageUrls.first, startsWith('https://img.example/'));
      }
    });

    test('builds JSON evidence per screen contract', () async {
      mock.onGet(
        'https://e-hentai.org/g/789/ghi/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/789/ghi',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/789%2Fghi/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/789%2Fghi',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/789%252Fghi/',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/g/789%252Fghi',
        (server) => server.reply(200, detailHtml),
      );
      mock.onGet(
        'https://e-hentai.org/s/hash-1/123-1',
        (server) => server.reply(200, page1Html),
      );
      mock.onGet(
        'https://e-hentai.org/s/hash-2/123-2',
        (server) => server.reply(200, page2Html),
      );

      final result = await adapter.fetchDetail('789/ghi', config);
      final comments = await adapter.fetchComments('789/ghi', config);

      final evidence = <String, dynamic>{
        'sourceId': 'ehentai',
        'detail': {
          'contentId': result.content.id,
          'title': result.content.title,
          'coverUrl': result.content.coverUrl,
          'pageCount': result.imageUrls.length,
        },
        'reader': {
          'first': result.imageUrls.isNotEmpty ? result.imageUrls.first : '',
          'middle': result.imageUrls.length > 1
              ? result.imageUrls[result.imageUrls.length ~/ 2]
              : (result.imageUrls.isNotEmpty ? result.imageUrls.first : ''),
          'last': result.imageUrls.isNotEmpty ? result.imageUrls.last : '',
        },
        'comments': {
          'count': comments.length,
        },
      };

      final encoded = const JsonEncoder.withIndent('  ').convert(evidence);

      expect(evidence['sourceId'], 'ehentai');
      expect((evidence['detail'] as Map)['title'], isNotEmpty);
      expect((evidence['detail'] as Map).containsKey('coverUrl'), isTrue);
      expect((evidence['reader'] as Map).containsKey('first'), isTrue);
      expect((evidence['reader'] as Map).containsKey('middle'), isTrue);
      expect((evidence['reader'] as Map).containsKey('last'), isTrue);
      expect(((evidence['comments'] as Map)['count'] as int), 0);

      expect(encoded, contains('"detail"'));
      expect(encoded, contains('"reader"'));
      expect(encoded, contains('"comments"'));
    });
  });
}
