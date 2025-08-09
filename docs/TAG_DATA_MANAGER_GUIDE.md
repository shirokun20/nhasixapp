# TagDataManager Implementation Guide

## Overview

The `TagDataManager` is a comprehensive utility class designed to manage tag data from `assets/json/tags.json` with advanced features including caching, validation, and Matrix Filter Support. This implementation fulfills task 6.7 requirements for assets integration.

## Features

### 1. Asset Loading and Caching
- Loads tag data from `assets/json/tags.json`
- In-memory caching for performance optimization
- Type-based indexing for faster lookups
- Automatic cache management with age tracking

### 2. Advanced Search Capabilities
- Search tags by query with type filtering
- Case-sensitive and case-insensitive search options
- Relevance-based sorting (exact matches first, then starts with, then popularity)
- Configurable result limits

### 3. Type-Based Operations
- Get tags by specific type (tag, artist, character, parody, group, language, category)
- Pagination support with offset and limit
- Search within specific types
- Popular tags retrieval with filtering

### 4. Matrix Filter Support Validation
- Validates filter selection rules
- Enforces single selection for language and category types
- Supports multiple selection for other types
- Provides validation feedback

### 5. Performance Optimization
- Lazy loading with `_ensureDataCached()`
- Type-based caching for O(1) lookups
- Memory usage tracking
- Cache statistics and monitoring

## Usage Examples

### Basic Usage

```dart
// Initialize TagDataManager
final tagDataManager = TagDataManager(logger: Logger());

// Cache tag data from assets
await tagDataManager.cacheTagData();

// Search tags
final results = await tagDataManager.searchTags('school', limit: 10);

// Get tags by type
final artistTags = await tagDataManager.getTagsByType('artist', limit: 50);

// Get popular tags
final popularTags = await tagDataManager.getPopularTags(limit: 20);
```

### Advanced Search

```dart
// Search with type filtering
final characterTags = await tagDataManager.searchTags(
  'girl',
  type: 'character',
  limit: 10,
  caseSensitive: false,
);

// Search with pagination
final paginatedTags = await tagDataManager.getTagsByType(
  'artist',
  offset: 20,
  limit: 10,
  searchQuery: 'anime',
);
```

### Matrix Filter Support Validation

```dart
// Validate multiple selection (should pass for tags)
final isValid = tagDataManager.validateMatrixFilterSupport(
  'tag', 
  ['tag1', 'tag2', 'tag3']
);

// Validate single selection (should pass for language)
final isValidSingle = tagDataManager.validateMatrixFilterSupport(
  'language', 
  ['english']
);

// Check if type supports multiple selection
final supportsMultiple = tagDataManager.supportsMultipleSelection('language'); // false
```

### Integration with FilterDataCubit

```dart
class FilterDataCubit extends Cubit<FilterDataState> {
  FilterDataCubit({
    required TagDataManager tagDataManager,
    required Logger logger,
  }) : _tagDataManager = tagDataManager, ...

  Future<void> initialize({
    required String filterType,
    required List<FilterItem> selectedFilters,
  }) async {
    // Ensure tag data is cached
    await _tagDataManager.cacheTagData();

    // Get tags by type
    _filteredTags = await _tagDataManager.getTagsByType(filterType, limit: 100);
    
    // Emit loaded state
    emit(FilterDataLoaded(...));
  }

  Future<void> searchFilterData(String query) async {
    if (query.isEmpty) {
      _filteredTags = await _tagDataManager.getTagsByType(_currentFilterType, limit: 100);
    } else {
      _filteredTags = await _tagDataManager.searchTags(
        query,
        type: _currentFilterType,
        limit: 50,
      );
    }
    
    emit(FilterDataLoaded(...));
  }
}
```

## API Reference

### Core Methods

#### `cacheTagData()`
Loads and caches tag data from assets/json/tags.json.
- **Returns**: `Future<void>`
- **Throws**: `Exception` if loading fails

#### `searchTags(String query, {String? type, int limit = 20, bool caseSensitive = false})`
Searches tags by query with optional type filtering.
- **Parameters**:
  - `query`: Search query string
  - `type`: Optional type filter (tag, artist, character, etc.)
  - `limit`: Maximum number of results (default: 20)
  - `caseSensitive`: Whether search is case-sensitive (default: false)
- **Returns**: `Future<List<Tag>>`

#### `getTagsByType(String type, {int offset = 0, int limit = 100, String? searchQuery})`
Gets tags by specific type with pagination and search.
- **Parameters**:
  - `type`: Tag type to filter by
  - `offset`: Number of results to skip (default: 0)
  - `limit`: Maximum number of results (default: 100)
  - `searchQuery`: Optional search query within type
- **Returns**: `Future<List<Tag>>`

#### `getPopularTags({String? type, int limit = 20, int minCount = 0})`
Gets popular tags with optional type filtering.
- **Parameters**:
  - `type`: Optional type filter
  - `limit`: Maximum number of results (default: 20)
  - `minCount`: Minimum popularity count (default: 0)
- **Returns**: `Future<List<Tag>>`

### Validation Methods

#### `validateMatrixFilterSupport(String type, List<String> selectedValues)`
Validates Matrix Filter Support rules for given type and values.
- **Parameters**:
  - `type`: Filter type to validate
  - `selectedValues`: List of selected values
- **Returns**: `bool` - true if valid, false otherwise

#### `supportsMultipleSelection(String type)`
Checks if a type supports multiple selection.
- **Parameters**:
  - `type`: Type to check
- **Returns**: `bool` - true if multiple selection supported

#### `getAvailableTypes()`
Gets all available tag types.
- **Returns**: `List<String>` - List of available types

### Utility Methods

#### `getTagStatistics()`
Gets comprehensive tag statistics.
- **Returns**: `Future<Map<String, dynamic>>` - Statistics including total tags, cache info, type breakdown

#### `clearCache()`
Clears all cached data.
- **Returns**: `void`

### Properties

#### `isCached`
Whether data is currently cached in memory.
- **Type**: `bool`

#### `cacheAgeMinutes`
Age of cache in minutes, null if not cached.
- **Type**: `int?`

## Matrix Filter Support Rules

The TagDataManager enforces Matrix Filter Support rules as defined in the requirements:

| Type | Multiple Selection | Single Selection |
|------|-------------------|------------------|
| tag | ✅ Yes | ✅ Yes |
| artist | ✅ Yes | ✅ Yes |
| character | ✅ Yes | ✅ Yes |
| parody | ✅ Yes | ✅ Yes |
| group | ✅ Yes | ✅ Yes |
| language | ❌ No | ✅ Yes |
| category | ❌ No | ✅ Yes |

## Error Handling

The TagDataManager includes comprehensive error handling:

1. **Asset Loading Errors**: Throws `Exception` with descriptive message
2. **Invalid Data Entries**: Logs warnings and skips invalid entries
3. **Search Errors**: Returns empty list and logs error
4. **Cache Errors**: Graceful degradation with logging

## Performance Considerations

1. **Memory Usage**: Tracks cache size and provides statistics
2. **Lazy Loading**: Data is loaded only when needed
3. **Type Indexing**: O(1) lookups for type-based operations
4. **Result Limiting**: Configurable limits to prevent memory issues

## Integration Points

### Service Locator Registration

```dart
// In lib/core/di/service_locator.dart
getIt.registerLazySingleton<TagDataManager>(
  () => TagDataManager(logger: getIt<Logger>())
);
```

### FilterDataCubit Integration

The TagDataManager is designed to work seamlessly with the existing FilterDataCubit:

```dart
getIt.registerFactory<FilterDataCubit>(() => FilterDataCubit(
  tagDataManager: getIt<TagDataManager>(),
  logger: getIt<Logger>(),
));
```

## Testing

The TagDataManager includes built-in validation and can be tested with:

1. **Unit Tests**: Test individual methods with mock data
2. **Integration Tests**: Test with actual assets in Flutter environment
3. **Performance Tests**: Monitor cache performance and memory usage

## Migration from TagDataSource

The TagDataManager replaces the previous TagDataSource with enhanced functionality:

### Before (TagDataSource)
```dart
final tags = await tagDataSource.loadTags();
final results = await tagDataSource.searchTags(query, limit: 10);
```

### After (TagDataManager)
```dart
await tagDataManager.cacheTagData(); // Explicit caching
final results = await tagDataManager.searchTags(query, limit: 10);
// Or with type filtering:
final results = await tagDataManager.searchTags(query, type: 'artist', limit: 10);
```

## Conclusion

The TagDataManager provides a robust, performant, and feature-rich solution for managing tag data from assets. It fulfills all requirements for task 6.7 including:

- ✅ Asset loading from `assets/json/tags.json`
- ✅ Advanced search with type filtering
- ✅ Performance optimization with caching
- ✅ Popular tags functionality
- ✅ Matrix Filter Support validation
- ✅ Comprehensive error handling

The implementation is ready for production use and integrates seamlessly with the existing FilterDataCubit architecture.