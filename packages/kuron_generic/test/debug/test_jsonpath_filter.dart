/// Quick diagnostic: verify json_path filter expression support for MangaDex.
library;

import 'package:json_path/json_path.dart';
import 'package:test/test.dart';

void main() {
  final singleMangaItem = {
    'id': '74d4794b-test',
    'type': 'manga',
    'attributes': {
      'title': {'ja-ro': 'Test Manga', 'en': 'Test Manga EN'},
      'altTitles': [
        {'en': 'English Title Alt'},
        {'ja': 'Japanese Title Alt'},
      ],
      'tags': [
        {
          'id': 'tag1',
          'type': 'tag',
          'attributes': {
            'name': {'en': 'Action'},
          },
        },
      ],
    },
    'relationships': [
      {
        'id': 'cover1',
        'type': 'cover_art',
        'attributes': {'fileName': 'my-cover.jpg'},
      },
      {
        'id': 'author1',
        'type': 'author',
        'attributes': {'name': 'Author Name'},
      },
    ],
  };

  group('json_path filter expression support', () {
    test('filter [?(@.type=="cover_art")] is supported', () {
      final path = JsonPath(
          r"$.relationships[?(@.type=='cover_art')].attributes.fileName");
      final matches = path.read(singleMangaItem);
      final values = matches.map((m) => m.value).toList();
      expect(values, isNotEmpty, reason: 'Should find cover_art filename');
      expect(values.first, equals('my-cover.jpg'));
    });

    test('title Map extraction returns en key', () {
      final path = JsonPath(r'$.attributes.title');
      final matches = path.read(singleMangaItem);
      final value = matches.isNotEmpty ? matches.first.value : null;
      // Should return a Map
      expect(value, isA<Map>());
      expect((value as Map)['en'], equals('Test Manga EN'));
    });

    test('altTitles extraction returns list of Maps', () {
      final path = JsonPath(r'$.attributes.altTitles');
      final matches = path.read(singleMangaItem);
      final value = matches.isNotEmpty ? matches.first.value : null;
      expect(value, isA<List>());
    });

    test('tags extraction with wildcard + nested', () {
      final path = JsonPath(r'$.attributes.tags[*].attributes.name.en');
      final matches = path.read(singleMangaItem);
      final values = matches.map((m) => m.value?.toString() ?? '').toList();
      expect(values, contains('Action'));
    });
  });
}
