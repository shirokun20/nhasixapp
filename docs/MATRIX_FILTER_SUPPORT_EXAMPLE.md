# Matrix Filter Support Implementation Example

## Overview

This document demonstrates the Matrix Filter Support implementation in the NhentaiApp search functionality.

## Filter Types and Rules

| Filter      | Multiple | Prefix Format   | Include/Exclude | Example |
|-------------|----------|------------------|-----------------|---------|
| Tag         | ✅       | `tag:"..."`     | ✅              | `tag:"romance"`, `-tag:"ntr"` |
| Artist      | ✅       | `artist:"..."`  | ✅              | `artist:"john"`, `-artist:"jane"` |
| Character   | ✅       | `character:"..."` | ✅            | `character:"alice"`, `-character:"bob"` |
| Parody      | ✅       | `parody:"..."`    | ✅            | `parody:"naruto"`, `-parody:"bleach"` |
| Group       | ✅       | `group:"..."`     | ✅            | `group:"circle1"`, `-group:"circle2"` |
| Language    | ❎       | `language:"..."`  | ❎            | `language:"english"` |
| Category    | ❎       | `category:"..."`  | ❎            | `category:"doujinshi"` |

## Code Example

```dart
import 'package:nhasixapp/domain/entities/search_filter.dart';

void main() {
  // Create a search filter with Matrix Filter Support
  final filter = SearchFilter(
    query: 'romance story',
    tags: [
      FilterItem.include('romance'),     // Include romance tag
      FilterItem.exclude('ntr'),         // Exclude ntr tag
      FilterItem.include('vanilla'),     // Include vanilla tag
    ],
    artists: [
      FilterItem.include('artist1'),     // Include artist1
      FilterItem.exclude('artist2'),     // Exclude artist2
    ],
    characters: [
      FilterItem.include('alice'),       // Include alice character
    ],
    language: 'english',                 // Single select - only one language
    category: 'doujinshi',              // Single select - only one category
  );

  // Generate query string
  final queryString = filter.buildQueryString();
  print('Query: $queryString');
  // Output: romance story tag:"romance" -tag:"ntr" tag:"vanilla" artist:"artist1" -artist:"artist2" character:"alice" language:"english" category:"doujinshi"

  // Generate URL query string
  final urlQuery = filter.toQueryString();
  print('URL: search/?$urlQuery');
  // Output: search/?q=romance%20story%20tag%3A%22romance%22%20-tag%3A%22ntr%22%20tag%3A%22vanilla%22%20artist%3A%22artist1%22%20-artist%3A%22artist2%22%20character%3A%22alice%22%20language%3A%22english%22%20category%3A%22doujinshi%22&sort=&page=1

  // Validate filter
  final validation = filter.validate();
  if (validation.isValid) {
    print('Filter is valid!');
  } else {
    print('Filter errors: ${validation.errors.join(', ')}');
  }
}
```

## SearchBloc Integration

The SearchBloc properly handles FilterItem with prefix formatting:

```dart
// In SearchBloc
Future<void> _onSearchUpdateFilter(
  SearchUpdateFilterEvent event,
  Emitter<SearchState> emit,
) async {
  // Validate filter before updating
  final validationResult = event.filter.validate();
  
  if (!validationResult.isValid) {
    emit(SearchError(
      message: 'Invalid filter: ${validationResult.errors.join(', ')}',
      errorType: SearchErrorType.validation,
      canRetry: false,
      filter: _currentFilter,
    ));
    return;
  }

  _currentFilter = event.filter;
  
  emit(SearchFilterUpdated(
    filter: _currentFilter,
    timestamp: DateTime.now(),
  ));
}
```

## Usage in UI

```dart
// Add include tag
final newFilter = currentFilter.copyWith(
  tags: [...currentFilter.tags, FilterItem.include('romance')]
);
searchBloc.add(SearchUpdateFilterEvent(newFilter));

// Add exclude tag  
final newFilter = currentFilter.copyWith(
  tags: [...currentFilter.tags, FilterItem.exclude('ntr')]
);
searchBloc.add(SearchUpdateFilterEvent(newFilter));

// Set single select language (replaces previous)
final newFilter = currentFilter.copyWith(language: 'english');
searchBloc.add(SearchUpdateFilterEvent(newFilter));

// Submit search (triggers API call)
searchBloc.add(SearchSubmittedEvent());
```

## Validation Rules

The system validates filters according to Matrix Filter Support rules:

1. **Empty Values**: Filter values cannot be empty
2. **Duplicate Detection**: Warns about duplicate values in multiple select filters
3. **Page Validation**: Page numbers must be greater than 0
4. **Range Validation**: Page count ranges must be valid

## Query Format Examples

### Simple Query
```
Input: SearchFilter(query: 'test')
Output: "test"
```

### Tags with Include/Exclude
```
Input: SearchFilter(tags: [FilterItem.include('a1'), FilterItem.exclude('a2')])
Output: 'tag:"a1" -tag:"a2"'
```

### Mixed Filters
```
Input: SearchFilter(
  tags: [FilterItem.include('romance')],
  artists: [FilterItem.exclude('badartist')],
  language: 'english'
)
Output: 'tag:"romance" -artist:"badartist" language:"english"'
```

### Complex Example (as per requirements)
```
Input: SearchFilter(
  tags: [FilterItem.include('a1'), FilterItem.exclude('a3')],
  artists: [FilterItem.include('b1')],
  language: 'english'
)
Output: 'tag:"a1" -tag:"a3" artist:"b1" language:"english"'
URL: search/?q=tag%3A%22a1%22%20-tag%3A%22a3%22%20artist%3A%22b1%22%20language%3A%22english%22&page=1
```

This matches the required format: `"+-tag:"a1"+-artist:"b1"+language:"english""`