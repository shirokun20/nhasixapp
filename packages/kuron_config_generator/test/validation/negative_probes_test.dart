import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:kuron_config_generator/src/validation/negative_probes.dart';
import 'package:test/test.dart';

Document _doc(String html) => parser.parse(html);

void main() {
  group('probeRelativeCovers', () {
    test('null when all covers absolute', () {
      final f = probeRelativeCovers(
          ['https://a.com/1.jpg', 'http://b.com/2.webp'], 'https://a.com');
      expect(f, isNull);
    });
    test('flags relative and protocol-relative', () {
      final f = probeRelativeCovers(
          ['/img/1.jpg', '//cdn.a.com/2.jpg', 'https://a.com/3.jpg'],
          'https://a.com');
      expect(f, isNotNull);
      expect(f!.severity, FindingSeverity.warning);
      expect(f.message, contains('1 relative + 1 protocol-relative'));
    });
    test('empty list → null', () {
      expect(probeRelativeCovers([], 'https://a.com'), isNull);
    });
  });

  group('probeLazyAttributes', () {
    test('detects data-src holding real URL while src empty', () {
      final doc = _doc('''
        <div>
          <img src="" data-src="https://cdn.a.com/1.jpg">
          <img src="" data-src="https://cdn.a.com/2.jpg">
        </div>
      ''');
      final f = probeLazyAttributes(doc);
      expect(f, isNotNull);
      expect(f!.suggestion, contains('data-src'));
    });
    test('null when src populated normally', () {
      final doc = _doc(
          '<img src="https://cdn.a.com/1.jpg"><img src="https://cdn.a.com/2.jpg">');
      expect(probeLazyAttributes(doc), isNull);
    });
    test('ignores isolated lazy attr (below half threshold)', () {
      final doc = _doc('''
        <img src="https://a.com/1.jpg" data-src="https://lazy.com/1.jpg">
        <img src="https://a.com/2.jpg">
        <img src="https://a.com/3.jpg">
      ''');
      expect(probeLazyAttributes(doc), isNull);
    });
  });

  group('probeSinglePagePagination', () {
    test('identical page-2 content flagged', () {
      final p1 = {'a', 'b', 'c'};
      final f = probeSinglePagePagination(page1ItemIds: p1, page2ItemIds: p1);
      expect(f, isNotNull);
      expect(f!.message, contains('100% identical'));
    });
    test('distinct page-2 → null', () {
      final f = probeSinglePagePagination(
        page1ItemIds: {'a', 'b', 'c'},
        page2ItemIds: {'d', 'e', 'f'},
      );
      expect(f, isNull);
    });
    test('page2 failed → info finding single-page', () {
      final f =
          probeSinglePagePagination(page1ItemIds: {'a'}, page2Failed: true);
      expect(f, isNotNull);
      expect(f!.severity, FindingSeverity.info);
      expect(f.message, contains('single-page'));
    });
    test('empty page1 → null (home probe owns it)', () {
      expect(
        probeSinglePagePagination(page1ItemIds: {}, page2Failed: true),
        isNull,
      );
    });
  });

  group('probeTitleBadges', () {
    test('flags badge-prefixed titles', () {
      final f = probeTitleBadges(['18+ Bad Title', 'NEW Chapter', 'Clean']);
      expect(f, isNotNull);
      expect(f!.message, contains('2/3'));
    });
    test('clean titles → null', () {
      expect(probeTitleBadges(['One', 'Two']), isNull);
    });
  });

  group('probeReaderScopeImpurity', () {
    test('flags logo/thumb URLs in reader images', () {
      final f = probeReaderScopeImpurity([
        'https://cdn.a.com/pages/1.jpg',
        'https://cdn.a.com/logo.png',
        'https://cdn.a.com/banner/ad.png',
      ]);
      expect(f, isNotNull);
      expect(f!.message, contains('2/3'));
    });
    test('pure page images → null', () {
      expect(
        probeReaderScopeImpurity([
          'https://cdn.a.com/p/1.jpg',
          'https://cdn.a.com/p/2.jpg',
          'https://cdn.a.com/p/3.jpg',
        ]),
        isNull,
      );
    });
    test('fewer than 3 images → null (not worth judging)', () {
      expect(probeReaderScopeImpurity(['https://a.com/logo.png']), isNull);
    });
  });

  group('runDomProbes', () {
    test('empty html → no findings', () {
      expect(runDomProbes(''), isEmpty);
    });
    test('parses html and surfaces lazy findings', () {
      final findings =
          runDomProbes('<img src="" data-src="https://a.com/1.jpg">');
      // 1 img with lazy attr = 1/1 ≥ half → flagged
      expect(findings.map((f) => f.probe), contains('lazy-attributes'));
    });
  });

  group('ProbeFinding severity gate', () {
    test('blocking severity marks isBlocking', () {
      const f = ProbeFinding(
          probe: 'x', severity: FindingSeverity.blocking, message: 'm');
      expect(f.isBlocking, isTrue);
      expect(f.toString(), startsWith('[BLOCKING]'));
    });
  });
}
