/// CMS signatures and matched selector candidates.
library;

/// A known CMS pattern we can detect from HTML.
class CmsSignature {
  CmsSignature({
    required this.id,
    required this.hints,
    required this.selectors,
  });

  final String id;
  final List<String> hints;
  final Map<String, String> selectors;

  static final List<CmsSignature> known = [
    // WordPress Madara / Manga+Press
    CmsSignature(
      id: 'madara',
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
        'detail.cover': 'img[class*="cover"]',
        'detail.author': 'a[href*="/author/"]',
        'detail.artist': 'a[href*="/artist/"]',
        'detail.genre': 'a[href*="/genre/"]',
        'detail.tags': 'a[href*="/tag/"]',
        'chapters.item': 'a[href*="chapter"]',
        'reader.image': 'img[class*="page-image"], .reading-content img',
      },
    ),

    // Generic WordPress (any theme)
    CmsSignature(
      id: 'wordpress',
      hints: ['wp-content', 'wp-json', 'wordpress'],
      selectors: {
        'list.item': 'article, .post, .entry',
        'list.title': 'h1, h2 a, .entry-title a',
        'list.cover': 'img',
        'detail.title': 'h1',
        'chapters.item': 'a[href*="chapter"], a[href*="episode"]',
        'reader.image': 'img',
      },
    ),

    // Custom manga site (no known CMS)
    CmsSignature(
      id: 'custom',
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

  /// Score how likely this CMS matches the HTML.
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
    required this.confidence,
    required this.selectors,
  });

  final String cmsId;
  final double confidence; // 0.0 - 1.0
  final Map<String, String> selectors;

  bool get isKnown => cmsId != 'custom';

  @override
  String toString() => 'CmsResult($cmsId, ${(confidence * 100).round()}%)';
}

/// Detect CMS from HTML and return suggested selectors.
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
  final confidence = bestScore / (detected.hints.isEmpty ? 1 : detected.hints.length);

  return CmsResult(
    cmsId: detected.id,
    confidence: confidence.clamp(0.0, 1.0),
    selectors: Map.from(detected.selectors),
  );
}
