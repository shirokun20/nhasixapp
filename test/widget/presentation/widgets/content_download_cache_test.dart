import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';

void main() {
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
}
