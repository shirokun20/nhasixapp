library;

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../support/config_test_harness.dart';

const _baseUrl = 'https://hentairead.com';
const _contentId = 'mama-no-saikon-aite-wa-papakatsu-no-papa';

const _detailHtml = '''
<html>
  <body>
    <div class="manga-titles">
      <h1 class="clipboard-copy">Mama no Saikon Aite wa Papakatsu no Papa</h1>
      <h2>Alt One | Alt Two</h2>
    </div>
    <img src="https://mancover.xyz/cover/2026/01/hentairead-mama-no-saikon-aite-wa-papakatsu-no-papa.webp">
    <div class="description">
      <p>pages: 24</p>
    </div>
    <a href="/artist/test-artist"><span>Some Artist</span></a>
    <a href="/circle/test-circle"><span>Circle House</span></a>
    <a href="/tag/milf"><span>MILF</span></a>
    <a href="/tag/full-color"><span>Full Color</span></a>
  </body>
</html>
''';

const _readerHtml = '''
<html>
  <body>
    <script id="single-chapter-js-extra">
      var boot = {"baseUrl":"https://cdn.hentairead.test/gallery"};
    </script>
    <script id="single-chapter-js-before">
      window.mMjM5MjM2 = '(eyJkYXRhIjp7ImNoYXB0ZXIiOnsiaW1hZ2VzIjpbeyJzcmMiOiIwMDEuanBnIn0seyJzcmMiOiIwMDIuanBnIn1dfX19)';
    </script>
  </body>
</html>
''';

GenericScraperAdapter _buildAdapter(Dio dio) {
  final logger = Logger(level: Level.off);
  return GenericScraperAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
    parser: GenericHtmlParser(logger: logger),
    logger: logger,
    sourceId: 'hentairead',
  );
}

void main() {
  late Map<String, dynamic> config;

  setUpAll(() {
    config = loadConfig('hentairead-config.json').cast<String, dynamic>();
  });

  group('hentairead scraper config', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('extracts detail fields without chapter list', () async {
      dioAdapter.onGet(
        '$_baseUrl/hentai/$_contentId/',
        (server) => server.reply(
          200,
          _detailHtml,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.fetchDetail(_contentId, config);

      expect(result.content.title, 'Mama no Saikon Aite wa Papakatsu no Papa');
      expect(result.content.artists, contains('Some Artist'));
      expect(result.content.groups, contains('Circle House'));
      expect(result.content.tags.map((tag) => tag.name),
          containsAll(['MILF', 'Full Color']));
      expect(result.content.chapters, isNull);
      expect(result.imageUrls, isEmpty);
    });

    test('reads english reader page from chapterDataScript fallback format',
        () async {
      dioAdapter.onGet(
        '$_baseUrl/hentai/$_contentId/english/p/1/',
        (server) => server.reply(
          200,
          _readerHtml,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.fetchChapterImages(_contentId, config);

      expect(result, isNotNull);
      expect(result!.images, [
        'https://cdn.hentairead.test/gallery/001.jpg',
        'https://cdn.hentairead.test/gallery/002.jpg',
      ]);
    });
  });
}
