/// Regression tests for [PageResolutionPipeline] (task 5.7).
///
/// Verifies that reader and download use equivalent resolved page data for
/// both REST and scraper-style inputs.
library;

import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/config/typed_config/network_rules.dart';
import 'package:kuron_generic/src/pipeline/page_resolution_pipeline.dart';
import 'package:test/test.dart';

void main() {
  // ── REST source (MangaDex style) ──────────────────────────────────────────
  group('REST source — direct image URLs', () {
    late PageResolutionResult result;
    const List<String> imageUrls = <String>[
      'https://cdn.mangadex.org/data/abc123/p001.jpg',
      'https://cdn.mangadex.org/data/abc123/p002.jpg',
      'https://cdn.mangadex.org/data/abc123/p003.jpg',
    ];

    setUp(() {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      result = pipeline.resolve(const PageResolutionInput(
        sourceId: 'mangadex',
        contentId: 'abc-123',
        chapterId: 'ch1',
        imageUrls: imageUrls,
        globalHeaders: <String, String>{'Accept': 'image/*'},
        referer: 'https://mangadex.org/',
      ));
    });

    test('produces correct page count', () {
      expect(result.pages.pages, hasLength(3));
    });

    test('all pages are download-ready', () {
      expect(result.isDownloadReady, isTrue);
    });

    test('no download-readiness diagnostics', () {
      expect(
        result.diagnostics
            .where((ValidationDiagnostic d) => d.code == 'downloadNotReady'),
        isEmpty,
      );
    });

    test('page numbers are sequential', () {
      expect(
        result.pages.pages
            .map((ResolvedPageRequest p) => p.pageNumber)
            .toList(),
        orderedEquals(<int>[1, 2, 3]),
      );
    });

    test('finalImageUrl matches input', () {
      expect(result.pages.pages[0].finalImageUrl, imageUrls[0]);
      expect(result.pages.pages[2].finalImageUrl, imageUrls[2]);
    });

    test('referer is set on pages', () {
      expect(
        result.pages.pages.every(
            (ResolvedPageRequest p) => p.referer == 'https://mangadex.org/'),
        isTrue,
      );
    });

    test('reader and download use same resolved data', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final List<String> downloadUrls = pipeline.toDownloadUrls(result.pages);
      expect(downloadUrls, equals(imageUrls));
    });

    test('global headers are propagated to mergedPage', () {
      final Map<String, String> h = result.pages.mergedPage(0).perPageHeaders;
      expect(h['Accept'], 'image/*');
    });
  });

  // ── Scraper source (HentaiFox style) — with config headers ───────────────
  group('Scraper source — with NetworkRules static headers', () {
    late PageResolutionResult result;
    const List<String> imageUrls = <String>[
      'https://i.hentaifox.com/galleries/1234/1.jpg',
      'https://i.hentaifox.com/galleries/1234/2.jpg',
    ];

    setUp(() {
      final NetworkRules rules = NetworkRules.fromConfig(<String, Object?>{
        'network': <String, Object?>{
          'headers': <String, Object?>{
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://hentaifox.com/',
          },
        },
      });
      final PageResolutionPipeline pipeline =
          PageResolutionPipeline(networkRules: rules);
      result = pipeline.resolve(const PageResolutionInput(
        sourceId: 'hentaifox',
        contentId: '1234',
        imageUrls: imageUrls,
      ));
    });

    test('static headers from NetworkRules are merged into globalHeaders', () {
      final Map<String, String> h = result.pages.globalHeaders;
      expect(h['User-Agent'], 'Mozilla/5.0');
    });

    test('referer is inferred from static headers', () {
      expect(
        result.pages.pages.every(
            (ResolvedPageRequest p) => p.referer == 'https://hentaifox.com/'),
        isTrue,
      );
    });

    test('pages are download-ready', () {
      expect(result.isDownloadReady, isTrue);
    });
  });

  // ── Download-readiness failure ────────────────────────────────────────────
  group('Download-readiness check', () {
    test('empty URL emits emptyImageUrl and downloadNotReady diagnostics', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final PageResolutionResult result = pipeline.resolve(
        const PageResolutionInput(
          sourceId: 'test',
          contentId: 'c1',
          imageUrls: <String>['https://cdn.example.com/p1.jpg', ''],
        ),
      );
      expect(
        result.diagnostics
            .any((ValidationDiagnostic d) => d.code == 'emptyImageUrl'),
        isTrue,
      );
      expect(
        result.diagnostics
            .any((ValidationDiagnostic d) => d.code == 'downloadNotReady'),
        isTrue,
      );
    });

    test('all-empty URLs → isDownloadReady is false', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final PageResolutionResult result = pipeline.resolve(
        const PageResolutionInput(
          sourceId: 'test',
          contentId: 'c1',
          imageUrls: <String>['', ''],
        ),
      );
      expect(result.isDownloadReady, isFalse);
    });

    test('mixed valid/empty pages emits readerDownloadParity warning', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final PageResolutionResult result = pipeline.resolve(
        const PageResolutionInput(
          sourceId: 'test',
          contentId: 'c1',
          imageUrls: <String>['https://cdn.example.com/p1.jpg', ''],
        ),
      );
      expect(
        result.diagnostics
            .any((ValidationDiagnostic d) => d.code == 'readerDownloadParity'),
        isTrue,
      );
    });
  });

  // ── Filename hints ────────────────────────────────────────────────────────
  group('Filename hints', () {
    test('filenamePrefix produces padded hints', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final PageResolutionResult result = pipeline.resolve(
        const PageResolutionInput(
          sourceId: 'x',
          contentId: 'y',
          imageUrls: <String>[
            'https://x.com/p1.jpg',
            'https://x.com/p2.jpg',
          ],
          filenamePrefix: 'ch01_',
        ),
      );
      expect(result.pages.pages[0].filenameHint, 'ch01_001');
      expect(result.pages.pages[1].filenameHint, 'ch01_002');
    });
  });

  // ── toDownloadUrls helper ─────────────────────────────────────────────────
  group('toDownloadUrls', () {
    test('returns only ready URLs in order', () {
      const PageResolutionPipeline pipeline = PageResolutionPipeline();
      final PageResolutionResult result = pipeline.resolve(
        const PageResolutionInput(
          sourceId: 'x',
          contentId: 'y',
          imageUrls: <String>[
            'https://x.com/p1.jpg',
            '',
            'https://x.com/p3.jpg',
          ],
        ),
      );
      expect(
        pipeline.toDownloadUrls(result.pages),
        <String>['https://x.com/p1.jpg', 'https://x.com/p3.jpg'],
      );
    });
  });
}
