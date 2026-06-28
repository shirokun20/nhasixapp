library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import '../support/config_test_harness.dart';

const _baseUrl = 'https://www.tooncubus.top';

String _readFixture(String filename) {
  final candidates = [
    'informations/documentation/tooncubus/$filename',
    '../../informations/documentation/tooncubus/$filename',
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
    sourceId: 'tooncubus',
  );
}

void main() {
  late Map<String, dynamic> config;

  setUpAll(() {
    config = loadConfig('tooncubus-config.json').cast<String, dynamic>();
  });

  test('home fixture extracts Blogger cards from Series label page', () async {
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    final dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final adapter = _buildAdapter(dio);

    dioAdapter.onGet(
      '$_baseUrl/search/label/Series?max-results=20',
      (server) => server.reply(
        200,
        _readFixture('halaman-utama.html'),
        headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        },
      ),
    );

    final result = await adapter.search(const SearchFilter(page: 1), config);

    expect(result.items, isNotEmpty);
    expect(result.items.first.title, 'Love For Amalthea');
    expect(result.items.first.id, '2026/03/love-for-amalthea.html');
    expect(
      result.items.first.coverUrl,
      startsWith('https://blogger.googleusercontent.com/'),
    );
    expect(result.hasNextPage, isTrue);
  });
}
