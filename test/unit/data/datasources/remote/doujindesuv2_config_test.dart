import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoujinDesu v2 Config Validation', () {
    late Map<String, dynamic> configJson;

    setUp(() {
      // Sample config from doujindesuv2-config.json
      configJson = {
        'source': 'doujindesuv2',
        'version': '1.0.0',
        'enabled': true,
        'defaultLanguage': 'indonesian',
        'baseUrl': 'https://v2.doujindesu.fun',
        'ui': {
          'displayName': 'DoujinDesu v2',
          'brandColor': '#d43726',
          'openInBrowserUrl': 'https://v2.doujindesu.fun'
        },
        'network': {
          'requiresBypass': false,
          'headers': {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json',
            'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7'
          }
        },
        'api': {
          'enabled': true,
          'endpoints': {
            'allGalleries': '/api/manga-list?limit=24&page={page}',
            'search': '/api/search?q={query}',
            'detail': '/api/manga/{id}',
            'chapters': '/api/manga/{id}',
            'images': '/api/read/{id}/{chapter}',
            'contentUrl': 'https://v2.doujindesu.fun/manga/{id}'
          },
          'list': {
            'items': '\$.data[*]',
            'pagination': {
              'pageMode': true,
              'total': {'path': '\$.pagination.totalItems'},
              'limit': {'path': '\$.pagination.perPage'},
              'currentPage': {'path': '\$.pagination.currentPage'},
              'totalPages': {'path': '\$.pagination.totalPages'},
              'pageSize': 24
            },
            'fields': {
              'id': {'selector': '\$.slug'},
              'title': {'selector': '\$.title'},
              'coverUrl': {'selector': '\$.thumb'},
              'type': {'selector': '\$.metadata.type'},
              'status': {'selector': '\$.metadata.status'},
              'rating': {'selector': '\$.metadata.rating'},
              'author': {'selector': '\$.metadata.author'},
              'views': {'selector': '\$.views'},
              'chapterCount': {'selector': '\$.chapter_count'},
              'latestChapter': {'selector': '\$.last_chapter.title'},
              'tags': {'selector': '\$.tags[*]', 'multi': true}
            }
          }
        }
      };
    });

    test('config has required top-level fields', () {
      expect(configJson['source'], 'doujindesuv2');
      expect(configJson['version'], '1.0.0');
      expect(configJson['enabled'], isTrue);
      expect(configJson['baseUrl'], 'https://v2.doujindesu.fun');
    });

    test('config has valid UI configuration', () {
      final ui = configJson['ui'] as Map<String, dynamic>;
      expect(ui['displayName'], 'DoujinDesu v2');
      expect(ui['brandColor'], '#d43726');
      expect(ui['openInBrowserUrl'], 'https://v2.doujindesu.fun');
    });

    test('config has valid network headers', () {
      final headers = configJson['network']['headers'] as Map<String, dynamic>;
      expect(headers['User-Agent'], isNotEmpty);
      expect(headers['Accept'], 'application/json');
      expect(headers['Accept-Language'], isNotEmpty);
    });

    test('config has all required API endpoints', () {
      final endpoints = configJson['api']['endpoints'] as Map<String, dynamic>;
      expect(endpoints['allGalleries'], isNotEmpty);
      expect(endpoints['search'], isNotEmpty);
      expect(endpoints['detail'], isNotEmpty);
      expect(endpoints['chapters'], isNotEmpty);
      expect(endpoints['images'], isNotEmpty);
      expect(endpoints['contentUrl'], isNotEmpty);
    });

    test('config has valid JSON path selectors', () {
      final list = configJson['api']['list'] as Map<String, dynamic>;
      expect(list['items'], '\$.data[*]');

      final fields = list['fields'] as Map<String, dynamic>;
      expect(fields['id']['selector'], '\$.slug');
      expect(fields['title']['selector'], '\$.title');
      expect(fields['coverUrl']['selector'], '\$.thumb');
      expect(fields['tags']['multi'], isTrue);
    });

    test('config pagination settings are correct', () {
      final pagination =
          configJson['api']['list']['pagination'] as Map<String, dynamic>;
      expect(pagination['pageMode'], isTrue);
      expect(pagination['pageSize'], 24);
      expect(pagination['total']['path'], '\$.pagination.totalItems');
      expect(pagination['currentPage']['path'], '\$.pagination.currentPage');
      expect(pagination['totalPages']['path'], '\$.pagination.totalPages');
    });

    test('config is valid JSON serializable', () {
      final jsonString = jsonEncode(configJson);
      expect(jsonString, isNotEmpty);

      final decoded = jsonDecode(jsonString);
      expect(decoded['source'], 'doujindesuv2');
      expect(decoded['api']['enabled'], isTrue);
    });

    test('config endpoints use correct parameter placeholders', () {
      final endpoints = configJson['api']['endpoints'] as Map<String, dynamic>;

      // Check for {page} placeholder
      expect(endpoints['allGalleries'], contains('{page}'));

      // Check for {query} placeholder
      expect(endpoints['search'], contains('{query}'));

      // Check for {id} placeholder
      expect(endpoints['detail'], contains('{id}'));
      expect(endpoints['images'], contains('{id}'));
      expect(endpoints['images'], contains('{chapter}'));
    });

    test('config base URL is HTTPS', () {
      expect(configJson['baseUrl'], startsWith('https://'));
    });

    test('config has API mode enabled (not scraper mode)', () {
      final api = configJson['api'] as Map<String, dynamic>;
      expect(api['enabled'], isTrue);
      expect(api.containsKey('endpoints'), isTrue);
      expect(api.containsKey('list'), isTrue);
    });
  });
}
