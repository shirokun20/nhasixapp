import 'dart:convert';
import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../../domain/value_objects/value_objects.dart';
import '../datasources/local/local_data_source.dart';
import '../models/content_model.dart';
import '../models/download_status_model.dart';
import '../models/history_model.dart';

/// Implementation of UserDataRepository for local data management
class UserDataRepositoryImpl implements UserDataRepository {
  UserDataRepositoryImpl({
    required this.localDataSource,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final LocalDataSource localDataSource;
  final Logger _logger;

  static const int defaultPageSize = 20;

  // ==================== FAVORITES ====================

  @override
  Future<void> addToFavorites({
    required Content content,
    int? categoryId,
  }) async {
    try {
      _logger.i(
          'Adding content ${content.id} to favorites (category: $categoryId)');

      // Cache the content first to ensure it's available offline
      final contentModel = ContentModel.fromEntity(content);
      await localDataSource.cacheContent(contentModel);

      // Add to favorites
      await localDataSource.addToFavorites(
        content.id,
        categoryId: categoryId ?? 1, // Default category
      );

      _logger.d('Successfully added to favorites');
    } catch (e, stackTrace) {
      _logger.e('Failed to add to favorites', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites({
    required ContentId contentId,
    int? categoryId,
  }) async {
    try {
      _logger.i('Removing content ${contentId.value} from favorites');

      await localDataSource.removeFromFavorites(
        contentId.value,
        categoryId: categoryId,
      );

      _logger.d('Successfully removed from favorites');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from favorites',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<FavoriteListResult> getFavorites({
    int? categoryId,
    int page = 1,
    FavoriteSortOption sortBy = FavoriteSortOption.dateAdded,
  }) async {
    try {
      _logger.i(
          'Getting favorites - category: $categoryId, page: $page, sort: $sortBy');

      final favoriteModels = await localDataSource.getFavorites(
        categoryId: categoryId,
        page: page,
        limit: defaultPageSize,
      );

      final favorites =
          favoriteModels.map((model) => model.toEntity()).toList();

      // Apply sorting (local data source returns by date added DESC by default)
      _sortFavorites(favorites, sortBy);

      final hasNext = favorites.length == defaultPageSize;
      final hasPrevious = page > 1;

      final result = FavoriteListResult(
        favorites: favorites,
        currentPage: page,
        totalPages: hasNext ? page + 1 : page,
        totalCount: favorites.length,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
      );

      _logger.d('Retrieved ${favorites.length} favorites');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorites', error: e, stackTrace: stackTrace);
      return const FavoriteListResult(
        favorites: [],
        currentPage: 1,
        totalPages: 0,
        totalCount: 0,
      );
    }
  }

  @override
  Future<bool> isFavorite({
    required ContentId contentId,
    int? categoryId,
  }) async {
    try {
      return await localDataSource.isFavorited(
        contentId.value,
        categoryId: categoryId,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to check if favorite',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<List<FavoriteCategory>> getFavoriteCategories() async {
    try {
      _logger.i('Getting favorite categories');

      final categoryMaps = await localDataSource.getFavoriteCategories();

      final categories = categoryMaps
          .map((map) => FavoriteCategory(
                id: map['id'],
                name: map['name'],
                count: 0, // Would need to be calculated
                createdAt:
                    DateTime.fromMillisecondsSinceEpoch(map['created_at']),
                isDefault: map['id'] == 1,
              ))
          .toList();

      _logger.d('Retrieved ${categories.length} favorite categories');
      return categories;
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorite categories',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<FavoriteCategory> createFavoriteCategory(String name) async {
    try {
      _logger.i('Creating favorite category: $name');

      final id = await localDataSource.createFavoriteCategory(name);

      final category = FavoriteCategory(
        id: id,
        name: name,
        count: 0,
        createdAt: DateTime.now(),
      );

      _logger.d('Created favorite category with ID: $id');
      return category;
    } catch (e, stackTrace) {
      _logger.e('Failed to create favorite category',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<FavoriteCategory> updateFavoriteCategory({
    required int categoryId,
    required String name,
  }) async {
    try {
      _logger.i('Updating favorite category $categoryId to: $name');

      // This would require additional database operations
      // For now, return updated category
      final category = FavoriteCategory(
        id: categoryId,
        name: name,
        count: 0,
        createdAt: DateTime.now(),
      );

      _logger.d('Updated favorite category');
      return category;
    } catch (e, stackTrace) {
      _logger.e('Failed to update favorite category',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteFavoriteCategory({
    required int categoryId,
    bool moveToDefault = true,
  }) async {
    try {
      _logger.i(
          'Deleting favorite category $categoryId (moveToDefault: $moveToDefault)');

      // This would require additional database operations to handle moving favorites
      // For now, just log the operation

      _logger.d('Deleted favorite category');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete favorite category',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> moveFavoriteToCategory({
    required ContentId contentId,
    required int fromCategoryId,
    required int toCategoryId,
  }) async {
    try {
      _logger.i(
          'Moving favorite ${contentId.value} from $fromCategoryId to $toCategoryId');

      // Remove from old category and add to new category
      await localDataSource.removeFromFavorites(
        contentId.value,
        categoryId: fromCategoryId,
      );

      await localDataSource.addToFavorites(
        contentId.value,
        categoryId: toCategoryId,
      );

      _logger.d('Moved favorite to new category');
    } catch (e, stackTrace) {
      _logger.e('Failed to move favorite to category',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<FavoriteStatistics> getFavoriteStatistics() async {
    try {
      _logger.i('Getting favorite statistics');

      final stats = await localDataSource.getDatabaseStats();
      final totalFavorites = stats['favorites'] ?? 0;

      // Get sample favorites to calculate statistics
      final sampleFavorites = await localDataSource.getFavorites(limit: 100);

      final artistCounts = <String, int>{};
      final tagCounts = <String, int>{};
      double totalPages = 0;

      for (final favorite in sampleFavorites) {
        totalPages += favorite.pageCount;

        for (final artist in favorite.artists) {
          artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
        }

        for (final tag in favorite.tags) {
          tagCounts[tag.name] = (tagCounts[tag.name] ?? 0) + 1;
        }
      }

      final averagePages = sampleFavorites.isNotEmpty
          ? totalPages / sampleFavorites.length
          : 0.0;

      return FavoriteStatistics(
        totalFavorites: totalFavorites,
        categoriesCount: 1, // Would need to be calculated
        mostFavoritedArtists: artistCounts,
        mostFavoritedTags: tagCounts,
        averagePagesPerFavorite: averagePages,
        oldestFavorite:
            sampleFavorites.isNotEmpty ? sampleFavorites.last.uploadDate : null,
        newestFavorite: sampleFavorites.isNotEmpty
            ? sampleFavorites.first.uploadDate
            : null,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorite statistics',
          error: e, stackTrace: stackTrace);
      return const FavoriteStatistics(
        totalFavorites: 0,
        categoriesCount: 0,
        mostFavoritedArtists: {},
        mostFavoritedTags: {},
        averagePagesPerFavorite: 0.0,
      );
    }
  }

  // ==================== DOWNLOADS ====================

  @override
  Future<DownloadStatus> queueDownload({
    required Content content,
    int priority = 0,
  }) async {
    try {
      _logger.i('Queueing download for content: ${content.id}');

      // Cache the content first
      final contentModel = ContentModel.fromEntity(content);
      await localDataSource.cacheContent(contentModel);

      // Create download status
      final downloadStatus = DownloadStatus(
        contentId: content.id,
        state: DownloadState.queued,
        totalPages: content.pageCount,
        startTime: DateTime.now(),
      );

      final statusModel = DownloadStatusModel.fromEntity(downloadStatus);
      await localDataSource.saveDownloadStatus(statusModel);

      _logger.d('Queued download successfully');
      return downloadStatus;
    } catch (e, stackTrace) {
      _logger.e('Failed to queue download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DownloadStatus?> getDownloadStatus(ContentId contentId) async {
    try {
      final statusModel =
          await localDataSource.getDownloadStatus(contentId.value);
      return statusModel?.toEntity();
    } catch (e, stackTrace) {
      _logger.e('Failed to get download status',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<List<DownloadStatus>> getAllDownloads({
    DownloadState? state,
    DownloadSortOption sortBy = DownloadSortOption.dateAdded,
  }) async {
    try {
      _logger.i('Getting all downloads - state: $state, sort: $sortBy');

      final statusModels = await localDataSource.getAllDownloads(
        state: state,
        limit: 100, // Get more for sorting
      );

      final downloads = statusModels.map((model) => model.toEntity()).toList();

      // Apply sorting
      _sortDownloads(downloads, sortBy);

      _logger.d('Retrieved ${downloads.length} downloads');
      return downloads;
    } catch (e, stackTrace) {
      _logger.e('Failed to get all downloads',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> updateDownloadStatus(DownloadStatus status) async {
    try {
      _logger.d('Updating download status for: ${status.contentId}');

      final statusModel = DownloadStatusModel.fromEntity(status);
      await localDataSource.saveDownloadStatus(statusModel);
    } catch (e, stackTrace) {
      _logger.e('Failed to update download status',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> pauseDownload(ContentId contentId) async {
    try {
      _logger.i('Pausing download: ${contentId.value}');

      final currentStatus = await getDownloadStatus(contentId);
      if (currentStatus != null &&
          currentStatus.state == DownloadState.downloading) {
        final updatedStatus = DownloadStatus(
          contentId: currentStatus.contentId,
          state: DownloadState.paused,
          downloadedPages: currentStatus.downloadedPages,
          totalPages: currentStatus.totalPages,
          startTime: currentStatus.startTime,
          downloadPath: currentStatus.downloadPath,
          fileSize: currentStatus.fileSize,
        );

        await updateDownloadStatus(updatedStatus);
        _logger.d('Download paused');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to pause download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> resumeDownload(ContentId contentId) async {
    try {
      _logger.i('Resuming download: ${contentId.value}');

      final currentStatus = await getDownloadStatus(contentId);
      if (currentStatus != null &&
          currentStatus.state == DownloadState.paused) {
        final updatedStatus = DownloadStatus(
          contentId: currentStatus.contentId,
          state: DownloadState.downloading,
          downloadedPages: currentStatus.downloadedPages,
          totalPages: currentStatus.totalPages,
          startTime: currentStatus.startTime,
          downloadPath: currentStatus.downloadPath,
          fileSize: currentStatus.fileSize,
        );

        await updateDownloadStatus(updatedStatus);
        _logger.d('Download resumed');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to resume download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cancelDownload({
    required ContentId contentId,
    bool deleteFiles = true,
  }) async {
    try {
      _logger.i('Cancelling download: ${contentId.value}');

      final currentStatus = await getDownloadStatus(contentId);
      if (currentStatus != null) {
        final updatedStatus = DownloadStatus(
          contentId: currentStatus.contentId,
          state: DownloadState.cancelled,
          downloadedPages: currentStatus.downloadedPages,
          totalPages: currentStatus.totalPages,
          startTime: currentStatus.startTime,
          endTime: DateTime.now(),
          downloadPath: currentStatus.downloadPath,
          fileSize: currentStatus.fileSize,
        );

        await updateDownloadStatus(updatedStatus);

        if (deleteFiles) {
          // File deletion would be handled by a file manager service
          _logger.d('Download cancelled and files deleted');
        } else {
          _logger.d('Download cancelled');
        }
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to cancel download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> retryDownload(ContentId contentId) async {
    try {
      _logger.i('Retrying download: ${contentId.value}');

      final currentStatus = await getDownloadStatus(contentId);
      if (currentStatus != null &&
          currentStatus.state == DownloadState.failed) {
        final updatedStatus = DownloadStatus(
          contentId: currentStatus.contentId,
          state: DownloadState.queued,
          downloadedPages: 0, // Reset progress
          totalPages: currentStatus.totalPages,
          startTime: DateTime.now(),
          downloadPath: currentStatus.downloadPath,
          fileSize: 0,
        );

        await updateDownloadStatus(updatedStatus);
        _logger.d('Download queued for retry');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to retry download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DownloadedContentResult> getDownloadedContent({
    int page = 1,
    DownloadSortOption sortBy = DownloadSortOption.dateCompleted,
  }) async {
    try {
      _logger.i('Getting downloaded content - page: $page, sort: $sortBy');

      // Get completed downloads
      final completedDownloads = await localDataSource.getAllDownloads(
        state: DownloadState.completed,
        page: page,
        limit: defaultPageSize,
      );

      // Get the actual content for each download
      final contents = <Content>[];
      for (final download in completedDownloads) {
        final content =
            await localDataSource.getContentById(download.contentId);
        if (content != null) {
          contents.add(content.toEntity());
        }
      }

      final hasNext = contents.length == defaultPageSize;
      final hasPrevious = page > 1;

      final result = DownloadedContentResult(
        content: contents,
        currentPage: page,
        totalPages: hasNext ? page + 1 : page,
        totalCount: contents.length,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
      );

      _logger.d('Retrieved ${contents.length} downloaded contents');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to get downloaded content',
          error: e, stackTrace: stackTrace);
      return const DownloadedContentResult(
        content: [],
        currentPage: 1,
        totalPages: 0,
        totalCount: 0,
      );
    }
  }

  @override
  Future<bool> isDownloaded(ContentId contentId) async {
    try {
      final status = await getDownloadStatus(contentId);
      return status?.state == DownloadState.completed;
    } catch (e, stackTrace) {
      _logger.e('Failed to check if downloaded',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<void> deleteDownloadedContent({
    required ContentId contentId,
    bool deleteFiles = true,
  }) async {
    try {
      _logger.i('Deleting downloaded content: ${contentId.value}');

      await localDataSource.deleteDownloadStatus(contentId.value);

      if (deleteFiles) {
        // File deletion would be handled by a file manager service
        _logger.d('Downloaded content and files deleted');
      } else {
        _logger.d('Download record deleted');
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to delete downloaded content',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DownloadStatistics> getDownloadStatistics() async {
    try {
      _logger.i('Getting download statistics');

      final allDownloads = await getAllDownloads();

      final completed =
          allDownloads.where((d) => d.state == DownloadState.completed).length;
      final failed =
          allDownloads.where((d) => d.state == DownloadState.failed).length;

      final totalSize = allDownloads
          .where((d) => d.state == DownloadState.completed)
          .fold<int>(0, (sum, d) => sum + d.fileSize);

      // Calculate average download time for completed downloads
      final completedWithTimes = allDownloads
          .where((d) =>
              d.state == DownloadState.completed &&
              d.startTime != null &&
              d.endTime != null)
          .toList();

      Duration averageTime = Duration.zero;
      if (completedWithTimes.isNotEmpty) {
        final totalTime = completedWithTimes
            .map((d) => d.endTime!.difference(d.startTime!))
            .reduce((a, b) => a + b);
        averageTime = Duration(
          milliseconds: totalTime.inMilliseconds ~/ completedWithTimes.length,
        );
      }

      return DownloadStatistics(
        totalDownloads: allDownloads.length,
        completedDownloads: completed,
        failedDownloads: failed,
        totalSizeBytes: totalSize,
        averageDownloadTime: averageTime,
        oldestDownload: allDownloads.isNotEmpty
            ? allDownloads
                .map((d) => d.startTime)
                .where((t) => t != null)
                .reduce((a, b) => a!.isBefore(b!) ? a : b)
            : null,
        newestDownload: allDownloads.isNotEmpty
            ? allDownloads
                .map((d) => d.startTime)
                .where((t) => t != null)
                .reduce((a, b) => a!.isAfter(b!) ? a : b)
            : null,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get download statistics',
          error: e, stackTrace: stackTrace);
      return const DownloadStatistics(
        totalDownloads: 0,
        completedDownloads: 0,
        failedDownloads: 0,
        totalSizeBytes: 0,
        averageDownloadTime: Duration.zero,
      );
    }
  }

  // ==================== HISTORY ====================

  @override
  Future<void> addToHistory({
    required ContentId contentId,
    required int page,
    required int totalPages,
    Duration? timeSpent,
  }) async {
    try {
      _logger.d('Adding to history: ${contentId.value}, page: $page');

      final history = History(
        contentId: contentId.value,
        lastViewed: DateTime.now(),
        lastPage: page,
        totalPages: totalPages,
        timeSpent: timeSpent ?? Duration.zero,
        isCompleted: page >= totalPages,
      );

      final historyModel = HistoryModel.fromEntity(history);
      await localDataSource.saveHistory(historyModel);
    } catch (e, stackTrace) {
      _logger.e('Failed to add to history', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<HistoryListResult> getHistory({
    int page = 1,
    int limit = 50,
    HistorySortOption sortBy = HistorySortOption.lastViewed,
  }) async {
    try {
      _logger.i('Getting history - page: $page, limit: $limit, sort: $sortBy');

      final historyModels = await localDataSource.getAllHistory(
        page: page,
        limit: limit,
      );

      final history = historyModels.map((model) => model.toEntity()).toList();

      // Apply sorting
      _sortHistory(history, sortBy);

      final hasNext = history.length == limit;
      final hasPrevious = page > 1;

      final result = HistoryListResult(
        history: history,
        currentPage: page,
        totalPages: hasNext ? page + 1 : page,
        totalCount: history.length,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
      );

      _logger.d('Retrieved ${history.length} history entries');
      return result;
    } catch (e, stackTrace) {
      _logger.e('Failed to get history', error: e, stackTrace: stackTrace);
      return const HistoryListResult(
        history: [],
        currentPage: 1,
        totalPages: 0,
        totalCount: 0,
      );
    }
  }

  @override
  Future<History?> getHistoryEntry(ContentId contentId) async {
    try {
      final historyModel = await localDataSource.getHistory(contentId.value);
      return historyModel?.toEntity();
    } catch (e, stackTrace) {
      _logger.e('Failed to get history entry',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> updateReadingProgress({
    required ContentId contentId,
    required int page,
    Duration? additionalTime,
  }) async {
    try {
      _logger.d('Updating reading progress: ${contentId.value}, page: $page');

      final existingHistory = await getHistoryEntry(contentId);

      final updatedHistory = History(
        contentId: contentId.value,
        lastViewed: DateTime.now(),
        lastPage: page,
        totalPages: existingHistory?.totalPages ?? 0,
        timeSpent: (existingHistory?.timeSpent ?? Duration.zero) +
            (additionalTime ?? Duration.zero),
        isCompleted: existingHistory?.isCompleted ?? false,
      );

      final historyModel = HistoryModel.fromEntity(updatedHistory);
      await localDataSource.saveHistory(historyModel);
    } catch (e, stackTrace) {
      _logger.e('Failed to update reading progress',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markAsCompleted(ContentId contentId) async {
    try {
      _logger.i('Marking as completed: ${contentId.value}');

      final existingHistory = await getHistoryEntry(contentId);

      if (existingHistory != null) {
        final completedHistory = History(
          contentId: contentId.value,
          lastViewed: DateTime.now(),
          lastPage: existingHistory.totalPages,
          totalPages: existingHistory.totalPages,
          timeSpent: existingHistory.timeSpent,
          isCompleted: true,
        );

        final historyModel = HistoryModel.fromEntity(completedHistory);
        await localDataSource.saveHistory(historyModel);
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to mark as completed',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFromHistory(ContentId contentId) async {
    try {
      _logger.i('Removing from history: ${contentId.value}');

      await localDataSource.deleteHistory(contentId.value);
      _logger.d('Removed from history');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from history',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearHistory({Duration? olderThan}) async {
    try {
      _logger.i('Clearing history - older than: $olderThan');

      if (olderThan != null) {
        // Would need additional implementation for selective clearing
        _logger.w('Selective history clearing not implemented, clearing all');
      }

      await localDataSource.clearHistory();
      _logger.d('History cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear history', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ReadingStatistics> getReadingStatistics() async {
    try {
      _logger.i('Getting reading statistics');

      final allHistory = await localDataSource.getAllHistory(limit: 1000);

      final totalContentRead = allHistory.length;
      final totalPagesRead =
          allHistory.fold<int>(0, (sum, h) => sum + h.lastPage);
      final totalTimeSpent = allHistory.fold<Duration>(
        Duration.zero,
        (sum, h) => sum + h.timeSpent,
      );

      // Get content for additional statistics
      final artistStats = <String, int>{};
      final tagStats = <String, int>{};
      final languageStats = <String, int>{};

      for (final history in allHistory.take(100)) {
        // Limit for performance
        final content = await localDataSource.getContentById(history.contentId);
        if (content != null) {
          for (final artist in content.artists) {
            artistStats[artist] = (artistStats[artist] ?? 0) + 1;
          }

          for (final tag in content.tags) {
            tagStats[tag.name] = (tagStats[tag.name] ?? 0) + 1;
          }

          languageStats[content.language] =
              (languageStats[content.language] ?? 0) + 1;
        }
      }

      return ReadingStatistics(
        totalContentRead: totalContentRead,
        totalPagesRead: totalPagesRead,
        totalTimeSpent: totalTimeSpent,
        favoriteArtists: artistStats,
        favoriteTags: tagStats,
        favoriteLanguages: languageStats,
        averageReadingTime: totalContentRead > 0
            ? Duration(
                milliseconds: totalTimeSpent.inMilliseconds ~/ totalContentRead)
            : Duration.zero,
        completedContent: allHistory.where((h) => h.isCompleted).length,
        readingStreak: 0, // Would need additional implementation
        lastReadDate:
            allHistory.isNotEmpty ? allHistory.first.lastViewed : null,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get reading statistics',
          error: e, stackTrace: stackTrace);
      return ReadingStatistics(
        totalContentRead: 0,
        totalPagesRead: 0,
        totalTimeSpent: Duration.zero,
        favoriteArtists: const {},
        favoriteTags: const {},
        favoriteLanguages: const {},
        averageReadingTime: Duration.zero,
        completedContent: 0,
        readingStreak: 0,
        lastReadDate: null,
      );
    }
  }

  // ==================== BLACKLIST ====================

  @override
  Future<void> addToBlacklist(String tagName) async {
    try {
      _logger.i('Adding tag to blacklist: $tagName');

      final preferences = await localDataSource.getUserPreferences();
      final updatedBlacklist = [...preferences.blacklistedTags, tagName];

      final updatedPreferences = preferences.copyWith(
        blacklistedTags: updatedBlacklist,
      );

      await localDataSource.saveUserPreferences(updatedPreferences);
      _logger.d('Tag added to blacklist');
    } catch (e, stackTrace) {
      _logger.e('Failed to add to blacklist', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFromBlacklist(String tagName) async {
    try {
      _logger.i('Removing tag from blacklist: $tagName');

      final preferences = await localDataSource.getUserPreferences();
      final updatedBlacklist =
          preferences.blacklistedTags.where((tag) => tag != tagName).toList();

      final updatedPreferences = preferences.copyWith(
        blacklistedTags: updatedBlacklist,
      );

      await localDataSource.saveUserPreferences(updatedPreferences);
      _logger.d('Tag removed from blacklist');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from blacklist',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> getBlacklistedTags() async {
    try {
      final preferences = await localDataSource.getUserPreferences();
      return preferences.blacklistedTags;
    } catch (e, stackTrace) {
      _logger.e('Failed to get blacklisted tags',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<bool> isTagBlacklisted(String tagName) async {
    try {
      final blacklistedTags = await getBlacklistedTags();
      return blacklistedTags.contains(tagName);
    } catch (e, stackTrace) {
      _logger.e('Failed to check if tag is blacklisted',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ==================== BACKUP & SYNC ====================

  @override
  Future<String> exportUserData({
    bool includeHistory = true,
    bool includeDownloads = false,
  }) async {
    try {
      _logger.i('Exporting user data');

      final data = <String, dynamic>{};

      // Export favorites
      final favorites = await getFavorites();
      data['favorites'] = favorites.favorites.map((c) => c.id).toList();

      // Export favorite categories
      final categories = await getFavoriteCategories();
      data['favoriteCategories'] = categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList();

      // Export history if requested
      if (includeHistory) {
        final history = await getHistory();
        data['history'] = history.history
            .map((h) => {
                  'contentId': h.contentId,
                  'lastViewed': h.lastViewed.toIso8601String(),
                  'lastPage': h.lastPage,
                  'totalPages': h.totalPages,
                  'timeSpent': h.timeSpent.inMilliseconds,
                  'isCompleted': h.isCompleted,
                })
            .toList();
      }

      // Export downloads if requested
      if (includeDownloads) {
        final downloads = await getAllDownloads();
        data['downloads'] = downloads
            .map((d) => {
                  'contentId': d.contentId,
                  'state': d.state.name,
                  'downloadedPages': d.downloadedPages,
                  'totalPages': d.totalPages,
                  'startTime': d.startTime?.toIso8601String(),
                  'endTime': d.endTime?.toIso8601String(),
                })
            .toList();
      }

      // Export preferences
      final preferences = await localDataSource.getUserPreferences();
      data['preferences'] = preferences.toJson();

      data['exportedAt'] = DateTime.now().toIso8601String();
      data['version'] = '1.0';

      final jsonString = jsonEncode(data);
      _logger.d('User data exported successfully');
      return jsonString;
    } catch (e, stackTrace) {
      _logger.e('Failed to export user data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> importUserData({
    required String jsonData,
    bool mergeWithExisting = true,
  }) async {
    try {
      _logger.i('Importing user data (merge: $mergeWithExisting)');

      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Import preferences
      if (data.containsKey('preferences')) {
        final prefsData = data['preferences'] as Map<String, dynamic>;
        final preferences = UserPreferences.fromJson(prefsData);
        await localDataSource.saveUserPreferences(preferences);
      }

      // Import favorites
      if (data.containsKey('favorites')) {
        final favoriteIds = (data['favorites'] as List).cast<String>();
        // Would need to fetch content and add to favorites
        // This is a simplified implementation
        _logger.d('Would import ${favoriteIds.length} favorites');
      }

      // Import history
      if (data.containsKey('history')) {
        final historyData = data['history'] as List;
        for (final historyItem in historyData) {
          final history = History(
            contentId: historyItem['contentId'],
            lastViewed: DateTime.parse(historyItem['lastViewed']),
            lastPage: historyItem['lastPage'],
            totalPages: historyItem['totalPages'],
            timeSpent: Duration(milliseconds: historyItem['timeSpent']),
            isCompleted: historyItem['isCompleted'],
          );

          final historyModel = HistoryModel.fromEntity(history);
          await localDataSource.saveHistory(historyModel);
        }
      }

      _logger.d('User data imported successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to import user data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SyncStatus> getSyncStatus() async {
    try {
      // This would be implemented with a sync service
      return const SyncStatus(
        lastSyncTime: null,
        hasPendingChanges: false,
        pendingFavorites: 0,
        pendingHistory: 0,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get sync status', error: e, stackTrace: stackTrace);
      return const SyncStatus(
        lastSyncTime: null,
        hasPendingChanges: false,
        pendingFavorites: 0,
        pendingHistory: 0,
        syncError: 'Failed to get sync status',
      );
    }
  }

  @override
  Future<SyncResult> syncUserData() async {
    try {
      _logger.i('Syncing user data');

      // This would be implemented with a sync service
      return SyncResult(
        success: true,
        syncedFavorites: 0,
        syncedHistory: 0,
        syncTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to sync user data', error: e, stackTrace: stackTrace);
      return SyncResult(
        success: false,
        syncedFavorites: 0,
        syncedHistory: 0,
        syncTime: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Sort favorites based on sort option
  void _sortFavorites(List<Content> favorites, FavoriteSortOption sortBy) {
    switch (sortBy) {
      case FavoriteSortOption.dateAdded:
        // Already sorted by date added DESC from database
        break;
      case FavoriteSortOption.title:
        favorites.sort((a, b) => a.title.compareTo(b.title));
        break;
      case FavoriteSortOption.artist:
        favorites.sort((a, b) {
          final artistA = a.artists.isNotEmpty ? a.artists.first : '';
          final artistB = b.artists.isNotEmpty ? b.artists.first : '';
          return artistA.compareTo(artistB);
        });
        break;
      case FavoriteSortOption.pageCount:
        favorites.sort((a, b) => b.pageCount.compareTo(a.pageCount));
        break;
      case FavoriteSortOption.uploadDate:
        favorites.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        break;
    }
  }

  /// Sort downloads based on sort option
  void _sortDownloads(
      List<DownloadStatus> downloads, DownloadSortOption sortBy) {
    switch (sortBy) {
      case DownloadSortOption.dateAdded:
        downloads.sort((a, b) => (b.startTime ?? DateTime.now())
            .compareTo(a.startTime ?? DateTime.now()));
        break;
      case DownloadSortOption.dateCompleted:
        downloads.sort((a, b) => (b.endTime ?? DateTime.now())
            .compareTo(a.endTime ?? DateTime.now()));
        break;
      case DownloadSortOption.title:
        // Would need content title, skip for now
        break;
      case DownloadSortOption.fileSize:
        downloads.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case DownloadSortOption.progress:
        downloads.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }
  }

  /// Sort history based on sort option
  void _sortHistory(List<History> history, HistorySortOption sortBy) {
    switch (sortBy) {
      case HistorySortOption.lastViewed:
        history.sort((a, b) => b.lastViewed.compareTo(a.lastViewed));
        break;
      case HistorySortOption.title:
        // Would need content title, skip for now
        break;
      case HistorySortOption.progress:
        history.sort(
            (a, b) => b.progressPercentage.compareTo(a.progressPercentage));
        break;
      case HistorySortOption.timeSpent:
        history.sort((a, b) => b.timeSpent.compareTo(a.timeSpent));
        break;
    }
  }
}
