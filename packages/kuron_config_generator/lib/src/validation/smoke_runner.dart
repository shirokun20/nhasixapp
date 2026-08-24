import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';
import 'negative_probes.dart';
import 'search_key_probe.dart';

/// Result of a single screen probe during live smoke validation.
class ScreenResult {
  const ScreenResult({
    required this.screen,
    required this.passed,
    this.itemCount = 0,
    this.failure,
  });

  final String screen;
  final bool passed;
  final int itemCount;
  final String? failure;

  @override
  String toString() =>
      passed ? '$screen: OK ($itemCount items)' : '$screen: FAIL — $failure';
}

/// Aggregate outcome of the 5-screen live smoke run.
class SmokeReport {
  const SmokeReport({
    required this.results,
    required this.fixtures,
    this.findings = const [],
  });

  final List<ScreenResult> results;

  /// Raw HTML per probed screen, for golden fixture emission.
  final Map<String, String> fixtures;

  /// Negative-case probe findings (D4) — advisory unless blocking.
  final List<ProbeFinding> findings;

  bool get allPassed =>
      results.every((r) => r.passed) && !findings.any((f) => f.isBlocking);
  List<ScreenResult> get failures =>
      results.where((r) => !r.passed).toList(growable: false);
}

/// Runs a generated scraper config through the real [GenericScraperAdapter]
/// and asserts the five app screens (home, search, detail, chapters, reader)
/// return usable data. Captures raw HTML per screen for fixture emission.
///
/// ponytail: probes are sequential and shallow (first item walked into
/// detail/reader); upgrade to parallel + multi-item sampling when a source
/// needs deeper coverage than "does the happy path work".
class SmokeRunner {
  SmokeRunner({Logger? logger}) : _logger = logger ?? Logger(level: Level.off);

  final Logger _logger;

  Future<SmokeReport> run(Map<String, dynamic> config) async {
    final baseUrl = config['baseUrl'] as String?;
    if (baseUrl == null || baseUrl.isEmpty) {
      return SmokeReport(
        results: [
          ScreenResult(
              screen: 'config', passed: false, failure: 'missing baseUrl'),
        ],
        fixtures: const {},
      );
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: ((config['network'] as Map?)?['headers'] as Map?)
          ?.cast<String, dynamic>(),
      // Live sites flake; treat any status as parseable so parser behavior
      // is what's under test, not HTTP status codes.
      validateStatus: (status) => status != null && status < 500,
    ));
    final adapter = GenericScraperAdapter(
      dio: dio,
      urlBuilder: GenericUrlBuilder(baseUrl: baseUrl),
      parser: GenericHtmlParser(logger: _logger),
      logger: _logger,
      sourceId: config['source'] as String? ?? 'smoke',
    );

    final results = <ScreenResult>[];
    final fixtures = <String, String>{};
    final findings = <ProbeFinding>[];

    // ── home ────────────────────────────────────────────────────────────────
    List<Content> homeItems = const [];
    var homeHtml = '';
    try {
      final result = await adapter.search(
        const SearchFilter(query: '', page: 1),
        config,
      );
      homeItems = result.items;
      homeHtml = await _fetchRaw(dio, baseUrl);
      if (homeItems.isEmpty) {
        results.add(
            ScreenResult(screen: 'home', passed: false, failure: '0 items'));
      } else if (homeItems.first.id.isEmpty || homeItems.first.title.isEmpty) {
        results.add(ScreenResult(
            screen: 'home',
            passed: false,
            itemCount: homeItems.length,
            failure: 'first item missing id/title'));
      } else {
        final relCovers = homeItems
            .where((c) =>
                c.coverUrl.startsWith('/') && !c.coverUrl.startsWith('//'))
            .length;
        results.add(ScreenResult(
            screen: 'home',
            passed: true,
            itemCount: homeItems.length,
            failure: relCovers > 0
                ? 'warning: $relCovers relative cover URLs'
                : null));
      }
    } catch (e) {
      results.add(
          ScreenResult(screen: 'home', passed: false, failure: e.toString()));
    }
    if (homeHtml.isNotEmpty) fixtures['home'] = homeHtml;
    findings.addAll(runDomProbes(homeHtml));
    final relFinding =
        probeRelativeCovers(homeItems.map((c) => c.coverUrl).toList(), baseUrl);
    if (relFinding != null) findings.add(relFinding);
    final badgeFinding =
        probeTitleBadges(homeItems.map((c) => c.title).toList());
    if (badgeFinding != null) findings.add(badgeFinding);

    // ── search ──────────────────────────────────────────────────────────────
    try {
      final result = await adapter.search(
        SearchFilter(query: 'a', page: 1),
        config,
      );
      results.add(ScreenResult(
          screen: 'search',
          passed: result.items.isNotEmpty,
          itemCount: result.items.length,
          failure: result.items.isEmpty ? '0 results for query "a"' : null));
      if (result.items.isNotEmpty) {
        // Phase 3: verify the search key actually filtered (keiyoushi ?q=
        // trap — wrong param silently returns unfiltered recents).
        final key = verifySearchKey(
          query: 'a',
          titles: result.items.map((c) => c.title).toList(),
        );
        if (key.finding != null) findings.add(key.finding!);
      }
    } catch (e) {
      results.add(
          ScreenResult(screen: 'search', passed: false, failure: e.toString()));
    }

    // Detail/chapters/reader need an id from home.
    if (homeItems.isEmpty) {
      for (final s in ['detail', 'chapters', 'reader']) {
        results.add(ScreenResult(
            screen: s,
            passed: false,
            failure: 'skipped — home yielded no items'));
      }
      return SmokeReport(
          results: results, fixtures: fixtures, findings: findings);
    }

    // ── detail ──────────────────────────────────────────────────────────────
    final contentId = homeItems.first.id;
    AdapterDetailResult? detail;
    try {
      detail = await adapter.fetchDetail(contentId, config);
      final hasPages = detail.content.pageCount > 0 ||
          detail.imageUrls.isNotEmpty ||
          (detail.content.chapters?.isNotEmpty ?? false);
      results.add(ScreenResult(
          screen: 'detail',
          passed: detail.content.title.isNotEmpty && hasPages,
          itemCount: detail.imageUrls.length,
          failure: !hasPages
              ? 'no pages or chapters for $contentId'
              : (detail.content.title.isEmpty ? 'empty title' : null)));
    } catch (e) {
      results.add(
          ScreenResult(screen: 'detail', passed: false, failure: e.toString()));
    }

    // ── chapters + reader ───────────────────────────────────────────────────
    final chapters = detail?.content.chapters;
    if (chapters == null || chapters.isEmpty) {
      results.add(const ScreenResult(
          screen: 'chapters',
          passed: false,
          failure: 'no chapters (gallery-only source?)'));
      results.add(const ScreenResult(
          screen: 'reader', passed: false, failure: 'skipped — no chapters'));
      return SmokeReport(
          results: results, fixtures: fixtures, findings: findings);
    }
    results.add(ScreenResult(
        screen: 'chapters', passed: true, itemCount: chapters.length));

    try {
      final chapterData =
          await adapter.fetchChapterImages(chapters.first.id, config);
      final images = chapterData?.images ?? const <String>[];
      final impurityFinding = probeReaderScopeImpurity(images);
      if (impurityFinding != null) findings.add(impurityFinding);
      if (images.isEmpty) {
        results.add(
            ScreenResult(screen: 'reader', passed: false, failure: '0 images'));
      } else {
        // Spot-check first image resolves to image/* content.
        final contentType = await _probeContentType(dio, images.first, config);
        final ok = contentType != null && contentType.startsWith('image/');
        results.add(ScreenResult(
            screen: 'reader',
            passed: ok,
            itemCount: images.length,
            failure: ok
                ? null
                : 'first image content-type "${contentType ?? 'error'}" '
                    'not image/*'));
      }
    } catch (e) {
      results.add(
          ScreenResult(screen: 'reader', passed: false, failure: e.toString()));
    }

    return SmokeReport(
        results: results, fixtures: fixtures, findings: findings);
  }

  Future<String> _fetchRaw(Dio dio, String path) async {
    try {
      final res = await dio.get<String>(
        path.startsWith('http') ? path : '/',
        options: Options(responseType: ResponseType.plain),
      );
      return res.data ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String?> _probeContentType(
    Dio dio,
    String url,
    Map<String, dynamic> config,
  ) async {
    try {
      final headers = (((config['network'] as Map?)?['imageHeaders'] as Map?) ??
              (config['network'] as Map?)?['headers'] as Map?)
          ?.cast<String, dynamic>();
      final res = await dio.head<Object?>(
        url,
        options: Options(headers: headers, followRedirects: true),
      );
      return res.headers.value('content-type');
    } catch (_) {
      // Some CDNs reject HEAD; fall back to ranged GET.
      try {
        final headers =
            (((config['network'] as Map?)?['imageHeaders'] as Map?) ??
                    (config['network'] as Map?)?['headers'] as Map?)
                ?.cast<String, dynamic>();
        final res = await dio.get<List<int>>(
          url,
          options: Options(
            headers: {...?headers, 'range': 'bytes=0-1023'},
            responseType: ResponseType.bytes,
          ),
        );
        return res.headers.value('content-type');
      } catch (_) {
        return null;
      }
    }
  }
}

/// Writes golden fixtures (raw HTML per screen + manifest.json) next to the
/// generated config.
class FixtureEmitter {
  FixtureEmitter({required this.outputDir, required this.sourceId});

  final String outputDir;
  final String sourceId;

  Directory get _fixtureDir => Directory('$outputDir/fixtures/$sourceId');

  void writeAll(Map<String, String> fixtures, Map<String, dynamic> config) {
    if (fixtures.isEmpty) return;
    _fixtureDir.createSync(recursive: true);
    for (final entry in fixtures.entries) {
      File('${_fixtureDir.path}/${entry.key}.html')
          .writeAsStringSync(entry.value);
    }
    File('${_fixtureDir.path}/manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source': sourceId,
        'baseUrl': config['baseUrl'],
        'probedAt': DateTime.now().toUtc().toIso8601String(),
        'screens': fixtures.keys.toList(),
      }),
    );
  }
}
