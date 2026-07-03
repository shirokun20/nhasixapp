import 'package:test/test.dart';
import 'package:html/parser.dart' show parse;
import 'package:kuron_config_generator/src/discovery/cms_detector.dart';

void main() {
  group('CMS Detector', () {
    test('detects Madara by wp-content/themes/madara hint', () {
      const html = '''
<html><body>
<link rel="stylesheet" href="https://example.com/wp-content/themes/madara/style.css">
<div class="page-item"><a href="/manhwa/title/">Title</a></div>
<div class="tab-summary"><img class="size-thumbnail" src="cover.jpg"></div>
</body></html>''';
      final result = detectCms(html);
      expect(result.cmsId, 'madara');
      expect(result.confidence, greaterThan(0));
      expect(result.selectors, isNotEmpty);
    });

    test('detects Madara by class="manga-item" hint', () {
      const html = '''
<html><body>
<div class="manga-item"><a href="/manga/title/">Title</a></div>
<div class="wp-manga-chapter"><a href="/manga/title/chapter-1/">Ch 1</a></div>
</body></html>''';
      final result = detectCms(html);
      expect(result.cmsId, 'madara');
      expect(result.confidence, greaterThan(0));
    });

    test('detects generic WordPress', () {
      const html = '''
<html><body>
<link rel="stylesheet" href="https://example.com/wp-content/themes/twenty/style.css">
<article class="post"><h2 class="entry-title"><a href="/post/">Post Title</a></h2></article>
</body></html>''';
      final result = detectCms(html);
      expect(result.cmsId, 'wordpress');
    });

    test('falls back to custom for unknown HTML', () {
      const html = '<html><body><div>Hello World</div></body></html>';
      final result = detectCms(html);
      expect(result.cmsId, 'custom');
      expect(result.selectors, isNotEmpty);
    });

    test('Madara selectors include detail and chapter fields', () {
      const html = '''
<html><body>
<link rel="stylesheet" href="https://example.com/wp-content/themes/madara/style.css">
<div class="page-item"><a href="/manhwa/title/">Title</a></div>
</body></html>''';
      final result = detectCms(html);
      expect(result.selectors, containsPair('detail.title', 'h1'));
      expect(result.selectors,
          containsPair('detail.author', 'a[href*="/author/"]'));
      expect(result.selectors,
          containsPair('chapters.item', 'a[href*="chapter"]'));
      expect(
          result.selectors,
          containsPair('reader.image',
              'img[class*="page-image"], .reading-content img'));
    });

    test('CmsSignature.known contains madara, wordpress, custom', () {
      final ids = CmsSignature.known.map((c) => c.id).toList();
      expect(ids, containsAll(['madara', 'wordpress', 'custom']));
    });
  });

  group('Search Form Detector', () {
    test('detects search form by role="search"', () {
      final document = parse('''
        <form role="search" action="/search" method="get">
          <input type="text" name="keyword" />
        </form>
      ''');
      final result = detectSearchForm(document);
      expect(result, isNotNull);
      expect(result!['searchEndpoint'], '/search');
      expect(result['queryParam'], 'keyword');
    });

    test('detects search form by action containing search', () {
      final document = parse('''
        <form action="/search.php" method="get">
          <input type="search" name="q" />
        </form>
      ''');
      final result = detectSearchForm(document);
      expect(result, isNotNull);
      expect(result!['searchEndpoint'], '/search.php');
      expect(result['queryParam'], 'q');
    });

    test('detects search form by input name="s"', () {
      final document = parse('''
        <form action="/">
          <input type="text" name="s" />
        </form>
      ''');
      final result = detectSearchForm(document);
      expect(result, isNotNull);
      expect(result!['searchEndpoint'], '/');
      expect(result['queryParam'], 's');
    });

    test('ignores hidden inputs and picks text input', () {
      final document = parse('''
        <form action="/advanced-search">
          <input type="hidden" name="type" value="manga" />
          <input type="text" name="query" />
          <input type="submit" value="Search" />
        </form>
      ''');
      final result = detectSearchForm(document);
      expect(result, isNotNull);
      expect(result!['searchEndpoint'], '/advanced-search');
      expect(result['queryParam'], 'query');
    });

    test('handles full URLs in action attribute', () {
      final document = parse('''
        <form role="search" action="https://example.com/search">
          <input type="text" name="q" />
        </form>
      ''');
      final result = detectSearchForm(document);
      expect(result, isNotNull);
      expect(result!['searchEndpoint'], '/search');
      expect(result['queryParam'], 'q');
    });

    test('returns null if no form found', () {
      final document = parse('<html><body></body></html>');
      final result = detectSearchForm(document);
      expect(result, isNull);
    });
  });
}
