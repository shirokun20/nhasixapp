import 'dart:collection';

enum MangaFireVrfScope {
  search,
  reader,
}

class MangaFireVrfEntry {
  const MangaFireVrfEntry({
    required this.token,
    required this.timestamp,
    required this.scope,
  });

  final String token;
  final DateTime timestamp;
  final MangaFireVrfScope scope;
}

class MangaFireVrfCache {
  MangaFireVrfCache({
    this.maxEntries = 20,
    this.ttl = const Duration(minutes: 5),
  });

  final int maxEntries;
  final Duration ttl;
  final LinkedHashMap<String, MangaFireVrfEntry> _entries =
      LinkedHashMap<String, MangaFireVrfEntry>();

  String? get({
    required MangaFireVrfScope scope,
    required String key,
  }) {
    final cacheKey = _cacheKey(scope, key);
    final entry = _entries.remove(cacheKey);
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      return null;
    }
    _entries[cacheKey] = entry;
    return entry.token;
  }

  void set({
    required MangaFireVrfScope scope,
    required String key,
    required String token,
  }) {
    final cacheKey = _cacheKey(scope, key);
    _entries.remove(cacheKey);
    _entries[cacheKey] = MangaFireVrfEntry(
      token: token,
      timestamp: DateTime.now(),
      scope: scope,
    );

    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void invalidate({
    required MangaFireVrfScope scope,
    required String key,
  }) {
    _entries.remove(_cacheKey(scope, key));
  }

  String _cacheKey(MangaFireVrfScope scope, String key) => '${scope.name}:$key';
}
