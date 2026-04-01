import 'package:flutter/material.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/pages/search/dynamic_form_search_ui.dart';
import 'package:nhasixapp/presentation/pages/search/form_based_search_ui.dart';
import 'package:nhasixapp/presentation/pages/search/query_string_search_ui.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

/// Advanced search route rendered fully from source config.
///
/// This replaces hardcoded tabs/fields and delegates rendering to existing
/// config-driven search widgets.
class AdvancedSearchScreen extends StatefulWidget {
  final String sourceId;

  const AdvancedSearchScreen({
    super.key,
    required this.sourceId,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  SearchConfig? _buildScraperQueryFallback(Map<String, dynamic>? rawMap) {
    final scraper = rawMap?['scraper'] as Map<String, dynamic>?;
    final urlPatterns = scraper?['urlPatterns'] as Map<String, dynamic>?;
    final searchPattern = urlPatterns?['search'];

    String? endpoint;
    if (searchPattern is String) {
      endpoint = searchPattern;
    } else if (searchPattern is Map<String, dynamic>) {
      endpoint = searchPattern['url'] as String?;
    }

    if (endpoint == null || endpoint.isEmpty) {
      return null;
    }

    return SearchConfig(
      searchMode: SearchMode.queryString,
      endpoint: endpoint,
      queryParam: 'q',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remoteConfig = getIt<RemoteConfigService>();
    final rawMap = remoteConfig.getRawConfig(widget.sourceId);
    final searchForm = remoteConfig.getSearchFormConfig(widget.sourceId);
    final searchConfig = remoteConfig.getSearchConfig(widget.sourceId) ??
        (searchForm == null ? _buildScraperQueryFallback(rawMap) : null);

    return AppScaffoldWithOffline(
      title: l10n?.advancedSearchTitle ?? 'Advanced Search',
      body: Builder(
        builder: (context) {
          if (searchConfig != null) {
            switch (searchConfig.searchMode) {
              case SearchMode.queryString:
                return QueryStringSearchUI(
                  config: searchConfig,
                  sourceId: widget.sourceId,
                );
              case SearchMode.formBased:
                return FormBasedSearchUI(
                  config: searchConfig,
                  sourceId: widget.sourceId,
                );
            }
          }

          if (searchForm != null) {
            return DynamicFormSearchUI(
              config: searchForm,
              sourceId: widget.sourceId,
            );
          }

          return _buildFallback(context);
        },
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Advanced search config unavailable for ${widget.sourceId}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Please check source configuration and try again.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
