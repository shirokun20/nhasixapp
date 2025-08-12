import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static const String _databaseName = 'nhasix_app.db';
  static const int _databaseVersion = 4;

  static Database? _database;
  static final Logger _logger = Logger();

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = '${documentsDirectory.path}/$_databaseName';

      _logger.i('Initializing database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: (db) async {
          _logger.i('Database opened successfully');
        },
      );
    } catch (e) {
      _logger.e('Error initializing database: $e');

      // If database initialization fails, try to delete the corrupted database file
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final path = '${documentsDirectory.path}/$_databaseName';
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          _logger
              .w('Deleted corrupted database file, attempting to recreate...');

          // Try to initialize again
          return await openDatabase(
            path,
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onConfigure: _onConfigure,
            onOpen: (db) async {
              _logger.i('Database recreated and opened successfully');
            },
          );
        }
      } catch (deleteError) {
        _logger.e('Error deleting corrupted database: $deleteError');
      }

      rethrow;
    }
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    try {
      // Enable foreign key constraints
      await db.rawQuery('PRAGMA foreign_keys = ON');

      // Set journal mode to WAL for better performance
      await db.rawQuery('PRAGMA journal_mode = WAL');

      // Set synchronous mode to NORMAL for better performance
      await db.rawQuery('PRAGMA synchronous = NORMAL');

      // Set cache size to 10MB
      await db.rawQuery('PRAGMA cache_size = -10000');

      _logger.d('Database configuration completed successfully');
    } catch (e) {
      _logger.e('Error configuring database: $e');
      // Don't rethrow here as it might prevent database initialization
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables...');

    final batch = db.batch();

    // Create essential tables only
    _createFavoritesTable(batch);
    _createDownloadsTable(batch);
    _createHistoryTable(batch);
    _createPreferencesTable(batch);
    _createSearchHistoryTable(batch);
    _createSearchFilterStateTable(batch);

    // Create indexes
    _createIndexes(batch);

    // Insert default data
    _insertDefaultData(batch);

    await batch.commit();
    _logger.i('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');

    // Handle specific version upgrades
    if (oldVersion < 3 && newVersion >= 3) {
      // Add search_filter_state table in version 3
      await db.execute('''
        CREATE TABLE search_filter_state (
          id INTEGER PRIMARY KEY DEFAULT 1,
          filter_data TEXT, -- JSON serialized SearchFilter
          saved_at INTEGER
        )
      ''');
      _logger.i('Added search_filter_state table in database upgrade');
    }

    // Fix history table schema if needed (for any version upgrade)
    try {
      // Check if history table has the correct schema
      final historyColumns = await db.rawQuery("PRAGMA table_info(history)");
      final hasIdColumn = historyColumns.any((col) => col['name'] == 'id');

      if (!hasIdColumn) {
        _logger.w('History table missing id column, recreating table...');

        // Backup existing data
        final existingData = await db.query('history');

        // Drop and recreate history table
        await db.execute('DROP TABLE IF EXISTS history');
        await db.execute('''
          CREATE TABLE history (
            id TEXT PRIMARY KEY,
            title TEXT,
            cover_url TEXT,
            last_viewed INTEGER,
            last_page INTEGER DEFAULT 1,
            total_pages INTEGER,
            time_spent INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0
          )
        ''');

        // Restore data with proper column mapping
        for (final row in existingData) {
          await db.insert('history', {
            'id': row['content_id'] ??
                row['id'], // Handle both old and new column names
            'title': row['title'],
            'cover_url': row['cover_url'],
            'last_viewed': row['last_viewed'],
            'last_page': row['last_page'] ?? 1,
            'total_pages': row['total_pages'] ?? 0,
            'time_spent': row['time_spent'] ?? 0,
            'is_completed': row['is_completed'] ?? 0,
          });
        }

        // Recreate index
        await db.execute(
            'CREATE INDEX idx_history_last_viewed ON history (last_viewed DESC)');
        await db.execute(
            'CREATE INDEX idx_history_is_completed ON history (is_completed)');

        _logger.i('History table schema fixed successfully');
      }
    } catch (e) {
      _logger.e('Error fixing history table schema: $e');
      // If fixing fails, recreate the entire database
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }

    // For major version changes, recreate database
    if (oldVersion < newVersion && (newVersion - oldVersion) > 2) {
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }
  }

  /// Create favorites table (simplified - only id and cover_url)
  void _createFavoritesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        cover_url TEXT,
        added_at INTEGER
      )
    ''');
  }

  /// Create downloads table
  void _createDownloadsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE downloads (
        id TEXT PRIMARY KEY,
        title TEXT,
        cover_url TEXT,
        download_path TEXT,
        state TEXT NOT NULL, -- queued, downloading, paused, completed, failed, cancelled
        downloaded_pages INTEGER DEFAULT 0,
        total_pages INTEGER,
        start_time INTEGER,
        end_time INTEGER,
        file_size INTEGER,
        error_message TEXT
      )
    ''');
  }

  /// Create history table
  void _createHistoryTable(Batch batch) {
    batch.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        title TEXT,
        cover_url TEXT,
        last_viewed INTEGER,
        last_page INTEGER DEFAULT 1,
        total_pages INTEGER,
        time_spent INTEGER DEFAULT 0, -- in milliseconds
        is_completed INTEGER DEFAULT 0 -- boolean as integer
      )
    ''');
  }

  /// Create preferences table
  void _createPreferencesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE preferences (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Create search history table
  void _createSearchHistoryTable(Batch batch) {
    batch.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searched_at INTEGER
      )
    ''');
  }

  /// Create search filter state table
  void _createSearchFilterStateTable(Batch batch) {
    batch.execute('''
      CREATE TABLE search_filter_state (
        id INTEGER PRIMARY KEY DEFAULT 1,
        filter_data TEXT, -- JSON serialized SearchFilter
        saved_at INTEGER
      )
    ''');
  }

  /// Create database indexes for performance
  void _createIndexes(Batch batch) {
    // Favorites indexes
    batch.execute(
        'CREATE INDEX idx_favorites_added_at ON favorites (added_at DESC)');

    // Downloads indexes
    batch.execute('CREATE INDEX idx_downloads_state ON downloads (state)');
    batch.execute(
        'CREATE INDEX idx_downloads_start_time ON downloads (start_time DESC)');

    // History indexes
    batch.execute(
        'CREATE INDEX idx_history_last_viewed ON history (last_viewed DESC)');
    batch.execute(
        'CREATE INDEX idx_history_is_completed ON history (is_completed)');

    // Search history indexes
    batch.execute(
        'CREATE INDEX idx_search_history_searched_at ON search_history (searched_at DESC)');
  }

  /// Insert default data
  void _insertDefaultData(Batch batch) {
    // Insert default preferences
    final defaultPreferences = {
      'theme': 'dark',
      'defaultLanguage': 'english',
      'imageQuality': 'high',
      'autoDownload': 'false',
      'showTitles': 'true',
      'blurThumbnails': 'false',
      'infiniteScroll': 'true',
      'columnsPortrait': '2',
      'columnsLandscape': '3',
      'useVolumeKeys': 'false',
      'readingDirection': 'leftToRight',
      'keepScreenOn': 'false',
      'showSystemUI': 'true',
      'maxConcurrentDownloads': '3',
      'autoBackup': 'false',
      'showNsfwContent': 'true',
    };

    for (final entry in defaultPreferences.entries) {
      batch.insert('preferences', {
        'key': entry.key,
        'value': entry.value,
      });
    }
  }

  /// Drop all tables (for database recreation)
  Future<void> _dropAllTables(Database db) async {
    final tables = [
      'search_filter_state',
      'search_history',
      'preferences',
      'history',
      'downloads',
      'favorites',
    ];

    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _logger.i('Database connection closed');
    }
  }

  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();

    // Clear all tables except preferences
    batch.delete('search_filter_state');
    batch.delete('search_history');
    batch.delete('history');
    batch.delete('downloads');
    batch.delete('favorites');

    await batch.commit();
    _logger.i('All data cleared from database');
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = '${documentsDirectory.path}/$_databaseName';
      final file = File(path);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      _logger.e('Error getting database size: $e');
      return 0;
    }
  }

  /// Vacuum database to reclaim space
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.rawQuery('VACUUM');
      _logger.i('Database vacuumed successfully');
    } catch (e) {
      _logger.e('Error vacuuming database: $e');
    }
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.isNotEmpty && result.first.values.first == 'ok';

      if (isOk) {
        _logger.i('Database integrity check passed');
      } else {
        _logger.w('Database integrity check failed: $result');
      }

      return isOk;
    } catch (e) {
      _logger.e('Error checking database integrity: $e');
      return false;
    }
  }

  /// Reset database by deleting and recreating it
  Future<void> resetDatabase() async {
    try {
      // Close existing connection
      await close();

      // Delete database file
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = '${documentsDirectory.path}/$_databaseName';
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
        _logger.i('Database file deleted');
      }

      // Reinitialize database
      _database = await _initDatabase();
      _logger.i('Database reset completed');
    } catch (e) {
      _logger.e('Error resetting database: $e');
      rethrow;
    }
  }
}
