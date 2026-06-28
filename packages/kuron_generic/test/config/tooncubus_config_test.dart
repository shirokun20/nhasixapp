library;

import 'package:test/test.dart';

import '../support/config_test_harness.dart';

void main() {
  late Map<String, Object?> config;

  setUpAll(() {
    config = loadConfig('tooncubus-config.json');
  });

  test('uses Blogger Series label page and keeps no-chapters reader mode', () {
    final scraper = (config['scraper'] as Map).cast<String, Object?>();
    final urlPatterns = (scraper['urlPatterns'] as Map).cast<String, Object?>();
    final features = (config['features'] as Map).cast<String, Object?>();

    expect((urlPatterns['home'] as Map)['url'],
        '/search/label/Series?max-results=20');
    expect((urlPatterns['search'] as Map)['url'],
        '/search?q={query}&max-results=20');
    expect(features['chapters'], isFalse);
  });
}
