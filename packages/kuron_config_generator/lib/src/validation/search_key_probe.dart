import 'negative_probes.dart';

/// Result of the search-key verification probe (Phase 3).
class SearchKeyResult {
  const SearchKeyResult({
    required this.verified,
    required this.matchRatio,
    this.finding,
  });

  /// True when ≥ half of result titles contain the query (or fuzzy match).
  final bool verified;

  /// Fraction of titles that matched the query.
  final double matchRatio;

  final ProbeFinding? finding;
}

/// Verifies that a search actually filtered by [query]: at least
/// [matchRatio] of [titles] must contain it (case-insensitive, per-word for
/// multi-word queries). A wrong query param silently returns unfiltered
/// recents — the keiyoushi `?q=` trap — so exact-zero matches block.
///
/// - ratio == 0 → blocking finding (wrong key / silent fail)
/// - 0 < ratio < 0.5 → warning (fuzzy site)
/// - ratio ≥ 0.5 → verified, no finding
SearchKeyResult verifySearchKey({
  required String query,
  required List<String> titles,
}) {
  if (query.isEmpty || titles.isEmpty) {
    return const SearchKeyResult(verified: false, matchRatio: 0);
  }
  final words =
      query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  var matched = 0;
  for (final t in titles) {
    final lower = t.toLowerCase();
    // Multi-word: any word present counts as a fuzzy hit; single word must
    // be contained.
    if (words.any(lower.contains)) matched++;
  }
  final ratio = matched / titles.length;

  if (matched == 0) {
    return SearchKeyResult(
      verified: false,
      matchRatio: ratio,
      finding: ProbeFinding(
        probe: 'search-key',
        severity: FindingSeverity.blocking,
        message: '0/${titles.length} results mention "$query" — search key is '
            'likely wrong (results are unfiltered recents)',
        suggestion: 'check searchForm queryParam against the site form',
      ),
    );
  }
  if (ratio < 0.5) {
    return SearchKeyResult(
      verified: true,
      matchRatio: ratio,
      finding: ProbeFinding(
        probe: 'search-key',
        severity: FindingSeverity.warning,
        message: 'only $matched/${titles.length} results mention "$query" — '
            'site search may be fuzzy or partially filtered',
        suggestion: null,
      ),
    );
  }
  return SearchKeyResult(verified: true, matchRatio: ratio);
}

// ── CMS detection confidence (D5) ────────────────────────────────────────

/// Per-signature hint hit counts from CMS detection.
class CmsConfidence {
  const CmsConfidence({
    required this.cmsId,
    required this.hits,
    required this.totalHints,
  });

  final String cmsId;
  final int hits;
  final int totalHints;

  /// D5 threshold: below 0.6 the CMS guess is not trustworthy.
  static const double confidentThreshold = 0.6;

  double get ratio => totalHints == 0 ? 0 : hits / totalHints;
  bool get confident => ratio >= confidentThreshold;

  ProbeFinding? get needsReviewFinding => confident
      ? null
      : ProbeFinding(
          probe: 'cms-confidence',
          severity: FindingSeverity.info,
          message: '$cmsId signature confidence ${(ratio * 100).round()}% '
              '(<${(confidentThreshold * 100).round()}%) — selectors are generic guesses',
          suggestion: 'review all suggested selectors manually',
        );

  @override
  String toString() => '$cmsId: $hits/$totalHints hints '
      '(${(ratio * 100).round()}%)${confident ? '' : ' — needsReview'}';
}
