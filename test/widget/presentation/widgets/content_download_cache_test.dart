import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';

void main() {
  test('matches slash-style chapter download to parent series card', () {
    const download = DownloadStatus(
      contentId: 'komikcast-slug/17',
      state: DownloadState.completed,
      totalPages: 32,
      title: 'Komikcast Ch.17',
      sourceId: 'komikcast',
      downloadPath: '/tmp/komikcast-chapter-17',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        'komikcast-slug',
        sourceId: 'komikcast',
      ),
      isTrue,
    );
  });

  test('matches ehentai part download to parent gallery card', () {
    const download = DownloadStatus(
      contentId: '__ehpart__:3902890:a3cd1a97d6:0',
      state: DownloadState.completed,
      totalPages: 20,
      title: 'Gallery Title - Part 1',
      sourceId: 'ehentai',
      downloadPath: '/tmp/ehentai-part-1',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        '3902890/a3cd1a97d6',
        sourceId: 'ehentai',
      ),
      isTrue,
    );
  });

  test('matches crotpedia chapter slug download to parent series card', () {
    const download = DownloadStatus(
      contentId: 'my-series-chapter-12-bahasa-indonesia',
      state: DownloadState.completed,
      totalPages: 24,
      title: 'My Series Chapter 12',
      sourceId: 'crotpedia',
      downloadPath: '/tmp/crotpedia-chapter-12',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        'my-series',
        sourceId: 'crotpedia',
      ),
      isTrue,
    );
  });

  test('matches komiktap chapter slug download to parent series card', () {
    const download = DownloadStatus(
      contentId: 'sakare-seishun-ragai-katsudou-chapter-6',
      state: DownloadState.completed,
      totalPages: 23,
      title: 'sakare-seishun-ragai-katsudou-chapter-6',
      sourceId: 'komiktap',
      downloadPath: '/tmp/10vlmmznl1',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        'sakare-seishun-ragai-katsudou',
        sourceId: 'komiktap',
      ),
      isTrue,
    );
  });

  test('matches mangafire reader url download to parent series card', () {
    const download = DownloadStatus(
      contentId:
          'https://mangafire.to/read/the-honor-students-secret-jobb.w1q37/en/volume-1',
      state: DownloadState.completed,
      totalPages: 185,
      title: 'The Honor Student\'s Secret Job - Vol 1',
      sourceId: 'mangafire',
      downloadPath: '/tmp/sp8yihdx',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        'the-honor-students-secret-jobb.w1q37',
        sourceId: 'mangafire',
      ),
      isTrue,
    );
  });

  test('matches mangadex title url download to manga id', () {
    const download = DownloadStatus(
      contentId: 'https://mangadex.org/title/3c7854f8-56c4-41d0-ae48-4c9b06c66a06',
      state: DownloadState.completed,
      totalPages: 18,
      title:
          'Shut Up, Malevolent Dragon! I Don’t Want to Have Any More Children With You - Ch.99',
      sourceId: 'mangadex',
      downloadPath: '/tmp/1nmpabyaxp',
    );

    expect(
      ContentDownloadCache.matchesDownload(
        download,
        '3c7854f8-56c4-41d0-ae48-4c9b06c66a06',
        sourceId: 'mangadex',
      ),
      isTrue,
    );
  });
}
