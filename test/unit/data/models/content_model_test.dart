import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/data/models/content_model.dart';

void main() {
  final chapters = [
    Chapter(
      id: 'you-wont-break-me-chapter-37',
      title: 'Chapter 37',
      url: 'https://komiktap.info/you-wont-break-me-chapter-37/',
      uploadDate: DateTime(2026, 5, 19),
    ),
    Chapter(
      id: 'you-wont-break-me-chapter-36',
      title: 'Chapter 36',
      url: 'https://komiktap.info/you-wont-break-me-chapter-36/',
      uploadDate: DateTime(2026, 5, 18),
    ),
  ];

  final content = Content(
    id: 'you-wont-break-me',
    title: "You Won't Break Me",
    coverUrl: 'https://cdn.example.com/cover.jpg',
    sourceId: 'komiktap',
    tags: const [
      Tag(id: 1, name: 'Drama', type: 'tag', count: 0, url: '/tag/drama'),
    ],
    artists: const [],
    characters: const [],
    parodies: const [],
    groups: const [],
    language: 'id',
    pageCount: chapters.length,
    imageUrls: const [],
    uploadDate: DateTime(2026, 5, 19),
    chapters: chapters,
  );

  group('ContentModel chapter serialization', () {
    test('fromEntity preserves chapters', () {
      final model = ContentModel.fromEntity(content);

      expect(model.chapters, isNotNull);
      expect(model.chapters, hasLength(2));
      expect(model.chapters!.first.id, 'you-wont-break-me-chapter-37');
    });

    test('json round-trip preserves chapters', () {
      final model = ContentModel.fromEntity(content);
      final hydrated = ContentModel.fromJson(model.toJson()).toEntity();

      expect(hydrated.chapters, isNotNull);
      expect(hydrated.chapters, hasLength(2));
      expect(hydrated.chapters!.first.title, 'Chapter 37');
      expect(hydrated.chapters!.last.id, 'you-wont-break-me-chapter-36');
    });
  });
}
