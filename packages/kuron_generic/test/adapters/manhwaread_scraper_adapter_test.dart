library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../support/config_test_harness.dart';

const _baseUrl = 'https://manhwaread.com';

String _readFixture(String filename) {
  final candidates = [
    'informations/documentation/manhwaread/$filename',
    '../../informations/documentation/manhwaread/$filename',
  ];

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }

  throw StateError('Cannot locate fixture $filename');
}

GenericScraperAdapter _buildAdapter(Dio dio) {
  final logger = Logger(level: Level.off);
  return GenericScraperAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
    parser: GenericHtmlParser(logger: logger),
    logger: logger,
    sourceId: 'manhwaread',
  );
}

void main() {
  late Map<String, dynamic> config;

  setUpAll(() {
    config = loadConfig('manhwaread-config.json').cast<String, dynamic>();
  });

  group('manhwaread detail chapter scoping', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('keeps only groupChapterList chapters from the live fixture',
        () async {
      dioAdapter.onGet(
        '$_baseUrl/manhwa/queen-bee',
        (server) => server.reply(
          200,
          _readFixture('halaman-detail.html'),
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        ),
      );

      final result = await adapter.fetchDetail('queen-bee', config);
      final chapters = result.content.chapters!;

      expect(chapters, isNotEmpty);
      expect(
        chapters.every((chapter) => chapter.id.startsWith('queen-bee/')),
        isTrue,
      );
      expect(
        chapters.any((chapter) => chapter.id == 'queen-bee/chapter-001'),
        isTrue,
      );
      expect(
        chapters.any(
          (chapter) => chapter.id.contains('the-patron-s-daughters/chapter-82'),
        ),
        isFalse,
      );
      expect(
        chapters.any((chapter) => chapter.id.contains('what-s-for-dinner')),
        isFalse,
      );
    });
  });
}
