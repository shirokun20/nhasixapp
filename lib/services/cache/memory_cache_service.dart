import 'dart:collection';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'cache_service.dart';

/// In-memory LRU cache implementation
/// Uses LinkedHashMap to maintain insertion order
/// Automatically evicts least recently used entries when size limit is reached
class MemoryCacheService<T> implements CacheService<T> {
  final int maxEntries;
  final Duration defaultTTL;
  final Logger _logger = Logger();

  // LRU cache using LinkedHashMap (maintains insertion order)
  final LinkedHashMap<String, CacheEntry<T>> _cache = LinkedHashMap();

  // Statistics tracking
  int _hits = 0;
  int _misses = 0;

  MemoryCacheService({
    this.maxEntries = 100,
    this.defaultTTL = const Duration(hours: 1),
  });

  @override
  Future<T?> get(String key) async {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      _logger.d('Memory cache miss: $key');
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _misses++;
      await remove(key);
      _logger.d('Memory cache expired: $key');
      return null;
    }

    // Move to end (mark as recently used)
    _cache.remove(key);
    _cache[key] = entry;

    _hits++;
    _logger.d('Memory cache hit: $key');
    return entry.value;
  }

  @override
  Future<void> set(String key, T value, {Duration? ttl}) async {
    final effectiveTTL = ttl ?? defaultTTL;
    final entry = CacheEntry.withTTL(value, effectiveTTL);

    // Remove if already exists
    _cache.remove(key);

    // Add new entry
    _cache[key] = entry;

    // Evict oldest entry if size limit exceeded
    if (_cache.length > maxEntries) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      _logger.d('Evicted oldest entry from memory cache: $oldestKey');
    }

    _logger.d('Cached in memory: $key (TTL: ${effectiveTTL.inMinutes}min)');
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
    _logger.d('Removed from memory cache: $key');
  }

  @override
  Future<void> clear() async {
    final count = _cache.length;
    _cache.clear();
    _hits = 0;
    _misses = 0;
    _logger.i('Cleared memory cache ($count entries)');
  }

  @override
  Future<bool> containsKey(String key) async {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  @override
  Future<CacheStats> getStats() async {
    // Calculate approximate memory size
    int totalSize = 0;
    for (final entry in _cache.values) {
      try {
        // Approximate size calculation based on JSON serialization
        final jsonStr = json.encode(entry.value);
        totalSize += jsonStr.length;
      } catch (e) {
        // If can't serialize, use rough estimate
        totalSize += 1024; // 1KB estimate per entry
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      totalSize: totalSize,
      hits: _hits,
      misses: _misses,
    );
  }

  /// Remove expired entries
  Future<int> removeExpired() async {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger
          .i('Removed ${expiredKeys.length} expired entries from memory cache');
    }

    return expiredKeys.length;
  }
}
