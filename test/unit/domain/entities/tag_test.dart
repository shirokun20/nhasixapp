import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/tag.dart';

void main() {
  group('Tag Entity', () {
    const sampleTag = Tag(
      id: 1,
      name: 'romance',
      type: 'tag',
      count: 5000,
      url: '/tag/romance',
    );

    group('displayName', () {
      test('returns name with count', () {
        expect(sampleTag.displayName, 'romance (5000)');
      });
    });

    group('type checks', () {
      test('isType works case insensitively', () {
        expect(sampleTag.isType('tag'), true);
        expect(sampleTag.isType('TAG'), true);
        expect(sampleTag.isType('artist'), false);
      });

      test('isArtist returns true for artist type', () {
        const artistTag = Tag(
            id: 1,
            name: 'Artist',
            type: 'artist',
            count: 100,
            url: '/artist/test');
        expect(artistTag.isArtist, true);
        expect(artistTag.isCharacter, false);
      });

      test('isCharacter returns true for character type', () {
        const charTag = Tag(
            id: 1,
            name: 'Character',
            type: 'character',
            count: 100,
            url: '/char/test');
        expect(charTag.isCharacter, true);
      });

      test('isParody returns true for parody type', () {
        const parodyTag = Tag(
            id: 1,
            name: 'Parody',
            type: 'parody',
            count: 100,
            url: '/parody/test');
        expect(parodyTag.isParody, true);
      });

      test('isGroup returns true for group type', () {
        const groupTag = Tag(
            id: 1,
            name: 'Group',
            type: 'group',
            count: 100,
            url: '/group/test');
        expect(groupTag.isGroup, true);
      });

      test('isLanguage returns true for language type', () {
        const langTag = Tag(
            id: 1,
            name: 'English',
            type: 'language',
            count: 100,
            url: '/lang/test');
        expect(langTag.isLanguage, true);
      });

      test('isCategory returns true for category type', () {
        const catTag = Tag(
            id: 1,
            name: 'Doujinshi',
            type: 'category',
            count: 100,
            url: '/cat/test');
        expect(catTag.isCategory, true);
      });

      test('isRegularTag returns true for tag type', () {
        expect(sampleTag.isRegularTag, true);
      });
    });

    group('colorHex', () {
      test('returns correct color for each type', () {
        expect(
            const Tag(id: 1, name: 'n', type: 'artist', count: 1, url: '/')
                .colorHex,
            '#FF6B6B');
        expect(
            const Tag(id: 1, name: 'n', type: 'character', count: 1, url: '/')
                .colorHex,
            '#4ECDC4');
        expect(
            const Tag(id: 1, name: 'n', type: 'parody', count: 1, url: '/')
                .colorHex,
            '#45B7D1');
        expect(
            const Tag(id: 1, name: 'n', type: 'group', count: 1, url: '/')
                .colorHex,
            '#96CEB4');
        expect(
            const Tag(id: 1, name: 'n', type: 'language', count: 1, url: '/')
                .colorHex,
            '#FFEAA7');
        expect(
            const Tag(id: 1, name: 'n', type: 'category', count: 1, url: '/')
                .colorHex,
            '#DDA0DD');
        expect(
            const Tag(id: 1, name: 'n', type: 'tag', count: 1, url: '/')
                .colorHex,
            '#74B9FF');
        expect(
            const Tag(id: 1, name: 'n', type: 'unknown', count: 1, url: '/')
                .colorHex,
            '#74B9FF');
      });
    });

    group('popularity', () {
      test('isPopular returns true for count > 1000', () {
        expect(sampleTag.isPopular, true);
        expect(
            const Tag(id: 1, name: 'n', type: 'tag', count: 500, url: '/')
                .isPopular,
            false);
      });

      test('popularity returns correct level', () {
        expect(
          const Tag(id: 1, name: 'n', type: 'tag', count: 50000, url: '/')
              .popularity,
          TagPopularity.veryHigh,
        );
        expect(
          const Tag(id: 1, name: 'n', type: 'tag', count: 7000, url: '/')
              .popularity,
          TagPopularity.high,
        );
        expect(
          const Tag(id: 1, name: 'n', type: 'tag', count: 3000, url: '/')
              .popularity,
          TagPopularity.medium,
        );
        expect(
          const Tag(id: 1, name: 'n', type: 'tag', count: 500, url: '/')
              .popularity,
          TagPopularity.low,
        );
        expect(
          const Tag(id: 1, name: 'n', type: 'tag', count: 50, url: '/')
              .popularity,
          TagPopularity.veryLow,
        );
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final copy = sampleTag.copyWith(
          name: 'newName',
          count: 10000,
        );
        expect(copy.name, 'newName');
        expect(copy.count, 10000);
        expect(copy.id, sampleTag.id);
        expect(copy.type, sampleTag.type);
      });
    });

    group('equatable', () {
      test('two tags with same data are equal', () {
        const tag1 =
            Tag(id: 1, name: 'test', type: 'tag', count: 100, url: '/test');
        const tag2 =
            Tag(id: 1, name: 'test', type: 'tag', count: 100, url: '/test');
        expect(tag1, equals(tag2));
      });

      test('two tags with different data are not equal', () {
        const tag1 =
            Tag(id: 1, name: 'test', type: 'tag', count: 100, url: '/test');
        const tag2 =
            Tag(id: 2, name: 'test', type: 'tag', count: 100, url: '/test');
        expect(tag1, isNot(equals(tag2)));
      });
    });
  });

  group('TagType Constants', () {
    test('all types are defined', () {
      expect(TagType.tag, 'tag');
      expect(TagType.artist, 'artist');
      expect(TagType.character, 'character');
      expect(TagType.parody, 'parody');
      expect(TagType.group, 'group');
      expect(TagType.language, 'language');
      expect(TagType.category, 'category');
    });

    test('all list contains all types', () {
      expect(
          TagType.all,
          containsAll([
            'tag',
            'artist',
            'character',
            'parody',
            'group',
            'language',
            'category',
          ]));
      expect(TagType.all.length, 7);
    });

    test('getDisplayName returns correct names', () {
      expect(TagType.getDisplayName('tag'), 'Tag');
      expect(TagType.getDisplayName('artist'), 'Artist');
      expect(TagType.getDisplayName('character'), 'Character');
      expect(TagType.getDisplayName('parody'), 'Parody');
      expect(TagType.getDisplayName('group'), 'Group');
      expect(TagType.getDisplayName('language'), 'Language');
      expect(TagType.getDisplayName('category'), 'Category');
      expect(TagType.getDisplayName('unknown'), 'unknown');
    });
  });
}
