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
import 'package:nhasixapp/presentation/pages/search/search_form_contract_adapter.dart';
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
  int _configReloadNonce = 0;

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

  bool _shouldUseLegacySearchUi(SearchConfig config) {
    if (config.filterSupport != null) return true;
    if (config.searchMode == SearchMode.queryString) {
      return config.textFields?.isNotEmpty == true ||
          config.radioGroups?.isNotEmpty == true ||
          config.checkboxGroups?.isNotEmpty == true;
    }
    return false;
  }

  Widget _buildLegacySearchUi(SearchConfig config, String sourceId) {
    switch (config.searchMode) {
      case SearchMode.queryString:
        return QueryStringSearchUI(
          key: _searchUiKey(sourceId),
          config: config,
          sourceId: sourceId,
          initialQuery: widget.query,
          reloadSignal: _configReloadNonce,
        );
      case SearchMode.formBased:
        return FormBasedSearchUI(
          key: _searchUiKey(sourceId),
          config: config,
          sourceId: sourceId,
          reloadSignal: _configReloadNonce,
        );
    }
  }

  Key _searchUiKey(String sourceId) => ValueKey('search-ui-$sourceId');

  Future<void> _reloadSearchUi(String sourceId) async {
    setState(() {
      _configReloadNonce++;
    });

    context.read<SourceCubit>().refreshSources();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reloading search filters'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldWithOffline(
      title: AppLocalizations.of(context)?.searchTitle ?? 'Search',
      actions: [
        IconButton(
          tooltip: 'Reload search UI',
          onPressed: () => _reloadSearchUi(
            context.read<SourceCubit>().state.activeSource?.id ?? 'nhentai',
          ),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: BlocBuilder<SourceCubit, SourceState>(
        builder: (context, sourceState) {
          final sourceId = sourceState.activeSource?.id ?? 'nhentai';
          final remoteConfig = getIt<RemoteConfigService>();
          final rawMap = remoteConfig.getRawConfig(sourceId);
          final canonicalSearchForm =
              remoteConfig.getCanonicalSearchForm(sourceId);
          final searchForm = remoteConfig.getSearchFormConfig(sourceId);
          final searchConfig = remoteConfig.getSearchConfig(sourceId) ??
              (searchForm == null && canonicalSearchForm == null
                  ? _buildScraperQueryFallback(rawMap)
                  : null);

          // Priority:
          // 1) Canonical package-side contract (searchForm/searchConfig/inference)
          // 2) Legacy explicit searchConfig fallback
          // 3) Legacy searchForm fallback
          // 4) scraper query fallback when only URL pattern exists
          if (searchConfig != null && _shouldUseLegacySearchUi(searchConfig)) {
            return _buildLegacySearchUi(searchConfig, sourceId);
          } else if (canonicalSearchForm != null) {
            return DynamicFormSearchUI(
              key: _searchUiKey(sourceId),
              config: SearchFormContractAdapter.toSearchFormConfig(
                  canonicalSearchForm),
              sourceId: sourceId,
              canonicalContract: canonicalSearchForm,
              reloadSignal: _configReloadNonce,
            );
          } else if (searchConfig != null) {
            return _buildLegacySearchUi(searchConfig, sourceId);
          }

          if (searchForm != null) {
            return DynamicFormSearchUI(
              key: _searchUiKey(sourceId),
              config: searchForm,
              sourceId: sourceId,
              reloadSignal: _configReloadNonce,
            );
          }

          return _buildFallbackUI(sourceId);
        },
      ),
    );
  }

  Widget _buildFallbackUI(String sourceId) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              l10n.searchConfigUnavailable(sourceId),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkInternetOrReload,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _reloadSearchUi(sourceId),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retrySearch),
            ),
          ],
        ),
      ),
    );
  }
}
