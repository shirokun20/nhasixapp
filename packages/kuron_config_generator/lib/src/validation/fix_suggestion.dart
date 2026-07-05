import 'report_parser.dart';

/// A mapping from a validator diagnostic code to a human-readable fix instruction.
class FixSuggestion {
  const FixSuggestion({
    required this.diagnosticCode,
    required this.suggestionText,
    this.targetFeature,
    this.configField,
  });

  /// The diagnostic code this suggestion addresses (e.g. `schemaVersionMissing`).
  final String diagnosticCode;

  /// Human-readable fix instruction text.
  final String suggestionText;

  /// The feature this suggestion targets, if applicable (e.g. `reader`).
  final String? targetFeature;

  /// The specific config field to modify, if applicable (e.g. `scraper.selectors.reader`).
  final String? configField;

  factory FixSuggestion.fromJson(Map<String, dynamic> json) {
    return FixSuggestion(
      diagnosticCode: json['diagnosticCode'] as String,
      suggestionText: json['suggestionText'] as String,
      targetFeature: json['targetFeature'] as String?,
      configField: json['configField'] as String?,
    );
  }
}

/// Maps validator diagnostic codes to [FixSuggestion] instances.
class FixSuggestionMapper {
  FixSuggestionMapper._();

  /// Static mapping of diagnostic codes to fix suggestions.
  static const Map<String, FixSuggestion> kFixSuggestions = {
    'schemaVersionMissing': FixSuggestion(
      diagnosticCode: 'schemaVersionMissing',
      suggestionText: 'Add `schemaVersion: 2.0` to the config.',
      configField: 'schemaVersion',
    ),
    'contentIdPatternMissing': FixSuggestion(
      diagnosticCode: 'contentIdPatternMissing',
      suggestionText:
          'Add a `contentIdPattern` that matches series slugs in the URL (e.g., `/([^/]+)`).',
      configField: 'contentIdPattern',
    ),
    'homeUrlUnreachable': FixSuggestion(
      diagnosticCode: 'homeUrlUnreachable',
      suggestionText:
          'Verify `baseUrl` and that the site is accessible — consider adding `headers` or `cloudflare.bypassEnabled` if blocked.',
      configField: 'baseUrl',
    ),
    'reader.configError': FixSuggestion(
      diagnosticCode: 'reader.configError',
      suggestionText:
          'Check `scraper.selectors.reader` — if the site uses `chapterDataScript`, enable with `imageMode.chapterDataScript` in `requiredPrimitives`.',
      targetFeature: 'reader',
    ),
    'search.configError': FixSuggestion(
      diagnosticCode: 'search.configError',
      suggestionText:
          'Verify `searchForm` URL pattern, query parameter, and that the search results list selector matches actual HTML.',
      targetFeature: 'search',
    ),
    'download.configError': FixSuggestion(
      diagnosticCode: 'download.configError',
      suggestionText:
          'Check `reader` selector — downloads reuse the reader image pipeline. If the site uses `chapterDataScript`, add `imageMode.chapterDataScript` to `requiredPrimitives`.',
      targetFeature: 'download',
    ),
  };

  /// Maps a list of [ReportDiagnostic]s to a list of [FixSuggestion]s.
  /// Known codes are looked up in [kFixSuggestions]; unknown codes get a
  /// generic fallback (R3.8).
  static List<FixSuggestion> map(List<ReportDiagnostic> diagnostics) {
    return diagnostics.map((d) {
      final known = kFixSuggestions[d.code];
      if (known != null) return known;
      // R3.8: generic fallback
      final msg = d.feature != null
          ? 'Review the feature `${d.feature}` — see diagnostic: `${d.message}`.'
          : 'Review the config — see diagnostic: `${d.message}`.';
      return FixSuggestion(
        diagnosticCode: d.code,
        suggestionText: msg,
        targetFeature: d.feature,
      );
    }).toList();
  }
}
