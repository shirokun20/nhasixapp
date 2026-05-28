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

const _baseApiUrl = 'https://hentalk.pw/api';
const _galleryId = '18114';
const _galleryHash = 'df033486f1a05315';
const _galleryTitle = 'Bavel Pin-Up Girls #279';

const _config = {
  'source': 'spyfakku',
  'baseUrl': 'https://hentalk.pw',
  'defaultLanguage': 'english',
  'network': {
    'headers': {
      'Referer': 'https://hentalk.pw/',
      'Origin': 'https://hentalk.pw',
      'User-Agent': 'Mozilla/5.0',
    },
  },
  'api': {
    'url': _baseApiUrl,
    'endpoints': {
      'allGalleries': {
        'path': '/library',
        'params': {
          'sort': 'released_at',
          'page': '{page}',
        },
      },
      'search': {
        'path': '/library',
        'params': {
          'sort': 'released_at',
          'q': '{query}',
          'page': '{page}',
        },
      },
      'detail': {
        'path': '/g/{id}',
      },
    },
    'list': {
      'items': r'$.archives[*]',
      'pagination': {
        'currentPage': {'path': r'$.page'},
        'limit': {'path': r'$.limit'},
        'total': {'path': r'$.total'},
      },
      'fields': {
        'id': {'selector': r'$.id'},
        'mediaId': {'selector': r'$.hash'},
        'title': {'selector': r'$.title'},
        'pageCount': {'selector': r'$.pages'},
        'uploadDate': {'selector': r'$.releasedAt'},
        'coverUrl': {
          'type': 'coverBuilder',
          'mangaIdPath': r'$.hash',
          'filenamePath': r'$.thumbnail',
          'template':
              'https://hentalk.pw/image/{mangaId}/{fileName}?type=cover',
        },
      },
    },
    'detail': {
      'fields': {
        'id': {'selector': r'$.id'},
        'mediaId': {'selector': r'$.hash'},
        'title': {'selector': r'$.title'},
        'description': {'selector': r'$.description'},
        'pageCount': {'selector': r'$.pages'},
        'uploadDate': {'selector': r'$.releasedAt'},
        'status': {'value': 'completed'},
        'tagObjects': {
          'type': 'tagObjects',
          'selector': r'$.tags[*]',
        },
        'coverUrl': {
          'type': 'coverBuilder',
          'mangaIdPath': r'$.hash',
          'filenamePath': r'$.thumbnail',
          'template':
              'https://hentalk.pw/image/{mangaId}/{fileName}?type=cover',
        },
      },
      'images': {
        'template': 'https://hentalk.pw/image/{mediaId}/{page}',
        'mediaIdSelector': r'$.hash',
        'pageCountSelector': r'$.pages',
      },
    },
  },
  'searchConfig': {
    'searchMode': 'query-string',
    'endpoint': '/library',
    'queryParam': 'q',
  },
};

const _searchResponse = {
  'archives': [
    {
      'id': 18114,
      'hash': _galleryHash,
      'title': _galleryTitle,
      'description': null,
      'pages': 1,
      'thumbnail': 1,
      'releasedAt': '2026-03-08T00:00:00.000Z',
      'tags': [
        {'namespace': 'artist', 'name': 'Aka'},
      ],
    },
  ],
  'page': 1,
  'limit': 24,
  'total': 17654,
};

const _detailResponse = {
  'id': 18114,
  'hash': _galleryHash,
  'title': _galleryTitle,
  'description': 'Pin-up illustration gallery',
  'pages': 3,
  'thumbnail': 1,
  'releasedAt': '2026-03-08T00:00:00.000Z',
  'tags': [
    {'id': 4709, 'namespace': 'artist', 'name': 'Aka'},
    {'id': 3239, 'namespace': 'parody', 'name': 'Original Work'},
    {'id': 3366, 'namespace': 'tag', 'name': 'Busty'},
  ],
};

Dio _buildDio() => Dio(BaseOptions(baseUrl: _baseApiUrl));

GenericRestAdapter _buildAdapter(Dio dio) {
  return GenericRestAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseApiUrl),
    parser: GenericJsonParser(logger: Logger(level: Level.off)),
    logger: Logger(level: Level.off),
    sourceId: 'spyfakku',
  );
}

void main() {
  group('SpyFakku REST integration', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericRestAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('search builds absolute cover URLs and derives total pages', () async {
      const expectedUrl = '$_baseApiUrl/library?sort=released_at&q=aka&page=1';

      dioAdapter.onGet(
        expectedUrl,
        (server) => server.reply(200, jsonDecode(jsonEncode(_searchResponse))),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'aka', page: 1),
        _config,
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.id, _galleryId);
      expect(result.items.first.mediaId, _galleryHash);
      expect(
        result.items.first.coverUrl,
        'https://hentalk.pw/image/$_galleryHash/1?type=cover',
      );
      expect(result.items.first.language, 'english');
      expect(result.totalItems, 17654);
      expect(result.totalPages, 736);
      expect(result.hasNextPage, isTrue);
    });

    test('raw artist query keeps namespace-aware q parameter', () async {
      const expectedUrl =
          '$_baseApiUrl/library?sort=released_at&q=artist%3A%22Aka%22&page=1';

      dioAdapter.onGet(
        expectedUrl,
        (server) => server.reply(200, jsonDecode(jsonEncode(_searchResponse))),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'raw:q=artist:"Aka"', page: 1),
        _config,
      );

      expect(result.items, isNotEmpty);
      expect(result.items.first.id, _galleryId);
    });

    test('detail uses numeric id and builds reader image URLs from hash',
        () async {
      const expectedUrl = '$_baseApiUrl/g/$_galleryId';

      dioAdapter.onGet(
        expectedUrl,
        (server) => server.reply(200, jsonDecode(jsonEncode(_detailResponse))),
      );

      final result = await adapter.fetchDetail(_galleryId, _config);

      expect(result.content.id, _galleryId);
      expect(result.content.mediaId, _galleryHash);
      expect(result.content.title, _galleryTitle);
      expect(result.content.status, ContentStatus.completed);
      expect(result.content.coverUrl,
          'https://hentalk.pw/image/$_galleryHash/1?type=cover');
      expect(result.content.artists, contains('Aka'));
      expect(result.content.parodies, contains('Original Work'));
      expect(result.imageUrls, [
        'https://hentalk.pw/image/$_galleryHash/1',
        'https://hentalk.pw/image/$_galleryHash/2',
        'https://hentalk.pw/image/$_galleryHash/3',
      ]);
      expect(result.content.imageUrls, result.imageUrls);
      expect(result.content.chapters, anyOf(isNull, isEmpty));
    });
  });
}
