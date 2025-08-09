# FilterDataScreen Navigation Guide

## Overview

This document explains the navigation flow for the FilterDataScreen, which provides advanced filter selection functionality for the search feature.

## Navigation Flow

### 1. SearchScreen → FilterDataScreen

**Trigger**: User taps on a filter type button (Tags, Artists, Characters, Parodies, Groups) in the SearchScreen.

**Navigation Method**:
```dart
final result = await AppRouter.goToFilterData(
  context,
  filterType: filterType, // 'tag', 'artist', 'character', 'parody', 'group'
  selectedFilters: selectedFilters, // List<FilterItem>
);
```

**Route**: `/filter-data?type={filterType}`

**Parameters**:
- `filterType`: String indicating the type of filter ('tag', 'artist', 'character', 'parody', 'group')
- `selectedFilters`: List<FilterItem> passed as `extra` data containing currently selected filters

### 2. FilterDataScreen → SearchScreen (Apply)

**Trigger**: User taps the "Apply" button after selecting filters.

**Navigation Method**:
```dart
AppRouter.returnFromFilterData(context, selectedFilters);
```

**Result**: Returns `List<FilterItem>` containing the selected filters back to SearchScreen.

### 3. FilterDataScreen → SearchScreen (Cancel)

**Trigger**: User taps the "Cancel" button or back button.

**Navigation Method**:
```dart
AppRouter.cancelFilterData(context);
```

**Result**: Returns `null` to SearchScreen, indicating no changes should be made.

## Route Configuration

### Route Definition
```dart
GoRoute(
  path: AppRoute.filterData, // '/filter-data'
  name: AppRoute.filterDataName, // 'filter-data'
  builder: (context, state) {
    final filterType = state.uri.queryParameters['type'] ?? 'tag';
    final selectedFilters = state.extra as List<FilterItem>? ?? [];
    return FilterDataScreen(
      filterType: filterType,
      selectedFilters: selectedFilters,
    );
  },
),
```

### Route Constants
```dart
class AppRoute {
  static const String filterData = '/filter-data';
  static const String filterDataName = 'filter-data';
}
```

## Navigation Helper Methods

### AppRouter Methods

1. **goToFilterData**: Navigate to FilterDataScreen with parameters
   ```dart
   static Future<List<FilterItem>?> goToFilterData(
     BuildContext context, {
     required String filterType,
     required List<FilterItem> selectedFilters,
   })
   ```

2. **returnFromFilterData**: Return from FilterDataScreen with results
   ```dart
   static void returnFromFilterData(BuildContext context, List<FilterItem> selectedFilters)
   ```

3. **cancelFilterData**: Cancel FilterDataScreen navigation
   ```dart
   static void cancelFilterData(BuildContext context)
   ```

## Data Flow

### FilterItem Structure
```dart
class FilterItem {
  final String value;
  final bool isExcluded; // true = exclude, false = include
  
  // Factory constructors
  FilterItem.include(String value);
  FilterItem.exclude(String value);
}
```

### SearchFilter Integration
The navigation results are integrated into SearchFilter based on the filter type:

```dart
switch (filterType.toLowerCase()) {
  case 'tag':
    _currentFilter = _currentFilter.copyWith(tags: result);
    break;
  case 'artist':
    _currentFilter = _currentFilter.copyWith(artists: result);
    break;
  case 'character':
    _currentFilter = _currentFilter.copyWith(characters: result);
    break;
  case 'parody':
    _currentFilter = _currentFilter.copyWith(parodies: result);
    break;
  case 'group':
    _currentFilter = _currentFilter.copyWith(groups: result);
    break;
}
```

## Error Handling

### Navigation Error Handling
```dart
try {
  final result = await AppRouter.goToFilterData(
    context,
    filterType: filterType,
    selectedFilters: selectedFilters,
  );
  
  if (result != null && result.isNotEmpty) {
    // Process result
  }
} catch (e) {
  Logger().e('SearchScreen: Error navigating to filter data: $e');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error opening filter selection: $e'),
        backgroundColor: ColorsConst.accentRed,
      ),
    );
  }
}
```

## Testing

### Unit Tests
- Route construction with parameters
- FilterItem serialization/deserialization
- SearchFilter integration
- Navigation result processing

### Integration Tests
- Complete navigation flow
- Parameter passing
- Result handling
- Error scenarios

## Best Practices

1. **Always check for null results** when navigation is cancelled
2. **Use proper error handling** for navigation failures
3. **Validate filter types** before navigation
4. **Maintain state consistency** when updating SearchFilter
5. **Test navigation flows** thoroughly

## Supported Filter Types

- `tag`: Content tags
- `artist`: Content artists
- `character`: Content characters
- `parody`: Content parodies
- `group`: Content groups

Each filter type supports both include and exclude functionality through FilterItem.