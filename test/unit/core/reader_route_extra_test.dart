import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';
import 'package:nhasixapp/core/routing/reader_route_extra.dart';

void main() {
  group('ReaderRouteExtra', () {
    test('round-trips serialized image metadata and chapter payloads', () {
      const imageMetadata = [
        ImageMetadata(
          imageUrl: 'https://example.com/1.webp',
          contentId: 'gallery-1',
          pageNumber: 1,
          imageType: ImageType.online,
        ),
        ImageMetadata(
          imageUrl: 'https://example.com/2.webp',
          contentId: 'gallery-1',
          pageNumber: 2,
          imageType: ImageType.cached,
        ),
      ];
      const chapterData = ChapterData(
        images: ['1.webp', '2.webp'],
        prevChapterId: 'prev',
        nextChapterId: 'next',
        prevChapterTitle: 'Previous',
        nextChapterTitle: 'Next',
      );
      final allChapters = [
        Chapter(
          id: 'c1',
          title: 'Chapter 1',
          url: '/c1',
          uploadDate: DateTime.parse('2026-04-20T10:00:00Z'),
          scanGroup: 'Group A',
          language: 'en',
        ),
      ];

      final extra = buildReaderRouteExtra(
        imageMetadata: imageMetadata,
        chapterData: chapterData,
        allChapters: allChapters,
        currentChapter: allChapters.first,
      );

      final parsedExtra = asReaderRouteExtra(extra);
      expect(parsedExtra, isNotNull);

      final parsedImageMetadata =
          readReaderImageMetadata(parsedExtra!['imageMetadata']);
      final parsedChapterData =
          readReaderChapterData(parsedExtra['chapterData']);
      final parsedAllChapters = readReaderChapters(parsedExtra['allChapters']);
      final parsedCurrentChapter =
          readReaderChapter(parsedExtra['currentChapter']);

      expect(parsedImageMetadata, imageMetadata);
      expect(parsedChapterData, chapterData);
      expect(parsedAllChapters, allChapters);
      expect(parsedCurrentChapter, allChapters.first);
    });

    test('parses mixed dynamic image metadata lists safely', () {
      const metadata = ImageMetadata(
        imageUrl: 'https://example.com/1.webp',
        contentId: 'gallery-2',
        pageNumber: 1,
        imageType: ImageType.online,
      );

      final parsed = readReaderImageMetadata([
        metadata,
        metadata.toJson(),
        {'invalid': true},
        42,
      ]);

      expect(parsed, [metadata, metadata]);
    });

    test('returns null for malformed chapter payloads', () {
      expect(readReaderChapterData({'images': 'not-a-list'}), isNull);
      expect(readReaderChapter({'title': 'Missing id'}), isNull);
      expect(readReaderChapters('not-a-list'), isNull);
    });
  });
}
