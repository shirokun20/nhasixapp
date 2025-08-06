# ⚠️ DEPRECATED: Pagination Cache Implementation Guide

> **NOTICE**: This pagination cache system has been **REMOVED** in the simplified architecture.  
> **Date Deprecated**: January 2025  
> **Reason**: Database simplification - removed complex caching to focus on core functionality  
> **Alternative**: Basic pagination without local cache  

## ~~Overview~~ (DEPRECATED)

~~Dokumen ini menjelaskan implementasi pagination cache system yang memungkinkan aplikasi NhentaiApp untuk menyimpan pagination metadata (total pages, current page, navigation info) secara lokal. Ini memberikan consistent pagination experience antara online dan offline mode.~~

**This feature has been removed as part of database simplification efforts.**

## Problem Statement

### Before Implementation:
```
Online:  Page 1 of 22,114 (0.0%) ✅ Accurate
Offline: Page 1 of 1 (100.0%)   ❌ Wrong info - lost pagination metadata
```

### After Implementation:
```
Online:  Page 1 of 22,114 (0.0%) ✅ Accurate
Offline: Page 1 of 22,114 (0.0%) ✅ Accurate from cache
```

## Architecture Overview

```
┌─────────────────────────────────────────┐
│            UI Layer                     │
│  ┌─────────────────────────────────────┐│
│  │        PaginationWidget             ││
│  │  - Shows accurate total pages       ││
│  │  - Progress bar with real %         ││
│  │  - Navigation buttons state         ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│           Repository Layer              │
│  ┌─────────────────────────────────────┐│
│  │    ContentRepositoryImpl            ││
│  │  - Cache pagination metadata        ││
│  │  - Retrieve cached pagination       ││
│  │  - Fallback to cached data          ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌─────────────────────────────────────┐│
│  │        LocalDataSource              ││
│  │  - cachePaginationInfo()            ││
│  │  - getCachedPaginationInfo()        ││
│  │  - Pagination cache management      ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│          Database Layer                 │
│  ┌─────────────────────────────────────┐│
│  │        DatabaseHelper               ││
│  │  - pagination_cache table           ││
│  │  - Indexes for performance          ││
│  │  - Migration support                ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## Implementation Details

### 1. Database Schema

#### Pagination Cache Table
```sql
CREATE TABLE pagination_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  context_key TEXT NOT NULL UNIQUE,
  current_page INTEGER NOT NULL,
  total_pages INTEGER NOT NULL,
  has_next INTEGER NOT NULL, -- boolean as integer
  has_previous INTEGER NOT NULL, -- boolean as integer
  total_count INTEGER,
  next_page INTEGER,
  previous_page INTEGER,
  cached_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);
```

#### Indexes for Performance
```sql
CREATE INDEX idx_pagination_cache_context_key ON pagination_cache (context_key);
CREATE INDEX idx_pagination_cache_expires_at ON pagination_cache (expires_at);
CREATE INDEX idx_pagination_cache_cached_at ON pagination_cache (cached_at DESC);
```

### 2. Cache Key Strategy

#### PaginationCacheKeys Utility
```dart
class PaginationCacheKeys {
  /// Generate cache key for content list
  static String contentList(int page, SortOption sortBy) {
    return 'content_list_${sortBy.name}_page_$page';
  }

  /// Generate cache key for search results
  static String search(SearchFilter filter) {
    final queryHash = filter.toQueryString().hashCode.abs();
    return 'search_${queryHash}_page_${filter.page}';
  }

  /// Generate cache key for popular content
  static String popular(PopularTimeframe timeframe, int page) {
    return 'popular_${timeframe.name}_page_$page';
  }

  /// Generate cache key for content by tag
  static String byTag(String tagName, int page, SortOption sortBy) {
    final tagHash = tagName.hashCode.abs();
    return 'tag_${tagHash}_${sortBy.name}_page_$page';
  }
}
```

#### Cache Key Examples
```
content_list_newest_page_1
content_list_popular_page_5
search_12345_page_2
popular_allTime_page_10
tag_67890_newest_page_3
```

### 3. LocalDataSource Implementation

#### Cache Pagination Info
```dart
/// Cache pagination information
Future<void> cachePaginationInfo({
  required String contextKey,
  required Map<String, dynamic> paginationInfo,
  Duration cacheExpiration = const Duration(hours: 6),
}) async {
  try {
    final db = await _getSafeDatabase();
    if (db == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = DateTime.now().add(cacheExpiration).millisecondsSinceEpoch;

    await db.insert(
      'pagination_cache',
      {
        'context_key': contextKey,
        'current_page': paginationInfo['currentPage'] as int? ?? 1,
        'total_pages': paginationInfo['totalPages'] as int? ?? 1,
        'has_next': (paginationInfo['hasNext'] as bool? ?? false) ? 1 : 0,
        'has_previous': (paginationInfo['hasPrevious'] as bool? ?? false) ? 1 : 0,
        'total_count': paginationInfo['totalCount'] as int?,
        'next_page': paginationInfo['nextPage'] as int?,
        'previous_page': paginationInfo['previousPage'] as int?,
        'cached_at': now,
        'expires_at': expiresAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    _logger.e('Error caching pagination info: $e');
  }
}
```

#### Retrieve Cached Pagination Info
```dart
/// Get cached pagination information
Future<Map<String, dynamic>?> getCachedPaginationInfo(String contextKey) async {
  try {
    final db = await _getSafeDatabase();
    if (db == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.query(
      'pagination_cache',
      where: 'context_key = ? AND expires_at > ?',
      whereArgs: [contextKey, now],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'currentPage': row['current_page'] as int,
      'totalPages': row['total_pages'] as int,
      'hasNext': (row['has_next'] as int) == 1,
      'hasPrevious': (row['has_previous'] as int) == 1,
      'totalCount': row['total_count'] as int?,
      'nextPage': row['next_page'] as int?,
      'previousPage': row['previous_page'] as int?,
    };
  } catch (e) {
    _logger.e('Error getting cached pagination info: $e');
    return null;
  }
}
```

### 4. ContentRepositoryImpl Integration

#### Enhanced getContentList Method
```dart
@override
Future<ContentListResult> getContentList({
  int page = 1,
  SortOption sortBy = SortOption.newest,
}) async {
  try {
    final contextKey = PaginationCacheKeys.contentList(page, sortBy);

    // Try to get cached content and pagination info
    final cachedModels = await localDataSource.getCachedContentList(
      page: page,
      limit: defaultPageSize,
    );
    final cachedPaginationInfo = await localDataSource.getCachedPaginationInfo(contextKey);

    // If we have both content and pagination cache, and content is not expired
    if (cachedModels.isNotEmpty &&
        !cachedModels.first.isCacheExpired(maxAge: cacheExpiration) &&
        cachedPaginationInfo != null) {
      final entities = cachedModels.map((model) => model.toEntity()).toList();
      return _buildContentListResultWithPagination(entities, cachedPaginationInfo);
    }

    try {
      // Fetch from remote with pagination info
      final remoteResult = await remoteDataSource.getContentListWithPagination(page: page);
      final remoteContents = remoteResult['contents'] as List<ContentModel>;
      final paginationInfo = remoteResult['pagination'] as Map<String, dynamic>;

      // Cache BOTH content and pagination info
      await _cacheContentList(remoteContents);
      await localDataSource.cachePaginationInfo(
        contextKey: contextKey,
        paginationInfo: paginationInfo,
      );

      final entities = remoteContents.map((model) => model.toEntity()).toList();
      return _buildContentListResultWithPagination(entities, paginationInfo);
    } catch (e) {
      // Fallback to cached content
      if (cachedModels.isNotEmpty) {
        final entities = cachedModels.map((model) => model.toEntity()).toList();
        
        // Try to use cached pagination info if available
        if (cachedPaginationInfo != null) {
          return _buildContentListResultWithPagination(entities, cachedPaginationInfo);
        } else {
          return _buildContentListResult(entities, page); // Fallback method
        }
      }
      rethrow;
    }
  } catch (e, stackTrace) {
    _logger.e('Failed to get content list', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
```

## Cache Management

### 1. Cache Expiration
- **Default expiration**: 6 hours
- **Automatic cleanup**: Expired entries are automatically ignored
- **Manual cleanup**: `deleteExpiredPaginationCache()` method

### 2. Cache Invalidation
```dart
// Clear cache for specific context
await localDataSource.clearPaginationCacheForContext('content_list');

// Clear all pagination cache
await localDataSource.clearAllPaginationCache();

// Delete expired entries
await localDataSource.deleteExpiredPaginationCache();
```

### 3. Cache Statistics
```dart
final stats = await localDataSource.getPaginationCacheStats();
print('Total entries: ${stats['totalEntries']}');
print('Valid entries: ${stats['validEntries']}');
print('Expired entries: ${stats['expiredEntries']}');
print('Context stats: ${stats['contextStats']}');
```

## Benefits

### ✅ **Consistent User Experience**
- User sees accurate total pages (22,114) even when offline
- Navigation buttons show correct enabled/disabled state
- Progress bar displays accurate percentage

### ✅ **Performance Improvements**
- Reduced network requests for pagination metadata
- Faster navigation between cached pages
- Improved offline experience

### ✅ **Better Offline Support**
- Full pagination functionality works offline
- Cached pagination info persists across app restarts
- Graceful degradation when cache is not available

### ✅ **Memory Efficiency**
- Pagination metadata is much smaller than content data
- Efficient database storage with indexes
- Automatic cleanup of expired entries

## Usage Examples

### Basic Usage
```dart
// Cache pagination info
await localDataSource.cachePaginationInfo(
  contextKey: 'content_list_newest_page_1',
  paginationInfo: {
    'currentPage': 1,
    'totalPages': 22114,
    'hasNext': true,
    'hasPrevious': false,
    'nextPage': 2,
    'previousPage': null,
  },
);

// Retrieve cached pagination info
final cachedInfo = await localDataSource.getCachedPaginationInfo('content_list_newest_page_1');
if (cachedInfo != null) {
  print('Total pages: ${cachedInfo['totalPages']}'); // 22114
  print('Has next: ${cachedInfo['hasNext']}');       // true
}
```

### Repository Integration
```dart
// In ContentRepositoryImpl
final contextKey = PaginationCacheKeys.contentList(page, sortBy);
final cachedPaginationInfo = await localDataSource.getCachedPaginationInfo(contextKey);

if (cachedPaginationInfo != null) {
  // Use cached pagination info
  return _buildContentListResultWithPagination(entities, cachedPaginationInfo);
} else {
  // Fallback to approximation
  return _buildContentListResult(entities, page);
}
```

## Testing

### Unit Tests
```dart
void testPaginationCache() async {
  final localDataSource = LocalDataSource(databaseHelper);
  
  // Test caching
  await localDataSource.cachePaginationInfo(
    contextKey: 'test_key',
    paginationInfo: {
      'currentPage': 1,
      'totalPages': 100,
      'hasNext': true,
      'hasPrevious': false,
    },
  );
  
  // Test retrieval
  final cached = await localDataSource.getCachedPaginationInfo('test_key');
  expect(cached, isNotNull);
  expect(cached!['totalPages'], equals(100));
  expect(cached['hasNext'], equals(true));
}
```

### Integration Tests
```dart
void testRepositoryWithPaginationCache() async {
  final repository = ContentRepositoryImpl(
    remoteDataSource: mockRemoteDataSource,
    localDataSource: localDataSource,
  );
  
  // First call - should cache pagination info
  final result1 = await repository.getContentList(page: 1);
  expect(result1.totalPages, equals(22114));
  
  // Second call - should use cached pagination info
  final result2 = await repository.getContentList(page: 1);
  expect(result2.totalPages, equals(22114));
  
  // Verify cache was used (no network call)
  verifyNever(() => mockRemoteDataSource.getContentListWithPagination(page: 1));
}
```

## Migration Guide

### Database Migration
The pagination cache table is automatically created during database upgrade from version 1 to version 2:

```dart
// In DatabaseHelper._onUpgrade
if (oldVersion < 2 && newVersion >= 2) {
  final batch = db.batch();
  _createPaginationCacheTable(batch);
  _createPaginationCacheIndexes(batch);
  await batch.commit();
}
```

### Existing Apps
- Existing installations will automatically upgrade to version 2
- No data loss occurs during migration
- Pagination cache starts working immediately after upgrade

## Monitoring

### Cache Hit Rate
```dart
// Monitor cache effectiveness
final stats = await localDataSource.getPaginationCacheStats();
final hitRate = stats['validEntries'] / (stats['validEntries'] + networkRequests);
print('Pagination cache hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
```

### Storage Usage
```dart
// Monitor storage usage
final dbSize = await databaseHelper.getDatabaseSize();
print('Database size: ${(dbSize / 1024 / 1024).toStringAsFixed(2)} MB');
```

## Conclusion

Pagination cache implementation memberikan significant improvement untuk user experience dengan:

- ✅ **Consistent pagination info** antara online dan offline
- ✅ **Reduced network requests** untuk metadata
- ✅ **Better performance** dengan cached navigation
- ✅ **Improved offline experience** dengan persistent pagination data

System ini production-ready dan siap untuk real device testing dengan proper error handling dan fallback mechanisms.