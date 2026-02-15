import '../entities/entities.dart';

/// Repository interface for user data operations (favorites, downloads, history) - Simplified
abstract class UserDataRepository {
  // ==================== FAVORITES ====================

  /// Add content to favorites with full metadata
  ///
  /// [id] - Content ID to add to favorites
  /// [sourceId] - Source identifier (from SourceType enum)
  /// [coverUrl] - Content cover URL
  /// [title] - Content title (optional)
  Future<void> addToFavorites({
    required String id,
    required String sourceId,
    required String coverUrl,
    String? title,
  });

  /// Remove content from favorites
  ///
  /// [id] - Content ID to remove
  Future<void> removeFromFavorites(String id);

  /// Get all favorite content (simplified)
  ///
  /// [page] - Page number for pagination
  /// [limit] - Items per page
  /// Returns list of favorite items with basic info
  Future<List<Map<String, dynamic>>> getFavorites({
    int page = 1,
    int limit = 20,
  });

  /// Check if content is in favorites
  ///
  /// [id] - Content ID to check
  /// Returns true if content is favorited
  Future<bool> isFavorite(String id);

  /// Get favorites count
  ///
  /// Returns total number of favorites
  Future<int> getFavoritesCount();

  // ==================== DOWNLOADS ====================

  /// Save download status
  ///
  /// [status] - Download status to save
  Future<void> saveDownloadStatus(DownloadStatus status);

  /// Get download status
  ///
  /// [id] - Content ID to check
  /// Returns current download status
  Future<DownloadStatus?> getDownloadStatus(String id);

  /// Get all download statuses
  ///
  /// [state] - Filter by download state (all states if null)
  /// [sourceId] - Filter by source ID (optional)
  /// [limit] - Maximum items to return (default: 20)
  /// [offset] - Number of items to skip for pagination (default: 0)
  /// [orderBy] - Field to sort by: 'created_at', 'updated_at', 'content_id' (default: 'created_at')
  /// [descending] - Sort in descending order if true (default: true - newest first)
  /// Returns list of download statuses
  Future<List<DownloadStatus>> getAllDownloads({
    DownloadState? state,
    String? sourceId,
    int limit = 20,
    int offset = 0,
    String orderBy = 'created_at',
    bool descending = true,
  });

  /// Delete download status
  ///
  /// [id] - Content ID to delete
  Future<void> deleteDownloadStatus(String id);

  /// Get downloads count (for pagination)
  ///
  /// [state] - Filter by download state (all states if null)
  /// [sourceId] - Filter by source ID (optional)
  /// Returns total number of downloads matching the state filter
  Future<int> getDownloadsCount({
    DownloadState? state,
    String? sourceId,
  });

  /// Get total download size
  ///
  /// [state] - Filter by download state (all states if null)
  /// [sourceId] - Filter by source ID (optional)
  /// Returns total size in bytes of matching downloads
  Future<int> getTotalDownloadSize({
    DownloadState? state,
    String? sourceId,
  });

  /// Search downloads by query
  ///
  /// [query] - Search query to match against content ID, title, or source ID
  /// [state] - Filter by download state (completed by default for offline search)
  /// [sourceId] - Filter by source ID (optional)
  /// [limit] - Maximum items to return (default: 20)
  /// [offset] - Number of items to skip for pagination (default: 0)
  /// Returns list of matching download records as maps with id, title, source_id, etc.
  Future<List<Map<String, dynamic>>> searchDownloads({
    required String query,
    DownloadState? state,
    String? sourceId,
    int limit = 20,
    int offset = 0,
  });
  
  /// Get search results count
  ///
  /// [query] - Search query to match against content ID, title, or source ID
  /// [state] - Filter by download state
  /// [sourceId] - Filter by source ID (optional)
  /// Returns total number of downloads matching the search query
  Future<int> getSearchCount({
    required String query,
    DownloadState? state,
    String? sourceId,
  });

  /// Get total size of search results
  ///
  /// [query] - Search query
  /// [state] - Filter by download state
  /// [sourceId] - Filter by source ID (optional)
  /// Returns total size in bytes
  Future<int> getSearchDownloadSize({
    required String query,
    DownloadState? state,
    String? sourceId,
  });

  // ==================== HISTORY ====================

  /// Save history entry
  ///
  /// [history] - History entry to save
  Future<void> saveHistory(History history);

  /// Get reading history
  ///
  /// [page] - Page number for pagination
  /// [limit] - Items per page
  /// Returns list of history entries
  Future<List<History>> getHistory({
    int page = 1,
    int limit = 50,
  });

  /// Get history entry for specific content
  ///
  /// [id] - Content ID to get history for
  /// Returns history entry or null if not found
  Future<History?> getHistoryEntry(String id);

  /// Get history entry for specific chapter
  ///
  /// [id] - Content ID
  /// [chapterId] - Chapter ID
  Future<History?> getChapterHistoryEntry(String id, String chapterId);

  /// Get all chapter history for a content
  ///
  /// [id] - Content ID
  Future<List<History>> getAllChapterHistory(String id);

  /// Remove from history
  ///
  /// [id] - Content ID to remove from history
  Future<void> removeFromHistory(String id);

  /// Clear all history
  Future<void> clearHistory();

  /// Get history count
  ///
  /// Returns total number of history entries
  Future<int> getHistoryCount();

  // ==================== PREFERENCES ====================

  /// Save user preferences
  ///
  /// [preferences] - User preferences to save
  Future<void> saveUserPreferences(UserPreferences preferences);

  /// Get user preferences
  ///
  /// Returns current user preferences
  Future<UserPreferences> getUserPreferences();

  /// Save single preference
  ///
  /// [key] - Preference key
  /// [value] - Preference value
  Future<void> savePreference(String key, String value);

  /// Get single preference
  ///
  /// [key] - Preference key
  /// Returns preference value or null if not found
  Future<String?> getPreference(String key);

  // ==================== SEARCH HISTORY ====================

  /// Add search query to history
  ///
  /// [query] - Search query to add
  Future<void> addSearchHistory(String query);

  /// Get search history
  ///
  /// [limit] - Maximum number of entries to return
  /// Returns list of recent search queries
  Future<List<String>> getSearchHistory({int limit = 20});

  /// Clear search history
  Future<void> clearSearchHistory();

  /// Delete specific search history entry
  ///
  /// [query] - Search query to delete
  Future<void> deleteSearchHistory(String query);

  // ==================== SEARCH STATE PERSISTENCE ====================

  /// Save search filter state for persistence
  ///
  /// [sourceId] - Source identifier
  /// [filter] - Search filter to save
  Future<void> saveSearchFilter(String sourceId, SearchFilter filter);

  /// Get last search filter state
  ///
  /// [sourceId] - Source identifier
  /// Returns last saved search filter or null if none exists
  Future<SearchFilter?> getLastSearchFilter(String sourceId);

  /// Clear search filter state
  ///
  /// [sourceId] - Source identifier
  Future<void> clearSearchFilter(String sourceId);

  // ==================== SORTING PREFERENCES ====================

  /// Save sorting preference for persistence
  ///
  /// [sortBy] - Sort option to save
  Future<void> saveSortingPreference(SortOption sortBy);

  /// Get saved sorting preference
  ///
  /// Returns saved sort option or default (newest) if none exists
  Future<SortOption> getSortingPreference();

  // ==================== OFFLINE SYNC ====================

  /// Sync offline favorites and history when coming back online
  ///
  /// This method handles syncing local changes made while offline
  Future<void> syncOfflineData();

  /// Mark data as needing sync when offline changes are made
  ///
  /// [dataType] - Type of data that needs sync ('favorites', 'history', etc.)
  /// [operation] - Operation performed ('add', 'remove', 'update')
  /// [contentId] - ID of content affected
  Future<void> markForSync(String dataType, String operation, String contentId);

  /// Get items that need to be synced
  ///
  /// Returns list of sync operations to perform when online
  Future<List<Map<String, dynamic>>> getPendingSyncItems();

  /// Clear sync queue after successful sync
  Future<void> clearSyncQueue();

  // ==================== UTILITIES ====================

  /// Get database statistics
  ///
  /// Returns statistics about database usage
  Future<Map<String, int>> getDatabaseStats();

  /// Cleanup old data
  Future<void> cleanupOldData();

  /// Clear all data except preferences
  Future<void> clearAllData();
}
