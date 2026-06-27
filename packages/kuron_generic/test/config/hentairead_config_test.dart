library;

import 'package:test/test.dart';

import '../support/config_test_harness.dart';

void main() {
  late Map<String, Object?> config;

  setUpAll(() {
    config = loadConfig('hentairead-config.json');
  });

  test('uses the /hentai/ listing and english reader route', () {
    final scraper = (config['scraper'] as Map).cast<String, Object?>();
    final urlPatterns = (scraper['urlPatterns'] as Map).cast<String, Object?>();

    expect((urlPatterns['home'] as Map)['url'], '/hentai/');
    expect(urlPatterns['detail'], '/hentai/{id}/');
    expect(urlPatterns['chapter'], '/hentai/{id}/english/p/1/');
  });

  test('keeps hentairead as a no-chapters source with reader fallback', () {
    final scraper = (config['scraper'] as Map).cast<String, Object?>();
    final selectors = (scraper['selectors'] as Map).cast<String, Object?>();
    final reader = (selectors['reader'] as Map).cast<String, Object?>();
    final features = (config['features'] as Map).cast<String, Object?>();

    expect(reader['mode'], 'chapterDataScript');
    expect(features['chapters'], isFalse);
  });
}
