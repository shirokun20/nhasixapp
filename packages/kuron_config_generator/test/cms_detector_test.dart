import 'package:test/test.dart';
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
}
