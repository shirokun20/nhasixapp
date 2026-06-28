/// Smoke test: programmatically test the full wizard flow
library;

import 'package:test/test.dart';
import 'package:kuron_config_generator/src/wizard/wizard_builder.dart';
import 'package:kuron_config_generator/src/generator/config_generator.dart';

void main() {
  group('Smoke Test - Full Config Generation', () {
    test('Can generate complete REST config from answers', () {
      // Simulate user answering all wizard questions
      final answers = {
        // Identity
        'sourceId': 'test_manga_source',
        'displayName': 'Test Manga Source',
        'version': '1.0.0',
        'homeUrl': 'https://testmanga.example.com',
        'contentType': 'manga',

        // Features
        'mode': 'rest_json',
        'supportsSearch': 'y',
        'supportsChapters': 'y',
        'supportsComments': 'n',

        // API
        'apiBase': 'https://api.testmanga.example.com',
        'listEndpoint': '/api/manga/list',
        'detailEndpoint': '/api/manga/{id}',

        // Headers
        'needsHeaders': 'y',
        'referer': 'https://testmanga.example.com/',
      };

      // Generate config
      final config = ConfigGenerator.generateConfig(answers);

      // Verify config structure
      expect(config['source'], 'test_manga_source');
      expect(config['displayName'], 'Test Manga Source');
      expect(config['schemaVersion'], '2.0');
      expect(config['homeUrl'], 'https://testmanga.example.com');

      // Verify features
      final features = config['features'] as Map;
      expect(features['home'], {'supported': true});
      expect(features['search'], {'supported': true});
      expect(features['chapters'], {'supported': true});
      expect(features['download'], {'supported': true});

      // Verify API block
      final api = config['api'] as Map;
      expect(api['type'], 'rest_json');
      expect(api['url'], 'https://api.testmanga.example.com');
      expect(api['listEndpoint'], '/api/manga/list');
      expect(api['detailEndpoint'], '/api/manga/{id}');
      expect(api['chaptersEndpoint'], '/chapters/{id}');

      // Verify headers
      final network = config['network'] as Map;
      final headers = network['headers'] as Map;
      expect(headers['Referer'], 'https://testmanga.example.com');

      // Verify primitives
      final primitives = config['requiredPrimitives'] as List;
      expect(primitives, contains('imageMode.directUrl'));
      expect(primitives, contains('pagination.page'));
      expect(primitives, contains('auth.none'));
      expect(primitives, contains('headers.static'));
    });

    test('Can generate scraper config from answers', () {
      final answers = {
        'sourceId': 'test_scraper_source',
        'displayName': 'Test Scraper',
        'version': '1.0.0',
        'homeUrl': 'https://testscraper.example.com',
        'contentType': 'doujin',
        'mode': 'scraper',
        'supportsSearch': 'y',
        'supportsChapters': 'n',
        'supportsComments': 'n',
        'listSelector': '.manga-item',
        'detailTitleSelector': 'h1.title',
        'needsHeaders': 'n',
      };

      final config = ConfigGenerator.generateConfig(answers);

      expect(config['source'], 'test_scraper_source');
      expect(config['scraper'], isA<Map>());

      final scraper = config['scraper'] as Map;
      final selectors = scraper['selectors'] as Map;
      final list = selectors['list'] as Map;
      expect(list['item'], '.manga-item');
    });

    test('Wizard flow has all required question sections', () {
      final flow = WizardBuilder.buildFlow();

      // Verify sections exist
      expect(
          flow.sections.keys,
          containsAll([
            'identity',
            'features',
            'api',
            'scraper',
            'headers',
          ]));

      // Verify identity section has required questions
      final identity = flow.sections['identity']!;
      final ids = identity.map((q) => q.id).toList();
      expect(ids, containsAll(['sourceId', 'homeUrl']));

      // Verify all questions have prompts
      for (final question in flow.allQuestions) {
        expect(question.prompt, isNotEmpty);
        expect(question.id, isNotEmpty);
      }
    });
  });
}
