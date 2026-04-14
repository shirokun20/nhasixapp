import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/source/source_cubit.dart';
import 'package:nhasixapp/presentation/cubits/source/source_state.dart';
import 'package:nhasixapp/presentation/pages/search/dynamic_form_search_ui.dart';
import 'package:nhasixapp/presentation/pages/search/form_based_search_ui.dart';
import 'package:nhasixapp/presentation/pages/search/query_string_search_ui.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

class SearchScreen extends StatefulWidget {
  final String? query;

  const SearchScreen({
    super.key,
    this.query,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    return AppScaffoldWithOffline(
      title: AppLocalizations.of(context)?.searchTitle ?? 'Search',
      body: BlocBuilder<SourceCubit, SourceState>(
        builder: (context, sourceState) {
          final sourceId = sourceState.activeSource?.id ?? 'nhentai';
          final remoteConfig = getIt<RemoteConfigService>();
          final rawMap = remoteConfig.getRawConfig(sourceId);
          final searchForm = remoteConfig.getSearchFormConfig(sourceId);
          final searchConfig = remoteConfig.getSearchConfig(sourceId) ??
              (searchForm == null ? _buildScraperQueryFallback(rawMap) : null);

          // Priority:
          // 1) Explicit searchConfig from source config (nhentai/crotpedia, etc)
          // 2) searchForm dynamic UI
          // 3) scraper query fallback when only URL pattern exists
          if (searchConfig != null) {
            switch (searchConfig.searchMode) {
              case SearchMode.queryString:
                return QueryStringSearchUI(
                  config: searchConfig,
                  sourceId: sourceId,
                  initialQuery: widget.query,
                );
              case SearchMode.formBased:
                return FormBasedSearchUI(
                  config: searchConfig,
                  sourceId: sourceId,
                );
            }
          }

          if (searchForm != null) {
            return DynamicFormSearchUI(
              config: searchForm,
              sourceId: sourceId,
            );
          }

          return _buildFallbackUI(sourceId);
        },
      ),
    );
  }

  Widget _buildFallbackUI(String sourceId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.searchConfigUnavailable(sourceId),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.checkInternetOrReload,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
