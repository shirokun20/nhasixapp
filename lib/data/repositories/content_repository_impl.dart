import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../domain/usecases/base_usecase.dart';
// import '../datasources/local/pagination_cache_keys.dart';
import '../datasources/remote/remote_data_source.dart';
import '../../services/cache/cache_manager.dart' as multi_cache;
import '../models/content_model.dart';
import '../models/tag_model.dart';
import '../../services/detail_cache_service.dart';
import '../../services/request_deduplication_service.dart';

/// Implementation of ContentRepository with caching strategy and offline-first architecture
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({
    required this.remoteDataSource,
    required this.detailCacheService,
    required this.requestDeduplicationService,
    required this.contentCacheManager,
    required this.tagCacheManager,
    // required this.localDataSource,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final RemoteDataSource remoteDataSource;
  final DetailCacheService detailCacheService;
  final RequestDeduplicationService requestDeduplicationService;
  final multi_cache.CacheManager<Content> contentCacheManager;
  final multi_cache.CacheManager<List<Tag>> tagCacheManager;
  // final LocalDataSource localDataSource;
  final Logger _logger;

  static const Duration cacheExpiration = Duration(hours: 6);
  static const int defaultPageSize = 20;

  @override
  Future<ContentListResult> getContentList({
    int page = 1,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      _logger.i('Getting content list - page: $page, sort: $sortBy');

      try {
        // Try to fetch from remote via API (with automatic fallback to scraping)
        final remoteResult = await remoteDataSource
            .getContentListWithPaginationViaApi(page: page, sortBy: sortBy);

        final remoteContents = remoteResult['contents'] as List<ContentModel>;
        final paginationInfo =
            remoteResult['pagination'] as Map<String, dynamic>;

        // Cache individual content items (not the whole list)
        final entities =
            remoteContents.map((model) => model.toEntity()).toList();

        // Cache each content individually for detail page access
        for (final content in entities) {
          final cacheKey = 'content_${content.id}';
          await contentCacheManager.set(cacheKey, content);
        }

        _logger.i(
            'Fetched and cached ${remoteContents.length} contents with pagination from remote');

        return _buildContentListResultWithPagination(entities, paginationInfo);
      } catch (e) {
        _logger.w('Failed to fetch from remote: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get content list', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Content> getContentDetail(ContentId contentId) async {
    final requestKey = 'content_detail_${contentId.value}';

    return requestDeduplicationService.deduplicate(
      requestKey,
      () async {
        try {
          _logger.i('Getting content detail for ID: ${contentId.value}');

          // 1. Try multi-layer cache first (memory -> disk)
          final cacheKey = 'content_${contentId.value}';
          final multiLayerCached = await contentCacheManager.get(cacheKey);

          // Only return cached content if it is complete (has images)
          // Search results cached in getContentList often lack imageUrls
          if (multiLayerCached != null) {
            if (multiLayerCached.imageUrls.isNotEmpty) {
              _logger.i(
                  'Cache HIT (multi-layer) for content detail: ${contentId.value}');
              return multiLayerCached;
            } else {
              _logger.i(
                  'Cache HIT (partial) for content detail: ${contentId.value} - missing images, fetching fresh data');
            }
          }

          // 2. Try old DetailCacheService for backward compatibility
          final legacyCached =
              await detailCacheService.getCachedDetail(contentId.value);
          if (legacyCached != null) {
            if (legacyCached.imageUrls.isNotEmpty) {
              _logger.i(
                  'Cache HIT (legacy) for content detail: ${contentId.value}');
              // Promote to multi-layer cache
              await contentCacheManager.set(cacheKey, legacyCached);
              return legacyCached;
            } else {
              _logger.i(
                  'Cache HIT (legacy-partial) for content detail: ${contentId.value} - missing images, ignoring');
            }
          }

          // 3. Cache MISS - fetch from remote via API (with fallback)
          _logger.d('Cache MISS for content detail: ${contentId.value}');
          try {
            final remoteContent =
                await remoteDataSource.getContentDetailViaApi(contentId.value);
            final entity = remoteContent.toEntity();

            // Cache to both systems
            await Future.wait([
              contentCacheManager.set(cacheKey, entity),
              detailCacheService.cacheDetail(entity),
            ]);

            _logger.i('Fetched and cached content detail from remote');
            return entity;
          } catch (e) {
            _logger.w('Failed to fetch detail from remote: $e');
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
      // For search, try remote API first for fresh results (with fallback)
      try {
        final remoteResult =
            await remoteDataSource.searchContentWithPaginationViaApi(filter);

        final remoteResults = remoteResult['contents'] as List<ContentModel>;
        var paginationInfo = remoteResult['pagination'] as Map<String, dynamic>;
        paginationInfo['totalCount'] =
            remoteResult['totalData'] as int? ?? remoteResults.length;
        _logger.i('Found ${remoteResults.length} search results from remote');

        final entities =
            remoteResults.map((model) => model.toEntity()).toList();
        return _buildContentListResultWithPagination(entities, paginationInfo);
      } catch (e) {
        _logger.w('Remote search failed, trying cached search: $e');
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

      final randomContents = <Content>[];

      for (int i = 0; i < count; i++) {
        try {
          // Add progressive delay between requests to avoid rate limiting
          if (i > 0) {
            final delay = Duration(
                milliseconds:
                    2000 + (i * 500)); // Progressive delay: 2s, 2.5s, 3s, etc.
            await Future.delayed(delay);
          }

          final remoteContent = await remoteDataSource.getRandomContent();
          randomContents.add(remoteContent.toEntity());

          _logger.d('Successfully got random content ${i + 1}/$count');
        } catch (e) {
          _logger.w('Failed to get random content ${i + 1}/$count: $e');
          // Continue with other random content, but add exponential backoff on error
          if (e.toString().toLowerCase().contains('rate limit')) {
            _logger.w('Rate limit detected, applying exponential backoff');
            final backoffDelay =
                Duration(seconds: 10 + (i * 5)); // 10s, 15s, 20s, etc.
            await Future.delayed(backoffDelay);
          } else {
            // Regular error, add shorter delay
            await Future.delayed(const Duration(seconds: 3));
          }
        }
      }

      _logger.i('Returning ${randomContents.length} random content(s)');
      return randomContents;
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
      final remoteResult =
          await remoteDataSource.getPopularContentWithPagination(
        period: timeframe.apiValue,
        page: page,
      );

      final remoteContents = remoteResult['contents'] as List<ContentModel>;
      final paginationInfo = remoteResult['pagination'] as Map<String, dynamic>;

      _logger.i('Fetched ${remoteContents.length} popular contents');

      final entities = remoteContents.map((model) => model.toEntity()).toList();
      return _buildContentListResultWithPagination(entities, paginationInfo);
    } catch (e) {
      _logger.w('Failed to fetch popular content from remote: $e');
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

      // Try API-based related content first (new feature!)
      try {
        final relatedContents =
            await remoteDataSource.getRelatedContentViaApi(contentId.value);
        if (relatedContents.isNotEmpty) {
          _logger.i('Found ${relatedContents.length} related contents via API');
          return relatedContents.take(limit).map((m) => m.toEntity()).toList();
        }
      } catch (e) {
        _logger.w('API related content failed: $e');
      }

      // Fallback: Get the reference content to find related tags
      final referenceContent = await getContentDetail(contentId);

      if (referenceContent.tags.isEmpty) {
        return [];
      }

      // Use the most common tags to find related content
      final commonTags = referenceContent.tags
          .where((tag) => tag.type == 'tag' || tag.type == 'artist')
          .take(3)
          .map((tag) => tag.name)
          .toList();

      if (commonTags.isEmpty) {
        return [];
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

  /// Build ContentListResult with real pagination data from scraper
  ContentListResult _buildContentListResultWithPagination(
      List<Content> contents, Map<String, dynamic> paginationInfo) {
    final currentPage = paginationInfo['currentPage'] as int? ?? 1;
    final totalPages = paginationInfo['totalPages'] as int? ?? 1;
    final hasNext = paginationInfo['hasNext'] as bool? ?? false;
    final hasPrevious = paginationInfo['hasPrevious'] as bool? ?? false;

    // Calculate approximate total count based on pages and content per page
    final totalCount = paginationInfo['totalCount'] as int? ?? 0;

    _logger.d('Built ContentListResult with real pagination: '
        'currentPage=$currentPage, totalPages=$totalPages, '
        'hasNext=$hasNext, hasPrevious=$hasPrevious, '
        'totalCount=$totalCount');

    return ContentListResult(
      contents: contents,
      currentPage: currentPage,
      totalPages: totalPages,
      totalCount: totalCount,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
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
        // For recent, we'd need a timestamp in the tag model
        // For now, sort by count as fallback
        tags.sort((a, b) => b.count.compareTo(a.count));
        break;
    }
  }
}
