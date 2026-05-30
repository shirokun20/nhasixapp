import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedPageRequest', () {
    test('isDownloadReady requires directImage + non-empty finalImageUrl', () {
      final ResolvedPageRequest direct = ResolvedPageRequest(
        pageNumber: 1,
        kind: PageRequestKind.directImage,
        finalImageUrl: 'https://cdn.example.com/img/1.jpg',
      );
      expect(direct.isDownloadReady, isTrue);

      final ResolvedPageRequest reader = ResolvedPageRequest(
        pageNumber: 1,
        kind: PageRequestKind.readerPage,
        sourcePageUrl: 'https://site.example.com/g/1/1',
      );
      expect(reader.isDownloadReady, isFalse);

      final ResolvedPageRequest empty = ResolvedPageRequest(
        pageNumber: 1,
        kind: PageRequestKind.directImage,
        finalImageUrl: '',
      );
      expect(empty.isDownloadReady, isFalse);
    });

    test('perPageHeaders is unmodifiable', () {
      final ResolvedPageRequest page = ResolvedPageRequest(
        pageNumber: 1,
        kind: PageRequestKind.directImage,
        finalImageUrl: 'https://x/y.jpg',
        perPageHeaders: <String, String>{'Cookie': 'sid=abc'},
      );
      expect(
        () => (page.perPageHeaders)['x'] = 'y',
        throwsUnsupportedError,
      );
    });
  });

  group('ResolvedChapterPages', () {
    test('isDownloadReady true only when every page is direct + has url', () {
      final ResolvedChapterPages ready = ResolvedChapterPages(
        sourceId: 's',
        contentId: 'c',
        pages: <ResolvedPageRequest>[
          ResolvedPageRequest(
            pageNumber: 1,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/1.jpg',
          ),
          ResolvedPageRequest(
            pageNumber: 2,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/2.jpg',
          ),
        ],
      );
      expect(ready.isDownloadReady, isTrue);
      expect(ready.unresolvedPages, isEmpty);

      final ResolvedChapterPages partial = ResolvedChapterPages(
        sourceId: 's',
        contentId: 'c',
        pages: <ResolvedPageRequest>[
          ResolvedPageRequest(
            pageNumber: 1,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/1.jpg',
          ),
          ResolvedPageRequest(
            pageNumber: 2,
            kind: PageRequestKind.readerPage,
            sourcePageUrl: 'https://site/g/c/2',
          ),
        ],
      );
      expect(partial.isDownloadReady, isFalse);
      expect(partial.unresolvedPages, hasLength(1));
      expect(partial.unresolvedPages.first.pageNumber, 2);
    });

    test('mergedPage combines global+per-page headers, per-page wins', () {
      final ResolvedChapterPages chapter = ResolvedChapterPages(
        sourceId: 's',
        contentId: 'c',
        globalHeaders: <String, String>{
          'User-Agent': 'UA',
          'Referer': 'https://site/',
          'X-Token': 'global',
        },
        referer: 'https://site/g/c',
        pages: <ResolvedPageRequest>[
          ResolvedPageRequest(
            pageNumber: 1,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/1.jpg',
            perPageHeaders: <String, String>{
              'X-Token': 'page-specific',
              'X-Page': '1',
            },
          ),
        ],
      );

      final ResolvedPageRequest merged = chapter.mergedPage(0);
      expect(merged.perPageHeaders['User-Agent'], 'UA');
      expect(merged.perPageHeaders['Referer'], 'https://site/');
      expect(merged.perPageHeaders['X-Token'], 'page-specific');
      expect(merged.perPageHeaders['X-Page'], '1');
      expect(merged.referer, 'https://site/g/c');
    });

    test('mergedPage page-level referer overrides chapter referer', () {
      final ResolvedChapterPages chapter = ResolvedChapterPages(
        sourceId: 's',
        contentId: 'c',
        referer: 'https://chapter/ref',
        pages: <ResolvedPageRequest>[
          ResolvedPageRequest(
            pageNumber: 1,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/1.jpg',
            referer: 'https://page/ref',
          ),
        ],
      );
      expect(chapter.mergedPage(0).referer, 'https://page/ref');
    });

    test('toJson contains expected keys', () {
      final ResolvedChapterPages chapter = ResolvedChapterPages(
        sourceId: 's',
        contentId: 'c',
        chapterId: 'ch1',
        referer: 'https://site/',
        pages: <ResolvedPageRequest>[
          ResolvedPageRequest(
            pageNumber: 1,
            kind: PageRequestKind.directImage,
            finalImageUrl: 'https://x/1.jpg',
          ),
        ],
      );
      final Map<String, Object?> json = chapter.toJson();
      expect(json['sourceId'], 's');
      expect(json['contentId'], 'c');
      expect(json['chapterId'], 'ch1');
      expect(json['referer'], 'https://site/');
      final List<Object?> pages = json['pages']! as List<Object?>;
      expect(pages, hasLength(1));
      final Map<String, Object?> p1 = pages.first! as Map<String, Object?>;
      expect(p1['pageNumber'], 1);
      expect(p1['kind'], 'directImage');
    });
  });
}
