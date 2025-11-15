import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'cache_service.dart';

/// Disk-based cache implementation using SQLite for metadata and files for content
/// Provides persistent caching across app restarts
class DiskCacheService<T> implements CacheService<T> {
  static const String _cacheTableName = 'cache_metadata';
  static const int _databaseVersion = 1;

  final String namespace;
  final int maxSizeMB;
  final Duration defaultTTL;
  final Logger _logger = Logger();

  Database? _database;
  Directory? _cacheDir;

  // Statistics tracking
  int _hits = 0;
  int _misses = 0;

  DiskCacheService({
    required this.namespace,
    this.maxSizeMB = 50,
    this.defaultTTL = const Duration(days: 1),
  });

  /// Initialize database and cache directory
  Future<void> initialize() async {
    if (_database != null && _cacheDir != null) return;

    // Initialize database
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'disk_cache_$namespace.db');

    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    // Initialize cache directory
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'disk_cache', namespace));

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    _logger.i('DiskCacheService initialized for namespace: $namespace');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_cacheTableName (
        cache_key TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<T?> get(String key) async {
    await initialize();

    try {
      final result = await _database!.query(
        _cacheTableName,
        where: 'cache_key = ?',
        whereArgs: [key],
      );

      if (result.isEmpty) {
        _misses++;
        _logger.d('Disk cache miss: $key');
        return null;
      }

      final entry = result.first;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        entry['expires_at'] as int,
      );

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        _misses++;
        await remove(key);
        _logger.d('Disk cache expired: $key');
        return null;
      }

      // Read from file
      final filePath = entry['file_path'] as String;
      final file = File(filePath);

      if (!await file.exists()) {
        _misses++;
        await remove(key);
        _logger.w('Disk cache file not found: $filePath');
        return null;
      }

      final jsonStr = await file.readAsString();
      final jsonData = json.decode(jsonStr);

      _hits++;
      _logger.d('Disk cache hit: $key');
      return jsonData as T;
    } catch (e) {
      _misses++;
      _logger.w('Error reading from disk cache: $e');
      return null;
    }
  }

  @override
  Future<void> set(String key, T value, {Duration? ttl}) async {
    await initialize();

    try {
      final effectiveTTL = ttl ?? defaultTTL;
      final now = DateTime.now();
      final expiresAt = now.add(effectiveTTL);

      // Serialize to JSON
      final jsonStr = json.encode(value);
      final sizeBytes = jsonStr.length;

      // Write to file
      final filePath = path.join(_cacheDir!.path, _sanitizeKey(key));
      final file = File(filePath);
      await file.writeAsString(jsonStr);

      // Save metadata to database
      await _database!.insert(
        _cacheTableName,
        {
          'cache_key': key,
          'file_path': filePath,
          'created_at': now.millisecondsSinceEpoch,
          'expires_at': expiresAt.millisecondsSinceEpoch,
          'size_bytes': sizeBytes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d(
          'Cached to disk: $key (${(sizeBytes / 1024).toStringAsFixed(1)}KB, TTL: ${effectiveTTL.inHours}h)');

      // Cleanup if needed
      await _cleanupIfNeeded();
    } catch (e) {
      _logger.w('Error writing to disk cache: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    await initialize();

    try {
      // Get file path
      final result = await _database!.query(
        _cacheTableName,
        where: 'cache_key = ?',
        whereArgs: [key],
      );

      if (result.isNotEmpty) {
        final filePath = result.first['file_path'] as String;
        final file = File(filePath);

        // Delete file
        if (await file.exists()) {
          await file.delete();
        }

        // Delete metadata
        await _database!.delete(
          _cacheTableName,
          where: 'cache_key = ?',
          whereArgs: [key],
        );

        _logger.d('Removed from disk cache: $key');
      }
    } catch (e) {
      _logger.w('Error removing from disk cache: $e');
    }
  }

  @override
  Future<void> clear() async {
    await initialize();

    try {
      // Get all file paths
      final results = await _database!.query(_cacheTableName);

      // Delete all files
      for (final entry in results) {
        final filePath = entry['file_path'] as String;
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear database
      await _database!.delete(_cacheTableName);

      _hits = 0;
      _misses = 0;

      _logger.i(
          'Cleared disk cache for namespace: $namespace (${results.length} entries)');
    } catch (e) {
      _logger.w('Error clearing disk cache: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    await initialize();

    final result = await _database!.query(
      _cacheTableName,
      where: 'cache_key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return false;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      result.first['expires_at'] as int,
    );

    return DateTime.now().isBefore(expiresAt);
  }

  @override
  Future<CacheStats> getStats() async {
    await initialize();

    final results = await _database!.query(_cacheTableName);

    int totalSize = 0;
    for (final entry in results) {
      totalSize += entry['size_bytes'] as int;
    }

    return CacheStats(
      totalEntries: results.length,
      totalSize: totalSize,
      hits: _hits,
      misses: _misses,
    );
  }

  /// Remove expired entries from cache
  Future<int> removeExpired() async {
    await initialize();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get expired entries
      final results = await _database!.query(
        _cacheTableName,
        where: 'expires_at < ?',
        whereArgs: [now],
      );

      // Delete files and metadata
      for (final entry in results) {
        final filePath = entry['file_path'] as String;
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete metadata
      final deletedCount = await _database!.delete(
        _cacheTableName,
        where: 'expires_at < ?',
        whereArgs: [now],
      );

      if (deletedCount > 0) {
        _logger.i('Removed $deletedCount expired entries from disk cache');
      }

      return deletedCount;
    } catch (e) {
      _logger.w('Error removing expired entries: $e');
      return 0;
    }
  }

  /// Cleanup old entries if cache size exceeds limit
  Future<void> _cleanupIfNeeded() async {
    final stats = await getStats();
    final maxSizeBytes = maxSizeMB * 1024 * 1024;

    if (stats.totalSize > maxSizeBytes) {
      _logger.i(
          'Disk cache size exceeded limit (${stats.totalSizeMB}MB), cleaning up...');

      // Get entries sorted by created_at (oldest first)
      final results = await _database!.query(
        _cacheTableName,
        orderBy: 'created_at ASC',
      );

      int removedSize = 0;
      final targetSize = (maxSizeBytes * 0.8).toInt(); // Keep 80% of limit

      for (final entry in results) {
        if (stats.totalSize - removedSize <= targetSize) {
          break;
        }

        final key = entry['cache_key'] as String;
        final size = entry['size_bytes'] as int;

        await remove(key);
        removedSize += size;
      }

      _logger.i(
          'Cleaned up ${(removedSize / (1024 * 1024)).toStringAsFixed(1)}MB from disk cache');
    }
  }

  /// Sanitize key for use as filename
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
