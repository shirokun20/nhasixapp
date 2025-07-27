import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';

/// Database helper class for managing SQLite database
class DatabaseHelper {
  static const String _databaseName = 'nhasix_app.db';
  static const int _databaseVersion = 1;

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
      );
    } catch (e) {
      _logger.e('Error initializing database: $e');
      rethrow;
    }
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    // Set journal mode to WAL for better performance
    await db.execute('PRAGMA journal_mode = WAL');

    // Set synchronous mode to NORMAL for better performance
    await db.execute('PRAGMA synchronous = NORMAL');

    // Set cache size to 10MB
    await db.execute('PRAGMA cache_size = -10000');
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables...');

    final batch = db.batch();

    // Create all tables
    _createContentTable(batch);
    _createTagsTable(batch);
    _createContentTagsTable(batch);
    _createFavoriteCategoriesTable(batch);
    _createFavoritesTable(batch);
    _createDownloadsTable(batch);
    _createHistoryTable(batch);
    _createPreferencesTable(batch);
    _createSearchHistoryTable(batch);

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

    // Handle future database migrations here
    // For now, we'll just recreate the database
    if (oldVersion < newVersion) {
      // Drop all tables and recreate
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }
  }

  /// Create content table
  void _createContentTable(Batch batch) {
    batch.execute('''
      CREATE TABLE contents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        english_title TEXT,
        japanese_title TEXT,
        cover_url TEXT,
        artists TEXT, -- JSON array
        characters TEXT, -- JSON array
        parodies TEXT, -- JSON array
        groups TEXT, -- JSON array
        language TEXT,
        category TEXT,
        page_count INTEGER,
        image_urls TEXT, -- JSON array
        upload_date INTEGER,
        favorites INTEGER DEFAULT 0,
        cached_at INTEGER
      )
    ''');
  }

  /// Create tags table
  void _createTagsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL, -- tag, artist, character, parody, group, language, category
        count INTEGER DEFAULT 0,
        url TEXT,
        UNIQUE(name, type)
      )
    ''');
  }

  /// Create content tags relationship table
  void _createContentTagsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE content_tags (
        content_id TEXT,
        tag_id INTEGER,
        PRIMARY KEY (content_id, tag_id),
        FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create favorite categories table
  void _createFavoriteCategoriesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE favorite_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER
      )
    ''');
  }

  /// Create favorites table
  void _createFavoritesTable(Batch batch) {
    batch.execute('''
      CREATE TABLE favorites (
        content_id TEXT,
        category_id INTEGER DEFAULT 1, -- Default category
        added_at INTEGER,
        PRIMARY KEY (content_id, category_id),
        FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES favorite_categories (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create downloads table
  void _createDownloadsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE downloads (
        content_id TEXT PRIMARY KEY,
        download_path TEXT,
        state TEXT NOT NULL, -- queued, downloading, paused, completed, failed, cancelled
        downloaded_pages INTEGER DEFAULT 0,
        total_pages INTEGER,
        start_time INTEGER,
        end_time INTEGER,
        file_size INTEGER,
        error_message TEXT,
        FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create history table
  void _createHistoryTable(Batch batch) {
    batch.execute('''
      CREATE TABLE history (
        content_id TEXT PRIMARY KEY,
        last_viewed INTEGER,
        last_page INTEGER DEFAULT 1,
        total_pages INTEGER,
        time_spent INTEGER DEFAULT 0, -- in milliseconds
        is_completed INTEGER DEFAULT 0, -- boolean as integer
        FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE
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

  /// Create database indexes for performance
  void _createIndexes(Batch batch) {
    // Content indexes
    batch.execute(
        'CREATE INDEX idx_contents_upload_date ON contents (upload_date DESC)');
    batch.execute(
        'CREATE INDEX idx_contents_favorites ON contents (favorites DESC)');
    batch.execute('CREATE INDEX idx_contents_language ON contents (language)');
    batch.execute('CREATE INDEX idx_contents_category ON contents (category)');
    batch
        .execute('CREATE INDEX idx_contents_cached_at ON contents (cached_at)');

    // Tag indexes
    batch.execute('CREATE INDEX idx_tags_name ON tags (name)');
    batch.execute('CREATE INDEX idx_tags_type ON tags (type)');
    batch.execute('CREATE INDEX idx_tags_count ON tags (count DESC)');

    // Content tags indexes
    batch.execute(
        'CREATE INDEX idx_content_tags_content_id ON content_tags (content_id)');
    batch.execute(
        'CREATE INDEX idx_content_tags_tag_id ON content_tags (tag_id)');

    // Favorites indexes
    batch.execute(
        'CREATE INDEX idx_favorites_category_id ON favorites (category_id)');
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
    // Insert default favorite category
    batch.insert('favorite_categories', {
      'id': 1,
      'name': 'Default',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

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
      'search_history',
      'preferences',
      'history',
      'downloads',
      'favorites',
      'favorite_categories',
      'content_tags',
      'tags',
      'contents',
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

    // Clear all tables except preferences and favorite_categories
    batch.delete('search_history');
    batch.delete('history');
    batch.delete('downloads');
    batch.delete('favorites');
    batch.delete('content_tags');
    batch.delete('tags');
    batch.delete('contents');

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
      await db.execute('VACUUM');
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
      final isOk = result.isNotEmpty && result.first['integrity_check'] == 'ok';

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
}
