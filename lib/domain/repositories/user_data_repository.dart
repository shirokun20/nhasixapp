import '../entities/entities.dart';

/// Repository interface for user data operations (favorites, downloads, history) - Simplified
abstract class UserDataRepository {
  // ==================== FAVORITES ====================

  /// Add content to favorites (simplified - only id and cover_url)
  ///
  /// [id] - Content ID to add to favorites
  /// [coverUrl] - Content cover URL
  Future<void> addToFavorites({
    required String id,
    required String coverUrl,
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
  /// [page] - Page number for pagination
  /// [limit] - Items per page
  /// Returns list of download statuses
  Future<List<DownloadStatus>> getAllDownloads({
    DownloadState? state,
    int page = 1,
    int limit = 20,
  });

  /// Delete download status
  ///
  /// [id] - Content ID to delete
  Future<void> deleteDownloadStatus(String id);

  /// Get downloads count
  ///
  /// [state] - Filter by download state (all states if null)
  /// Returns total number of downloads
  Future<int> getDownloadsCount({DownloadState? state});

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
