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
