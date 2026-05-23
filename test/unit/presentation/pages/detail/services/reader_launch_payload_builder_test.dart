import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/models/image_metadata.dart';
import 'package:nhasixapp/presentation/pages/detail/services/reader_launch_payload_builder.dart';

void main() {
  group('ReaderLaunchPayloadBuilder', () {
    Content buildContent({
      required String id,
      required List<String> imageUrls,
      List<Chapter>? chapters,
    }) {
      return Content(
        id: id,
        sourceId: 'ehentai',
        title: 'Sample',
        coverUrl: 'https://cover.example/$id.webp',
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'english',
        pageCount: imageUrls.length,
        imageUrls: imageUrls,
        uploadDate: DateTime.parse('2026-05-20T00:00:00Z'),
        chapters: chapters,
      );
    }

    test('passes content when imageUrls already loaded', () {
      final parentChapters = [
        const Chapter(id: '__ehpart__:1:token:0', title: 'Part 1', url: '/p=0'),
        const Chapter(id: '__ehpart__:1:token:1', title: 'Part 2', url: '/p=1'),
      ];

      final parentContent = buildContent(
        id: '1/token',
        imageUrls: const [],
        chapters: parentChapters,
      );
      final chapterContent = buildContent(
        id: '__ehpart__:1:token:0',
        imageUrls: const ['https://img.example/1.webp'],
      );
      const chapterData = ChapterData(
        images: ['https://img.example/1.webp'],
        nextChapterId: '__ehpart__:1:token:1',
        nextChapterTitle: 'Part 2',
      );
      const metadata = [
        ImageMetadata(
          imageUrl: 'https://img.example/1.webp',
          contentId: '1/token',
          pageNumber: 1,
          imageType: ImageType.online,
        ),
      ];

      final payload = ReaderLaunchPayloadBuilder.build(
        content: chapterContent,
        imageMetadata: metadata,
        chapterData: chapterData,
        parentContent: parentContent,
        currentChapter: parentChapters.first,
      );

      expect(payload.content, chapterContent);
      expect(payload.imageMetadata, metadata);
      expect(payload.chapterData, chapterData);
      expect(payload.parentContent, parentContent);
      expect(payload.allChapters, parentChapters);
      expect(payload.currentChapter, parentChapters.first);
    });

    test('forces fresh reader fetch when content has no images', () {
      final chapterContent = buildContent(
        id: '__ehpart__:1:token:1',
        imageUrls: const [],
      );

      final payload = ReaderLaunchPayloadBuilder.build(
        content: chapterContent,
        chapterData: const ChapterData(images: []),
      );

      expect(payload.content, isNull);
      expect(payload.chapterData, isNotNull);
    });

    test('keeps part navigation context for direct gallery launches', () {
      final partChapters = [
        const Chapter(id: '__ehpart__:1:token:0', title: 'Part 1', url: '/p=0'),
        const Chapter(id: '__ehpart__:1:token:1', title: 'Part 2', url: '/p=1'),
      ];

      final galleryContent = buildContent(
        id: '1/token',
        imageUrls: const [],
        chapters: partChapters,
      );

      final payload = ReaderLaunchPayloadBuilder.build(content: galleryContent);

      expect(payload.content, isNull);
      expect(payload.parentContent, galleryContent);
      expect(payload.allChapters, partChapters);
      expect(payload.currentChapter, partChapters.first);
    });
  });
}
