import 'package:kuron_core/kuron_core.dart';

/// Converts wizard answers into a Source Config v2 JSON structure.
class ConfigGenerator {
  static Map<String, Object?> generateConfig(Map<String, String?> answers) {
    final mode = answers['mode'] ?? 'scraper';
    final cmsTheme = answers['cmsThemeType'] ?? '';
    final supportsChapters = answers['supportsChapters'] == 'y';
    final baseUrl = answers['homeUrl'] ?? '';

    final config = <String, Object?>{
      'source': answers['sourceId'],
      'displayName': answers['displayName'],
      'schemaVersion': '2.0',
      'version': answers['version'] ?? '1.0.0',
      'homeUrl': baseUrl,
      'features': _buildFeatures(answers),
      'requiredPrimitives': _buildPrimitives(mode, answers),
    };

    if (mode == 'rest_json') {
      config['api'] = _buildApiBlock(answers, supportsChapters);
    } else {
      config['scraper'] = _buildScraperBlock(answers);
    }

    if (answers['supportsSearch'] == 'y') {
      config['searchConfig'] = _buildSearchConfig(answers, mode);
    }

    final network = _buildNetworkConfig(answers);
    if (network.isNotEmpty) {
      config['network'] = network;
    }

    if (cmsTheme.startsWith('madara')) {
      config['contentIdPattern'] = '/manhwa/([^/]+)';
      config['navigation'] = <String, String>{
        'genreQueryPrefix': 'genre:',
        'genreTagType': 'genre',
      };
    }

    config['notes'] = _buildNotes(answers);

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

  static List<String> _buildPrimitives(
      String mode, Map<String, String?> answers) {
    final primitives = <String>[
      EnginePrimitive.paginationPage,
      EnginePrimitive.authNone,
    ];

    final readerMode = answers['readerMode'] ?? 'directUrl';
    if (readerMode == 'chapterDataScript') {
      primitives.add('imageMode.chapterDataScript');
    } else {
      primitives.add(EnginePrimitive.imageModeDirectUrl);
    }

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
      block['chaptersEndpoint'] =
          answers['chaptersEndpoint'] ?? '/chapters/{id}';
    }
    return block;
  }

  static Map<String, Object?> _buildScraperBlock(Map<String, String?> answers) {
    final listSel = answers['listSelector'] ?? '.item';
    final detailTitleSel = answers['detailTitleSelector'] ?? 'h1';
    final readerMode = answers['readerMode'] ?? 'directUrl';
    final cmsTheme = answers['cmsThemeType'] ?? '';

    // urlPatterns
    final urlPatterns = <String, dynamic>{};

    if (cmsTheme.startsWith('madara')) {
      urlPatterns['home'] = {
        'url': '/',
        'list': {
          'container': listSel,
          'fields': {
            'id': {
              'selector': 'a[href*="/manhwa/"]',
              'attribute': 'href',
              'transform': 'slug',
            },
            'title': {
              'selector': answers['listTitleSelector'] ?? 'a[href*="/manhwa/"]',
            },
            'coverUrl': {
              'selector': 'img',
              'attribute': 'src',
            },
          },
          'pagination': {
            'next': 'a.next, a[rel="next"]',
            'links': 'a.page-numbers',
          },
        },
      };
      urlPatterns['homePage'] = {'url': '/page/{page}/', 'inherits': 'home'};
      urlPatterns['search'] = {
        'url': '/?s={query}&post_type=wp-manga',
        'inherits': 'home',
      };
      urlPatterns['searchPage'] = {
        'url': '/page/{page}/?s={query}&post_type=wp-manga',
        'inherits': 'search',
      };
      urlPatterns['genreSearch'] = {
        'url': '/genre/{tag}/',
        'inherits': 'home',
      };
      urlPatterns['genreSearchPage'] = {
        'url': '/genre/{tag}/page/{page}/',
        'inherits': 'home',
      };
      if (cmsTheme == 'madara-tailwind') {
        urlPatterns['tagSearch'] = {'url': '/tag/{tag}/', 'inherits': 'home'};
        urlPatterns['tagSearchPage'] = {
          'url': '/tag/{tag}/page/{page}/',
          'inherits': 'home',
        };
      }
      urlPatterns['detail'] = '/manhwa/{id}';
      urlPatterns['chapter'] = '/manhwa/{id}';
    } else {
      urlPatterns['home'] = {
        'url': '/',
        'list': {
          'container': listSel,
          'fields': {
            'id': {'selector': 'a', 'attribute': 'href', 'transform': 'slug'},
            'title': {'selector': 'a'},
            'coverUrl': {'selector': 'img', 'attribute': 'src'},
          },
        },
      };
      urlPatterns['homePage'] = {'url': '/page/{page}/', 'inherits': 'home'};
      urlPatterns['detail'] = '/{id}';
      urlPatterns['chapter'] = '/{id}';

      final searchUrl = answers['searchUrl'] ?? '';
      if (searchUrl.isNotEmpty) {
        urlPatterns['search'] = {
          'url': searchUrl,
          'inherits': 'home',
        };
      }
    }

    // Detail fields
    final detailFields = <String, dynamic>{
      'title': {'selector': detailTitleSel},
      'coverUrl': {'selector': 'img', 'attribute': 'src'},
      'description': {'selector': 'p'},
      'author': {'selector': 'a[href*="/author/"]'},
      'artist': {'selector': 'a[href*="/artist/"]'},
      'genres': {'selector': 'a[href*="/genre/"]', 'multi': true},
      'tags': {'selector': 'a[href*="/tag/"]', 'multi': true},
      'status': {'selector': '[class*="status"]'},
    };

    final chaptersCfg = <String, dynamic>{
      'container': answers['chapterContainer'] ?? 'a[href*="chapter"]',
      'fields': {
        'id': {
          'selector': ':scope',
          'attribute': 'href',
        },
        'title': {
          'selector': answers['chapterTitleSel'] ?? 'a[href*="chapter"]'
        },
      },
    };

    // Reader
    Map<String, dynamic> readerCfg;
    if (readerMode == 'chapterDataScript') {
      readerCfg = {'mode': 'chapterDataScript'};
    } else {
      readerCfg = {
        'container': '.reading-content, .chapter-content',
        'images': {'selector': answers['readerImageSel'] ?? 'img'},
      };
    }

    return {
      'enabled': true,
      'urlPatterns': urlPatterns,
      'selectors': {
        'list': {
          'item': listSel,
          'fields': {
            'id': {
              'selector': 'a',
              'attribute': 'href',
              'transform': 'slug',
            },
            'title': {'selector': 'a'},
            'coverUrl': {'selector': 'img', 'attribute': 'src'},
          },
        },
        'detail': {'fields': detailFields, 'chapters': chaptersCfg},
        'reader': readerCfg,
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
        'pageParam': 'page',
      };
    }

    final searchUrl = answers['searchUrl'] ?? '/?s={query}';
    final queryParam = answers['searchQueryParam'] ?? 's';

    return {
      'searchMode': 'query-string',
      'endpoint': searchUrl,
      'queryParam': queryParam,
      'params': {
        'query': {
          'queryParam': queryParam,
          'type': 'text',
          'placeholder': 'Search...',
        },
      },
    };
  }

  static Map<String, Object?> _buildNetworkConfig(
      Map<String, String?> answers) {
    if (answers['needsHeaders'] != 'y' && answers['needsCloudflare'] != 'y') {
      return {};
    }

    return {
      'requiresBypass': answers['needsCloudflare'] == 'y',
      'headers': {
        'Referer': answers['homeUrl'] ?? '',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36',
      },
      'rateLimit': {
        'enabled': true,
        'requestsPerSecond': 1,
        'maxConcurrentRequests': 2,
      },
      if (answers['needsCloudflare'] == 'y')
        'cloudflare': {'bypassRequired': true},
    };
  }

  static String _buildNotes(Map<String, String?> answers) {
    final parts = <String>[];
    final cmsTheme = answers['cmsThemeType'] ?? '';
    if (cmsTheme.startsWith('madara')) {
      parts.add('WordPress Madara theme ($cmsTheme).');
    }
    final readerMode = answers['readerMode'] ?? 'directUrl';
    if (readerMode == 'chapterDataScript') {
      parts.add('Reader via chapterDataScript.');
    }
    if (!parts.isNotEmpty) {
      parts.add('Auto-generated config. Review selectors before use.');
    }
    return parts.join(' ');
  }
}
