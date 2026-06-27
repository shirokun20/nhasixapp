import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/presentation/pages/detail/services/detail_tag_query_resolver.dart';

void main() {
  group('DetailTagQueryResolver', () {
    const resolver = DetailTagQueryResolver();

    test(
        'returns explicit mapping failure when required mapping cannot resolve',
        () {
      final result = resolver.resolve(
        sourceId: 'komiktap',
        tagName: 'action',
        tagType: 'tag',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {
                'param': 'genre_id',
                'valueSource': 'tagId',
                'requiredPattern': r'^\d+$',
              },
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isTrue);
      expect(result.query, isEmpty);
    });

    test('builds E-Hentai namespace query with quoted values', () {
      final result = resolver.resolve(
        sourceId: 'ehentai',
        tagName: 'ai generated',
        tagId: 'other:ai generated',
        tagType: 'other',
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'raw:f_search=other:"ai generated"');
    });

    test('builds nhentai numeric tag query', () {
      final result = resolver.resolve(
        sourceId: 'nhentai',
        tagName: 'big breasts',
        tagId: '12345',
        tagType: 'tag',
      );

      expect(result.query, 'raw:tag_id=12345');
    });

    test('applies explicit mapping transform and resolved tag id', () {
      final result = resolver.resolve(
        sourceId: 'komiktap',
        tagName: 'Mika',
        tagType: 'artist',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'artist': {
                'param': 'f_search',
                'valueSource': 'tagIdOrName',
                'valuePrefix': 'artist:',
                'transform': 'lowercase',
              },
            },
          },
        },
        resolveTagIdFromLoadedContent: (_, __) => 'MiKA',
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'raw:f_search=artist:mika');
    });

    test('builds genre query for generic sources when genreSearch exists', () {
      final result = resolver.resolve(
        sourceId: 'komiktap',
        tagName: 'Action Comedy',
        tagType: 'tag',
        rawConfig: {
          'scraper': {
            'urlPatterns': {
              'genreSearch': {
                'url': '/genre/{tag}',
              },
            },
          },
          'navigation': {
            'genreQueryPrefix': 'genre:',
            'genreTagType': 'genre',
          },
        },
      );

      expect(result.query, 'genre:action-comedy');
    });

    test('builds SpyFakku artist query with explicit namespace', () {
      final result = resolver.resolve(
        sourceId: 'spyfakku',
        tagName: 'Aka',
        tagType: 'artist',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'artist': {
                'mode': 'rawParam',
                'param': 'q',
                'valueSource': 'tagName',
                'valuePrefix': 'artist:"',
                'valueSuffix': '"',
              },
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'raw:q=artist:"Aka"');
    });

    test('builds SpyFakku multi-word tag query with quotes preserved', () {
      final result = resolver.resolve(
        sourceId: 'spyfakku',
        tagName: 'Mating Press',
        tagType: 'tag',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {
                'mode': 'rawParam',
                'param': 'q',
                'valueSource': 'tagName',
                'valuePrefix': 'tag:"',
                'valueSuffix': '"',
              },
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'raw:q=tag:"Mating Press"');
    });

    test('mode:name returns type-prefixed query for tag', () {
      final result = resolver.resolve(
        sourceId: 'manhwaread',
        tagName: 'Facial',
        tagType: 'tag',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {'mode': 'name'},
              'author': {'mode': 'name'},
              'artist': {'mode': 'name'},
              'publisher': {'mode': 'name'},
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'tag:Facial');
    });

    test('mode:name returns type-prefixed query for author', () {
      final result = resolver.resolve(
        sourceId: 'manhwaread',
        tagName: 'Hwalhwasan',
        tagType: 'author',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {'mode': 'name'},
              'author': {'mode': 'name'},
              'artist': {'mode': 'name'},
              'publisher': {'mode': 'name'},
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'author:Hwalhwasan');
    });

    test('mode:name returns type-prefixed query for artist', () {
      final result = resolver.resolve(
        sourceId: 'manhwaread',
        tagName: 'Andrew',
        tagType: 'artist',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {'mode': 'name'},
              'author': {'mode': 'name'},
              'artist': {'mode': 'name'},
              'publisher': {'mode': 'name'},
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'artist:Andrew');
    });

    test('mode:name returns type-prefixed query for publisher', () {
      final result = resolver.resolve(
        sourceId: 'manhwaread',
        tagName: 'DAYcomics',
        tagType: 'publisher',
        rawConfig: {
          'navigation': {
            'tagQueryMapping': {
              'tag': {'mode': 'name'},
              'author': {'mode': 'name'},
              'artist': {'mode': 'name'},
              'publisher': {'mode': 'name'},
            },
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'publisher:DAYcomics');
    });

    test('mode:name with genre type falls back to genreQueryPrefix', () {
      final result = resolver.resolve(
        sourceId: 'manhwaread',
        tagName: 'Drama',
        tagType: 'genre',
        rawConfig: {
          'scraper': {
            'urlPatterns': {
              'genreSearch': {'url': '/genre/{tag}'},
            },
          },
          'navigation': {
            'tagQueryMapping': {
              'tag': {'mode': 'name'},
              'author': {'mode': 'name'},
            },
            'genreQueryPrefix': 'genre:',
            'genreTagType': 'genre',
          },
        },
      );

      expect(result.explicitMappingFailed, isFalse);
      expect(result.query, 'genre:drama');
    });
  });
}
