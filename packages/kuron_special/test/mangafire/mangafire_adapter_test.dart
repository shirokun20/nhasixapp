import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_special/src/mangafire/mangafire_adapter.dart';

void main() {
  group('MangaFire raw query helpers', () {
    const config = <String, dynamic>{
      'defaultLanguage': 'en',
      'searchForm': {
        'params': {
          'query': {
            'queryParam': 'keyword',
          },
        },
      },
    };

    test('extract plain query and language from dynamic raw format', () {
      const filter = SearchFilter(
        query: 'raw:keyword=neko&language%5B%5D=id',
      );

      expect(resolveMangaFireSearchQuery(filter, config), 'neko');
      expect(resolveMangaFireLanguage(filter, config), 'id');
    });

    test('builds full filter url for home browse', () {
      final url = buildMangaFireFilterUrl(
        baseUrl: 'https://mangafire.to',
        keyword: '',
        language: 'en',
        sort: 'recently_updated',
        vrf: '',
        page: 1,
      );

      expect(
        url,
        'https://mangafire.to/filter?keyword=&language%5B%5D=en&sort=recently_updated&vrf=&page=1',
      );
    });

    test('falls back to bare unit nodes when original wrapper is absent', () {
      final document = html.parse('''
<html><body>
  <div class="unit item-1">
    <div class="inner">
      <div class="info"><a href="/manga/test.one">Test</a></div>
    </div>
  </div>
</body></html>
''');

      expect(selectMangaFireListNodes(document), hasLength(1));
    });

    test('finds chapter and volume items from detail html lanes', () {
      final document = html.parse('''
<html><body>
  <div class="tab-content" data-name="chapter">
    <ul class="list-body">
      <li class="item" data-number="1"><a href="/read/test/en/chapter-1"><span>Start</span></a></li>
    </ul>
  </div>
  <div class="tab-content" data-name="volume">
    <ul class="list-body">
      <li class="item" data-number="1"><a href="/read/test/en/volume-1"><span>Vol 1</span></a></li>
    </ul>
  </div>
</body></html>
''');

      expect(
        selectMangaFireDetailChapterNodes(document, dataName: 'chapter'),
        hasLength(1),
      );
      expect(
        selectMangaFireDetailChapterNodes(document, dataName: 'volume'),
        hasLength(1),
      );
      expect(
        resolveMangaFireReaderLanguage(
          'https://mangafire.to/read/test/en/chapter-1',
        ),
        'en',
      );
    });

    test('does not treat side manga trending cards as related content', () {
      final document = html.parse('''
<html><body>
  <section class="side-manga">
    <a class="unit" href="/manga/trending.one">
      <div class="poster"><img src="cover.jpg"></div>
      <div class="info"><h6>Trending Item</h6></div>
    </a>
  </section>
  <section class="m-related">
    <a class="unit" href="/manga/related.one">
      <div class="poster"><img src="cover2.jpg"></div>
      <div class="info"><h6>Related Item</h6></div>
    </a>
  </section>
</body></html>
''');

      final nodes = selectMangaFireRelatedNodes(document);
      expect(nodes, hasLength(1));
      expect(nodes.single.attributes['href'], '/manga/related.one');
    });

    test('requests ajax only for missing languages and types', () {
      final requests = computeMissingMangaFireChapterRequests(
        chapters: const <Chapter>[
          Chapter(
            id: '/read/test/en/chapter-1',
            title: 'Chapter 1',
            url: '/read/test/en/chapter-1',
            language: 'en',
            scanGroup: 'Chapter',
          ),
        ],
        languages: const {'en', 'id'},
      );

      expect(
        requests,
        containsAll(<({String language, String type})>[
          (language: 'id', type: 'chapter'),
          (language: 'en', type: 'volume'),
          (language: 'id', type: 'volume'),
        ]),
      );
      expect(requests, hasLength(3));
    });

    test('normalizes json-encoded html payload before parsing', () {
      final normalized = normalizeMangaFireHtmlResponse(
        '"<html><head><title>Filter - MangaFire<\\\\/title><\\\\/head><body><div class=\\"unit\\"><div class=\\"inner\\"></div></div><\\\\/body><\\\\/html>"',
      );
      final document = html.parse(normalized);

      expect(document.querySelector('title')?.text, 'Filter - MangaFire');
      expect(selectMangaFireListNodes(document), hasLength(1));
    });
  });
}
