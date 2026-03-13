/// Integration tests for [GenericScraperAdapter].
///
/// Dio is mocked using [DioAdapter] so no real HTTP calls are made.
/// The tests validate the full adapter pipeline:
///   raw config + mocked HTML → typed Content / Chapter entities.
///
/// Key areas covered:
///   1. Home listing: CSS selectors in `list.fields` correctly
///      address CHILD elements of the container (the bug fixed in
///      `GenericHtmlParser.extractFromElement`).
///   2. `transform:"slug"` strips URL path to the content slug.
///   3. `inherits` correctly merges parent list config.
///   4. Pagination detection via `alt` or `next` CSS selector.
///   5. Detail extraction: title, coverUrl, tags (multi), chapters.
///   6. Chapter reader: ts_reader JSON → image list + prev/next slug.
///   7. Missing config blocks return safe empty results.
///
/// Run with:
///   dart test packages/kuron_generic/test/adapters/generic_scraper_adapter_test.dart
library;

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

// ── Test config ──────────────────────────────────────────────────────────────

const _baseUrl = 'https://komiktap.info';

/// Minimal komiktap scraper config for tests — mirrors the real config schema.
const _config = {
  'source': 'komiktap',
  'baseUrl': _baseUrl,
  'scraper': {
    'urlPatterns': {
      'home': {
        'url': '/',
        'list': {
          'container': '.utao',
          'fields': {
            'id': {
              'selector': 'a.series',
              'attribute': 'href',
              'transform': 'slug'
            },
            'title': {'selector': '.luf > a > h4'},
            'coverUrl': {'selector': 'img.ts-post-image', 'attribute': 'src'},
          },
          'pagination': {'alt': '.hpage a.r'},
        },
      },
      'homePage': {
        'url': '/page/{page}/',
        'inherits': 'home',
      },
      'search': {
        'url': '/?s={query}&paged={page}',
        'list': {
          'container': 'div.bsx',
          'fields': {
            'id': {
              'selector': 'a[href]',
              'attribute': 'href',
              'transform': 'slug'
            },
            'title': {'selector': '.tt'},
            'coverUrl': {'selector': '.limit img', 'attribute': 'src'},
          },
          'pagination': {'next': '.pagination .next.page-numbers'},
        },
      },
      'genreSearch': {
        'url': '/genre/{tag}/page/{page}/',
        'inherits': 'search',
      },
      'detail': '/manga/{id}/',
      'chapter': '/{id}/',
    },
    'selectors': {
      'detail': {
        'fields': {
          'title': {'selector': '.entry-title'},
          'coverUrl': {'selector': '.thumb img', 'attribute': 'src'},
          'tags': {'selector': '.seriestugenre a', 'multi': true},
        },
        'chapters': {
          'container': '#chapterlist li',
          'fields': {
            'id': {
              'selector': '.chbox .eph-num a',
              'attribute': 'href',
              'transform': 'slug'
            },
            'title': {'selector': '.chbox .chapternum'},
            'date': {'selector': '.chbox .chapterdate'},
          },
        },
      },
      'reader': {
        'tsReaderRegex': r'ts_reader\.run\((.*?)\);',
        'container': '#readerarea',
        'images': {'selector': 'img', 'attribute': 'src'},
        'nav': {
          'next': '.nextprev a.next',
          'prev': '.nextprev a.prev',
        },
      },
    },
  },
};

const _hfBaseUrl = 'https://hentaifox.com';

const _hentaiFoxConfig = {
  'source': 'hentaifox',
  'baseUrl': _hfBaseUrl,
  'scraper': {
    'urlPatterns': {
      'chapter': '/gallery/{id}/',
    },
    'selectors': {
      'reader': {
        'mode': 'hentaifoxCdn',
        'thumbSelector': '.gallery_thumb img',
        'thumbSrcAttr': 'data-src',
        'cdnPathRegex':
            '(?:https?:)?//([^/]+)/(.+?)/\\d+t\\.(?:jpg|webp|jpeg|png)',
        'pageCountSelector': '.i_text.pages',
        'readerPageUrlPattern': '/g/{id}/1/',
        'readerImageSelector': '#gimg',
        'readerImageAttr': 'data-src',
        'readerPageCountSelector': '#pages',
        'readerPageCountAttr': 'value',
      },
    },
  },
};

// ── Fake HTML pages ───────────────────────────────────────────────────────────

/// Home page with 2 content items + a next-page link.
const _homeHtml = '''
<html><body>
<div class="utao">
  <a class="series" href="https://komiktap.info/manga/manga-slug-one/"></a>
  <div class="luf">
    <a href="https://komiktap.info/manga/manga-slug-one/"><h4>Manga Slug One</h4></a>
  </div>
  <img class="ts-post-image" src="https://cdn.example.com/cover1.jpg">
</div>
<div class="utao">
  <a class="series" href="https://komiktap.info/manga/manga-slug-two/"></a>
  <div class="luf">
    <a href="https://komiktap.info/manga/manga-slug-two/"><h4>Manga Slug Two</h4></a>
  </div>
  <img class="ts-post-image" src="https://cdn.example.com/cover2.jpg">
</div>
<div class="hpage"><a class="r" href="/page/2/">Next →</a></div>
</body></html>
''';

/// Same structure as home but without the next-page link.
const _homeHtmlNoNext = '''
<html><body>
<div class="utao">
  <a class="series" href="https://komiktap.info/manga/only-manga/"></a>
  <div class="luf">
    <a href="https://komiktap.info/manga/only-manga/"><h4>Only Manga</h4></a>
  </div>
  <img class="ts-post-image" src="https://cdn.example.com/cover-only.jpg">
</div>
</body></html>
''';

/// Search result page using `.bsx` containers.
const _searchHtml = '''
<html><body>
<div class="bsx">
  <a href="https://komiktap.info/manga/search-result-one/">
    <div class="tt">Search Result One</div>
    <div class="limit"><img src="https://cdn.example.com/s1.jpg"></div>
  </a>
</div>
<div class="bsx">
  <a href="https://komiktap.info/manga/search-result-two/">
    <div class="tt">Search Result Two</div>
    <div class="limit"><img src="https://cdn.example.com/s2.jpg"></div>
  </a>
</div>
<div class="pagination"><a class="next page-numbers" href="/?s=test&paged=2">2</a></div>
</body></html>
''';

/// Detail page for "manga-slug-one".
const _detailHtml = '''
<html><body>
<h1 class="entry-title">The Full Title</h1>
<div class="thumb"><img src="https://cdn.example.com/detail-cover.jpg"></div>
<div class="seriestugenre">
  <a href="/genre/action/">Action</a>
  <a href="/genre/romance/">Romance</a>
  <a href="/genre/comedy/">Comedy</a>
</div>
<ul id="chapterlist">
  <li>
    <div class="chbox">
      <div class="eph-num"><a href="https://komiktap.info/manga-slug-one-chapter-5/">Ch 5 Link</a></div>
      <div class="chapternum">Chapter 5</div>
      <div class="chapterdate">March 1, 2024</div>
    </div>
  </li>
  <li>
    <div class="chbox">
      <div class="eph-num"><a href="https://komiktap.info/manga-slug-one-chapter-1/">Ch 1 Link</a></div>
      <div class="chapternum">Chapter 1</div>
      <div class="chapterdate">January 1, 2024</div>
    </div>
  </li>
</ul>
</body></html>
''';

/// Chapter page for "manga-slug-one-chapter-5" — uses ts_reader JSON.
const _chapterHtml = '''
<html><body>
<script>
ts_reader.run({"sources":[{"server":"s1","images":["https://img.example.com/1.jpg","https://img.example.com/2.jpg","https://img.example.com/3.jpg"]}],"prevUrl":"https://komiktap.info/manga-slug-one-chapter-4/","nextUrl":"https://komiktap.info/manga-slug-one-chapter-6/"});
</script>
<div id="readerarea"><img src="https://img.example.com/fallback.jpg"></div>
</body></html>
''';

/// Chapter page with NO ts_reader JSON — DOM fallback should be used.
const _chapterHtmlNoTsReader = '''
<html><body>
<div id="readerarea">
  <img src="https://img.example.com/dom-1.jpg">
  <img src="https://img.example.com/dom-2.jpg">
</div>
<div class="nextprev">
  <a class="next" href="https://komiktap.info/manga-slug-one-chapter-6/">Next</a>
  <a class="prev" href="https://komiktap.info/manga-slug-one-chapter-4/">Prev</a>
</div>
</body></html>
''';

const _hfDetailHtml = '''
<html><body>
<div class="gallery_thumb"><img data-src="https://i3.hentaifox.com/004/3837511/1t.jpg"></div>
<div class="i_text pages">Pages: 3</div>
</body></html>
''';

const _hfReaderHtmlJpg = '''
<html><body>
<input type="hidden" id="pages" value="3" />
<a class="next_img"><img id="gimg" data-src="https://i3.hentaifox.com/004/3837511/2.jpg" /></a>
</body></html>
''';

const _hfReaderHtmlMixedExt = """
<html><body>
<input type="hidden" id="pages" value="3" />
<a class="next_img"><img id="gimg" data-src="https://i3.hentaifox.com/004/3834485/1.webp" /></a>
<script type="text/javascript">
var g_th = \$.parseJSON('{"1":"w,1280,1810","2":"j,1280,1810","3":"w,1280,1810"}');
</script>
</body></html>
""";

// ── Test setup helpers ────────────────────────────────────────────────────────

GenericScraperAdapter _buildAdapter(Dio dio) {
  return GenericScraperAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _baseUrl),
    parser: GenericHtmlParser(logger: Logger(printer: PrettyPrinter())),
    logger: Logger(printer: PrettyPrinter()),
    sourceId: 'komiktap',
  );
}

Dio _buildDio() => Dio(BaseOptions(baseUrl: _baseUrl));

GenericScraperAdapter _buildHentaiFoxAdapter(Dio dio) {
  return GenericScraperAdapter(
    dio: dio,
    urlBuilder: const GenericUrlBuilder(baseUrl: _hfBaseUrl),
    parser: GenericHtmlParser(logger: Logger(printer: PrettyPrinter())),
    logger: Logger(printer: PrettyPrinter()),
    sourceId: 'hentaifox',
  );
}

Dio _buildHentaiFoxDio() => Dio(BaseOptions(baseUrl: _hfBaseUrl));

// ═════════════════════════════════════════════════════════════════════════════
// Tests
// ═════════════════════════════════════════════════════════════════════════════

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // search() — home listing
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.search() — home listing', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('returns correct number of items', () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.items, hasLength(2));
    });

    test('id is the slug extracted from /manga/<slug>/ URL — not the raw URL',
        () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.items[0].id, 'manga-slug-one',
          reason:
              'transform:slug should strip /manga/<slug>/ to just the slug');
      expect(result.items[1].id, 'manga-slug-two');
    });

    test('id does NOT contain "http" or slashes (raw URL not leaked)',
        () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      for (final item in result.items) {
        expect(item.id, isNot(contains('/')),
            reason: 'id should be a slug, not a full URL');
        expect(item.id, isNot(contains('http')));
      }
    });

    test('title is extracted from child .luf > a > h4 (not container text)',
        () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.items[0].title, 'Manga Slug One');
      expect(result.items[1].title, 'Manga Slug Two');
    });

    test('coverUrl is extracted from child img.ts-post-image src attribute',
        () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.items[0].coverUrl, 'https://cdn.example.com/cover1.jpg');
      expect(result.items[1].coverUrl, 'https://cdn.example.com/cover2.jpg');
    });

    test('sourceId is set correctly on all items', () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.items.every((i) => i.sourceId == 'komiktap'), isTrue);
    });

    test('hasNextPage is true when alt pagination selector found', () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.hasNextPage, isTrue);
    });

    test('hasNextPage is false when pagination selector absent', () async {
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, _homeHtmlNoNext, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      expect(result.hasNextPage, isFalse);
    });

    test('items with empty id are filtered out (not returned)', () async {
      // HTML where the a.series href is missing
      const badHtml = '''
<html><body>
<div class="utao">
  <div class="luf"><a href="#"><h4>No ID Manga</h4></a></div>
  <img class="ts-post-image" src="https://cdn.example.com/nocover.jpg">
</div>
</body></html>
''';
      dioAdapter.onGet(
          '$_baseUrl/',
          (s) => s.reply(200, badHtml, headers: {
                Headers.contentTypeHeader: ['text/html; charset=utf-8']
              }));

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        _config,
      );
      // Either empty (no a.series element with href) or filtered (empty slug)
      expect(result.items.where((i) => i.id.isEmpty), isEmpty,
          reason: 'items with empty id must be filtered');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // search() — inherits (homePage → home)
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.search() — inherits (homePage)', () {
    test('page > 1 uses homePage URL and inherits home list config', () async {
      final dio = _buildDio();
      final dioAdapter =
          DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final adapter = _buildAdapter(dio);

      // Page 2 → homePage URL → /page/2/
      dioAdapter.onGet(
        '$_baseUrl/page/2/',
        (s) => s.reply(200, _homeHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.search(
        const SearchFilter(query: '', page: 2),
        _config,
      );

      // Should use .utao containers (inherited from home)
      expect(result.items, hasLength(2));
      expect(result.items[0].id, 'manga-slug-one');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // search() — text query
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.search() — text search', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('text query uses search URL pattern with .bsx containers', () async {
      // search URL: /?s={query}&paged={page}
      dioAdapter.onGet(
        '$_baseUrl/?s=test&paged=1',
        (s) => s.reply(200, _searchHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'test', page: 1),
        _config,
      );
      expect(result.items, hasLength(2));
      expect(result.items[0].title, 'Search Result One');
      expect(result.items[1].title, 'Search Result Two');
    });

    test('search result ids are slug-transformed', () async {
      dioAdapter.onGet(
        '$_baseUrl/?s=test&paged=1',
        (s) => s.reply(200, _searchHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'test', page: 1),
        _config,
      );
      expect(result.items[0].id, 'search-result-one');
      expect(result.items[1].id, 'search-result-two');
    });

    test('search hasNextPage is true when next pagination element present',
        () async {
      dioAdapter.onGet(
        '$_baseUrl/?s=test&paged=1',
        (s) => s.reply(200, _searchHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.search(
        const SearchFilter(query: 'test', page: 1),
        _config,
      );
      expect(result.hasNextPage, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // search() — genre filter (genreSearch inherits search)
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.search() — genre search', () {
    test('tag filter uses genreSearch URL and inherited search list config',
        () async {
      final dio = _buildDio();
      final dioAdapter =
          DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final adapter = _buildAdapter(dio);

      // genreSearch URL: /genre/{tag}/page/{page}/
      dioAdapter.onGet(
        '$_baseUrl/genre/action/page/1/',
        (s) => s.reply(200, _searchHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.search(
        const SearchFilter(
          query: '',
          page: 1,
          includeTags: [FilterItem(id: 0, name: 'action', type: 'tag')],
        ),
        _config,
      );

      // Should use inherited .bsx containers from search pattern
      expect(result.items, hasLength(2));
      expect(result.items[0].title, 'Search Result One');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // search() — safety
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.search() — safety', () {
    test('returns empty when scraper block is missing', () async {
      final dio = _buildDio();
      DioAdapter(
          dio: dio,
          matcher:
              const UrlRequestMatcher()); // no mock needed — should not hit network
      final adapter = _buildAdapter(dio);

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        {'source': 'komiktap'}, // no 'scraper' key
      );
      expect(result.items, isEmpty);
      expect(result.hasNextPage, isFalse);
    });

    test('returns empty when url pattern key is missing', () async {
      final dio = _buildDio();
      DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final adapter = _buildAdapter(dio);

      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        {
          'source': 'komiktap',
          'scraper': {'urlPatterns': {}}, // no 'home' key
        },
      );
      expect(result.items, isEmpty);
    });

    test('returns empty when list block is absent from pattern', () async {
      final dio = _buildDio();
      DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final adapter = _buildAdapter(dio);

      // Pattern is a plain string (no list block) → no list config
      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        {
          'source': 'komiktap',
          'scraper': {
            'urlPatterns': {
              'home': '/', // plain String — no list block
            },
          },
        },
      );
      expect(result.items, isEmpty);
      expect(result.hasNextPage, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // fetchDetail()
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.fetchDetail()', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('maps title from .entry-title', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      expect(result.content.title, 'The Full Title');
    });

    test('maps coverUrl from .thumb img[src]', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      expect(
          result.content.coverUrl, 'https://cdn.example.com/detail-cover.jpg');
    });

    test('maps tags as List<Tag> with type "tag" (multi: true)', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      final tagNames = result.content.tags.map((t) => t.name).toList();
      expect(tagNames, containsAll(['Action', 'Romance', 'Comedy']));
    });

    test('extracts chapters with correct count', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      expect(result.content.chapters, isNotNull);
      expect(result.content.chapters, hasLength(2));
    });

    test('chapter id is slug (not raw URL)', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      final chapters = result.content.chapters!;
      expect(chapters[0].id, isNot(contains('http')),
          reason: 'chapter id should be a slug, not a full URL');
      expect(chapters[0].id, isNot(contains('/')));
      // slug: last non-empty path segment of the href
      expect(chapters[0].id, 'manga-slug-one-chapter-5');
    });

    test('chapter title extracted from .chapternum', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      final chapters = result.content.chapters!;
      expect(chapters[0].title, 'Chapter 5');
      expect(chapters[1].title, 'Chapter 1');
    });

    test('content id falls back to contentId param when field id is empty',
        () async {
      dioAdapter.onGet(
        '$_baseUrl/manga/manga-slug-one/',
        (s) => s.reply(200, _detailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result = await adapter.fetchDetail('manga-slug-one', _config);
      // Detail HTML has no "id" field — should fall back to param
      expect(result.content.id, 'manga-slug-one');
    });

    test('returns empty content (not throw) when scraper block missing',
        () async {
      DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      final result = await adapter.fetchDetail(
        'manga-slug-one',
        {'source': 'komiktap'}, // no scraper
      );
      expect(result.content.id, 'manga-slug-one');
      expect(result.content.title, ''); // empty — graceful degradation
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // fetchChapterImages() — ts_reader JSON path
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.fetchChapterImages() — ts_reader JSON', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('extracts image URLs from ts_reader JSON', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga-slug-one-chapter-5/',
        (s) => s.reply(200, _chapterHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('manga-slug-one-chapter-5', _config);
      expect(result, isNotNull);
      expect(result!.images, [
        'https://img.example.com/1.jpg',
        'https://img.example.com/2.jpg',
        'https://img.example.com/3.jpg',
      ]);
    });

    test('extracts prevChapterId as slug from ts_reader prevUrl', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga-slug-one-chapter-5/',
        (s) => s.reply(200, _chapterHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('manga-slug-one-chapter-5', _config);
      expect(result!.prevChapterId, 'manga-slug-one-chapter-4');
    });

    test('extracts nextChapterId as slug from ts_reader nextUrl', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga-slug-one-chapter-5/',
        (s) => s.reply(200, _chapterHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('manga-slug-one-chapter-5', _config);
      expect(result!.nextChapterId, 'manga-slug-one-chapter-6');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // fetchChapterImages() — DOM fallback (no ts_reader)
  // ─────────────────────────────────────────────────────────────────────────

  group('GenericScraperAdapter.fetchChapterImages() — DOM fallback', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildAdapter(dio);
    });

    test('falls back to DOM image extraction when no ts_reader script',
        () async {
      dioAdapter.onGet(
        '$_baseUrl/manga-slug-one-chapter-5/',
        (s) => s.reply(200, _chapterHtmlNoTsReader, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('manga-slug-one-chapter-5', _config);
      expect(result, isNotNull);
      expect(result!.images, [
        'https://img.example.com/dom-1.jpg',
        'https://img.example.com/dom-2.jpg',
      ]);
    });

    test('extracts nav prev/next from DOM when ts_reader absent', () async {
      dioAdapter.onGet(
        '$_baseUrl/manga-slug-one-chapter-5/',
        (s) => s.reply(200, _chapterHtmlNoTsReader, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('manga-slug-one-chapter-5', _config);
      expect(result!.nextChapterId, 'manga-slug-one-chapter-6');
      expect(result.prevChapterId, 'manga-slug-one-chapter-4');
    });

    test('returns null when chapter URL pattern is not configured', () async {
      final result = await adapter.fetchChapterImages(
        'some-chapter',
        {
          'source': 'komiktap',
          'scraper': {'urlPatterns': {}}, // no 'chapter' key
        },
      );
      expect(result, isNull);
    });
  });

  group('GenericScraperAdapter.fetchChapterImages() — HentaiFox CDN', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late GenericScraperAdapter adapter;

    setUp(() {
      dio = _buildHentaiFoxDio();
      dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      adapter = _buildHentaiFoxAdapter(dio);
    });

    test('uses full-res extension from reader page (non-webp)', () async {
      dioAdapter.onGet(
        '$_hfBaseUrl/gallery/159323/',
        (s) => s.reply(200, _hfDetailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );
      dioAdapter.onGet(
        '$_hfBaseUrl/g/159323/1/',
        (s) => s.reply(200, _hfReaderHtmlJpg, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('159323', _hentaiFoxConfig);
      expect(result, isNotNull);
      expect(result!.images, [
        'https://i3.hentaifox.com/004/3837511/1.jpg',
        'https://i3.hentaifox.com/004/3837511/2.jpg',
        'https://i3.hentaifox.com/004/3837511/3.jpg',
      ]);
    });

    test('supports mixed per-page extensions from g_th map', () async {
      dioAdapter.onGet(
        '$_hfBaseUrl/gallery/159186/',
        (s) => s.reply(200, _hfDetailHtml, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );
      dioAdapter.onGet(
        '$_hfBaseUrl/g/159186/1/',
        (s) => s.reply(200, _hfReaderHtmlMixedExt, headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8']
        }),
      );

      final result =
          await adapter.fetchChapterImages('159186', _hentaiFoxConfig);
      expect(result, isNotNull);
      expect(result!.images, [
        'https://i3.hentaifox.com/004/3834485/1.webp',
        'https://i3.hentaifox.com/004/3834485/2.jpg',
        'https://i3.hentaifox.com/004/3834485/3.webp',
      ]);
    });
  });
}
