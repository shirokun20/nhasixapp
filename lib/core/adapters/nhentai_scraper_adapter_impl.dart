import 'package:kuron_core/kuron_core.dart' as core;
import 'package:kuron_nhentai/kuron_nhentai.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart' as app_filter;
import 'package:nhasixapp/services/license_service.dart';

/// Custom exception for premium required access
class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException([this.message = 'Premium subscription required']);

  @override
  String toString() => 'PremiumRequiredException: $message';
}

/// Implementation of NhentaiScraperAdapter that delegates to RemoteDataSource.
///
/// Requires premium subscription to access Nhentai content.
class NhentaiScraperAdapterImpl implements NhentaiScraperAdapter {
  final RemoteDataSource _remoteDataSource;
  final LicenseService _licenseService;

  NhentaiScraperAdapterImpl(this._remoteDataSource, this._licenseService);

  void _checkPremium() {
    if (!_licenseService.isPremiumActive) {
      throw PremiumRequiredException('Nhentai requires premium subscription');
    }
  }

  @override
  Future<core.Content> getDetail(String contentId) async {
    _checkPremium();
    return await _remoteDataSource.getContentDetailViaApi(contentId);
  }

  @override
  Future<core.ContentListResult> getList({
    int page = 1,
    core.SortOption sort = core.SortOption.newest,
  }) async {
    _checkPremium();
    final appSort = _mapSortOption(sort);
    final result = await _remoteDataSource.getContentListWithPaginationViaApi(
      page: page,
      sortBy: appSort,
    );
    return _mapListResult(result, page);
  }

  @override
  Future<core.ContentListResult> getPopular({
    core.PopularTimeframe timeframe = core.PopularTimeframe.allTime,
    int page = 1,
  }) async {
    _checkPremium();
    app_filter.SortOption appSort = app_filter.SortOption.popular;
    switch (timeframe) {
      case core.PopularTimeframe.today:
        appSort = app_filter.SortOption.popularToday;
        break;
      case core.PopularTimeframe.week:
        appSort = app_filter.SortOption.popularWeek;
        break;
      case core.PopularTimeframe.allTime:
        appSort = app_filter.SortOption.popular;
        break;
    }

    final result = await _remoteDataSource.getContentListWithPaginationViaApi(
      page: page,
      sortBy: appSort,
    );
    return _mapListResult(result, page);
  }

  @override
  Future<List<core.Content>> getRandom({int count = 1}) async {
    _checkPremium();
    final List<core.Content> results = [];
    for (int i = 0; i < count; i++) {
      try {
        final content = await _remoteDataSource.getRandomContent();
        results.add(content);
      } catch (e) {
        // Ignore single failures in random batch
      }
    }
    return results;
  }

  @override
  Future<List<core.Content>> getRelated(String contentId) async {
    _checkPremium();
    final contents = await _remoteDataSource.getRelatedContentViaApi(contentId);
    return contents.cast<core.Content>();
  }

  @override
  Future<core.ContentListResult> search(core.SearchFilter filter) async {
    _checkPremium();
    final appFilter = _mapSearchFilter(filter);
    final result =
        await _remoteDataSource.searchContentWithPaginationViaApi(appFilter);
    return _mapListResult(result, filter.page);
  }

  // --- Mappers ---

  app_filter.SortOption _mapSortOption(core.SortOption sort) {
    switch (sort) {
      case core.SortOption.newest:
        return app_filter.SortOption.newest;
      case core.SortOption.popular:
        return app_filter.SortOption.popular;
      case core.SortOption.popularWeek:
        return app_filter.SortOption.popularWeek;
      case core.SortOption.popularToday:
        return app_filter.SortOption.popularToday;
      case core.SortOption.popularMonth:
        return app_filter.SortOption.popular;
    }
  }

  core.ContentListResult _mapListResult(Map<String, dynamic> result, int page) {
    final List<dynamic> rawContents = result['contents'];
    final List<core.Content> contents = rawContents.cast<core.Content>();

    final pagination = result['pagination'] as Map<String, dynamic>;
    final totalData = result['totalData'] as int? ?? 0;

    return core.ContentListResult(
      contents: contents,
      currentPage: page,
      totalPages: pagination['totalPages'] as int? ?? 1,
      totalCount: totalData,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrevious: pagination['hasPrevious'] as bool? ?? false,
    );
  }

  app_filter.SearchFilter _mapSearchFilter(core.SearchFilter filter) {
    app_filter.SortOption appSort = app_filter.SortOption.newest;
    switch (filter.sort) {
      case core.SortOption.newest:
        appSort = app_filter.SortOption.newest;
        break;
      case core.SortOption.popular:
        appSort = app_filter.SortOption.popular;
        break;
      case core.SortOption.popularWeek:
        appSort = app_filter.SortOption.popularWeek;
        break;
      case core.SortOption.popularToday:
        appSort = app_filter.SortOption.popularToday;
        break;
      case core.SortOption.popularMonth:
        appSort = app_filter.SortOption.popular;
        break;
    }

    final tags = <app_filter.FilterItem>[];
    final artists = <app_filter.FilterItem>[];
    final characters = <app_filter.FilterItem>[];
    final parodies = <app_filter.FilterItem>[];
    final groups = <app_filter.FilterItem>[];

    void processItems(List<core.FilterItem> items, bool isExcluded) {
      for (final item in items) {
        final appItem =
            app_filter.FilterItem(value: item.name, isExcluded: isExcluded);

        switch (item.type.toLowerCase()) {
          case 'artist':
            artists.add(appItem);
            break;
          case 'character':
            characters.add(appItem);
            break;
          case 'parody':
            parodies.add(appItem);
            break;
          case 'group':
            groups.add(appItem);
            break;
          case 'tag':
          default:
            tags.add(appItem);
            break;
        }
      }
    }

    processItems(filter.includeTags, false);
    processItems(filter.excludeTags, true);

    return app_filter.SearchFilter(
      query: filter.query,
      page: filter.page,
      sortBy: appSort,
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: filter.language,
      category: filter.category,
    );
  }
}
