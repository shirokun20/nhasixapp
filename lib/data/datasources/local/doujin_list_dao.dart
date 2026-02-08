
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../../../../domain/entities/crotpedia/crotpedia_entities.dart';

class DoujinListDao {
  final DatabaseHelper databaseHelper;

  DoujinListDao(this.databaseHelper);

  Future<Database> get _db async => await databaseHelper.database;

  Future<void> insertAll(List<DoujinListItem> items) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final item in items) {
      batch.insert(
        'doujin_list',
        {
          'id': item.id ?? item.url, // Fallback to URL if ID missing
          'title': item.title,
          'url': item.url,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<DoujinListItem>> search(String query, {int limit = 50, int offset = 0}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'doujin_list',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      limit: limit,
      offset: offset,
      orderBy: 'title ASC',
    );

    return List.generate(maps.length, (i) {
      return DoujinListItem(
        id: maps[i]['id'] as String?,
        title: maps[i]['title'] as String,
        url: maps[i]['url'] as String,
      );
    });
  }

  Future<List<DoujinListItem>> getAll({int limit = 50, int offset = 0}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'doujin_list',
      limit: limit,
      offset: offset,
      orderBy: 'title ASC',
    );

    return List.generate(maps.length, (i) {
      return DoujinListItem(
        id: maps[i]['id'] as String?,
        title: maps[i]['title'] as String,
        url: maps[i]['url'] as String,
      );
    });
  }
  
  Future<int> count() async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM doujin_list')) ?? 0;
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete('doujin_list');
  }
}
