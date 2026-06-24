/// Demo script: Generate a sample config without interactive input
library;

import 'dart:io';
import 'dart:convert';
import 'package:kuron_config_generator/src/generator/config_generator.dart';

void main() {
  // Simulate wizard answers for a test manga source
  final answers = {
    'sourceId': 'demo_manga_api',
    'displayName': 'Demo Manga API',
    'version': '1.0.0',
    'homeUrl': 'https://demo-manga.example.com',
    'contentType': 'manga',
    'mode': 'rest_json',
    'supportsSearch': 'y',
    'supportsChapters': 'y',
    'supportsComments': 'n',
    'apiBase': 'https://api.demo-manga.example.com',
    'listEndpoint': '/v1/manga/list',
    'detailEndpoint': '/v1/manga/{id}',
    'needsHeaders': 'y',
    'referer': 'https://demo-manga.example.com/',
  };

  // Generate config using the wizard's generator
  final config = ConfigGenerator.generateConfig(answers);

  // Create output directory
  final outputDir = Directory('build/demo');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Write config to file
  final configFile = File('build/demo/${answers['sourceId']}-config.json');
  final prettyJson = const JsonEncoder.withIndent('  ').convert(config);
  configFile.writeAsStringSync(prettyJson);
}
