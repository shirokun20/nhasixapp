import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

import '../../models/download_status_model.dart';
import '../../models/history_model.dart';
import '../../models/reader_position_model.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../domain/entities/download_status.dart';
import 'database_helper.dart';

/// Local data source for database operations (simplified)
class LocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Logger _logger = Logger();

  LocalDataSource(this._databaseHelper);

  /// Handle database errors and attempt recovery
  Future<Database?> _getSafeDatabase() async {
    try {
      return await _databaseHelper.database;
    } catch (e) {
      _logger.e('Database access failed: $e');

      // Attempt to reset database if it's corrupted
      try {
        _logger.w('Attempting to reset corrupted database...');
        await _databaseHelper.resetDatabase();
        return await _databaseHelper.database;
      } catch (resetError) {
        _logger.e('Database reset failed: $resetError');
        return null;
      }
    }
  }

  // ==================== FAVORITES OPERATIONS ====================

  /// Add content to favorites (simplified - only id and cover_url)
  Future<void> addToFavorites(String id, String coverUrl) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot add to favorites');
        return;
      }

      await db.insert(
        'favorites',
        {
          'id': id,
          'cover_url': coverUrl,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Added content $id to favorites');
    } catch (e) {
      _logger.e('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove content from favorites
  Future<void> removeFromFavorites(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot remove from favorites');
        return;
      }

      await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
      _logger.d('Removed content $id from favorites');
    } catch (e) {
      _logger.e('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Get favorite content (simplified)
  Future<List<Map<String, dynamic>>> getFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty favorites');
        return [];
      }

      final offset = (page - 1) * limit;

      final result = await db.query(
        'favorites',
        orderBy: 'added_at DESC',
        limit: limit,
        offset: offset,
      );

      return result;
    } catch (e) {
      _logger.e('Error getting favorites: $e');
      return [];
    }
  }

  /// Check if content is favorited
  Future<bool> isFavorited(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot check if favorited');
        return false;
      }

      final result = await db.query(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking if favorited: $e');
      return false;
    }
  }

  /// Get favorites count
  Future<int> getFavoritesCount() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) return 0;

      final result =
          await db.rawQuery('SELECT COUNT(*) as count FROM favorites');
      return result.first['count'] as int;
    } catch (e) {
      _logger.e('Error getting favorites count: $e');
      return 0;
    }
  }

  // ==================== DOWNLOAD OPERATIONS ====================

  /// Save download status (with title and cover_url)
  Future<void> saveDownloadStatus(DownloadStatusModel status) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save download status');
        return;
      }

      await db.insert(
        'downloads',
        status.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved download status for ${status.contentId}');
    } catch (e) {
      _logger.e('Error saving download status: $e');
      rethrow;
    }
  }

  /// Get download status
  Future<DownloadStatusModel?> getDownloadStatus(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot get download status');
        return null;
      }

      final result = await db.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return DownloadStatusModel.fromMap(result.first);
    } catch (e) {
      _logger.e('Error getting download status: $e');
      return null;
    }
  }

  /// Get all downloads with optional state filtering
  Future<List<DownloadStatusModel>> getAllDownloads({
    DownloadState? state,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty downloads');
        return [];
      }

      final offset = (page - 1) * limit;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (state != null) {
        whereClause += ' AND state = ?';
        whereArgs.add(state.name);
      }

      final result = await db.query(
        'downloads',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'start_time DESC',
        limit: limit,
        offset: offset,
      );

      return result.map((row) => DownloadStatusModel.fromMap(row)).toList();
    } catch (e) {
      _logger.e('Error getting all downloads: $e');
      return [];
    }
  }

  /// Delete download status
  Future<void> deleteDownloadStatus(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot delete download status');
        return;
      }

      await db.delete(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );

      _logger.d('Deleted download status for $id');
    } catch (e) {
      _logger.e('Error deleting download status: $e');
    }
  }

  /// Get downloads count by state
  Future<int> getDownloadsCount({DownloadState? state}) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) return 0;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (state != null) {
        whereClause += ' AND state = ?';
        whereArgs.add(state.name);
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM downloads WHERE $whereClause',
        whereArgs.isNotEmpty ? whereArgs : null,
      );
      return result.first['count'] as int;
    } catch (e) {
      _logger.e('Error getting downloads count: $e');
      return 0;
    }
  }

  // ==================== HISTORY OPERATIONS ====================

  /// Save history entry (with title and cover_url)
  Future<void> saveHistory(HistoryModel history) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save history');
        return;
      }

      _logger.i("isi datanya: ${history.toMap()}");

      await db.insert(
        'history',
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved history for ${history.contentId}');
    } catch (e) {
      _logger.e('Error saving history: $e');

      // If it's a schema error, try to fix it
      if (e.toString().contains('no column named id') ||
          e.toString().contains('table history has no column named id')) {
        _logger.w(
            'Detected history table schema issue, attempting to reset database...');
        try {
          await _databaseHelper.resetDatabase();
          // Retry the operation after reset
          final newDb = await _getSafeDatabase();
          if (newDb != null) {
            await newDb.insert(
              'history',
              history.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _logger.i('Successfully saved history after database reset');
            return;
          }
        } catch (resetError) {
          _logger.e('Failed to reset database: $resetError');
        }
      }

      rethrow;
    }
  }

  /// Get history entry
  Future<HistoryModel?> getHistory(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot get history');
        return null;
      }

      final result = await db.query(
        'history',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return HistoryModel.fromMap(result.first);
    } catch (e) {
      _logger.e('Error getting history: $e');
      return null;
    }
  }

  /// Get all history entries
  Future<List<HistoryModel>> getAllHistory({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty history');
        return [];
      }

      final offset = (page - 1) * limit;

      final result = await db.query(
        'history',
        orderBy: 'last_viewed DESC',
        limit: limit,
        offset: offset,
      );

      return result.map((row) => HistoryModel.fromMap(row)).toList();
    } catch (e) {
      _logger.e('Error getting all history: $e');
      return [];
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot clear history');
        return;
      }

      await db.delete('history');
      _logger.d('Cleared all history');
    } catch (e) {
      _logger.e('Error clearing history: $e');
    }
  }

  /// Delete history entry
  Future<void> deleteHistory(String id) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot delete history');
        return;
      }

      await db.delete(
        'history',
        where: 'id = ?',
        whereArgs: [id],
      );

      _logger.d('Deleted history for $id');
    } catch (e) {
      _logger.e('Error deleting history: $e');
    }
  }

  /// Get history count
  Future<int> getHistoryCount() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) return 0;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM history');
      return result.first['count'] as int;
    } catch (e) {
      _logger.e('Error getting history count: $e');
      return 0;
    }
  }

  // ==================== PREFERENCES OPERATIONS ====================

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save preferences');
        return;
      }

      final batch = db.batch();

      final prefsMap = preferences.toJson();
      for (final entry in prefsMap.entries) {
        batch.insert(
          'preferences',
          {
            'key': entry.key,
            'value': entry.value.toString(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Handle list preferences separately
      batch.insert(
        'preferences',
        {
          'key': 'blacklistedTags',
          'value': jsonEncode(preferences.blacklistedTags),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await batch.commit();
      _logger.d('Saved user preferences');
    } catch (e) {
      _logger.e('Error saving user preferences: $e');
      rethrow;
    }
  }

  /// Get user preferences
  Future<UserPreferences> getUserPreferences() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning default preferences');
        return const UserPreferences();
      }

      final result = await db.query('preferences');

      final prefsMap = <String, dynamic>{};
      for (final row in result) {
        final key = row['key'] as String;
        final value = row['value'] as String;

        // Handle special cases for different data types
        if (key == 'blacklistedTags' || key == 'favoriteCategories') {
          try {
            prefsMap[key] = jsonDecode(value);
          } catch (e) {
            prefsMap[key] = <String>[];
          }
        } else if (_isBooleanField(key)) {
          prefsMap[key] = value.toLowerCase() == 'true';
        } else if (_isIntField(key)) {
          prefsMap[key] = int.tryParse(value) ?? _getDefaultIntValue(key);
        } else if (_isDoubleField(key)) {
          prefsMap[key] = double.tryParse(value) ?? _getDefaultDoubleValue(key);
        } else {
          prefsMap[key] = value;
        }
      }

      return UserPreferences.fromJson(prefsMap);
    } catch (e, stackTrace) {
      _logger.e('Error getting user preferences: $e');
      _logger.e('Stack trace: $stackTrace');
      return const UserPreferences(); // Return default preferences
    }
  }

  /// Check if field should be boolean
  bool _isBooleanField(String key) {
    const boolFields = {
      'autoDownload',
      'showTitles',
      'blurThumbnails',
      'usePagination',
      'useVolumeKeys',
      'keepScreenOn',
      'showSystemUI',
      'autoBackup',
      'showNsfwContent',
      'readerInvertColors',
      'readerShowPageNumbers',
      'readerShowProgressBar',
      'readerAutoHideUI',
      'readerHideOnTap',
      'readerHideOnSwipe',
    };
    return boolFields.contains(key);
  }

  /// Check if field should be integer
  bool _isIntField(String key) {
    const intFields = {
      'columnsPortrait',
      'columnsLandscape',
      'maxConcurrentDownloads',
      'readerAutoHideDelay',
    };
    return intFields.contains(key);
  }

  /// Check if field should be double
  bool _isDoubleField(String key) {
    const doubleFields = {
      'readerBrightness',
    };
    return doubleFields.contains(key);
  }

  /// Get default integer value for field
  int _getDefaultIntValue(String key) {
    switch (key) {
      case 'columnsPortrait':
        return 2;
      case 'columnsLandscape':
        return 3;
      case 'maxConcurrentDownloads':
        return 3;
      case 'readerAutoHideDelay':
        return 3;
      default:
        return 0;
    }
  }

  /// Get default double value for field
  double _getDefaultDoubleValue(String key) {
    switch (key) {
      case 'readerBrightness':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Save single preference
  Future<void> savePreference(String key, String value) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save preference');
        return;
      }

      await db.insert(
        'preferences',
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved preference: $key = $value');
    } catch (e) {
      _logger.e('Error saving preference: $e');
      rethrow;
    }
  }

  /// Get single preference
  Future<String?> getPreference(String key) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot get preference');
        return null;
      }

      final result = await db.query(
        'preferences',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return result.first['value'] as String;
    } catch (e) {
      _logger.e('Error getting preference: $e');
      return null;
    }
  }

  // ==================== SEARCH HISTORY OPERATIONS ====================

  /// Add search query to history
  Future<void> addSearchHistory(String query) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot add search history');
        return;
      }

      // Remove existing entry if it exists
      await db.delete(
        'search_history',
        where: 'query = ?',
        whereArgs: [query],
      );

      // Add new entry
      await db.insert('search_history', {
        'query': query,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Keep only last 50 searches
      await db.rawDelete('''
        DELETE FROM search_history 
        WHERE id NOT IN (
          SELECT id FROM search_history 
          ORDER BY searched_at DESC 
          LIMIT 50
        )
      ''');

      _logger.d('Added search history: $query');
    } catch (e) {
      _logger.e('Error adding search history: $e');
    }
  }

  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty search history');
        return [];
      }

      final result = await db.query(
        'search_history',
        columns: ['query'],
        orderBy: 'searched_at DESC',
        limit: limit,
      );

      return result.map((row) => row['query'] as String).toList();
    } catch (e) {
      _logger.e('Error getting search history: $e');
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot clear search history');
        return;
      }

      await db.delete('search_history');
      _logger.d('Cleared search history');
    } catch (e) {
      _logger.e('Error clearing search history: $e');
    }
  }

  /// Delete specific search history entry
  Future<void> deleteSearchHistory(String query) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot delete search history');
        return;
      }

      await db.delete(
        'search_history',
        where: 'query = ?',
        whereArgs: [query],
      );

      _logger.d('Deleted search history: $query');
    } catch (e) {
      _logger.e('Error deleting search history: $e');
    }
  }

  // ==================== SEARCH FILTER STATE PERSISTENCE ====================

  /// Save search filter state for persistence
  Future<void> saveSearchFilter(Map<String, dynamic> filterData) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save search filter');
        return;
      }

      await db.insert(
        'search_filter_state',
        {
          'id': 1, // Always use ID 1 for single state
          'filter_data': jsonEncode(filterData),
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved search filter state');
    } catch (e) {
      _logger.e('Error saving search filter: $e');
      rethrow;
    }
  }

  /// Get last search filter state
  Future<Map<String, dynamic>?> getLastSearchFilter() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot get search filter');
        return null;
      }

      final result = await db.query(
        'search_filter_state',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final filterDataString = result.first['filter_data'] as String;
      return jsonDecode(filterDataString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error getting search filter: $e');
      return null;
    }
  }

  /// Clear search filter state
  Future<void> clearSearchFilter() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot clear search filter');
        return;
      }

      await db.delete('search_filter_state');
      _logger.d('Cleared search filter state');
    } catch (e) {
      _logger.e('Error clearing search filter: $e');
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty stats');
        return {};
      }

      final stats = <String, int>{};

      // Count records in each table
      final tables = [
        'favorites',
        'downloads',
        'history',
        'search_history',
        'preferences',
      ];

      for (final table in tables) {
        final result =
            await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats[table] = result.first['count'] as int;
      }

      return stats;
    } catch (e) {
      _logger.e('Error getting database stats: $e');
      return {};
    }
  }

  /// Cleanup old data
  Future<void> cleanupOldData() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot cleanup old data');
        return;
      }

      final batch = db.batch();

      // Delete old search history (older than 30 days)
      final searchThreshold = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      batch.delete('search_history',
          where: 'searched_at < ?', whereArgs: [searchThreshold]);

      // Delete completed downloads older than 30 days
      final downloadThreshold = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      batch.delete('downloads',
          where: 'state = ? AND end_time < ?',
          whereArgs: ['completed', downloadThreshold]);

      await batch.commit();
      _logger.d('Cleaned up old data');
    } catch (e) {
      _logger.e('Error cleaning up old data: $e');
    }
  }

  /// Clear all data except preferences
  Future<void> clearAllData() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot clear all data');
        return;
      }

      final batch = db.batch();

      // Clear all tables except preferences
      batch.delete('search_history');
      batch.delete('history');
      batch.delete('downloads');
      batch.delete('favorites');
      batch.delete('reader_positions');

      await batch.commit();
      _logger.i('All data cleared from database');
    } catch (e) {
      _logger.e('Error clearing all data: $e');
    }
  }

  // ==================== READER POSITION OPERATIONS ====================

  /// Save reader position
  Future<void> saveReaderPosition(ReaderPositionModel position) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot save reader position');
        return;
      }

      await db.insert(
        'reader_positions',
        position.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved reader position for ${position.contentId}');
    } catch (e) {
      _logger.e('Error saving reader position: $e');
      rethrow;
    }
  }

  /// Get reader position by content ID
  Future<ReaderPositionModel?> getReaderPosition(String contentId) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot get reader position');
        return null;
      }

      final result = await db.query(
        'reader_positions',
        where: 'content_id = ?',
        whereArgs: [contentId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return ReaderPositionModel.fromMap(result.first);
    } catch (e) {
      _logger.e('Error getting reader position: $e');
      return null;
    }
  }

  /// Get all reader positions
  Future<List<ReaderPositionModel>> getAllReaderPositions({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, returning empty reader positions');
        return [];
      }

      final offset = (page - 1) * limit;

      final result = await db.query(
        'reader_positions',
        orderBy: 'last_accessed DESC',
        limit: limit,
        offset: offset,
      );

      return result.map((row) => ReaderPositionModel.fromMap(row)).toList();
    } catch (e) {
      _logger.e('Error getting all reader positions: $e');
      return [];
    }
  }

  /// Delete reader position
  Future<void> deleteReaderPosition(String contentId) async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot delete reader position');
        return;
      }

      await db.delete(
        'reader_positions',
        where: 'content_id = ?',
        whereArgs: [contentId],
      );

      _logger.d('Deleted reader position for $contentId');
    } catch (e) {
      _logger.e('Error deleting reader position: $e');
    }
  }

  /// Clear all reader positions
  Future<void> clearAllReaderPositions() async {
    try {
      final db = await _getSafeDatabase();
      if (db == null) {
        _logger.e('Database not available, cannot clear reader positions');
        return;
      }

      await db.delete('reader_positions');
      _logger.d('Cleared all reader positions');
    } catch (e) {
      _logger.e('Error clearing reader positions: $e');
    }
  }

  /// Add method to remove last search filter (fix for search persistence issue)
  Future<void> removeLastSearchFilter() async {
    try {
      await clearSearchFilter();
      _logger.d('Removed last search filter');
    } catch (e) {
      _logger.e('Error removing last search filter: $e');
      rethrow;
    }
  }
}
