import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/glossary.dart';

/// Glossary entries stored as a JSON list in SharedPreferences.
class GlossaryRepositoryImpl implements GlossaryRepository {
  GlossaryRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _key = 'glossary_entries';

  @override
  Future<List<GlossaryEntry>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GlossaryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(GlossaryEntry entry) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.id == entry.id);
    entries.insert(0, entry);
    await _prefs.setString(
        _key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> delete(String id) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    await _prefs.setString(
        _key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
