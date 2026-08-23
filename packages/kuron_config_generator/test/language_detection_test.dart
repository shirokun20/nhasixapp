// Phase-5 focused checks: `global` language metadata + generator precedence.
//
// Covers spec requirements "Global content language metadata" and
// "Content language inference does not guess from site locale":
//  - explicit defaultLanguage wins over any heuristic,
//  - unverified sources fall back to `global` (NOT domain-guessed),
//  - languages.json carries the Global 🌐 display entry.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:kuron_config_generator/src/generator/config_generator.dart';

Map<String, dynamic> _loadLanguagesJson() {
  for (final path in [
    '../../assets/configs/languages.json',
    'assets/configs/languages.json',
  ]) {
    final f = File(path);
    if (f.existsSync()) {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('languages.json not found');
}

void main() {
  group('generator language precedence', () {
    test('explicit defaultLanguage wins', () {
      final config = ConfigGenerator.generateConfig({
        'sourceId': 'rawbaka',
        'homeUrl': 'https://komikindo.example.id', // would trip old heuristic
        'defaultLanguage': 'japanese',
      });
      expect(config['defaultLanguage'], 'japanese');
    });

    test('unverified source falls back to global, not domain guess', () {
      for (final url in [
        'https://komikindonesia.id', // .id + komik
        'https://doujin-desu.net',   // doujin
        'https://mangaku.pro',       // manga
      ]) {
        final config = ConfigGenerator.generateConfig({
          'sourceId': 'x',
          'homeUrl': url,
        });
        expect(config['defaultLanguage'], 'global',
            reason: '$url must not be language-guessed');
      }
    });
  });

  group('global display metadata', () {
    test('languages.json has Global entry with globe emoji', () {
      final parsed = _loadLanguagesJson();
      final languages = parsed['languages'] as Map<String, dynamic>;
      final global = languages['global'] as Map<String, dynamic>;
      expect(global['displayName'], 'Global');
      expect(global['code'], 'global');
      expect(global['flagEmoji'], '🌐');
    });

    test('existing `all` filter value unchanged', () {
      final parsed = _loadLanguagesJson();
      final all =
          (parsed['languages'] as Map<String, dynamic>)['all']
              as Map<String, dynamic>;
      expect(all['displayName'], 'All Languages');
      expect(all['code'], 'all');
    });
  });
}
