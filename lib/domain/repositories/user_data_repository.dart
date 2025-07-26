import '../entities/entities.dart';
import '../value_objects/value_objects.dart';

/// Repository interface for user data operations (favorites, downloads, history)
abstract class UserDataRepository {
  // ==================== FAVORITES ====================

  /// Add content to favorites
  ///
  /// [content] - Content to add to favorites
  /// [categoryId] - Optional category ID (default category if null)
  Future<void> addToFavorites({
    required Content content,
    int? categoryId,
  });

  /// Remove content from favorites
  ///
  /// [contentId] - Content ID to remove
  /// [categoryId] - Optional specific category (remove from all if null)
  Future<void> removeFromFavorites({
    required ContentId contentId,
    int? categoryId,
  });

  /// Get all favorite content
  ///
  /// [categoryId] - Filter by category (all categories if null)
  /// [page] - Page number for pagination
  /// [sortBy] - Sort option
  /// Returns paginated favorite content
  Future<FavoriteListResult> getFavorites({
    int? categoryId,
    int page = 1,
    FavoriteSortOption sortBy = FavoriteSortOption.dateAdded,
  });

  /// Check if content is in favorites
  ///
  /// [contentId] - Content ID to check
  /// [categoryId] - Check specific category (any category if null)
  /// Returns true if content is favorited
  Future<bool> isFavorite({
    required ContentId contentId,
    int? categoryId,
  });

  /// Get favorite categories
  ///
  /// Returns list of all favorite categories
  Future<List<FavoriteCategory>> getFavoriteCategories();

  /// Create new favorite category
  ///
  /// [name] - Category name
  /// Returns created category
  Future<FavoriteCategory> createFavoriteCategory(String name);

  /// Update favorite category
  ///
  /// [categoryId] - Category ID to update
  /// [name] - New category name
  /// Returns updated category
  Future<FavoriteCategory> updateFavoriteCategory({
    required int categoryId,
    required String name,
  });

  /// Delete favorite category
  ///
  /// [categoryId] - Category ID to delete
  /// [moveToDefault] - Move content to default category if true
  Future<void> deleteFavoriteCategory({
    required int categoryId,
    bool moveToDefault = true,
  });

  /// Move content between favorite categories
  ///
  /// [contentId] - Content to move
  /// [fromCategoryId] - Source category
  /// [toCategoryId] - Destination category
  Future<void> moveFavoriteToCategory({
    required ContentId contentId,
    required int fromCategoryId,
    required int toCategoryId,
  });

  /// Get favorite statistics
  ///
  /// Returns statistics about user's favorites
  Future<FavoriteStatistics> getFavoriteStatistics();

  // ==================== DOWNLOADS ====================

  /// Queue content for download
  ///
  /// [content] - Content to download
  /// [priority] - Download priority (higher = more priority)
  /// Returns download status
  Future<DownloadStatus> queueDownload({
    required Content content,
    int priority = 0,
  });

  /// Get download status
  ///
  /// [contentId] - Content ID to check
  /// Returns current download status
  Future<DownloadStatus?> getDownloadStatus(ContentId contentId);

  /// Get all download statuses
  ///
  /// [state] - Filter by download state (all states if null)
  /// [sortBy] - Sort option
  /// Returns list of download statuses
  Future<List<DownloadStatus>> getAllDownloads({
    DownloadState? state,
    DownloadSortOption sortBy = DownloadSortOption.dateAdded,
  });

  /// Update download status
  ///
  /// [status] - Updated download status
  Future<void> updateDownloadStatus(DownloadStatus status);

  /// Pause download
  ///
  /// [contentId] - Content ID to pause
  Future<void> pauseDownload(ContentId contentId);

  /// Resume download
  ///
  /// [contentId] - Content ID to resume
  Future<void> resumeDownload(ContentId contentId);

  /// Cancel download
  ///
  /// [contentId] - Content ID to cancel
  /// [deleteFiles] - Delete partially downloaded files
  Future<void> cancelDownload({
    required ContentId contentId,
    bool deleteFiles = true,
  });

  /// Retry failed download
  ///
  /// [contentId] - Content ID to retry
  Future<void> retryDownload(ContentId contentId);

  /// Get downloaded content (completed downloads)
  ///
  /// [page] - Page number for pagination
  /// [sortBy] - Sort option
  /// Returns paginated downloaded content
  Future<DownloadedContentResult> getDownloadedContent({
    int page = 1,
    DownloadSortOption sortBy = DownloadSortOption.dateCompleted,
  });

  /// Check if content is downloaded
  ///
  /// [contentId] - Content ID to check
  /// Returns true if content is fully downloaded
  Future<bool> isDownloaded(ContentId contentId);

  /// Delete downloaded content
  ///
  /// [contentId] - Content ID to delete
  /// [deleteFiles] - Delete associated files
  Future<void> deleteDownloadedContent({
    required ContentId contentId,
    bool deleteFiles = true,
  });

  /// Get download statistics
  ///
  /// Returns statistics about downloads
  Future<DownloadStatistics> getDownloadStatistics();

  // ==================== HISTORY ====================

  /// Add content to reading history
  ///
  /// [contentId] - Content ID
  /// [page] - Current page being read
  /// [totalPages] - Total pages in content
  /// [timeSpent] - Additional time spent reading
  Future<void> addToHistory({
    required ContentId contentId,
    required int page,
    required int totalPages,
    Duration? timeSpent,
  });

  /// Get reading history
  ///
  /// [page] - Page number for pagination
  /// [limit] - Items per page
  /// [sortBy] - Sort option
  /// Returns paginated reading history
  Future<HistoryListResult> getHistory({
    int page = 1,
    int limit = 50,
    HistorySortOption sortBy = HistorySortOption.lastViewed,
  });

  /// Get history entry for specific content
  ///
  /// [contentId] - Content ID to get history for
  /// Returns history entry or null if not found
  Future<History?> getHistoryEntry(ContentId contentId);

  /// Update reading progress
  ///
  /// [contentId] - Content ID
  /// [page] - Current page
  /// [additionalTime] - Additional reading time
  Future<void> updateReadingProgress({
    required ContentId contentId,
    required int page,
    Duration? additionalTime,
  });

  /// Mark content as completed
  ///
  /// [contentId] - Content ID to mark as completed
  Future<void> markAsCompleted(ContentId contentId);

  /// Remove from history
  ///
  /// [contentId] - Content ID to remove from history
  Future<void> removeFromHistory(ContentId contentId);

  /// Clear all history
  ///
  /// [olderThan] - Clear history older than specified duration
  Future<void> clearHistory({Duration? olderThan});

  /// Get reading statistics
  ///
  /// Returns comprehensive reading statistics
  Future<ReadingStatistics> getReadingStatistics();

  // ==================== BLACKLIST ====================

  /// Add tag to blacklist
  ///
  /// [tagName] - Tag name to blacklist
  Future<void> addToBlacklist(String tagName);

  /// Remove tag from blacklist
  ///
  /// [tagName] - Tag name to remove from blacklist
  Future<void> removeFromBlacklist(String tagName);

  /// Get blacklisted tags
  ///
  /// Returns list of blacklisted tag names
  Future<List<String>> getBlacklistedTags();

  /// Check if tag is blacklisted
  ///
  /// [tagName] - Tag name to check
  /// Returns true if tag is blacklisted
  Future<bool> isTagBlacklisted(String tagName);

  // ==================== BACKUP & SYNC ====================

  /// Export user data to JSON
  ///
  /// [includeHistory] - Include reading history in export
  /// [includeDownloads] - Include download data in export
  /// Returns JSON string with user data
  Future<String> exportUserData({
    bool includeHistory = true,
    bool includeDownloads = false,
  });

  /// Import user data from JSON
  ///
  /// [jsonData] - JSON string with user data
  /// [mergeWithExisting] - Merge with existing data or replace
  Future<void> importUserData({
    required String jsonData,
    bool mergeWithExisting = true,
  });

  /// Get data sync status
  ///
  /// Returns information about last sync and pending changes
  Future<SyncStatus> getSyncStatus();

  /// Sync user data with remote backup (if available)
  ///
  /// Returns sync result
  Future<SyncResult> syncUserData();
}

/// Result wrapper for paginated favorite lists
class FavoriteListResult {
  const FavoriteListResult({
    required this.favorites,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<Content> favorites;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  bool get isEmpty => favorites.isEmpty;
  bool get isNotEmpty => favorites.isNotEmpty;
  int get count => favorites.length;
}

/// Result wrapper for downloaded content
class DownloadedContentResult {
  const DownloadedContentResult({
    required this.content,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<Content> content;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  bool get isEmpty => content.isEmpty;
  bool get isNotEmpty => content.isNotEmpty;
  int get count => content.length;
}

/// Result wrapper for history lists
class HistoryListResult {
  const HistoryListResult({
    required this.history,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.hasNext = false,
    this.hasPrevious = false,
  });

  final List<History> history;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrevious;

  bool get isEmpty => history.isEmpty;
  bool get isNotEmpty => history.isNotEmpty;
  int get count => history.length;
}

/// Favorite category entity
class FavoriteCategory {
  const FavoriteCategory({
    required this.id,
    required this.name,
    required this.count,
    required this.createdAt,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final int count;
  final DateTime createdAt;
  final bool isDefault;

  FavoriteCategory copyWith({
    int? id,
    String? name,
    int? count,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return FavoriteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Favorite statistics
class FavoriteStatistics {
  const FavoriteStatistics({
    required this.totalFavorites,
    required this.categoriesCount,
    required this.mostFavoritedArtists,
    required this.mostFavoritedTags,
    required this.averagePagesPerFavorite,
    this.oldestFavorite,
    this.newestFavorite,
  });

  final int totalFavorites;
  final int categoriesCount;
  final Map<String, int> mostFavoritedArtists;
  final Map<String, int> mostFavoritedTags;
  final double averagePagesPerFavorite;
  final DateTime? oldestFavorite;
  final DateTime? newestFavorite;
}

/// Download statistics
class DownloadStatistics {
  const DownloadStatistics({
    required this.totalDownloads,
    required this.completedDownloads,
    required this.failedDownloads,
    required this.totalSizeBytes,
    required this.averageDownloadTime,
    this.oldestDownload,
    this.newestDownload,
  });

  final int totalDownloads;
  final int completedDownloads;
  final int failedDownloads;
  final int totalSizeBytes;
  final Duration averageDownloadTime;
  final DateTime? oldestDownload;
  final DateTime? newestDownload;

  int get activeDownloads =>
      totalDownloads - completedDownloads - failedDownloads;
  double get successRate =>
      totalDownloads > 0 ? completedDownloads / totalDownloads : 0.0;
}

/// Sync status information
class SyncStatus {
  const SyncStatus({
    required this.lastSyncTime,
    required this.hasPendingChanges,
    required this.pendingFavorites,
    required this.pendingHistory,
    this.syncError,
  });

  final DateTime? lastSyncTime;
  final bool hasPendingChanges;
  final int pendingFavorites;
  final int pendingHistory;
  final String? syncError;

  bool get hasError => syncError != null;
  bool get needsSync => hasPendingChanges || hasError;
}

/// Sync result
class SyncResult {
  const SyncResult({
    required this.success,
    required this.syncedFavorites,
    required this.syncedHistory,
    required this.syncTime,
    this.error,
  });

  final bool success;
  final int syncedFavorites;
  final int syncedHistory;
  final DateTime syncTime;
  final String? error;

  int get totalSynced => syncedFavorites + syncedHistory;
}

/// Sorting options for favorites
enum FavoriteSortOption {
  dateAdded,
  title,
  artist,
  pageCount,
  uploadDate,
}

/// Sorting options for downloads
enum DownloadSortOption {
  dateAdded,
  dateCompleted,
  title,
  fileSize,
  progress,
}

/// Sorting options for history
enum HistorySortOption {
  lastViewed,
  title,
  progress,
  timeSpent,
}

/// Extensions for sort options
extension FavoriteSortOptionExtension on FavoriteSortOption {
  String get displayName {
    switch (this) {
      case FavoriteSortOption.dateAdded:
        return 'Date Added';
      case FavoriteSortOption.title:
        return 'Title';
      case FavoriteSortOption.artist:
        return 'Artist';
      case FavoriteSortOption.pageCount:
        return 'Page Count';
      case FavoriteSortOption.uploadDate:
        return 'Upload Date';
    }
  }
}

extension DownloadSortOptionExtension on DownloadSortOption {
  String get displayName {
    switch (this) {
      case DownloadSortOption.dateAdded:
        return 'Date Added';
      case DownloadSortOption.dateCompleted:
        return 'Date Completed';
      case DownloadSortOption.title:
        return 'Title';
      case DownloadSortOption.fileSize:
        return 'File Size';
      case DownloadSortOption.progress:
        return 'Progress';
    }
  }
}

extension HistorySortOptionExtension on HistorySortOption {
  String get displayName {
    switch (this) {
      case HistorySortOption.lastViewed:
        return 'Last Viewed';
      case HistorySortOption.title:
        return 'Title';
      case HistorySortOption.progress:
        return 'Progress';
      case HistorySortOption.timeSpent:
        return 'Time Spent';
    }
  }
}
