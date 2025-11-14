import 'package:logger/logger.dart';
import 'cache_service.dart';
import 'memory_cache_service.dart';
import 'disk_cache_service.dart';

/// Multi-layer cache manager implementing cache-aside pattern
/// Orchestrates memory and disk caches for optimal performance
///
/// Cache flow:
/// 1. Check memory cache (fastest)
/// 2. Check disk cache (slower but persistent)
/// 3. If not found, load from source and populate caches
class CacheManager<T> implements CacheService<T> {
  final MemoryCacheService<T> memoryCache;
  final DiskCacheService<T> diskCache;
  final Logger _logger = Logger();

  // Combined statistics
  int _totalHits = 0;
  int _totalMisses = 0;

  CacheManager({
    required this.memoryCache,
    required this.diskCache,
  });

  /// Factory constructor for common use cases
  factory CacheManager.standard({
    required String namespace,
    int memoryMaxEntries = 100,
    int diskMaxSizeMB = 50,
    Duration memoryTTL = const Duration(hours: 1),
    Duration diskTTL = const Duration(days: 1),
  }) {
    return CacheManager(
      memoryCache: MemoryCacheService<T>(
        maxEntries: memoryMaxEntries,
        defaultTTL: memoryTTL,
      ),
      diskCache: DiskCacheService<T>(
        namespace: namespace,
        maxSizeMB: diskMaxSizeMB,
        defaultTTL: diskTTL,
      ),
    );
  }

  /// Initialize disk cache (memory cache doesn't need initialization)
  Future<void> initialize() async {
    await diskCache.initialize();
  }

  @override
  Future<T?> get(String key) async {
    // Try memory cache first
    final memoryValue = await memoryCache.get(key);
    if (memoryValue != null) {
      _totalHits++;
      _logger.d('Cache HIT (memory): $key');
      _logCacheStats();
      return memoryValue;
    }

    // Try disk cache
    final diskValue = await diskCache.get(key);
    if (diskValue != null) {
      _totalHits++;
      _logger.d('Cache HIT (disk): $key, promoting to memory');

      // Promote to memory cache for faster future access
      await memoryCache.set(key, diskValue);
      _logCacheStats();
      return diskValue;
    }

    _totalMisses++;
    _logger.d('Cache MISS: $key');
    _logCacheStats();
    return null;
  }

  @override
  Future<void> set(String key, T value, {Duration? ttl}) async {
    // Write to both caches
    await Future.wait([
      memoryCache.set(key, value, ttl: ttl),
      diskCache.set(key, value, ttl: ttl),
    ]);

    _logger.d('Cached to both layers: $key');
  }

  @override
  Future<void> remove(String key) async {
    // Remove from both caches
    await Future.wait([
      memoryCache.remove(key),
      diskCache.remove(key),
    ]);

    _logger.d('Removed from both layers: $key');
  }

  @override
  Future<void> clear() async {
    // Clear both caches
    await Future.wait([
      memoryCache.clear(),
      diskCache.clear(),
    ]);

    _totalHits = 0;
    _totalMisses = 0;

    _logger.i('Cleared all cache layers');
  }

  @override
  Future<bool> containsKey(String key) async {
    // Check both layers
    final inMemory = await memoryCache.containsKey(key);
    if (inMemory) return true;

    return await diskCache.containsKey(key);
  }

  @override
  Future<CacheStats> getStats() async {
    final memoryStats = await memoryCache.getStats();
    final diskStats = await diskCache.getStats();

    return CacheStats(
      totalEntries: memoryStats.totalEntries + diskStats.totalEntries,
      totalSize: memoryStats.totalSize + diskStats.totalSize,
      hits: _totalHits,
      misses: _totalMisses,
    );
  }

  /// Get detailed stats for each cache layer
  Future<Map<String, CacheStats>> getDetailedStats() async {
    return {
      'memory': await memoryCache.getStats(),
      'disk': await diskCache.getStats(),
      'combined': await getStats(),
    };
  }

  /// Remove expired entries from all caches
  Future<void> removeExpired() async {
    final results = await Future.wait([
      memoryCache.removeExpired(),
      diskCache.removeExpired(),
    ]);

    final totalRemoved = results[0] + results[1];
    if (totalRemoved > 0) {
      _logger
          .i('Removed $totalRemoved expired entries across all cache layers');
    }
  }

  /// Warm up cache with frequently accessed data
  /// Useful for preloading data on app startup
  Future<void> warmUp(Map<String, T> data, {Duration? ttl}) async {
    for (final entry in data.entries) {
      await set(entry.key, entry.value, ttl: ttl);
    }
    _logger.i('Warmed up cache with ${data.length} entries');
  }

  /// Close disk cache connection
  Future<void> close() async {
    await diskCache.close();
  }

  /// Log cache statistics periodically for monitoring
  void _logCacheStats() {
    final total = _totalHits + _totalMisses;
    if (total > 0 && total % 10 == 0) {
      // Log every 10 operations
      final hitRate = (_totalHits / total * 100).toStringAsFixed(1);
      _logger.i(
          'Cache Stats - Hit Rate: $hitRate% (Hits: $_totalHits, Misses: $_totalMisses, Total: $total)');
    }
  }
}
