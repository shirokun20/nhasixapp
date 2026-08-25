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
              'https://mangadex.org/covers/{mangaId}/{fileName}.512.jpg',
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
      'https://mangadex.org/covers/target-1/abc123.512.jpg',
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

  mainBatch();
}

// ── Batch two-phase (api.related.batch) ─────────────────────────────────────
// Phase 1: /manga/{id}/recommendation returns thin wrappers containing only
// target ids (+ score). Phase 2: /manga?ids[]=... resolves full manga with
// cover_art, reusing api.list.fields via the "@list.fields" reference token.
final Map<String, dynamic> _batchConfig = {
  'source': 'mangadex',
  'baseUrl': 'https://mangadex.org',
  'defaultLanguage': 'en',
  'api': {
    'apiBase': _baseUrl,
    'endpoints': {
      'related': '/manga/{id}/recommendation?includes[]=manga',
    },
    'list': {
      'items': r'$.data[*]',
      'fields': {
        'id': {'selector': r'$.id'},
        'title': {'selector': r'$.attributes.title'},
        'coverUrl': {
          'type': 'coverBuilder',
          'template':
              'https://mangadex.org/covers/{mangaId}/{fileName}.512.jpg',
          'mangaIdPath': r'$.id',
          'filenamePath':
              r"$.relationships[?(@.type=='cover_art')].attributes.fileName",
        },
        'artists': {
          'selector': r"$.relationships[?(@.type=='artist')].attributes.name",
          'multi': true,
        },
        'status': {'selector': r'$.attributes.status'},
      },
    },
    'related': {
      'batch': {
        'idEndpoint': '/manga/{id}/recommendation?includes[]=manga',
        'idItems': r'$.data[*]',
        'idField': {
          'selector': r"$.relationships[?(@.type=='manga')].id",
          'multi': true,
        },
        'itemsEndpoint':
            '/manga?ids[]={ids}&includes[]=cover_art&includes[]=author&includes[]=artist&limit=50',
        'items': r'$.data[*]',
        'fields': '@list.fields',
      },
    },
  },
};

// Thin phase-1 response: source id repeated, then targets A, B, C.
Map<String, dynamic> _thinIdsResponse() => {
      'result': 'ok',
      'data': [
        {
          'id': 'src_a1',
          'type': 'manga_recommendation',
          'relationships': [
            {'id': 'src', 'type': 'manga'},
            {'id': 'target-a', 'type': 'manga'},
          ],
        },
        // duplicate target id → must be deduped
        {
          'id': 'src_a2',
          'type': 'manga_recommendation',
          'relationships': [
            {'id': 'src', 'type': 'manga'},
            {'id': 'target-a', 'type': 'manga'},
          ],
        },
        {
          'id': 'src_b',
          'type': 'manga_recommendation',
          'relationships': [
            {'id': 'src', 'type': 'manga'},
            {'id': 'target-b', 'type': 'manga'},
          ],
        },
        {
          'id': 'src_c',
          'type': 'manga_recommendation',
          'relationships': [
            {'id': 'src', 'type': 'manga'},
            {'id': 'target-c', 'type': 'manga'},
          ],
        },
      ],
    };

// Full phase-2 response: server order A, C, B (NOT recommendation order) →
// reorder must restore A, B, C.
Map<String, dynamic> _fullBatchResponse() => {
      'result': 'ok',
      'response': 'collection',
      'data': [
        {
          'id': 'target-a',
          'type': 'manga',
          'attributes': {'title': 'Title A', 'status': 'ongoing'},
          'relationships': [
            {
              'id': 'cvr-a',
              'type': 'cover_art',
              'attributes': {'fileName': 'a.jpg'},
            },
          ],
        },
        {
          'id': 'target-c',
          'type': 'manga',
          'attributes': {'title': 'Title C', 'status': 'completed'},
          'relationships': [
            {
              'id': 'cvr-c',
              'type': 'cover_art',
              'attributes': {'fileName': 'c.jpg'},
            },
          ],
        },
        {
          'id': 'target-b',
          'type': 'manga',
          'attributes': {'title': 'Title B', 'status': 'ongoing'},
          'relationships': [
            {
              'id': 'cvr-b',
              'type': 'cover_art',
              'attributes': {'fileName': 'b.jpg'},
            },
          ],
        },
      ],
    };

void mainBatch() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late GenericRestAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    adapter = _buildAdapter(dio);
  });

  test('batch resolves full items with covers, dedup, and phase-1 order',
      () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, _thinIdsResponse()),
    );
    dioAdapter.onGet(
      'https://api.mangadex.org/manga?ids[]=target-a&ids[]=target-b&ids[]=target-c&includes[]=cover_art&includes[]=author&includes[]=artist&limit=50',
      (server) => server.reply(200, _fullBatchResponse()),
    );

    final related = await adapter.fetchRelated('src', _batchConfig);

    expect(related, hasLength(3));
    // Phase-1 (recommendation) order restored.
    expect(related.map((c) => c.id).toList(),
        ['target-a', 'target-b', 'target-c']);
    expect(related.first.title, 'Title A');
    expect(
      related.first.coverUrl,
      'https://mangadex.org/covers/target-a/a.jpg.512.jpg',
    );
  });

  test('phase1 empty → no phase2 request, empty result', () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, {'result': 'ok', 'data': []}),
    );

    final related = await adapter.fetchRelated('src', _batchConfig);
    expect(related, isEmpty);
  });

  test('phase2 failure returns empty', () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, _thinIdsResponse()),
    );
    dioAdapter.onGet(
      'https://api.mangadex.org/manga?ids[]=target-a&ids[]=target-b&ids[]=target-c&includes[]=cover_art&includes[]=author&includes[]=artist&limit=50',
      (server) => server.reply(500, {'error': 'boom'}),
    );

    final related = await adapter.fetchRelated('src', _batchConfig);
    expect(related, isEmpty);
  });

  test('items not returned by phase2 are skipped (preserve count)', () async {
    dioAdapter.onGet(
      'https://api.mangadex.org/manga/src/recommendation?includes[]=manga',
      (server) => server.reply(200, _thinIdsResponse()),
    );
    dioAdapter.onGet(
      'https://api.mangadex.org/manga?ids[]=target-a&ids[]=target-b&ids[]=target-c&includes[]=cover_art&includes[]=author&includes[]=artist&limit=50',
      (server) => server.reply(200, {
        'result': 'ok',
        'data': [
          {
            'id': 'target-b',
            'type': 'manga',
            'attributes': {'title': 'Title B'},
            'relationships': [
              {
                'id': 'cvr-b',
                'type': 'cover_art',
                'attributes': {'fileName': 'b.jpg'},
              },
            ],
          },
        ],
      }),
    );

    final related = await adapter.fetchRelated('src', _batchConfig);
    expect(related, hasLength(1));
    expect(related.single.id, 'target-b');
  });
}
