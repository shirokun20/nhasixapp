import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://api.mangadex.org';

GenericRestAdapter _buildAdapter(Dio dio) {
  return GenericRestAdapter(
    dio: dio,
    // Endpoint templates are root-relative, so the builder base must match
    // the API origin (mirrors production DI where baseUrl == apiBase).
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
    parser: GenericJsonParser(logger: Logger(level: Level.off)),
    logger: Logger(level: Level.off),
    sourceId: 'mangadex',
  );
}

// MangaDex /recommendation shape: wrapper objects whose target manga lives
// in relationships (embedded via includes[]=manga).
final Map<String, dynamic> _config = {
  'source': 'mangadex',
  'baseUrl': 'https://mangadex.org',
  'defaultLanguage': 'en',
  'api': {
    'apiBase': _baseUrl,
    'endpoints': {
      'related': '/manga/{id}/recommendation?includes[]=manga',
    },
    'related': {
      'items': r'$.data[*]',
      'fields': {
        'id': {
          'selector':
              r"$.relationships[?(@.type == 'manga' && @.attributes)].id",
        },
        'title': {
          'selector':
              r"$.relationships[?(@.type == 'manga' && @.attributes)].attributes.title",
        },
        'coverUrl': {
          'type': 'coverBuilder',
          'template':
              'https://uploads.mangadex.org/covers/{mangaId}/{fileName}.256.jpg',
          'mangaIdPath':
              r"$.relationships[?(@.type == 'manga' && @.attributes)].id",
          'filenamePath':
              r"$.relationships[?(@.type == 'cover_art')].attributes.fileName",
        },
      },
    },
  },
};

Map<String, dynamic> _response() => {
      'result': 'ok',
      'data': [
        {
          'id': 'src_target',
          'type': 'manga_recommendation',
          'attributes': {'score': 0.9},
          'relationships': [
            {'id': 'src', 'type': 'manga'},
            {
              'id': 'target-1',
              'type': 'manga',
              'attributes': {
                'title': {'ja-ro': 'ターゲット', 'en': 'Target One'},
                'status': 'ongoing',
              },
            },
            {
              'id': 'cover-art-1',
              'type': 'cover_art',
              'attributes': {'fileName': 'abc123'},
            },
          ],
        },
        {
          'id': 'x_y',
          'type': 'manga_recommendation',
          'attributes': {'score': 0.5},
          'relationships': [
            // No embedded attributes → not resolvable, must be skipped.
            {'id': 'ghost', 'type': 'manga'},
          ],
        },
      ],
    };

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late GenericRestAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    adapter = _buildAdapter(dio);
  });

  test('fetchRelated parses recommendation wrappers into manga items',
      () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, _response()),
    );

    final related = await adapter.fetchRelated('src', _config);

    expect(related, hasLength(1));
    expect(related.first.id, 'target-1');
    expect(related.first.title, 'Target One');
    expect(
      related.first.coverUrl,
      'https://uploads.mangadex.org/covers/target-1/abc123.256.jpg',
    );
  });

  test('fetchRelated returns empty when api.related block missing', () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, _response()),
    );

    final noRelated = Map<String, dynamic>.from(_config);
    noRelated['api'] = {
      'endpoints': {'related': '/manga/{id}/recommendation'},
    };

    final related = await adapter.fetchRelated('src', noRelated);
    expect(related, isEmpty);
  });

  test('fetchRelated returns empty on request failure', () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(500, {'error': 'boom'}),
    );

    final related = await adapter.fetchRelated('src', _config);
    expect(related, isEmpty);
  });

  test('config JSON round-trips through jsonEncode unchanged', () {
    final encoded = jsonEncode(_config['api']);
    expect(encoded, contains('recommendation'));
  });
}
