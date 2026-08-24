import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

/// Severity of a negative-probe finding.
enum FindingSeverity { info, warning, blocking }

/// One negative-case probe result. Probes are pure functions over a parsed
/// page (D4) — no network, no adapter state.
class ProbeFinding {
  const ProbeFinding({
    required this.probe,
    required this.severity,
    required this.message,
    this.suggestion,
  });

  final String probe;
  final FindingSeverity severity;
  final String message;

  /// Config-level fix hint, e.g. the attribute chain to add.
  final String? suggestion;

  bool get isBlocking => severity == FindingSeverity.blocking;

  @override
  String toString() {
    final s = switch (severity) {
      FindingSeverity.blocking => 'BLOCKING',
      FindingSeverity.warning => 'WARN',
      FindingSeverity.info => 'INFO',
    };
    return '[$s] $probe: $message${suggestion == null ? '' : ' — $suggestion'}';
  }
}

// ── Probe 1: relative / protocol-relative covers ─────────────────────────

/// Flags cover URLs that are relative (`/x`) or protocol-relative (`//x`).
/// The adapter resolves them against baseUrl, but a config that *emits*
/// relative URLs usually means the selector grabbed a lazy placeholder.
ProbeFinding? probeRelativeCovers(List<String> coverUrls, String baseUrl) {
  var rel = 0, protoRel = 0;
  for (final url in coverUrls) {
    if (url.startsWith('//')) {
      protoRel++;
    } else if (url.startsWith('/') && !url.startsWith('http')) {
      rel++;
    }
  }
  if (rel == 0 && protoRel == 0) return null;
  return ProbeFinding(
    probe: 'relative-covers',
    severity: FindingSeverity.warning,
    message:
        '$rel relative + $protoRel protocol-relative cover URL(s) of ${coverUrls.length}',
    suggestion: 'resolve against $baseUrl or fix cover selector/attribute',
  );
}

// ── Probe 2: lazy-load attribute chains ──────────────────────────────────

const _lazyAttrs = [
  'data-src',
  'data-original',
  'data-lazy-src',
  'data-pagespeed-lazy-src',
  'data-cfsrc',
  'data-url',
];

/// Detects `<img src>` values that look like placeholders while the real
/// image lives in a lazy attribute. Returns a finding naming the attribute
/// the config's fallback chain must include.
ProbeFinding? probeLazyAttributes(Document doc, {String scope = 'img'}) {
  final imgs = doc.querySelectorAll(scope);
  if (imgs.isEmpty) return null;

  for (final attr in _lazyAttrs) {
    var populated = 0;
    for (final img in imgs) {
      final lazy = img.attributes[attr];
      final src = img.attributes['src'];
      // Lazy attr holds a real image while src is empty/placeholder/data URI.
      if (lazy != null &&
          lazy.startsWith('http') &&
          (src == null || src.isEmpty || src.startsWith('data:'))) {
        populated++;
      }
    }
    if (populated > 0 && populated >= imgs.length ~/ 2) {
      return ProbeFinding(
        probe: 'lazy-attributes',
        severity: FindingSeverity.warning,
        message: '$populated/${imgs.length} images carry real URL in "$attr" '
            'while src is empty/placeholder',
        suggestion: 'add "$attr" to image attribute fallback chain',
      );
    }
  }
  return null;
}

// ── Probe 3: single-page pagination ──────────────────────────────────────

/// Compares page-1 and page-2 item id sets. Identical content or an error
/// on page 2 means the source has no real pagination — emitting a load-more
/// pattern would produce an infinite/duplicate loop in the app.
///
/// [page2ItemIds] = ids parsed from page 2; [page2Failed] = fetch/parse of
/// page 2 threw or returned non-200.
ProbeFinding? probeSinglePagePagination({
  required Set<String> page1ItemIds,
  Set<String>? page2ItemIds,
  bool page2Failed = false,
}) {
  if (page1ItemIds.isEmpty) return null; // home probe already reports this
  if (page2Failed || page2ItemIds == null || page2ItemIds.isEmpty) {
    return ProbeFinding(
      probe: 'single-page-pagination',
      severity: FindingSeverity.info,
      message: 'page 2 unavailable — source appears single-page',
      suggestion: 'omit pagination pattern (or keep paged mode off)',
    );
  }
  final overlap =
      page1ItemIds.intersection(page2ItemIds).length / page2ItemIds.length;
  if (overlap >= 0.9) {
    return ProbeFinding(
      probe: 'single-page-pagination',
      severity: FindingSeverity.warning,
      message: 'page 2 is ${(overlap * 100).round()}% identical to page 1 — '
          'pagination likely decorative',
      suggestion: 'verify pagination pattern or drop it',
    );
  }
  return null;
}

// ── Probe 4: title badge pollution ───────────────────────────────────────

final _badgePattern =
    RegExp(r'^\s*(18\+|NEW|HOT|UPDATE|BARU|ONGOING)\s*', caseSensitive: false);

/// Flags titles that begin with badge spans (`18+`, `NEW`, `HOT`, …).
/// Suggests a title transform so list titles render clean.
ProbeFinding? probeTitleBadges(List<String> titles) {
  var polluted = 0;
  for (final t in titles) {
    if (_badgePattern.hasMatch(t)) polluted++;
  }
  if (polluted == 0) return null;
  return ProbeFinding(
    probe: 'title-badges',
    severity: FindingSeverity.warning,
    message: '$polluted/${titles.length} titles start with a badge prefix',
    suggestion: 'add title transform stripping leading badges '
        '(e.g. regex ^\\s*(18\\+|NEW|HOT|UPDATE)\\\\s*)',
  );
}

// ── Probe 5: reader scope impurity ───────────────────────────────────────

final _impureHint = RegExp(
    r'(logo|banner|thumb|avatar|icon|related|recommend|next|prev)',
    caseSensitive: false);

/// Checks reader image candidates for non-page images (logos, related
/// thumbnails). Heuristic: URL path contains logo/thumb/banner-ish segments
/// or the count of tiny distinct-host images exceeds half.
ProbeFinding? probeReaderScopeImpurity(List<String> readerImageUrls) {
  if (readerImageUrls.length < 3) return null;
  final impure = readerImageUrls
      .where((u) => _impureHint.hasMatch(Uri.tryParse(u)?.path ?? ''))
      .toList();
  if (impure.isEmpty) return null;
  return ProbeFinding(
    probe: 'reader-scope-impurity',
    severity: FindingSeverity.warning,
    message: '${impure.length}/${readerImageUrls.length} reader URLs look like '
        'non-page assets (logo/thumb/banner): ${impure.take(2).join(', ')}',
    suggestion: 'narrow reader container/images selector to page images only',
  );
}

// ── Convenience: parse raw HTML once, run DOM probes ─────────────────────

/// Runs all DOM-only probes ([probeLazyAttributes]) over [rawHtml].
List<ProbeFinding> runDomProbes(String rawHtml) {
  final findings = <ProbeFinding>[];
  if (rawHtml.isEmpty) return findings;
  final doc = parser.parse(rawHtml);
  final lazy = probeLazyAttributes(doc);
  if (lazy != null) findings.add(lazy);
  return findings;
}
