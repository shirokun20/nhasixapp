library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/adapters/generic_rest_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_json_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://legacy.example';

const _legacyConfig = {
  'source': 'legacy-pagination',
  'baseUrl': _baseUrl,
  'selectors': {
    'items': r'$.archives[*]',
    'id': r'$.id',
    'title': r'$.title',
    'page': r'$.page',
    'limit': r'$.limit',
    'total': r'$.total',
  },
  'api': {
    'enabled': true,
    'endpoints': {
      'search': '/library?q={query}&page={page}',
    },
  },
};

const _legacyResponse = {
  'archives': [
    {'id': 'abc', 'title': 'Legacy Item'},
  ],
  'page': 2,
  'limit': 24,
  'total': 17654,
};

void main() {
  group('GenericRestAdapter legacy pagination normalization', () {
    test('derives totalPages from page + limit + total selectors', () async {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      final dioAdapter =
          DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final adapter = GenericRestAdapter(
        dio: dio,
        urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
        parser: GenericJsonParser(logger: Logger(level: Level.off)),
        logger: Logger(level: Level.off),
        sourceId: 'legacy-pagination',
      );

      dioAdapter.onGet(
        '$_baseUrl/library?q=legacy&page=2',
        (server) => server.reply(200, jsonDecode(jsonEncode(_legacyResponse))),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'legacy', page: 2),
        _legacyConfig,
      );

      expect(result.items, hasLength(1));
      expect(result.totalItems, 17654);
      expect(result.totalPages, 736);
      expect(result.hasNextPage, isTrue);
    });
  });
}
