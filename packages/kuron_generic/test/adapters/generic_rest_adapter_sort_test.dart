import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://nhentai.net';

Dio _buildDio() => Dio(BaseOptions(baseUrl: _baseUrl));

GenericRestAdapter _buildAdapter(Dio dio) {
  return GenericRestAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
    parser: GenericJsonParser(logger: Logger(level: Level.off)),
    logger: Logger(level: Level.off),
    sourceId: 'nhentai',
  );
}

final Map<String, dynamic> _config = {
  'source': 'nhentai',
  'baseUrl': _baseUrl,
  'api': {
    'apiBase': '$_baseUrl/api/v2',
    'endpoints': {
      'search': '/api/v2/search?query={query}&sort={sort}&page={page}',
      'allGalleries': '/api/v2/galleries?page={page}',
    },
  },
  'selectors': {
    'items': {'selector': r'$.result[*]', 'type': 'jsonpath'},
    'totalPages': {'selector': r'$.num_pages', 'type': 'jsonpath'},
  },
  'searchConfig': {
    'sortingConfig': {
      'options': [
        {'value': 'newest', 'apiValue': 'date'},
        {'value': 'popular', 'apiValue': 'popular'},
        {'value': 'popular-week', 'apiValue': 'popular-week'},
        {'value': 'popular-today', 'apiValue': 'popular-today'},
      ],
    },
  },
};

void main() {
  group('GenericRestAdapter sort mapping', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericRestAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('maps newest sort to date for nhentai v2 search', () async {
      const expectedUrl =
          '$_baseUrl/api/v2/search?query=language%3A%22english%22&sort=date&page=1';

      dioAdapter.onGet(
        expectedUrl,
        (server) => server.reply(200, {
          'result': <dynamic>[],
          'num_pages': 0,
        }),
      );

      final result = await adapter.search(
        const SearchFilter(
          query: 'language:"english"',
          page: 1,
          sort: SortOption.newest,
        ),
        _config,
      );

      expect(result.items, isEmpty);
    });

    test('maps popular sort to popular for nhentai v2 search', () async {
      const expectedUrl =
          '$_baseUrl/api/v2/search?query=language%3A%22english%22&sort=popular&page=1';

      dioAdapter.onGet(
        expectedUrl,
        (server) => server.reply(200, {
          'result': <dynamic>[],
          'num_pages': 0,
        }),
      );

      final result = await adapter.search(
        const SearchFilter(
          query: 'language:"english"',
          page: 1,
          sort: SortOption.popular,
        ),
        _config,
      );

      expect(result.items, isEmpty);
    });
  });
}
