import 'package:logger/logger.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../datasources/local/local_data_source.dart';
import '../models/download_status_model.dart';
import '../models/history_model.dart';

/// Implementation of UserDataRepository for local data management (simplified)
class UserDataRepositoryImpl implements UserDataRepository {
  UserDataRepositoryImpl({
    required this.localDataSource,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final LocalDataSource localDataSource;
  final Logger _logger;

  // ==================== FAVORITES ====================

  @override
  Future<void> addToFavorites({
    required String id,
    required String coverUrl,
  }) async {
    try {
      _logger.i('Adding content $id to favorites');
      await localDataSource.addToFavorites(id, coverUrl);
      _logger.d('Successfully added to favorites');
    } catch (e, stackTrace) {
      _logger.e('Failed to add to favorites', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String id) async {
    try {
      _logger.i('Removing content $id from favorites');
      await localDataSource.removeFromFavorites(id);
      _logger.d('Successfully removed from favorites');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from favorites',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.i('Getting favorites, page: $page, limit: $limit');
      final favorites = await localDataSource.getFavorites(
        page: page,
        limit: limit,
      );
      _logger.d('Retrieved ${favorites.length} favorites');
      return favorites;
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorites', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<bool> isFavorite(String id) async {
    try {
      return await localDataSource.isFavorited(id);
    } catch (e, stackTrace) {
      _logger.e('Failed to check if favorite',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<int> getFavoritesCount() async {
    try {
      return await localDataSource.getFavoritesCount();
    } catch (e, stackTrace) {
      _logger.e('Failed to get favorites count',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  // ==================== DOWNLOADS ====================

  @override
  Future<void> saveDownloadStatus(DownloadStatus status) async {
    try {
      _logger.d('Saving download status for: ${status.contentId}');

      // Create model with additional info if available
      final statusModel = DownloadStatusModel.fromEntity(status);
      await localDataSource.saveDownloadStatus(statusModel);
    } catch (e, stackTrace) {
      _logger.e('Failed to save download status',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<DownloadStatus?> getDownloadStatus(String id) async {
    try {
      final statusModel = await localDataSource.getDownloadStatus(id);
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
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.i('Getting all downloads - state: $state, page: $page');

      final statusModels = await localDataSource.getAllDownloads(
        state: state,
        page: page,
        limit: limit,
      );

      final downloads = statusModels.map((model) => model.toEntity()).toList();
      _logger.d('Retrieved ${downloads.length} downloads');
      return downloads;
    } catch (e, stackTrace) {
      _logger.e('Failed to get all downloads',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> deleteDownloadStatus(String id) async {
    try {
      _logger.i('Deleting download status: $id');
      await localDataSource.deleteDownloadStatus(id);
      _logger.d('Download status deleted');
    } catch (e, stackTrace) {
      _logger.e('Failed to delete download status',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getDownloadsCount({DownloadState? state}) async {
    try {
      return await localDataSource.getDownloadsCount(state: state);
    } catch (e, stackTrace) {
      _logger.e('Failed to get downloads count',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  // ==================== HISTORY ====================

  @override
  Future<void> saveHistory(History history) async {
    try {
      _logger.d('Saving history for: ${history.contentId}');

      // Create model with additional info if available
      final historyModel = HistoryModel.fromEntity(history);
      await localDataSource.saveHistory(historyModel);
    } catch (e, stackTrace) {
      _logger.e('Failed to save history', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<History>> getHistory({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _logger.i('Getting history - page: $page, limit: $limit');

      final historyModels = await localDataSource.getAllHistory(
        page: page,
        limit: limit,
      );

      final history = historyModels.map((model) => model.toEntity()).toList();
      _logger.d('Retrieved ${history.length} history entries');
      return history;
    } catch (e, stackTrace) {
      _logger.e('Failed to get history', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<History?> getHistoryEntry(String id) async {
    try {
      final historyModel = await localDataSource.getHistory(id);
      return historyModel?.toEntity();
    } catch (e, stackTrace) {
      _logger.e('Failed to get history entry',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> removeFromHistory(String id) async {
    try {
      _logger.i('Removing from history: $id');
      await localDataSource.deleteHistory(id);
      _logger.d('Removed from history');
    } catch (e, stackTrace) {
      _logger.e('Failed to remove from history',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      _logger.i('Clearing all history');
      await localDataSource.clearHistory();
      _logger.d('History cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear history', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getHistoryCount() async {
    try {
      return await localDataSource.getHistoryCount();
    } catch (e, stackTrace) {
      _logger.e('Failed to get history count',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  // ==================== PREFERENCES ====================

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      _logger.i('Saving user preferences');
      await localDataSource.saveUserPreferences(preferences);
      _logger.d('User preferences saved');
    } catch (e, stackTrace) {
      _logger.e('Failed to save user preferences',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserPreferences> getUserPreferences() async {
    try {
      return await localDataSource.getUserPreferences();
    } catch (e, stackTrace) {
      _logger.e('Failed to get user preferences',
          error: e, stackTrace: stackTrace);
      return const UserPreferences(); // Return default preferences
    }
  }

  @override
  Future<void> savePreference(String key, String value) async {
    try {
      _logger.d('Saving preference: $key = $value');
      await localDataSource.savePreference(key, value);
    } catch (e, stackTrace) {
      _logger.e('Failed to save preference', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> getPreference(String key) async {
    try {
      return await localDataSource.getPreference(key);
    } catch (e, stackTrace) {
      _logger.e('Failed to get preference', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // ==================== SEARCH HISTORY ====================

  @override
  Future<void> addSearchHistory(String query) async {
    try {
      _logger.d('Adding search history: $query');
      await localDataSource.addSearchHistory(query);
    } catch (e, stackTrace) {
      _logger.e('Failed to add search history',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      return await localDataSource.getSearchHistory(limit: limit);
    } catch (e, stackTrace) {
      _logger.e('Failed to get search history',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    try {
      _logger.i('Clearing search history');
      await localDataSource.clearSearchHistory();
      _logger.d('Search history cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear search history',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteSearchHistory(String query) async {
    try {
      _logger.d('Deleting search history: $query');
      await localDataSource.deleteSearchHistory(query);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete search history',
          error: e, stackTrace: stackTrace);
    }
  }

  // ==================== UTILITIES ====================

  @override
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      return await localDataSource.getDatabaseStats();
    } catch (e, stackTrace) {
      _logger.e('Failed to get database stats',
          error: e, stackTrace: stackTrace);
      return {};
    }
  }

  @override
  Future<void> cleanupOldData() async {
    try {
      _logger.i('Cleaning up old data');
      await localDataSource.cleanupOldData();
      _logger.d('Old data cleaned up');
    } catch (e, stackTrace) {
      _logger.e('Failed to cleanup old data', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      _logger.i('Clearing all data');
      await localDataSource.clearAllData();
      _logger.d('All data cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear all data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==================== SEARCH STATE PERSISTENCE ====================

  @override
  Future<void> saveSearchFilter(SearchFilter filter) async {
    try {
      _logger.d('Saving search filter state');
      await localDataSource.saveSearchFilter(filter.toJson());
      _logger.d('Search filter state saved');
    } catch (e, stackTrace) {
      _logger.e('Failed to save search filter',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SearchFilter?> getLastSearchFilter() async {
    try {
      final filterData = await localDataSource.getLastSearchFilter();
      if (filterData != null) {
        return SearchFilter.fromJson(filterData);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('Failed to get last search filter',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> clearSearchFilter() async {
    try {
      _logger.d('Clearing search filter state');
      await localDataSource.clearSearchFilter();
      _logger.d('Search filter state cleared');
    } catch (e, stackTrace) {
      _logger.e('Failed to clear search filter',
          error: e, stackTrace: stackTrace);
    }
  }

  // ==================== SORTING PREFERENCES ====================

  @override
  Future<void> saveSortingPreference(SortOption sortBy) async {
    try {
      _logger.d('Saving sorting preference: ${sortBy.name}');
      await localDataSource.savePreference('sorting_preference', sortBy.name);
      _logger.d('Sorting preference saved');
    } catch (e, stackTrace) {
      _logger.e('Failed to save sorting preference',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<SortOption> getSortingPreference() async {
    try {
      final sortName =
          await localDataSource.getPreference('sorting_preference');
      if (sortName != null) {
        return SortOption.values.firstWhere(
          (e) => e.name == sortName,
          orElse: () => SortOption.newest,
        );
      }
      return SortOption.newest; // Default sort option
    } catch (e, stackTrace) {
      _logger.e('Failed to get sorting preference',
          error: e, stackTrace: stackTrace);
      return SortOption.newest; // Default sort option
    }
  }

  // ==================== OFFLINE SYNC ====================

  @override
  Future<void> syncOfflineData() async {
    try {
      _logger.i('Starting offline data sync');

      final pendingItems = await getPendingSyncItems();
      if (pendingItems.isEmpty) {
        _logger.d('No pending sync items found');
        return;
      }

      _logger.i('Found ${pendingItems.length} items to sync');

      // For now, just clear the sync queue since we don't have a remote server
      // In a real implementation, this would sync with a remote server
      await clearSyncQueue();

      _logger.i('Offline data sync completed');
    } catch (e, stackTrace) {
      _logger.e('Failed to sync offline data',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markForSync(
      String dataType, String operation, String contentId) async {
    try {
      _logger.d('Marking for sync: $dataType $operation $contentId');

      // Store sync operation in preferences for simplicity
      // In a real implementation, this would use a dedicated sync table
      final syncData = {
        'dataType': dataType,
        'operation': operation,
        'contentId': contentId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await localDataSource.savePreference(
        'sync_${dataType}_${contentId}_${operation}',
        syncData.toString(),
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to mark for sync', error: e, stackTrace: stackTrace);
      // Don't rethrow - sync marking is not critical
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      // For simplicity, return empty list
      // In a real implementation, this would query a sync table
      return [];
    } catch (e, stackTrace) {
      _logger.e('Failed to get pending sync items',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<void> clearSyncQueue() async {
    try {
      _logger.d('Clearing sync queue');
      // For simplicity, do nothing
      // In a real implementation, this would clear the sync table
    } catch (e, stackTrace) {
      _logger.e('Failed to clear sync queue', error: e, stackTrace: stackTrace);
    }
  }
}
