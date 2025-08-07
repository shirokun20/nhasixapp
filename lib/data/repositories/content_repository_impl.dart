import 'package:logger/logger.dart';
import 'package:nhasixapp/domain/entities/pagination_info.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/value_objects/value_objects.dart';
// import '../datasources/local/pagination_cache_keys.dart';
import '../datasources/remote/remote_data_source.dart';
import '../models/content_model.dart';
import '../models/tag_model.dart';

/// Implementation of ContentRepository with caching strategy and offline-first architecture
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({
    required this.remoteDataSource,
    // required this.localDataSource,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final RemoteDataSource remoteDataSource;
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
        // Try to fetch from remote with pagination info
        final remoteResult =
            await remoteDataSource.getContentListWithPagination(page: page);

        final remoteContents = remoteResult['contents'] as List<ContentModel>;
        final paginationInfo =
            remoteResult['pagination'] as Map<String, dynamic>;
        // Cache both content and pagination info
        _logger.i(
            'Fetched and cached ${remoteContents.length} contents with pagination from remote');

        final entities =
            remoteContents.map((model) => model.toEntity()).toList();
        return _buildContentListResultWithPagination(entities, paginationInfo);
      } catch (e) {
        _logger.w('Failed to fetch from remote, falling back to cache: $e');
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
      try {
        // Fetch from remote
        final remoteContent =
            await remoteDataSource.getContentDetail(contentId.value);
        // Cache the content
        _logger.i('Fetched and cached content detail');
        return remoteContent.toEntity();
      } catch (e) {
        _logger.w('Failed to fetch detail from remote, using cache: $e');
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
        final remoteResult =
            await remoteDataSource.searchContentWithPagination(filter);

        final remoteResults = remoteResult['contents'] as List<ContentModel>;
        var paginationInfo = remoteResult['pagination'] as Map<String, dynamic>;
        paginationInfo['totalCount'] = remoteResult['totalData'] as int;
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
          final remoteContent = await remoteDataSource.getRandomContent();
          randomContents.add(remoteContent.toEntity());
        } catch (e) {
          _logger.w('Failed to get random content $i: $e');
          // Continue with other random content
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
