import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/pages/detail/detail_screen.dart';

void main() {
  group('DetailScreen.resolveDetailHeaderImageUrlForTesting', () {
    test('prefers cover url for hentainexus detail header', () {
      final content = Content(
        id: '21723',
        sourceId: 'hentainexus',
        title: 'Test',
        coverUrl: 'https://cdn.example.com/cover.jpg',
        tags: const <Tag>[],
        artists: const <String>[],
        characters: const <String>[],
        parodies: const <String>[],
        groups: const <String>[],
        language: 'en',
        pageCount: 1,
        imageUrls: const <String>[
          'https://images.hentainexus.com/v2/foo/001.webp',
        ],
        uploadDate: DateTime(2026),
      );

      expect(
        DetailScreen.resolveDetailHeaderImageUrlForTesting(content),
        'https://cdn.example.com/cover.jpg',
      );
    });

    test('keeps first image for non-hentainexus source', () {
      final content = Content(
        id: '1',
        sourceId: 'other',
        title: 'Test',
        coverUrl: 'https://cdn.example.com/cover.jpg',
        tags: const <Tag>[],
        artists: const <String>[],
        characters: const <String>[],
        parodies: const <String>[],
        groups: const <String>[],
        language: 'en',
        pageCount: 1,
        imageUrls: const <String>[
          'https://cdn.example.com/page-1.webp',
        ],
        uploadDate: DateTime(2026),
      );

      expect(
        DetailScreen.resolveDetailHeaderImageUrlForTesting(content),
        'https://cdn.example.com/page-1.webp',
      );
    });

    test('derives hentainexus thumb jpg when cover url is empty', () {
      final content = Content(
        id: '21723',
        sourceId: 'hentainexus',
        title: 'Test',
        coverUrl: '',
        tags: const <Tag>[],
        artists: const <String>[],
        characters: const <String>[],
        parodies: const <String>[],
        groups: const <String>[],
        language: 'en',
        pageCount: 1,
        imageUrls: const <String>[
          'https://images.hentainexus.com/v2/foo/001.webp',
        ],
        uploadDate: DateTime(2026),
      );

      expect(
        DetailScreen.resolveDetailHeaderImageUrlForTesting(content),
        'https://images.hentainexus.com/v2/foo/001.png.thumb.jpg',
      );
    });
  });
}
