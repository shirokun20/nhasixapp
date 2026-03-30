import 'dart:async';

/// Abstract interface for cache services
/// Defines the contract for memory and disk cache implementations
abstract class CacheService<T> {
  /// Get a cached value by key
  /// Returns null if key doesn't exist or cache is expired
  Future<T?> get(String key);

  /// Set a value in the cache with optional TTL (Time To Live)
  /// If [ttl] is null, uses the default cache duration
  Future<void> set(String key, T value, {Duration? ttl});

  /// Remove a specific key from cache
  Future<void> remove(String key);

  /// Clear all cached data
  Future<void> clear();

  /// Check if a key exists in cache and is not expired
  Future<bool> containsKey(String key);

  /// Get cache statistics
  Future<CacheStats> getStats();
}

/// Cache statistics data class
class CacheStats {
  final int totalEntries;
  final int totalSize; // in bytes
  final int hits;
  final int misses;
  final double hitRate;

  CacheStats({
    required this.totalEntries,
    required this.totalSize,
    required this.hits,
    required this.misses,
  }) : hitRate = hits + misses > 0 ? hits / (hits + misses) : 0.0;

  int get totalSizeKB => (totalSize / 1024).round();
  int get totalSizeMB => (totalSize / (1024 * 1024)).round();

  Map<String, dynamic> toMap() {
    return {
      'totalEntries': totalEntries,
      'totalSize': totalSize,
      'totalSizeKB': totalSizeKB,
      'totalSizeMB': totalSizeMB,
      'hits': hits,
      'misses': misses,
      'hitRate': hitRate,
    };
  }

  @override
  String toString() {
    return 'CacheStats(entries: $totalEntries, size: ${totalSizeMB}MB, '
        'hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Cache entry wrapper with expiration support
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final DateTime expiresAt;

  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CacheEntry.withTTL(T value, Duration ttl) {
    final now = DateTime.now();
    return CacheEntry(
      value: value,
      createdAt: now,
      expiresAt: now.add(ttl),
    );
  }
}
