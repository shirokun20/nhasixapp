import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/value_objects/value_objects.dart';
import '../datasources/local/local_data_source.dart';
import '../datasources/remote/remote_data_source.dart';
import '../models/content_model.dart';
import '../models/tag_model.dart';

/// Implementation of ContentRepository with caching strategy and offline-first architecture
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;
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

      // Try to get from cache first (offline-first approach)
      final cachedContents = await _getCachedContentList(page: page);

      // If we have cached content and it's not expired, return it
      if (cachedContents.isNotEmpty && !_isCacheExpired(cachedContents.first)) {
        _logger.d(
            'Returning cached content list (${cachedContents.length} items)');
        return _buildContentListResult(cachedContents, page);
      }

      try {
        // Try to fetch from remote
        final remoteContents =
            await remoteDataSource.getContentList(page: page);

        // Cache the fetched content
        await _cacheContentList(remoteContents);

        _logger.i(
            'Fetched and cached ${remoteContents.length} contents from remote');

        final entities =
            remoteContents.map((model) => model.toEntity()).toList();
        return _buildContentListResult(entities, page);
      } catch (e) {
        _logger.w('Failed to fetch from remote, falling back to cache: $e');

        // Fallback to cached content even if expired
        if (cachedContents.isNotEmpty) {
          _logger.d('Using expired cache as fallback');
          return _buildContentListResult(cachedContents, page);
        }

        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get content list', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Content> getContentDetail(ContentId contentId) async {
    try {
      _logger.i('Getting content detail for ID: ${contentId.value}');

      // Try cache first
      final cachedContent =
          await localDataSource.getContentById(contentId.value);

      if (cachedContent != null && !_isCacheExpired(cachedContent.toEntity())) {
        _logger.d('Returning cached content detail');
        return cachedContent.toEntity();
      }

      try {
        // Fetch from remote
        final remoteContent =
            await remoteDataSource.getContentDetail(contentId.value);

        // Cache the content
        await localDataSource.cacheContent(remoteContent);

        _logger.i('Fetched and cached content detail');
        return remoteContent.toEntity();
      } catch (e) {
        _logger.w('Failed to fetch detail from remote, using cache: $e');

        if (cachedContent != null) {
          return cachedContent.toEntity();
        }

        rethrow;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get content detail',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ContentListResult> searchContent(SearchFilter filter) async {
    try {
      _logger.i('Searching content with filter: ${filter.query}');

      // For search, try remote first for fresh results
      try {
        final remoteResults = await remoteDataSource.searchContent(filter);

        // Cache search results
        await _cacheContentList(remoteResults);

        _logger.i('Found ${remoteResults.length} search results from remote');

        final entities =
            remoteResults.map((model) => model.toEntity()).toList();
        return _buildContentListResult(entities, filter.page);
      } catch (e) {
        _logger.w('Remote search failed, trying cached search: $e');

        // Fallback to cached search
        final cachedResults = await localDataSource.searchCachedContent(
          query: filter.query,
          includeTags: filter.includeTags,
          excludeTags: filter.excludeTags,
          language: filter.language,
          page: filter.page,
        );

        if (cachedResults.isNotEmpty) {
          _logger.d('Found ${cachedResults.length} cached search results');
          final entities =
              cachedResults.map((model) => model.toEntity()).toList();
          return _buildContentListResult(entities, filter.page);
        }

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
          final remoteContent = await remoteDataSource.getRandomContent();
          await localDataSource.cacheContent(remoteContent);
          randomContents.add(remoteContent.toEntity());
        } catch (e) {
          _logger.w('Failed to get random content $i: $e');
          // Continue with other random content
        }
      }

      if (randomContents.isEmpty) {
        // Fallback to cached random selection
        final cachedContents = await _getCachedContentList(limit: count * 5);
        if (cachedContents.isNotEmpty) {
          cachedContents.shuffle();
          randomContents.addAll(cachedContents.take(count));
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
      _logger.i('Getting popular content - timeframe: $timeframe, page: $page');

      try {
        final remoteContents = await remoteDataSource.getPopularContent(
          period: timeframe.apiValue,
          page: page,
        );

        await _cacheContentList(remoteContents);

        _logger.i('Fetched ${remoteContents.length} popular contents');

        final entities =
            remoteContents.map((model) => model.toEntity()).toList();
        return _buildContentListResult(entities, page);
      } catch (e) {
        _logger.w('Failed to fetch popular content from remote: $e');

        // Fallback to cached content sorted by favorites
        final cachedContents = await localDataSource.getCachedContentList(
          page: page,
          limit: defaultPageSize,
        );

        // Sort by favorites count as approximation of popularity
        cachedContents.sort((a, b) => b.favorites.compareTo(a.favorites));

        final entities =
            cachedContents.map((model) => model.toEntity()).toList();
        return _buildContentListResult(entities, page);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get popular content',
          error: e, stackTrace: stackTrace);
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
        includeTags: [tag.name],
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

      // Get the reference content to find related tags
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

      // Search for content with similar tags
      final relatedResults = await localDataSource.searchCachedContent(
        includeTags: commonTags,
        limit: limit,
      );

      // Filter out the reference content
      final entities = relatedResults
          .where((model) => model.id != contentId.value)
          .map((model) => model.toEntity())
          .toList();

      _logger.i('Found ${entities.length} related contents');
      return entities;
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
      _logger.i('Getting all tags - type: $type, sort: $sortBy');

      try {
        // Try to fetch fresh tags from remote
        List<TagModel> remoteTags;
        if (type != null) {
          remoteTags = await remoteDataSource.getTagsByType(type);
        } else {
          remoteTags = await remoteDataSource.getAllTags();
        }

        // Cache tags are handled automatically when caching content

        final entities = remoteTags.map((model) => model.toEntity()).toList();
        _sortTags(entities, sortBy);

        _logger.i('Fetched ${entities.length} tags from remote');
        return entities;
      } catch (e) {
        _logger.w('Failed to fetch tags from remote, using cache: $e');

        // Fallback to cached tags
        final cachedTags = await localDataSource.getAllTags(
          type: type,
          limit: 1000,
        );

        final entities = cachedTags.map((model) => model.toEntity()).toList();
        _sortTags(entities, sortBy);

        return entities;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to get all tags', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<List<Tag>> searchTags({
    required String query,
    int limit = 20,
  }) async {
    try {
      _logger.i('Searching tags with query: $query');

      final cachedTags = await localDataSource.searchTags(query, limit: limit);
      final entities = cachedTags.map((model) => model.toEntity()).toList();

      _logger.i('Found ${entities.length} matching tags');
      return entities;
    } catch (e, stackTrace) {
      _logger.e('Failed to search tags', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<ContentListResult> getCachedContent({int page = 1}) async {
    try {
      _logger.i('Getting cached content - page: $page');

      final cachedContents = await _getCachedContentList(page: page);
      return _buildContentListResult(cachedContents, page);
    } catch (e, stackTrace) {
      _logger.e('Failed to get cached content',
          error: e, stackTrace: stackTrace);
      return ContentListResult.empty();
    }
  }

  @override
  Future<void> cacheContent({
    required List<Content> contents,
    bool replaceExisting = false,
  }) async {
    try {
      _logger.i('Caching ${contents.length} contents');

      final contentModels =
          contents.map((content) => ContentModel.fromEntity(content)).toList();

      await localDataSource.cacheContentList(contentModels);

      _logger.d('Successfully cached ${contents.length} contents');
    } catch (e, stackTrace) {
      _logger.e('Failed to cache content', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache({Duration? olderThan}) async {
    try {
      _logger.i('Clearing cache - older than: $olderThan');

      if (olderThan != null) {
        await localDataSource.deleteExpiredCache(maxAge: olderThan);
      } else {
        // Clear all cache by deleting very old entries
        await localDataSource.deleteExpiredCache(maxAge: Duration.zero);
      }

      _logger.d('Cache cleared successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> verifyContentExists(ContentId contentId) async {
    try {
      _logger.d('Verifying content exists: ${contentId.value}');

      // Check cache first
      final cachedContent =
          await localDataSource.getContentById(contentId.value);
      if (cachedContent != null) {
        return true;
      }

      // Try to fetch from remote to verify
      try {
        await remoteDataSource.getContentDetail(contentId.value);
        return true;
      } catch (e) {
        _logger.d('Content verification failed: $e');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to verify content exists',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<ContentStatistics> getContentStatistics() async {
    try {
      _logger.i('Getting content statistics');

      final stats = await localDataSource.getDatabaseStats();
      final allTags = await localDataSource.getAllTags(limit: 10);

      // Calculate basic statistics from cached data
      final totalContent = stats['contents'] ?? 0;
      final totalTags = stats['tags'] ?? 0;

      // Get sample content to calculate averages
      final sampleContents =
          await localDataSource.getCachedContentList(limit: 100);
      final averagePages = sampleContents.isNotEmpty
          ? sampleContents.map((c) => c.pageCount).reduce((a, b) => a + b) /
              sampleContents.length
          : 0.0;

      // Get language and category distribution
      final languageDistribution = <String, int>{};
      final categoryDistribution = <String, int>{};

      for (final content in sampleContents) {
        languageDistribution[content.language] =
            (languageDistribution[content.language] ?? 0) + 1;
        // Category would need to be added to content model
      }

      // Get most popular tags and artists
      final popularTags = allTags.take(10).map((t) => t.toEntity()).toList();
      final popularArtists = sampleContents
          .expand((c) => c.artists)
          .fold<Map<String, int>>({}, (map, artist) {
            map[artist] = (map[artist] ?? 0) + 1;
            return map;
          })
          .entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ContentStatistics(
        totalContent: totalContent,
        totalTags: totalTags,
        totalArtists: popularArtists.length,
        averagePages: averagePages,
        mostPopularTags: popularTags,
        mostPopularArtists: popularArtists.take(10).map((e) => e.key).toList(),
        languageDistribution: languageDistribution,
        categoryDistribution: categoryDistribution,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get content statistics',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Get cached content list with pagination
  Future<List<Content>> _getCachedContentList({
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final cachedModels = await localDataSource.getCachedContentList(
      page: page,
      limit: limit,
    );

    return cachedModels.map((model) => model.toEntity()).toList();
  }

  /// Cache a list of content models
  Future<void> _cacheContentList(List<ContentModel> contents) async {
    if (contents.isNotEmpty) {
      await localDataSource.cacheContentList(contents);
    }
  }

  /// Check if content cache is expired
  bool _isCacheExpired(Content content) {
    if (content is ContentModel) {
      return content.isCacheExpired(maxAge: cacheExpiration);
    }
    return true;
  }

  /// Build ContentListResult from content list
  ContentListResult _buildContentListResult(List<Content> contents, int page) {
    // For simplicity, assume each page has defaultPageSize items
    // In a real implementation, you'd get total count from the data source
    final hasNext = contents.length == defaultPageSize;
    final hasPrevious = page > 1;

    return ContentListResult(
      contents: contents,
      currentPage: page,
      totalPages: hasNext ? page + 1 : page, // Approximate
      totalCount: contents.length, // This would be the total across all pages
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
