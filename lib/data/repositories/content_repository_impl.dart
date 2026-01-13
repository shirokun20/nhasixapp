import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/value_objects/value_objects.dart';
import '../datasources/remote/remote_data_source.dart';
import '../../services/cache/cache_manager.dart' as multi_cache;
import '../models/tag_model.dart';
import '../../services/detail_cache_service.dart';
import '../datasources/remote/exceptions.dart';
import '../../services/request_deduplication_service.dart';
import 'package:kuron_core/kuron_core.dart' as core;
import 'package:kuron_crotpedia/kuron_crotpedia.dart' as crotpedia;

/// Implementation of ContentRepository with caching strategy and offline-first architecture
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({
    required this.contentSourceRegistry,
    required this.remoteDataSource, // Keep for legacy tag ops for now
    required this.detailCacheService,
    required this.requestDeduplicationService,
    required this.contentCacheManager,
    required this.tagCacheManager,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final core.ContentSourceRegistry contentSourceRegistry;
  final RemoteDataSource remoteDataSource;
  final DetailCacheService detailCacheService;
  final RequestDeduplicationService requestDeduplicationService;
  final multi_cache.CacheManager<Content> contentCacheManager;
  final multi_cache.CacheManager<List<Tag>> tagCacheManager;
  final Logger _logger;

  static const Duration cacheExpiration = Duration(hours: 6);
  static const int defaultPageSize = 20;

  core.ContentSource get _activeSource {
    final source = contentSourceRegistry.currentSource;
    if (source == null) {
      throw Exception('No active content source found');
    }
    return source;
  }

  @override
  Future<ContentListResult> getContentList({
    int page = 1,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      _logger.i('Getting content list - page: $page, sort: $sortBy');

      try {
        // Map SortOption
        core.SortOption coreSort = core.SortOption.newest;
        if (sortBy == SortOption.popular) coreSort = core.SortOption.popular;
        if (sortBy == SortOption.popularWeek) {
          coreSort = core.SortOption.popularWeek;
        }
        if (sortBy == SortOption.popularToday) {
          coreSort = core.SortOption.popularToday;
        }

        final coreResult =
            await _activeSource.getList(page: page, sort: coreSort);

        // Cache individual content items
        final entities = coreResult.contents.map(_mapToAppContent).toList();

        for (final content in entities) {
          final cacheKey = 'content_${content.id}';
          await contentCacheManager.set(cacheKey, content);
        }

        _logger.i(
            'Fetched and cached ${entities.length} contents from ${_activeSource.id}');

        return _mapToAppContentListResult(coreResult);
      } catch (e) {
        _logger.w('Failed to fetch from source: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get content list', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Content> getContentDetail(ContentId contentId,
      {String? sourceId}) async {
    final requestKey = 'content_detail_${contentId.value}';

    return requestDeduplicationService.deduplicate(
      requestKey,
      () async {
        try {
          _logger.i('Getting content detail for ID: ${contentId.value}');

          final cacheKey = 'content_${contentId.value}';
          final multiLayerCached = await contentCacheManager.get(cacheKey);

          if (multiLayerCached != null) {
            if (multiLayerCached.imageUrls.isNotEmpty) {
              return multiLayerCached;
            }
          }

          final legacyCached =
              await detailCacheService.getCachedDetail(contentId.value);
          if (legacyCached != null) {
            if (legacyCached.imageUrls.isNotEmpty) {
              await contentCacheManager.set(cacheKey, legacyCached);
              return legacyCached;
            }
          }

          _logger.d('Cache MISS for content detail: ${contentId.value}');
          try {
            final source = sourceId != null
                ? contentSourceRegistry.getSource(sourceId)
                : _activeSource;

            if (source == null) {
              throw Exception('Source not found for ID: $sourceId');
            }

            final coreContent = await source.getDetail(contentId.value);
            final entity = _mapToAppContent(coreContent);

            await Future.wait([
              contentCacheManager.set(cacheKey, entity),
              detailCacheService.cacheDetail(entity),
            ]);

            return entity;
          } catch (e) {
            _logger.w('Failed to fetch detail from source: $e');
            throw NetworkException('Failed to fetch content detail: $e');
          }
        } catch (e, stackTrace) {
          _logger.e('Failed to get content detail',
              error: e, stackTrace: stackTrace);
          rethrow;
        }
      },
    );
  }

  @override
  Future<ContentListResult> searchContent(SearchFilter filter) async {
    try {
      _logger.i('Searching content with filter: ${filter.query}');
      try {
        final coreFilter = _mapToCoreSearchFilter(filter);
        final coreResult = await _activeSource.search(coreFilter);

        return _mapToAppContentListResult(coreResult);
      } catch (e) {
        _logger.w('Search failed: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to search content', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Content>> getRandomContent({int count = 1}) async {
    try {
      _logger.i('Getting $count random content(s)');
      final coreContents = await _activeSource.getRandom(count: count);
      return coreContents.map(_mapToAppContent).toList();
    } catch (e, stackTrace) {
      _logger.e('Failed to get random content',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ContentListResult> getPopularContent({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  }) async {
    try {
      core.PopularTimeframe coreTimeframe = core.PopularTimeframe.allTime;
      if (timeframe == PopularTimeframe.today) {
        coreTimeframe = core.PopularTimeframe.today;
      }
      if (timeframe == PopularTimeframe.week) {
        coreTimeframe = core.PopularTimeframe.week;
      }

      final coreResult = await _activeSource.getPopular(
        timeframe: coreTimeframe,
        page: page,
      );

      return _mapToAppContentListResult(coreResult);
    } catch (e) {
      _logger.w('Failed to fetch popular content from source: $e');
      rethrow;
    }
  }

  @override
  Future<ContentListResult> getContentByTag({
    required Tag tag,
    int page = 1,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      _logger.i('Getting content by tag: ${tag.name}, page: $page');

      // Create search filter for tag
      final filter = SearchFilter(
        tags: [FilterItem.include(tag.name)],
        page: page,
        sortBy: sortBy,
      );

      return await searchContent(filter);
    } catch (e, stackTrace) {
      _logger.e('Failed to get content by tag',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Content>> getRelatedContent({
    required ContentId contentId,
    int limit = 10,
  }) async {
    try {
      _logger.i('Getting related content for: ${contentId.value}');
      // Use active source logic
      try {
        final coreRelated = await _activeSource.getRelated(contentId.value);
        if (coreRelated.isNotEmpty) {
          return coreRelated.take(limit).map(_mapToAppContent).toList();
        }
      } catch (e) {
        _logger.w('Related content failed: $e');
      }
      return [];
    } catch (e, stackTrace) {
      _logger.e('Failed to get related content',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<List<Tag>> getAllTags({
    String? type,
    TagSortOption sortBy = TagSortOption.count,
  }) async {
    try {
      // Generate cache key based on type and sort
      final cacheKey = 'tags_${type ?? 'all'}_${sortBy.name}';

      // Try cache first
      final cached = await tagCacheManager.get(cacheKey);
      if (cached != null) {
        _logger.i('Cache HIT for tags: $cacheKey (${cached.length} tags)');
        return cached;
      }

      // Cache MISS - fetch from remote
      _logger.d('Cache MISS for tags: $cacheKey');
      List<TagModel> remoteTags;
      if (type != null) {
        remoteTags = await remoteDataSource.getTagsByType(type);
      } else {
        remoteTags = await remoteDataSource.getAllTags();
      }

      final entities = remoteTags.map((model) => model.toEntity()).toList();
      _sortTags(entities, sortBy);

      // Cache the sorted result
      await tagCacheManager.set(cacheKey, entities);

      _logger.i('Fetched and cached ${entities.length} tags from remote');
      return entities;
    } catch (e) {
      _logger.w('Failed to fetch tags from remote: $e');
      rethrow;
    }
  }

  @override
  Future<bool> verifyContentExists(ContentId contentId) async {
    try {
      await remoteDataSource.getContentDetail(contentId.value);
      return true;
    } catch (e) {
      _logger.d('Content verification failed: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getChapterImages(ContentId chapterId,
      {String? sourceId}) async {
    try {
      _logger.d(
          'Getting chapter images for: ${chapterId.value}, source: $sourceId');
      final source = sourceId != null
          ? contentSourceRegistry.getSource(sourceId)
          : _activeSource;

      if (source == null) {
        throw Exception('Source not found for ID: $sourceId');
      }

      // Check if source supports getChapterImages
      // Note: core.ContentSource might not have getChapterImages exposed directly
      // if it's not in the base interface.
      // We might need to cast to CrotpediaSource or specific interface if not standard.
      // However, assuming standard interface upgrade or dynamic check.
      // Since `getChapterImages` is likely specific to Crotpedia/Manga sources:
      if (source is crotpedia.CrotpediaSource) {
        return await source.getChapterImages(chapterId.value);
      }

      // If source doesn't support it or is standard source without chapters
      // We could try getDetail as fallback? No, chapter images are specific.
      _logger.w('Source ${source.displayName} is not a CrotpediaSource');
      return [];
    } catch (e) {
      _logger.e('Failed to get chapter images: $e');
      return [];
    }
  }

  /// Sort tags based on sort option
  void _sortTags(List<Tag> tags, TagSortOption sortBy) {
    switch (sortBy) {
      case TagSortOption.count:
        tags.sort((a, b) => b.count.compareTo(a.count));
        break;
      case TagSortOption.name:
        tags.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TagSortOption.recent:
        tags.sort((a, b) => b.count.compareTo(a.count));
        break;
    }
  }

  /// --- Mappers ---

  ContentListResult _mapToAppContentListResult(
      core.ContentListResult coreResult) {
    return ContentListResult(
      contents: coreResult.contents,
      currentPage: coreResult.currentPage,
      totalPages: coreResult.totalPages,
      totalCount: coreResult.totalCount,
      hasNext: coreResult.hasNext,
      hasPrevious: coreResult.hasPrevious,
    );
  }

  /// Return core Content directly (no mapping needed since types are unified)
  Content _mapToAppContent(core.Content coreContent) => coreContent;

  core.SearchFilter _mapToCoreSearchFilter(SearchFilter appFilter) {
    // Map SortOption
    core.SortOption coreSort = core.SortOption.newest;
    if (appFilter.sortBy == SortOption.popular) {
      coreSort = core.SortOption.popular;
    }
    if (appFilter.sortBy == SortOption.popularWeek) {
      coreSort = core.SortOption.popularWeek;
    }
    if (appFilter.sortBy == SortOption.popularToday) {
      coreSort = core.SortOption.popularToday;
    }

    // Convert FilterItems to core.FilterItem
    final includeTags = <core.FilterItem>[];
    final excludeTags = <core.FilterItem>[];

    void process(List<FilterItem> items, String type) {
      for (final item in items) {
        final coreItem = core.FilterItem(
          id: 0, // App doesn't store ID for filter items
          name: item.value,
          type: type,
          isExcluded: item.isExcluded,
        );
        if (item.isExcluded) {
          excludeTags.add(coreItem);
        } else {
          includeTags.add(coreItem);
        }
      }
    }

    process(appFilter.tags, 'tag');
    process(appFilter.artists, 'artist');
    process(appFilter.characters, 'character');
    process(appFilter.parodies, 'parody');
    process(appFilter.groups, 'group');

    return core.SearchFilter(
      query: appFilter.query ?? '',
      page: appFilter.page,
      sort: coreSort,
      includeTags: includeTags,
      excludeTags: excludeTags,
      language: appFilter.language,
      category: appFilter.category,
    );
  }
}
