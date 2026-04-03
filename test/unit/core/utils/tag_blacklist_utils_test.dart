import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/core/utils/tag_blacklist_utils.dart';

void main() {
  group('TagBlacklistUtils', () {
    test('parseManualEntries normalizes and deduplicates values', () {
      expect(
        TagBlacklistUtils.parseManualEntries(
          ' Romance, artist:Foo \n#12345\nromance ',
        ),
        ['romance', 'artist:foo', '12345'],
      );
    });

    test('isContentBlacklisted matches by tag name and id', () {
      final content = _buildContent(
        tags: const [
          Tag(
            id: 12345,
            name: 'Romance',
            type: 'tag',
            count: 10,
            slug: 'romance',
          ),
        ],
      );

      expect(
        TagBlacklistUtils.isContentBlacklisted(content, const ['romance']),
        isTrue,
      );
      expect(
        TagBlacklistUtils.isContentBlacklisted(content, const ['12345']),
        isTrue,
      );
      expect(
        TagBlacklistUtils.isContentBlacklisted(content, const ['tag:romance']),
        isTrue,
      );
    });

    test('isContentBlacklisted matches typed fallback metadata', () {
      final content = _buildContent(
        artists: const ['John Doe'],
        groups: const ['Circle X'],
        language: 'english',
      );

      expect(
        TagBlacklistUtils.isContentBlacklisted(
          content,
          const ['artist:john doe'],
        ),
        isTrue,
      );
      expect(
        TagBlacklistUtils.isContentBlacklisted(content, const ['circle x']),
        isTrue,
      );
      expect(
        TagBlacklistUtils.isContentBlacklisted(
          content,
          const ['language:english'],
        ),
        isTrue,
      );
    });
  });
}

Content _buildContent({
  List<Tag> tags = const [],
  List<String> artists = const [],
  List<String> characters = const [],
  List<String> parodies = const [],
  List<String> groups = const [],
  String language = '',
}) {
  return Content(
    id: '1',
    sourceId: 'nhentai',
    title: 'Sample',
    coverUrl: 'https://example.com/cover.jpg',
    tags: tags,
    artists: artists,
    characters: characters,
    parodies: parodies,
    groups: groups,
    language: language,
    pageCount: 10,
    imageUrls: const ['https://example.com/1.jpg'],
    uploadDate: DateTime(2026),
  );
}
