import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/widgets/ehentai_download_strategy.dart';

void main() {
  const ehentaiConfig = <String, dynamic>{
    'source': 'ehentai',
    'features': <String, dynamic>{
      'download': true,
      'chapters': true,
    },
    'scraper': <String, dynamic>{
      'selectors': <String, dynamic>{
        'detail': <String, dynamic>{
          'imageUrls': <String, dynamic>{
            'mode': 'ehentai_page_fetch',
          },
        },
      },
    },
  };

  Content buildContent({
    required String id,
    required int pageCount,
  }) {
    return Content(
      id: id,
      sourceId: 'ehentai',
      title: 'Test Gallery',
      coverUrl: 'https://example.com/cover.jpg',
      tags: const <Tag>[],
      artists: const <String>[],
      characters: const <String>[],
      parodies: const <String>[],
      groups: const <String>[],
      language: 'en',
      pageCount: pageCount,
      imageUrls: const <String>[],
      uploadDate: DateTime(2026, 6, 22),
    );
  }

  test('gallery content exposes whole-gallery and gallery-range strategies',
      () {
    final content = buildContent(id: '123/abc', pageCount: 55);

    final strategies = EhentaiDownloadStrategyResolver.resolve(
      content,
      rawConfig: ehentaiConfig,
    );

    expect(
      strategies.map((strategy) => strategy.kind).toList(),
      const <EhentaiDownloadStrategyKind>[
        EhentaiDownloadStrategyKind.wholeGallery,
        EhentaiDownloadStrategyKind.galleryRange,
      ],
    );
  });

  test('gallery content without aggregate count skips gallery-range strategy',
      () {
    final content = buildContent(id: '123/abc', pageCount: 0);

    final strategies = EhentaiDownloadStrategyResolver.resolve(
      content,
      rawConfig: ehentaiConfig,
    );

    expect(
      strategies.map((strategy) => strategy.kind).toList(),
      const <EhentaiDownloadStrategyKind>[
        EhentaiDownloadStrategyKind.wholeGallery,
      ],
    );
  });

  test('part content exposes only part download strategy', () {
    final content = buildContent(id: '__ehpart__:123:tokenabc:1', pageCount: 0);

    final strategies = EhentaiDownloadStrategyResolver.resolve(
      content,
      rawConfig: ehentaiConfig,
    );

    expect(
      strategies.map((strategy) => strategy.kind).toList(),
      const <EhentaiDownloadStrategyKind>[
        EhentaiDownloadStrategyKind.partOnly,
      ],
    );
  });

  test('returns no strategies when config shape does not match ehentai runtime',
      () {
    final content = buildContent(id: '123/abc', pageCount: 55);

    final strategies = EhentaiDownloadStrategyResolver.resolve(
      content,
      rawConfig: const <String, dynamic>{
        'source': 'ehentai',
        'features': <String, dynamic>{
          'download': true,
          'chapters': true,
        },
        'scraper': <String, dynamic>{
          'selectors': <String, dynamic>{
            'detail': <String, dynamic>{
              'imageUrls': <String, dynamic>{
                'mode': 'generic',
              },
            },
          },
        },
      },
    );

    expect(strategies, isEmpty);
  });
}
