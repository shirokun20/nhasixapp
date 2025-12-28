import 'package:kuron_core/kuron_core.dart' as core;
import 'package:kuron_nhentai/kuron_nhentai.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/domain/entities/content.dart' as app_content;
import 'package:nhasixapp/domain/entities/tag.dart' as app_tag;
import 'package:nhasixapp/domain/entities/search_filter.dart' as app_filter;

/// Implementation of NhentaiScraperAdapter that delegates to RemoteDataSource
class NhentaiScraperAdapterImpl implements NhentaiScraperAdapter {
  final RemoteDataSource _remoteDataSource;

  NhentaiScraperAdapterImpl(this._remoteDataSource);

  @override
  Future<core.Content> getDetail(String contentId) async {
    final appContent = await _remoteDataSource.getContentDetail(contentId);
    return _mapToCoreContent(appContent);
  }

  @override
  Future<core.ContentListResult> getList({
    int page = 1,
    core.SortOption sort = core.SortOption.newest,
  }) async {
    // If specific sort explicitly requested, use API/fallback logic for sorted list
    if (sort != core.SortOption.newest) {
      String period = 'all';
      if (sort == core.SortOption.popularWeek) period = 'week';
      if (sort == core.SortOption.popularToday) period = 'today';
      if (sort == core.SortOption.popular) period = 'all';

      final result = await _remoteDataSource.getPopularContentWithPagination(
          period: period, page: page);
      return _mapListResult(result, page);
    }

    final result =
        await _remoteDataSource.getContentListWithPagination(page: page);
    return _mapListResult(result, page);
  }

  @override
  Future<core.ContentListResult> getPopular({
    core.PopularTimeframe timeframe = core.PopularTimeframe.allTime,
    int page = 1,
  }) async {
    String period = 'all';
    switch (timeframe) {
      case core.PopularTimeframe.today:
        period = 'today';
        break;
      case core.PopularTimeframe.week:
        period = 'week';
        break;
      case core.PopularTimeframe.allTime:
        period = 'all';
        break;
    }

    final result = await _remoteDataSource.getPopularContentWithPagination(
      period: period,
      page: page,
    );

    return _mapListResult(result, page);
  }

  @override
  Future<List<core.Content>> getRandom({int count = 1}) async {
    final List<core.Content> results = [];
    for (int i = 0; i < count; i++) {
      try {
        final appContent = await _remoteDataSource.getRandomContent();
        results.add(_mapToCoreContent(appContent));
      } catch (e) {
        // Ignore single failures in random batch
      }
    }
    return results;
  }

  @override
  Future<core.ContentListResult> search(core.SearchFilter filter) async {
    final appFilter = _mapSearchFilter(filter);
    final result =
        await _remoteDataSource.searchContentWithPagination(appFilter);
    return _mapListResult(result, filter.page);
  }

  // --- Mappers ---

  core.ContentListResult _mapListResult(Map<String, dynamic> result, int page) {
    final List<dynamic> rawContents = result['contents'];
    final List<core.Content> contents = rawContents
        .map((c) => _mapToCoreContent(c as app_content.Content))
        .toList();

    final pagination = result['pagination'] as Map<String, dynamic>;
    final totalData = result['totalData'] as int? ?? 0;

    // Core ContentListResult properties: contents, currentPage, totalPages, totalCount, hasNext, hasPrevious
    return core.ContentListResult(
      contents: contents,
      currentPage: page,
      totalPages: pagination['totalPages'] as int? ?? 1,
      totalCount: totalData,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrevious: pagination['hasPrevious'] as bool? ?? false,
    );
  }

  core.Content _mapToCoreContent(app_content.Content appContent) {
    return core.Content(
      id: appContent.id,
      sourceId: 'nhentai', // Hardcoded for this adapter
      title: appContent.title,
      coverUrl: appContent.coverUrl,
      tags: appContent.tags.map(_mapToCoreTag).toList(),
      artists: appContent.artists,
      characters: appContent.characters,
      parodies: appContent.parodies,
      groups: appContent.groups,
      language: appContent.language,
      pageCount: appContent.pageCount,
      imageUrls: appContent.imageUrls,
      uploadDate: appContent.uploadDate,
      favorites: appContent.favorites,
      englishTitle: appContent.englishTitle,
      japaneseTitle: appContent.japaneseTitle,
      mediaId: _extractMediaId(appContent.coverUrl),
      relatedContent: appContent.relatedContent.map(_mapToCoreContent).toList(),
    );
  }

  String? _extractMediaId(String coverUrl) {
    // Example: https://t.nhentai.net/galleries/12345/cover.jpg
    try {
      final uri = Uri.parse(coverUrl);
      final segments = uri.pathSegments;
      // pathSegments for /galleries/12345/cover.jpg -> ['galleries', '12345', 'cover.jpg']
      if (segments.contains('galleries')) {
        final index = segments.indexOf('galleries');
        if (index + 1 < segments.length) {
          return segments[index + 1];
        }
      }
    } catch (_) {}
    return null;
  }

  core.Tag _mapToCoreTag(app_tag.Tag appTag) {
    return core.Tag(
      id: appTag.id,
      name: appTag.name,
      type: appTag.type,
      count: appTag.count,
      url: appTag.url,
      slug: appTag.slug,
    );
  }

  app_filter.SearchFilter _mapSearchFilter(core.SearchFilter filter) {
    // Map SortOption
    app_filter.SortOption sortBy = app_filter.SortOption.newest;
    switch (filter.sort) {
      // Correct property is "sort" in core.SearchFilter
      case core.SortOption.newest:
        sortBy = app_filter.SortOption.newest;
        break;
      case core.SortOption.popular:
        sortBy = app_filter.SortOption.popular;
        break;
      case core.SortOption.popularWeek:
        sortBy = app_filter.SortOption.popularWeek;
        break;
      case core.SortOption.popularToday:
        sortBy = app_filter.SortOption.popularToday;
        break;
      case core.SortOption.popularMonth:
        // No direct mapping in app yet, fallback to popular or modify app if needed.
        // For now, map to popular (all time) or similar if month not verified supported in app filter.
        // Actually nhentai.net supports popular-month via URL but maybe app filter enum doesn't have it?
        // App SortOption: newest, popular, popularWeek, popularToday. No month.
        // So fallback to popular (all time) or closest.
        sortBy = app_filter.SortOption.popular;
        break;
    }

    // Initialize lists
    final tags = <app_filter.FilterItem>[];
    final artists = <app_filter.FilterItem>[];
    final characters = <app_filter.FilterItem>[];
    final parodies = <app_filter.FilterItem>[];
    final groups = <app_filter.FilterItem>[];

    // Helper to distribute items
    void distribute(core.FilterItem item) {
      final appItem = app_filter.FilterItem(
          value: item.name, // core uses name, app uses value
          isExcluded: item.isExcluded);

      switch (item.type.toLowerCase()) {
        case 'tag':
          tags.add(appItem);
          break;
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
        // Language and category are handled separately in app filter
      }
    }

    // Process included tags
    for (final item in filter.includeTags) {
      distribute(item);
    }

    // Process excluded tags
    for (final item in filter.excludeTags) {
      // Ensure excluded flag is set (though it should be)
      final excludedItem =
          item.isExcluded ? item : item.copyWith(isExcluded: true);
      distribute(excludedItem);
    }

    // NOTE: app_filter expects language and category as strings, not FilterItems usually,
    // unless they are part of tags. SearchFilter struct has specific fields for them.
    // core.SearchFilter has language and category strings too.

    return app_filter.SearchFilter(
      query: filter.query,
      page: filter.page,
      sortBy: sortBy,
      popular: false, // Core seems to handle popular via sort?
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
