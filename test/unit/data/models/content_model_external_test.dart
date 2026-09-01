import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/routing/reader_route_extra.dart';
import 'package:nhasixapp/data/models/content_model.dart';

void main() {
  group('ContentModel chapter externalUrl round-trip', () {
    test('toMap/fromMap preserves externalUrl/pages/isUnavailable', () {
      const chapter = Chapter(
        id: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        title: 'Ch.1.5',
        url: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        pages: 0,
        externalUrl:
            'https://comikey.com/read/isekai-returnee-is-too-op-manga/kj2PPk/chapter-1-5/',
        isUnavailable: false,
        language: 'en',
      );

      final model = ContentModel(
        id: 'manga-1',
        title: 'Test Manga',
        coverUrl: 'https://example.com/cover.jpg',
        tags: const [],
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'en',
        pageCount: 1,
        imageUrls: const [],
        uploadDate: DateTime(2026, 1, 1),
        chapters: const [chapter],
      );

      final map = model.toMap();
      final restored = ContentModel.fromMap(map, const []);

      expect(restored.chapters, isNotNull);
      expect(restored.chapters, hasLength(1));
      final ch = restored.chapters!.single;
      expect(ch.externalUrl,
          'https://comikey.com/read/isekai-returnee-is-too-op-manga/kj2PPk/chapter-1-5/');
      expect(ch.pages, 0);
      expect(ch.isUnavailable, isFalse);
      expect(ch.isExternal, isTrue);
      expect(ch.isReadableInApp, isFalse);
    });

    test('legacy map without external fields defaults correctly', () {
      final map = {
        'id': 'manga-1',
        'title': 'Test',
        'cover_url': 'https://example.com/cover.jpg',
        'artists': '[]',
        'characters': '[]',
        'parodies': '[]',
        'groups': '[]',
        'language': 'en',
        'page_count': 1,
        'image_urls': '[]',
        'upload_date': DateTime(2026, 1, 1).millisecondsSinceEpoch,
        'source_id': 'mangadex',
        'favorites': 0,
        'tags': [],
        'chapters': [
          {
            'id': 'ch-1',
            'title': 'Ch.1',
            'url': 'ch-1',
            'scan_group': 'Group A',
          },
        ],
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      final restored = ContentModel.fromMap(map, const []);
      final ch = restored.chapters!.single;
      expect(ch.externalUrl, isNull);
      expect(ch.pages, isNull);
      expect(ch.isUnavailable, isFalse);
      expect(ch.isExternal, isFalse);
      expect(ch.isReadableInApp, isTrue);
    });
  });

  group('reader_route_extra chapter externalUrl round-trip', () {
    test('serialize/deserialize preserves externalUrl/pages/isUnavailable', () {
      const chapter = Chapter(
        id: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        title: 'Ch.1.5',
        url: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        pages: 0,
        externalUrl:
            'https://comikey.com/read/isekai-returnee-is-too-op-manga/kj2PPk/chapter-1-5/',
        language: 'en',
      );

      final extra = buildReaderRouteExtra(currentChapter: chapter);
      final restored = readReaderChapter(extra['currentChapter']);

      expect(restored, isNotNull);
      expect(restored!.externalUrl,
          'https://comikey.com/read/isekai-returnee-is-too-op-manga/kj2PPk/chapter-1-5/');
      expect(restored.pages, 0);
      expect(restored.isExternal, isTrue);
    });

    test('legacy serialized chapter without external fields', () {
      final map = {
        'id': 'ch-1',
        'title': 'Ch.1',
        'url': 'ch-1',
        'language': 'en',
      };

      final restored = readReaderChapter(map);
      expect(restored, isNotNull);
      expect(restored!.externalUrl, isNull);
      expect(restored.pages, isNull);
      expect(restored.isUnavailable, isFalse);
    });
  });
}
