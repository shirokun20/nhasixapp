import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

import '../../models/content_model.dart';
import '../../models/tag_model.dart';
import '../../models/download_status_model.dart';
import '../../models/history_model.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../domain/entities/download_status.dart';
import 'database_helper.dart';

/// Local data source for database operations
class LocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Logger _logger = Logger();

  LocalDataSource(this._databaseHelper);

  // ==================== CONTENT OPERATIONS ====================

  /// Cache content list
  Future<void> cacheContentList(List<ContentModel> contents) async {
    try {
      final db = await _databaseHelper.database;

      // Use transaction for better performance and consistency
      await db.transaction((txn) async {
        for (final content in contents) {
          // Insert or update content
          await txn.insert(
            'contents',
            content.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insert tags and create relationships
          await _insertContentTagsInTransaction(content, txn);
        }
      });

      _logger.d('Cached ${contents.length} contents');
    } catch (e) {
      _logger.e('Error caching content list: $e');
      rethrow;
    }
  }

  /// Get cached content list with pagination
  Future<List<ContentModel>> getCachedContentList({
    int page = 1,
    int limit = 20,
    String? language,
    String? category,
    List<String>? excludeIds,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final offset = (page - 1) * limit;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (language != null) {
        whereClause += ' AND c.language = ?';
        whereArgs.add(language);
      }

      if (category != null) {
        whereClause += ' AND c.category = ?';
        whereArgs.add(category);
      }

      if (excludeIds != null && excludeIds.isNotEmpty) {
        final placeholders = List.filled(excludeIds.length, '?').join(',');
        whereClause += ' AND c.id NOT IN ($placeholders)';
        whereArgs.addAll(excludeIds);
      }

      final result = await db.rawQuery('''
        SELECT c.* FROM contents c
        WHERE $whereClause
        ORDER BY c.upload_date DESC
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      final contents = <ContentModel>[];
      for (final row in result) {
        final tags = await _getContentTags(row['id'] as String);
        contents.add(ContentModel.fromMap(row, tags));
      }

      return contents;
    } catch (e) {
      _logger.e('Error getting cached content list: $e');
      return [];
    }
  }

  /// Get content by ID
  Future<ContentModel?> getContentById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'contents',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final tags = await _getContentTags(id);
      return ContentModel.fromMap(result.first, tags);
    } catch (e) {
      _logger.e('Error getting content by ID: $e');
      return null;
    }
  }

  /// Search cached content
  Future<List<ContentModel>> searchCachedContent({
    String? query,
    List<String>? includeTags,
    List<String>? excludeTags,
    String? language,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final offset = (page - 1) * limit;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (query != null && query.isNotEmpty) {
        whereClause +=
            ' AND (c.title LIKE ? OR c.english_title LIKE ? OR c.japanese_title LIKE ?)';
        final searchQuery = '%$query%';
        whereArgs.addAll([searchQuery, searchQuery, searchQuery]);
      }

      if (language != null) {
        whereClause += ' AND c.language = ?';
        whereArgs.add(language);
      }

      if (category != null) {
        whereClause += ' AND c.category = ?';
        whereArgs.add(category);
      }

      // Handle tag filtering
      String fromClause = 'contents c';
      if (includeTags != null && includeTags.isNotEmpty) {
        fromClause += '''
          INNER JOIN content_tags ct ON c.id = ct.content_id
          INNER JOIN tags t ON ct.tag_id = t.id
        ''';
        final tagPlaceholders = List.filled(includeTags.length, '?').join(',');
        whereClause += ' AND t.name IN ($tagPlaceholders)';
        whereArgs.addAll(includeTags);
      }

      if (excludeTags != null && excludeTags.isNotEmpty) {
        final tagPlaceholders = List.filled(excludeTags.length, '?').join(',');
        whereClause += '''
          AND c.id NOT IN (
            SELECT ct2.content_id FROM content_tags ct2
            INNER JOIN tags t2 ON ct2.tag_id = t2.id
            WHERE t2.name IN ($tagPlaceholders)
          )
        ''';
        whereArgs.addAll(excludeTags);
      }

      final result = await db.rawQuery('''
        SELECT DISTINCT c.* FROM $fromClause
        WHERE $whereClause
        ORDER BY c.upload_date DESC
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      final contents = <ContentModel>[];
      for (final row in result) {
        final tags = await _getContentTags(row['id'] as String);
        contents.add(ContentModel.fromMap(row, tags));
      }

      return contents;
    } catch (e) {
      _logger.e('Error searching cached content: $e');
      return [];
    }
  }

  /// Delete expired cache
  Future<void> deleteExpiredCache(
      {Duration maxAge = const Duration(days: 7)}) async {
    try {
      final db = await _databaseHelper.database;
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

      await db.delete(
        'contents',
        where: 'cached_at < ?',
        whereArgs: [cutoffTime],
      );

      _logger.d('Deleted expired cache older than $maxAge');
    } catch (e) {
      _logger.e('Error deleting expired cache: $e');
    }
  }

  /// Cache single content
  Future<void> cacheContent(ContentModel content) async {
    try {
      final db = await _databaseHelper.database;

      await db.transaction((txn) async {
        // Insert or update content
        await txn.insert(
          'contents',
          content.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert tags and create relationships
        await _insertContentTagsInTransaction(content, txn);
      });

      _logger.d('Cached content: ${content.id}');
    } catch (e) {
      _logger.e('Error caching content: $e');
      rethrow;
    }
  }

  // ==================== TAG OPERATIONS ====================

  /// Insert content tags within a transaction
  Future<void> _insertContentTagsInTransaction(
      ContentModel content, Transaction txn) async {
    // First, delete existing relationships for this content
    await txn.delete('content_tags',
        where: 'content_id = ?', whereArgs: [content.id]);

    // Insert or update tags and create relationships
    for (final tag in content.tags) {
      final tagModel = TagModel.fromEntity(tag);

      // Insert or ignore tag (will not overwrite existing)
      await txn.insert(
        'tags',
        tagModel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Get the tag ID
      final tagResult = await txn.query(
        'tags',
        columns: ['id'],
        where: 'name = ? AND type = ?',
        whereArgs: [tag.name, tag.type],
        limit: 1,
      );

      if (tagResult.isNotEmpty) {
        final tagId = tagResult.first['id'];

        // Create content-tag relationship
        await txn.insert('content_tags', {
          'content_id': content.id,
          'tag_id': tagId,
        });
      }
    }
  }

  /// Get content tags
  Future<List<TagModel>> _getContentTags(String contentId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN content_tags ct ON t.id = ct.tag_id
      WHERE ct.content_id = ?
      ORDER BY t.type, t.name
    ''', [contentId]);

    return result.map((row) => TagModel.fromMap(row)).toList();
  }

  /// Get all tags with optional filtering
  Future<List<TagModel>> getAllTags({
    String? type,
    int? minCount,
    int limit = 100,
  }) async {
    try {
      final db = await _databaseHelper.database;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (type != null) {
        whereClause += ' AND type = ?';
        whereArgs.add(type);
      }

      if (minCount != null) {
        whereClause += ' AND count >= ?';
        whereArgs.add(minCount);
      }

      final result = await db.query(
        'tags',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'count DESC, name ASC',
        limit: limit,
      );

      return result.map((row) => TagModel.fromMap(row)).toList();
    } catch (e) {
      _logger.e('Error getting all tags: $e');
      return [];
    }
  }

  /// Search tags
  Future<List<TagModel>> searchTags(String query, {int limit = 50}) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'tags',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'count DESC, name ASC',
        limit: limit,
      );

      return result.map((row) => TagModel.fromMap(row)).toList();
    } catch (e) {
      _logger.e('Error searching tags: $e');
      return [];
    }
  }

  // ==================== FAVORITES OPERATIONS ====================

  /// Add content to favorites
  Future<void> addToFavorites(String contentId, {int categoryId = 1}) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        'favorites',
        {
          'content_id': contentId,
          'category_id': categoryId,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger
          .d('Added content $contentId to favorites (category: $categoryId)');
    } catch (e) {
      _logger.e('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove content from favorites
  Future<void> removeFromFavorites(String contentId, {int? categoryId}) async {
    try {
      final db = await _databaseHelper.database;

      String whereClause = 'content_id = ?';
      List<dynamic> whereArgs = [contentId];

      if (categoryId != null) {
        whereClause += ' AND category_id = ?';
        whereArgs.add(categoryId);
      }

      await db.delete('favorites', where: whereClause, whereArgs: whereArgs);
      _logger.d('Removed content $contentId from favorites');
    } catch (e) {
      _logger.e('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Get favorite content
  Future<List<ContentModel>> getFavorites({
    int? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final offset = (page - 1) * limit;

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (categoryId != null) {
        whereClause += ' AND f.category_id = ?';
        whereArgs.add(categoryId);
      }

      final result = await db.rawQuery('''
        SELECT c.* FROM contents c
        INNER JOIN favorites f ON c.id = f.content_id
        WHERE $whereClause
        ORDER BY f.added_at DESC
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      final contents = <ContentModel>[];
      for (final row in result) {
        final tags = await _getContentTags(row['id'] as String);
        contents.add(ContentModel.fromMap(row, tags));
      }

      return contents;
    } catch (e) {
      _logger.e('Error getting favorites: $e');
      return [];
    }
  }

  /// Check if content is favorited
  Future<bool> isFavorited(String contentId, {int? categoryId}) async {
    try {
      final db = await _databaseHelper.database;

      String whereClause = 'content_id = ?';
      List<dynamic> whereArgs = [contentId];

      if (categoryId != null) {
        whereClause += ' AND category_id = ?';
        whereArgs.add(categoryId);
      }

      final result = await db.query(
        'favorites',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking if favorited: $e');
      return false;
    }
  }

  /// Create favorite category
  Future<int> createFavoriteCategory(String name) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('favorite_categories', {
        'name': name,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      _logger.d('Created favorite category: $name (ID: $id)');
      return id;
    } catch (e) {
      _logger.e('Error creating favorite category: $e');
      rethrow;
    }
  }

  /// Get favorite categories
  Future<List<Map<String, dynamic>>> getFavoriteCategories() async {
    try {
      final db = await _databaseHelper.database;
      return await db.query(
        'favorite_categories',
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      _logger.e('Error getting favorite categories: $e');
      return [];
    }
  }

  // ==================== DOWNLOAD OPERATIONS ====================

  /// Save download status
  Future<void> saveDownloadStatus(DownloadStatusModel status) async {
    try {
      final db = await _databaseHelper.database;
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
  Future<DownloadStatusModel?> getDownloadStatus(String contentId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'downloads',
        where: 'content_id = ?',
        whereArgs: [contentId],
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
      final db = await _databaseHelper.database;
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
  Future<void> deleteDownloadStatus(String contentId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'downloads',
        where: 'content_id = ?',
        whereArgs: [contentId],
      );

      _logger.d('Deleted download status for $contentId');
    } catch (e) {
      _logger.e('Error deleting download status: $e');
    }
  }

  // ==================== HISTORY OPERATIONS ====================

  /// Save history entry
  Future<void> saveHistory(HistoryModel history) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        'history',
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Saved history for ${history.contentId}');
    } catch (e) {
      _logger.e('Error saving history: $e');
      rethrow;
    }
  }

  /// Get history entry
  Future<HistoryModel?> getHistory(String contentId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'history',
        where: 'content_id = ?',
        whereArgs: [contentId],
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
      final db = await _databaseHelper.database;
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
      final db = await _databaseHelper.database;
      await db.delete('history');
      _logger.d('Cleared all history');
    } catch (e) {
      _logger.e('Error clearing history: $e');
    }
  }

  /// Delete history entry
  Future<void> deleteHistory(String contentId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'history',
        where: 'content_id = ?',
        whereArgs: [contentId],
      );

      _logger.d('Deleted history for $contentId');
    } catch (e) {
      _logger.e('Error deleting history: $e');
    }
  }

  // ==================== PREFERENCES OPERATIONS ====================

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      final db = await _databaseHelper.database;
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

      batch.insert(
        'preferences',
        {
          'key': 'favoriteCategories',
          'value': jsonEncode(preferences.favoriteCategories),
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
      final db = await _databaseHelper.database;
      final result = await db.query('preferences');

      final prefsMap = <String, dynamic>{};
      for (final row in result) {
        final key = row['key'] as String;
        final value = row['value'] as String;

        // Handle special cases for lists
        if (key == 'blacklistedTags' || key == 'favoriteCategories') {
          try {
            prefsMap[key] = jsonDecode(value);
          } catch (e) {
            prefsMap[key] = <String>[];
          }
        } else {
          prefsMap[key] = value;
        }
      }

      return UserPreferences.fromJson(prefsMap);
    } catch (e) {
      _logger.e('Error getting user preferences: $e');
      return const UserPreferences(); // Return default preferences
    }
  }

  // ==================== SEARCH HISTORY OPERATIONS ====================

  /// Add search query to history
  Future<void> addSearchHistory(String query) async {
    try {
      final db = await _databaseHelper.database;

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
      final db = await _databaseHelper.database;
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
      final db = await _databaseHelper.database;
      await db.delete('search_history');
      _logger.d('Cleared search history');
    } catch (e) {
      _logger.e('Error clearing search history: $e');
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await _databaseHelper.database;

      final stats = <String, int>{};

      // Count records in each table
      final tables = [
        'contents',
        'tags',
        'content_tags',
        'favorites',
        'downloads',
        'history',
        'search_history',
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
      final db = await _databaseHelper.database;
      final batch = db.batch();

      // Delete old cache (older than 7 days)
      final cacheThreshold = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      batch.delete('contents',
          where: 'cached_at < ?', whereArgs: [cacheThreshold]);

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
}
