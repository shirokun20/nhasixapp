import 'package:kuron_core/kuron_core.dart';

/// Converts wizard answers into a Source Config v2 JSON structure.
class ConfigGenerator {
  /// Generate config JSON from wizard answers.
  static Map<String, Object?> generateConfig(Map<String, String?> answers) {
    final mode = answers['mode'] ?? 'rest_json';
    final supportsChapters = answers['supportsChapters'] == 'y';

    final config = <String, Object?>{
      'source': answers['sourceId'],
      'displayName': answers['displayName'],
      'schemaVersion': '2.0',
      'version': answers['version'] ?? '1.0.0',
      'homeUrl': answers['homeUrl'],

      // Feature declarations
      'features': _buildFeatures(answers),

      // Required primitives based on mode
      'requiredPrimitives': _buildPrimitives(mode, answers),
    };

    // Add API or scraper block based on mode
    if (mode == 'rest_json') {
      config['api'] = _buildApiBlock(answers, supportsChapters);
    } else {
      config['scraper'] = _buildScraperBlock(answers);
    }

    // Add search config if supported
    if (answers['supportsSearch'] == 'y') {
      config['searchConfig'] = _buildSearchConfig(answers, mode);
    }

    // Add headers if needed
    if (answers['needsHeaders'] == 'y') {
      config['network'] = _buildNetworkConfig(answers);
    }

    return config;
  }

  static Map<String, Object?> _buildFeatures(Map<String, String?> answers) {
    return {
      'home': {'supported': true},
      'search': {'supported': answers['supportsSearch'] == 'y'},
      'detail': {'supported': true},
      'reader': {'supported': true},
      'download': {'supported': true},
      'chapters': {'supported': answers['supportsChapters'] == 'y'},
      'comments': {'supported': answers['supportsComments'] == 'y'},
    };
  }

  static List<String> _buildPrimitives(String mode, Map<String, String?> answers) {
    final primitives = <String>[
      EnginePrimitive.imageModeDirectUrl,
      EnginePrimitive.paginationPage,
      EnginePrimitive.authNone,
    ];

    if (answers['needsHeaders'] == 'y') {
      primitives.add(EnginePrimitive.headersStatic);
    }

    return primitives;
  }

  static Map<String, Object?> _buildApiBlock(
    Map<String, String?> answers,
    bool supportsChapters,
  ) {
    final block = <String, Object?>{
      'type': 'rest_json',
      'url': answers['apiBase'],
      'listEndpoint': answers['listEndpoint'] ?? '/list',
      'detailEndpoint': answers['detailEndpoint'] ?? '/detail/{id}',
    };

    if (supportsChapters) {
      block['chaptersEndpoint'] = '/chapters/{id}';
    }

    return block;
  }

  static Map<String, Object?> _buildScraperBlock(Map<String, String?> answers) {
    return {
      'selectors': {
        'list': {
          'item': answers['listSelector'] ?? '.item',
        },
        'detail': {
          'title': answers['detailTitleSelector'] ?? 'h1.title',
        },
      },
    };
  }

  static Map<String, Object?> _buildSearchConfig(
    Map<String, String?> answers,
    String mode,
  ) {
    if (mode == 'rest_json') {
      return {
        'type': 'rest_json',
        'listEndpoint': '/search',
        'queryParam': 'q',
        'pageParam': 'page',
      };
    } else {
      return {
        'type': 'scraper',
        'searchUrl': '${answers['homeUrl']}/search',
      };
    }
  }

  static Map<String, Object?> _buildNetworkConfig(Map<String, String?> answers) {
    final config = <String, Object?>{};

    if (answers['referer'] != null && answers['referer']!.isNotEmpty) {
      config['headers'] = {
        'Referer': answers['referer'],
      };
    }

    return config;
  }
}
