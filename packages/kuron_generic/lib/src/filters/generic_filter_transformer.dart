/// Transforms [SearchFilter] and [FilterList] state into URL params / query
/// values understood by a generic source config.
library;

import 'package:kuron_core/kuron_core.dart';

/// Result of a filter transformation — a flat map of query-parameter key/value
/// pairs ready to be appended to a URL.
class FilterTransformResult {
  /// Query parameters derived from the active filter state.
  final Map<String, String> params;

  /// Page number (resolved from [SearchFilter.page]).
  final int page;

  const FilterTransformResult({required this.params, required this.page});
}

/// Transforms a [SearchFilter] into a flat `Map<String, String>` of query
/// parameters using the `searchConfig` block from a source's raw config JSON.
///
/// Config keys consulted (under `searchConfig`):
/// - `queryParam`      — name of the text-search parameter (default: `"q"`)
/// - `pageParam`       — name of the pagination parameter (default: `"page"`)
/// - `sortParam`       — name of the sort parameter (default: `"sort"`)
/// - `sortValues`      — map of [SortOption] enum name → provider sort value
/// - `languageParam`   — name of the language parameter
/// - `tagParam`        — name of the include-tag parameter
/// - `excludeTagParam` — name of the exclude-tag parameter
class GenericFilterTransformer {
  const GenericFilterTransformer();

  /// Transform [filter] using the `searchConfig` block from [rawConfig].
  FilterTransformResult transform(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) {
    final searchConfig =
        (rawConfig['searchConfig'] as Map<String, dynamic>?) ?? {};

    final queryParam = (searchConfig['queryParam'] as String?) ?? 'q';
    final pageParam = (searchConfig['pageParam'] as String?) ?? 'page';
    final sortParam = (searchConfig['sortParam'] as String?) ?? 'sort';
    final sortValues = (searchConfig['sortValues'] as Map<String, dynamic>?)
            ?.cast<String, String>() ??
        {};
    final languageParam = searchConfig['languageParam'] as String?;
    final tagParam = (searchConfig['tagParam'] as String?) ?? 'tag';
    final excludeTagParam = searchConfig['excludeTagParam'] as String?;

    final params = <String, String>{};

    // Text query
    if (filter.query.isNotEmpty) {
      params[queryParam] = filter.query;
    }

    // Pagination
    params[pageParam] = filter.page.toString();

    // Sort — map SortOption enum name to provider-specific value
    final sortKey = filter.sort.name;
    final sortValue = sortValues[sortKey];
    if (sortValue != null) {
      params[sortParam] = sortValue;
    } else if (sortKey.isNotEmpty) {
      params[sortParam] = sortKey;
    }

    // Language
    if (languageParam != null &&
        filter.language != null &&
        filter.language!.isNotEmpty) {
      params[languageParam] = filter.language!;
    }

    // Include tags — joined with comma; URL builder handles encoding
    if (filter.includeTags.isNotEmpty) {
      params[tagParam] = filter.includeTags.join(',');
    }

    // Exclude tags
    if (excludeTagParam != null && filter.excludeTags.isNotEmpty) {
      params[excludeTagParam] = filter.excludeTags.join(',');
    }

    return FilterTransformResult(params: params, page: filter.page);
  }

  /// Transform a [FilterList] (active filter states) into additional query
  /// params, using the filter's [SourceFilter.name] as the param key.
  ///
  /// Each filter type contributes differently:
  /// - [TextSourceFilter] → `{name}: state`
  /// - [SelectSourceFilter] → `{name}: options[state]`
  /// - [SortSourceFilter] → `{name}: options[state.index]` (if non-null)
  /// - [CheckBoxSourceFilter] → `{name}: "1"` when checked
  /// - [TriStateSourceFilter] → contributed to include/exclude param lists
  Map<String, String> transformFilterList(FilterList filters) {
    final params = <String, String>{};

    for (final filter in filters) {
      final key = filter.name;
      switch (filter) {
        case TextSourceFilter(:final state):
          if (state.isNotEmpty) params[key] = state;

        case CheckBoxSourceFilter(:final state):
          if (state) params[key] = '1';

        case SelectSourceFilter(:final state, :final options):
          if (state >= 0 && state < options.length) {
            params[key] = options[state];
          }

        case SortSourceFilter(:final state, :final options):
          if (state != null &&
              state.index >= 0 &&
              state.index < options.length) {
            final direction = state.ascending ? 'asc' : 'desc';
            params[key] = '${options[state.index]}:$direction';
          }

        case TriStateSourceFilter(:final state, :final name):
          // TriState filters use separate include/exclude buckets.
          // Callers that need fine-grained control should handle these
          // directly. Here we append to generic include/exclude lists.
          if (state == TriStateValue.include) {
            final existing = params['include'] ?? '';
            params['include'] = existing.isEmpty ? name : '$existing,$name';
          } else if (state == TriStateValue.exclude) {
            final existing = params['exclude'] ?? '';
            params['exclude'] = existing.isEmpty ? name : '$existing,$name';
          }

        case GroupSourceFilter(:final state):
          // Recurse into children
          final childParams = transformFilterList(state);
          params.addAll(childParams);

        default:
          break;
      }
    }

    return params;
  }
}
