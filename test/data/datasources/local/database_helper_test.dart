import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Database Schema', () {
    late Database database;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for unit testing calls for SQFlite
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create in-memory database for testing
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create test tables to verify schema
          await db.execute('''
            CREATE TABLE contents (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              english_title TEXT,
              japanese_title TEXT,
              cover_url TEXT,
              artists TEXT,
              characters TEXT,
              parodies TEXT,
              groups TEXT,
              language TEXT,
              category TEXT,
              page_count INTEGER,
              image_urls TEXT,
              upload_date INTEGER,
              favorites INTEGER DEFAULT 0,
              cached_at INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              count INTEGER DEFAULT 0,
              url TEXT,
              UNIQUE(name, type)
            )
          ''');

          await db.execute('''
            CREATE TABLE content_tags (
              content_id TEXT,
              tag_id INTEGER,
              PRIMARY KEY (content_id, tag_id),
              FOREIGN KEY (content_id) REFERENCES contents (id) ON DELETE CASCADE,
              FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
            )
          ''');
        },
      );
    });

    test('should create tables successfully', () async {
      // Test that tables exist
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      final tableNames = tables.map((table) => table['name']).toList();
      expect(tableNames, contains('contents'));
      expect(tableNames, contains('tags'));
      expect(tableNames, contains('content_tags'));
    });

    test('should insert and retrieve content', () async {
      // Insert test content
      await database.insert('contents', {
        'id': 'test123',
        'title': 'Test Content',
        'cover_url': 'https://example.com/cover.jpg',
        'language': 'english',
        'page_count': 20,
        'upload_date': DateTime.now().millisecondsSinceEpoch,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Retrieve content
      final result = await database.query(
        'contents',
        where: 'id = ?',
        whereArgs: ['test123'],
      );

      expect(result.length, 1);
      expect(result.first['title'], 'Test Content');
      expect(result.first['language'], 'english');
    });

    test('should handle tag relationships', () async {
      // Insert content
      await database.insert('contents', {
        'id': 'test456',
        'title': 'Test Content 2',
        'cover_url': 'https://example.com/cover2.jpg',
        'language': 'japanese',
        'page_count': 15,
        'upload_date': DateTime.now().millisecondsSinceEpoch,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Insert tag
      final tagId = await database.insert('tags', {
        'name': 'test-tag',
        'type': 'tag',
        'count': 1,
        'url': '/tag/test-tag',
      });

      // Create relationship
      await database.insert('content_tags', {
        'content_id': 'test456',
        'tag_id': tagId,
      });

      // Query with join
      final result = await database.rawQuery('''
        SELECT c.title, t.name as tag_name FROM contents c
        INNER JOIN content_tags ct ON c.id = ct.content_id
        INNER JOIN tags t ON ct.tag_id = t.id
        WHERE c.id = ?
      ''', ['test456']);

      expect(result.length, 1);
      expect(result.first['title'], 'Test Content 2');
      expect(result.first['tag_name'], 'test-tag');
    });

    tearDown(() async {
      await database.close();
    });
  });
}
