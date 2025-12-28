import 'package:kuron_core/kuron_core.dart' as core;
import 'package:kuron_nhentai/kuron_nhentai.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart' as app_filter;

/// Implementation of NhentaiScraperAdapter that delegates to RemoteDataSource.
///
/// Since ContentModel now extends core.Content, we can return it directly
/// without manual mapping.
class NhentaiScraperAdapterImpl implements NhentaiScraperAdapter {
  final RemoteDataSource _remoteDataSource;

  NhentaiScraperAdapterImpl(this._remoteDataSource);

  @override
  Future<core.Content> getDetail(String contentId) async {
    // ContentModel extends core.Content, so return directly
    return await _remoteDataSource.getContentDetailViaApi(contentId);
  }

  @override
  Future<core.ContentListResult> getList({
    int page = 1,
    core.SortOption sort = core.SortOption.newest,
  }) async {
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
    final List<core.Content> results = [];
    for (int i = 0; i < count; i++) {
      try {
        // ContentModel extends core.Content
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
    final contents = await _remoteDataSource.getRelatedContentViaApi(contentId);
    // ContentModel list is already List<core.Content> compatible
    return contents.cast<core.Content>();
  }

  @override
  Future<core.ContentListResult> search(core.SearchFilter filter) async {
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
    // Contents are already ContentModel which extends core.Content
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
    // Map SortOption
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

    // Convert core.FilterItem to app FilterItem
    final tags = <app_filter.FilterItem>[];
    final excludeTags = <app_filter.FilterItem>[];

    for (final item in filter.includeTags) {
      tags.add(app_filter.FilterItem(value: item.name, isExcluded: false));
    }
    for (final item in filter.excludeTags) {
      excludeTags
          .add(app_filter.FilterItem(value: item.name, isExcluded: true));
    }

    return app_filter.SearchFilter(
      query: filter.query,
      page: filter.page,
      sortBy: appSort,
      tags: tags,
      artists: const [], // Map from filter if needed
      characters: const [],
      parodies: const [],
      groups: const [],
      language: filter.language,
      category: filter.category,
    );
  }
}
