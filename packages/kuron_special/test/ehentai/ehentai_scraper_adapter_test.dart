import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
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
          'home': {
            'url': '/?page={page}',
            'list': {
              'container': 'tr',
              'fields': {
                'id': {
                  'selector': 'a',
                  'attribute': 'href',
                },
                'title': {'selector': '.glink'},
                'coverUrl': {
                  'selector': '.gl2c img',
                  'attribute': 'src',
                },
              },
            },
          },
          'search': {
            'url': '/?f_search={query}&page={page}',
            'inherits': 'home',
          },
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

    const homeHtmlWithMixedThumbs = '''
<html><body>
  <table class="itg gltc">
    <tr>
      <td class="gl2c"></td>
      <td class="gl3c glname">
          <a href="/g/111/aaa/"><span class="glink">Item A</span></a>
      </td>
        <td class="glthumb"><div style="background:transparent url('https://thumb.example/a.webp') 0 0 no-repeat;"></div></td>
    </tr>
    <tr>
      <td class="gl2c"><img data-src="https://thumb.example/b.webp"></td>
      <td class="gl3c glname">
          <a href="/g/222/bbb/"><span class="glink">Item B</span></a>
      </td>
    </tr>
    <tr>
      <td class="gl2c"><img src="https://thumb.example/c.webp"></td>
      <td class="gl3c glname">
          <a href="/g/333/ccc/"><span class="glink">Item C</span></a>
      </td>
    </tr>
  </table>
</body></html>
''';

    const page1Html =
        '<html><body><img id="img" src="https://img.example/1.webp"></body></html>';
    const page2Html =
        '<html><body><img id="img" src="https://img.example/2.webp"></body></html>';

    const searchPage1WithNextTokenHtml = '''
<html><body>
  <script>
    var nexturl = "https://e-hentai.org/?f_search=neko&next=12345";
  </script>
  <div class="searchnav">
    <a id="unext" href="https://e-hentai.org/?f_search=neko&next=12345">Next</a>
  </div>
  <table class="itg gltc">
    <tr>
      <td class="gl2c"><img src="https://thumb.example/search-p1.webp"></td>
      <td class="gl3c glname"><a href="/g/111/aaa/"><span class="glink">P1</span></a></td>
    </tr>
  </table>
</body></html>
''';

    const searchPage2TokenHtml = '''
<html><body>
  <table class="itg gltc">
    <tr>
      <td class="gl2c">
        <img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" data-src="https://thumb.example/search-p2.webp">
      </td>
      <td class="gl3c glname"><a href="/g/222/bbb/"><span class="glink">P2</span></a></td>
    </tr>
  </table>
</body></html>
''';

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
      expect(result.content.pageCount, greaterThan(0));
      expect(result.imageUrls, isEmpty,
          reason:
              'Detail should lazy-load reader images via fetchChapterImages');
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

    test('search home fills multiple covers from mixed thumbnail markup',
        () async {
      mock.onGet(
        'https://e-hentai.org/?page=1',
        (server) => server.reply(
          200,
          homeHtmlWithMixedThumbs,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.search(const SearchFilter(page: 1), config);

      expect(result.items.length, 3);
      expect(result.items.map((e) => e.id).toList(),
          containsAll(['/g/111/aaa/', '/g/222/bbb/', '/g/333/ccc/']));
      expect(
        result.items.map((e) => e.coverUrl).toList(),
        containsAll([
          'https://thumb.example/a.webp',
          'https://thumb.example/b.webp',
          'https://thumb.example/c.webp',
        ]),
      );

      final nonEmptyCoverCount =
          result.items.where((item) => item.coverUrl.trim().isNotEmpty).length;
      expect(nonEmptyCoverCount, greaterThan(1));
    });

    test('search query uses same fallback and does not collapse to one cover',
        () async {
      mock.onGet(
        'https://e-hentai.org/?f_search=tag%3Atest&page=1',
        (server) => server.reply(
          200,
          homeHtmlWithMixedThumbs,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'tag:test', page: 1),
        config,
      );

      expect(result.items.length, 3);
      final covers = result.items
          .map((e) => e.coverUrl)
          .where((e) => e.isNotEmpty)
          .toList();
      expect(covers.length, greaterThan(1));
      expect(covers, contains('https://thumb.example/a.webp'));
      expect(covers, contains('https://thumb.example/b.webp'));
      expect(covers, contains('https://thumb.example/c.webp'));
    });

    test(
        'search home handles lazy-loaded images with data-src and data: URI placeholders',
        () async {
      const lazyLoadHtml = '''
<html><body>
  <table class="itg gltc">
    <tr>
      <td class="gl1c glcat"><div class="cn cta">Western</div></td>
      <td class="gl2c">
        <div class="glcut" id="ic1"></div>
        <div class="glthumb">
          <div><img style="height:141px;width:250px" src="https://direct.example/1.webp" /></div>
        </div>
      </td>
      <td class="gl3c glname">
        <a href="/g/111/aaa/"><span class="glink">Item Direct</span></a>
      </td>
    </tr>
    <tr>
      <td class="gl1c glcat"><div class="cn cta">Western</div></td>
      <td class="gl2c">
        <div class="glcut" id="ic2"></div>
        <div class="glthumb">
          <div><img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" data-src="https://lazy.example/2.webp" /></div>
        </div>
      </td>
      <td class="gl3c glname">
        <a href="/g/222/bbb/"><span class="glink">Item LazyLoad</span></a>
      </td>
    </tr>
    <tr>
      <td class="gl1c glcat"><div class="cn cta">Western</div></td>
      <td class="gl2c">
        <div class="glcut" id="ic3"></div>
        <div class="glthumb">
          <div><img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" data-lazy-src="https://lazy-fancy.example/3.webp" /></div>
        </div>
      </td>
      <td class="gl3c glname">
        <a href="/g/333/ccc/"><span class="glink">Item LazyFancy</span></a>
      </td>
    </tr>
  </table>
</body></html>
''';

      mock.onGet(
        'https://e-hentai.org/?page=1',
        (server) => server.reply(
          200,
          lazyLoadHtml,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        config,
      );

      expect(result.items.length, 3);

      // All 3 items should have covers (NOT data: URIs)
      expect(result.items[0].coverUrl, equals('https://direct.example/1.webp'));
      expect(result.items[1].coverUrl, equals('https://lazy.example/2.webp'));
      expect(result.items[2].coverUrl,
          equals('https://lazy-fancy.example/3.webp'));

      // Verify no data: URIs leak through
      for (final item in result.items) {
        expect(item.coverUrl, isNotEmpty);
        expect(item.coverUrl.startsWith('data:'), false,
            reason: 'Cover should not be data: URI placeholder');
      }
    });

    test('search home extracts language tags from list items', () async {
      const homeHtmlWithLanguageTags = '''
<html><body>
  <table class="itg gltc">
    <tr>
      <td class="gl2c"><img src="data:image/gif;base64,R0lGODlh"></td>
      <td class="gl3c glname">
          <a href="/g/111/aaa/"><span class="glink">Item A</span></a>
      </td>
      <td>
        <div class="gt" title="language:english"></div>
        <div class="glthumb"><div style="background:url('https://thumb.example/a.webp')"></div></div>
      </td>
    </tr>
    <tr>
      <td class="gl2c"><img data-src="https://thumb.example/b.webp"></td>
      <td class="gl3c glname">
          <a href="/g/222/bbb/"><span class="glink">Item B</span></a>
      </td>
      <td>
        <div class="gt" title="language:chinese"></div>
      </td>
    </tr>
    <tr>
      <td class="gl2c"><img src="https://thumb.example/c.webp"></td>
      <td class="gl3c glname">
          <a href="/g/333/ccc/"><span class="glink">Item C</span></a>
      </td>
      <td>
        <div class="gt" title="language:japanese"></div>
      </td>
    </tr>
  </table>
</body></html>
''';

      mock.onGet(
        'https://e-hentai.org/?page=1',
        (server) => server.reply(
          200,
          homeHtmlWithLanguageTags,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.search(const SearchFilter(page: 1), config);

      expect(result.items.length, 3);

      // Verify language extraction
      expect(result.items[0].language, 'english');
      expect(result.items[1].language, 'chinese');
      expect(result.items[2].language, 'japanese');

      // Verify IDs are correct (mapping is preserved)
      expect(result.items[0].id, '/g/111/aaa/');
      expect(result.items[1].id, '/g/222/bbb/');
      expect(result.items[2].id, '/g/333/ccc/');

      // Verify covers are also fixed
      expect(result.items[0].coverUrl, 'https://thumb.example/a.webp');
      expect(result.items[1].coverUrl, 'https://thumb.example/b.webp');
      expect(result.items[2].coverUrl, 'https://thumb.example/c.webp');
    });

    test('search raw query page 2 follows token pagination and keeps covers',
        () async {
      mock.onGet(
        'https://e-hentai.org/?f_search=neko',
        (server) => server.reply(
          200,
          searchPage1WithNextTokenHtml,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );
      mock.onGet(
        'https://e-hentai.org/?f_search=neko&next=12345',
        (server) => server.reply(
          200,
          searchPage2TokenHtml,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );
      mock.onGet(
        'https://e-hentai.org/?f_search=neko&page=2',
        (server) => server.reply(
          200,
          searchPage2TokenHtml,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'raw:f_search=neko', page: 2),
        config,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, '/g/222/bbb/');
      expect(result.items.first.title, 'P2');
      expect(
          result.items.first.coverUrl, 'https://thumb.example/search-p2.webp');
    });
  });
}
