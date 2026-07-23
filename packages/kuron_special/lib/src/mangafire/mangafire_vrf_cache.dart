import 'dart:collection';

class _VRFCacheEntry {
  final String capturedUrl;
  final int capturedAt;
  const _VRFCacheEntry(this.capturedUrl, this.capturedAt);
}

class MangaFireVRFCache {
  final int _maxEntries;
  final int _ttlSeconds;
  final LinkedHashMap<String, _VRFCacheEntry> _cache;

  MangaFireVRFCache({int maxEntries = 20, int ttlSeconds = 300})
      : _maxEntries = maxEntries,
        _ttlSeconds = ttlSeconds,
        _cache = LinkedHashMap<String, _VRFCacheEntry>();

  String? getEntry(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - entry.capturedAt;
    if (age > _ttlSeconds * 1000) {
      _cache.remove(key);
      return null;
    }
    _cache.remove(key);
    _cache[key] = entry;
    return entry.capturedUrl;
  }

  void set(String key, String capturedUrl) {
    if (_cache.length >= _maxEntries && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache.remove(key);
    _cache[key] =
        _VRFCacheEntry(capturedUrl, DateTime.now().millisecondsSinceEpoch);
  }

  void invalidate(String key) => _cache.remove(key);
  void clear() => _cache.clear();
  int get size => _cache.length;
  int get maxEntries => _maxEntries;
  int get ttlSeconds => _ttlSeconds;
}
