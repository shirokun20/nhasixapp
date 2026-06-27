/// CMS signatures and matched selector candidates.
class CmsSignature {
  CmsSignature({
    required this.id,
    required this.themeType,
    required this.hints,
    required this.selectors,
    this.urlPatterns,
    this.searchDefaults,
    this.readerDefaults,
  });

  final String id;
  final String themeType; // 'madara-classic', 'madara-tailwind', 'wordpress', 'custom'
  final List<String> hints;
  final Map<String, String> selectors;
  final Map<String, String>? urlPatterns;
  final Map<String, Object?>? searchDefaults;
  final Map<String, Object?>? readerDefaults;

  static final List<CmsSignature> known = [
    // WordPress Madara — classic (standard themes)
    CmsSignature(
      id: 'madara',
      themeType: 'madara-classic',
      hints: [
        'wp-content/themes/madara',
        'madara',
        'class="manga-item',
        'class="page-item',
        '.tab-summary',
        'class="wp-manga',
      ],
      selectors: {
        'list.item': '.page-item, .grid-item',
        'list.title': 'a[href*="/manhwa/"], a[title]',
        'list.cover': 'img',
        'detail.title': 'h1',
        'detail.cover': 'img[class*="cover"], .summary_image img, .tab-summary img',
        'detail.author': 'a[href*="/author/"]',
        'detail.artist': 'a[href*="/artist/"]',
        'detail.genre': 'a[href*="/genre/"]',
        'detail.tags': 'a[href*="/tag/"]',
        'detail.status': '.post-status .status, .summary-content .status',
        'chapters.item': 'a[href*="chapter"]',
        'reader.image': 'img[class*="page-image"], .reading-content img',
      },
      urlPatterns: {
        'homePage': '/page/{page}/',
        'search': '/?s={query}&post_type=wp-manga',
        'searchPage': '/page/{page}/?s={query}&post_type=wp-manga',
        'genreSearch': '/genre/{tag}/',
        'genreSearchPage': '/genre/{tag}/page/{page}/',
        'detail': '/manhwa/{id}',
        'chapter': '/manhwa/{id}',
      },
      searchDefaults: {
        'searchUrl': '/?s={query}&post_type=wp-manga',
        'queryParam': 's',
        'postType': 'wp-manga',
      },
    ),

    // WordPress Madara — Tailwind-customized (modern child theme like manhwaread)
    CmsSignature(
      id: 'madara',
      themeType: 'madara-tailwind',
      hints: [
        'wp-theme-manhwaread',
        'manga-item loop-item',
        'clipboard-copy',
        'chapter-item',
        'chapter-item__name',
        'chapterData',
        'postid-',
      ],
      selectors: {
        'list.item': '.manga-item',
        'list.title': 'h3 a[href*="/manhwa/"]',
        'list.cover': '.manga-item img',
        'detail.title': 'h1.clipboard-copy',
        'detail.cover': 'img[src*="mancover"][src*="manhwaread-"]',
        'detail.author': 'a[href*="/author/"]',
        'detail.artist': 'a[href*="/artist/"]',
        'detail.genre': 'a[href*="/genre/"]',
        'detail.tags': 'a[href*="/tag/"]',
        'detail.status': '[class*="status"]',
        'chapters.item': 'a.chapter-item',
        'reader.image': 'img.reading-image',
      },
      urlPatterns: {
        'homePage': '/page/{page}/',
        'search': '/?s={query}&post_type=wp-manga',
        'searchPage': '/page/{page}/?s={query}&post_type=wp-manga',
        'genreSearch': '/genre/{tag}/',
        'genreSearchPage': '/genre/{tag}/page/{page}/',
        'tagSearch': '/tag/{tag}/',
        'tagSearchPage': '/tag/{tag}/page/{page}/',
        'detail': '/manhwa/{id}',
        'chapter': '/manhwa/{id}',
      },
      searchDefaults: {
        'searchUrl': '/?s={query}&post_type=wp-manga',
        'queryParam': 's',
        'postType': 'wp-manga',
      },
    ),

    // Generic WordPress (any theme)
    CmsSignature(
      id: 'wordpress',
      themeType: 'wordpress',
      hints: ['wp-content', 'wp-json', 'wordpress'],
      selectors: {
        'list.item': 'article, .post, .entry',
        'list.title': 'h1, h2 a, .entry-title a',
        'list.cover': 'img',
        'detail.title': 'h1',
        'chapters.item': 'a[href*="chapter"], a[href*="episode"]',
        'reader.image': 'img',
      },
      urlPatterns: {
        'homePage': '/page/{page}/',
        'search': '/?s={query}',
      },
      searchDefaults: {
        'queryParam': 's',
      },
    ),

    // Custom manga site (no known CMS)
    CmsSignature(
      id: 'custom',
      themeType: 'custom',
      hints: [],
      selectors: {
        'list.item': '[class*="item"], [class*="card"]',
        'list.title': 'a[href*="/manga"], a[href*="/manhwa"], a[href*="/series"]',
        'list.cover': 'img',
        'detail.title': 'h1',
        'reader.image': 'img',
      },
    ),
  ];

  int score(String html) {
    var s = 0;
    for (final h in hints) {
      if (h.isEmpty) continue;
      if (html.contains(h)) s++;
    }
    return s;
  }
}

/// Result from CMS detection.
class CmsResult {
  CmsResult({
    required this.cmsId,
    required this.themeType,
    required this.confidence,
    required this.selectors,
    this.urlPatterns,
    this.searchDefaults,
    this.readerDefaults,
  });

  final String cmsId;
  final String themeType;
  final double confidence;
  final Map<String, String> selectors;
  final Map<String, String>? urlPatterns;
  final Map<String, Object?>? searchDefaults;
  final Map<String, Object?>? readerDefaults;

  bool get isKnown => cmsId != 'custom';

  @override
  String toString() =>
      'CmsResult($cmsId/$themeType, ${(confidence * 100).round()}%)';
}

/// Detect CMS from HTML and return suggested selectors + defaults.
CmsResult detectCms(String html) {
  CmsSignature? best;
  var bestScore = 0;

  for (final cms in CmsSignature.known) {
    final s = cms.score(html);
    if (s > bestScore) {
      bestScore = s;
      best = cms;
    }
  }

  final detected = best ?? CmsSignature.known.last;
  final confidence = bestScore /
      (detected.hints.isEmpty ? 1 : detected.hints.length);

  return CmsResult(
    cmsId: detected.id,
    themeType: detected.themeType,
    confidence: confidence.clamp(0.0, 1.0),
    selectors: Map.from(detected.selectors),
    urlPatterns: detected.urlPatterns != null
        ? Map.from(detected.urlPatterns!)
        : null,
    searchDefaults: detected.searchDefaults != null
        ? Map.from(detected.searchDefaults!)
        : null,
    readerDefaults: detected.readerDefaults != null
        ? Map.from(detected.readerDefaults!)
        : null,
  );
}
