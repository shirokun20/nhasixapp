# Dynamic Search Screen Implementation Guide

## 📋 Complete Implementation Checklist

### Phase 1: Config Models (Priority 1)

#### ✅ Task 1.1: Create Base Config Models
**File**: `lib/core/config/config_models.dart`

Add these Freezed classes:

```dart
/// Search mode enum
enum SearchMode {
  @JsonValue('query-string')
  queryString,
  
  @JsonValue('form-based')
  formBased,
}

/// Widget type for sorting display
enum SortWidgetType {
  @JsonValue('dropdown')
  dropdown,
  
  @JsonValue('chips')
  chips,
  
  @JsonValue('readonly')
  readonly,
}

/// Main search configuration
@freezed
class SearchConfig with _$SearchConfig {
  const factory SearchConfig({
    required SearchMode searchMode,
    required String endpoint,
    
    // Sorting config (for main screen results)
    SortingConfig? sortingConfig,
    
    // Query-string mode fields (nhentai)
    String? queryParam,
    FilterSupportConfig? filterSupport,
    
    // Form-based mode fields (crotpedia)
    List<TextFieldConfig>? textFields,
    List<RadioGroupConfig>? radioGroups,
    List<CheckboxGroupConfig>? checkboxGroups,
    
    PaginationConfig? pagination,
  }) = _SearchConfig;
  
  factory SearchConfig.fromJson(Map<String, dynamic> json) =>
      _$SearchConfigFromJson(json);
}

/// Filter support configuration
@freezed
class FilterSupportConfig with _$FilterSupportConfig {
  const factory FilterSupportConfig({
    required List<String> singleSelect,  // ['language', 'category']
    required List<String> multiSelect,   // ['tag', 'artist', ...]
    required bool supportsExclude,       // true for nhentai
  }) = _FilterSupportConfig;
  
  factory FilterSupportConfig.fromJson(Map<String, dynamic> json) =>
      _$FilterSupportConfigFromJson(json);
}

/// Text field configuration
@freezed
class TextFieldConfig with _$TextFieldConfig {
  const factory TextFieldConfig({
    required String name,
    required String label,
    required String type,  // 'text' or 'number'
    String? placeholder,
    int? maxLength,
    int? min,
    int? max,
  }) = _TextFieldConfig;
  
  factory TextFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$TextFieldConfigFromJson(json);
}

/// Radio group configuration
@freezed
class RadioGroupConfig with _$RadioGroupConfig {
  const factory RadioGroupConfig({
    required String name,
    required String label,
    required List<RadioOptionConfig> options,
  }) = _RadioGroupConfig;
  
  factory RadioGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioGroupConfigFromJson(json);
}

@freezed
class RadioOptionConfig with _$RadioOptionConfig {
  const factory RadioOptionConfig({
    required String value,
    required String label,
    @Default(false) bool isDefault,
  }) = _RadioOptionConfig;
  
  factory RadioOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioOptionConfigFromJson(json);
}

/// Checkbox group configuration
@freezed
class CheckboxGroupConfig with _$CheckboxGroupConfig {
  const factory CheckboxGroupConfig({
    required String name,
    required String label,
    required String paramName,
    @Default('expandable') String displayMode,
    @Default(3) int columns,
    @Default(false) bool loadFromTags,
    String? tagType,
  }) = _CheckboxGroupConfig;
  
  factory CheckboxGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$CheckboxGroupConfigFromJson(json);
}

/// Sorting configuration
@freezed
class SortingConfig with _$SortingConfig {
  const factory SortingConfig({
    required bool allowDynamicReSort,
    required String defaultSort,
    required SortWidgetType widgetType,
    required List<SortOptionConfig> options,
    required SortingMessages messages,
  }) = _SortingConfig;
  
  factory SortingConfig.fromJson(Map<String, dynamic> json) =>
      _$SortingConfigFromJson(json);
}

@freezed
class SortOptionConfig with _$SortOptionConfig {
  const factory SortOptionConfig({
    required String value,
    required String apiValue,
    required String label,
    required String displayLabel,
    String? icon,
    @Default(false) bool isDefault,
  }) = _SortOptionConfig;
  
  factory SortOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SortOptionConfigFromJson(json);
}

@freezed
class SortingMessages with _$SortingMessages {
  const factory SortingMessages({
    String? dropdownLabel,
    String? noOptionsAvailable,
    String? readOnlyPrefix,
    String? readOnlySuffix,
    String? tapToModifyHint,
    String? returnToSearchButton,
  }) = _SortingMessages;
  
  factory SortingMessages.fromJson(Map<String, dynamic> json) =>
      _$SortingMessagesFromJson(json);
}

/// Pagination configuration
@freezed
class PaginationConfig with _$PaginationConfig {
  const factory PaginationConfig({
    required String urlPattern,
    @Default('page') String paramName,
  }) = _PaginationConfig;
  
  factory PaginationConfig.fromJson(Map<String, dynamic> json) =>
      _$PaginationConfigFromJson(json);
}
```

**After adding**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

#### ✅ Task 1.2: Update SourceConfig
**File**: `lib/core/config/config_models.dart`

Add `searchConfig` field:

```dart
@freezed
class SourceConfig with _$SourceConfig {
  const factory SourceConfig({
    required String version,
    required String minAppVersion,
    required String url,
    
    SearchConfig? searchConfig,  // ← ADD THIS
    
    // Existing fields
    ScrapingConfig? scraping,
    // ...
  }) = _SourceConfig;
  
  factory SourceConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceConfigFromJson(json);
}
```

---

### Phase 2: CDN Config Files (Priority 2)

#### ✅ Task 2.1: Update nhentai-config.json

Add to CDN repo: `configs/nhentai-config.json`

```json
{
  "version": "1.0.0",
  "minimumAppVersion": "0.7.0",
  "url": "https://nhentai.net",
  
  "searchConfig": {
    "searchMode": "query-string",
    "endpoint": "/search/",
    "queryParam": "q",
    
    "filterSupport": {
      "singleSelect": ["language", "category"],
      "multiSelect": ["tag", "artist", "character", "parody", "group"],
      "supportsExclude": true
    },
    
    "sortingConfig": {
      "allowDynamicReSort": true,
      "defaultSort": "newest",
      "widgetType": "dropdown",
      "options": [
        {
          "value": "newest",
          "apiValue": "",
          "label": "Recent",
          "displayLabel": "Sorted by: Recent",
          "icon": "update",
          "default": true
        },
        {
          "value": "popular",
          "apiValue": "popular",
          "label": "Popular",
          "displayLabel": "Sorted by: Most Popular",
          "icon": "trending_up"
        },
        {
          "value": "popular-week",
          "apiValue": "popular-week",
          "label": "Popular This Week",
          "displayLabel": "Sorted by: Popular This Week",
          "icon": "date_range"
        },
        {
          "value": "popular-today",
          "apiValue": "popular-today",
          "label": "Popular Today",
          "displayLabel": "Sorted by: Popular Today",
          "icon": "today"
        }
      ],
      "messages": {
        "dropdownLabel": "Sort by:",
        "noOptionsAvailable": "No sorting options"
      }
    },
    
    "pagination": {
      "urlPattern": "/search/?q={query}&page={page}",
      "paramName": "page"
    }
  },
  
  "scraping": {
    // ... existing scraping config
  }
}
```

---

#### ✅ Task 2.2: Update crotpedia-config.json

Add to CDN repo: `configs/crotpedia-config.json`

```json
{
  "version": "1.0.0",
  "minimumAppVersion": "0.7.0",
  "url": "https://crotpedia.net",
  
  "searchConfig": {
    "searchMode": "form-based",
    "endpoint": "/advanced-search/",
    
    "textFields": [
      {
        "name": "title",
        "label": "Title",
        "type": "text",
        "placeholder": "Search by title...",
        "maxLength": 100
      },
      {
        "name": "author",
        "label": "Author",
        "type": "text",
        "placeholder": "Search by author...",
        "maxLength": 100
      },
      {
        "name": "artist",
        "label": "Artist",
        "type": "text",
        "placeholder": "Search by artist...",
        "maxLength": 100
      },
      {
        "name": "yearx",
        "label": "Year",
        "type": "number",
        "min": 1900,
        "max": 2100,
        "placeholder": "e.g., 2024"
      }
    ],
    
    "radioGroups": [
      {
        "name": "status",
        "label": "Status",
        "options": [
          {"value": "", "label": "All", "default": true},
          {"value": "ongoing", "label": "Ongoing"},
          {"value": "completed", "label": "Completed"}
        ]
      },
      {
        "name": "type",
        "label": "Type",
        "options": [
          {"value": "", "label": "All", "default": true},
          {"value": "Manga", "label": "Manga"},
          {"value": "Image-set", "label": "Image Set"},
          {"value": "Manhwa", "label": "Manhwa"},
          {"value": "One-shot", "label": "One Shot"},
          {"value": "Doujinshi", "label": "Doujinshi"}
        ]
      },
      {
        "name": "order",
        "label": "Order By",
        "options": [
          {"value": "update", "label": "Latest Update", "default": true},
          {"value": "latest", "label": "Latest Added"},
          {"value": "popular", "label": "Popular"},
          {"value": "rating", "label": "Rating"},
          {"value": "title", "label": "A-Z"},
          {"value": "titlereverse", "label": "Z-A"}
        ]
      }
    ],
    
    "checkboxGroups": [
      {
        "name": "genre",
        "label": "Genre",
        "paramName": "genre[]",
        "displayMode": "expandable",
        "columns": 3,
        "loadFromTags": true,
        "tagType": "genre"
      }
    ],
    
    "sortingConfig": {
      "allowDynamicReSort": false,
      "defaultSort": "update",
      "widgetType": "readonly",
      "options": [
        {
          "value": "update",
          "apiValue": "update",
          "label": "Latest Update",
          "displayLabel": "Sorted by: Latest Update",
          "icon": "update",
          "default": true
        },
        {
          "value": "latest",
          "apiValue": "latest",
          "label": "Latest Added",
          "displayLabel": "Sorted by: Latest Added",
          "icon": "new_releases"
        },
        {
          "value": "popular",
          "apiValue": "popular",
          "label": "Popular",
          "displayLabel": "Sorted by: Most Popular",
          "icon": "trending_up"
        },
        {
          "value": "rating",
          "apiValue": "rating",
          "label": "Rating",
          "displayLabel": "Sorted by: Highest Rating",
          "icon": "star"
        },
        {
          "value": "title",
          "apiValue": "title",
          "label": "A-Z",
          "displayLabel": "Sorted by: A-Z",
          "icon": "sort_by_alpha"
        },
        {
          "value": "titlereverse",
          "apiValue": "titlereverse",
          "label": "Z-A",
          "displayLabel": "Sorted by: Z-A",
          "icon": "sort_by_alpha"
        }
      ],
      "messages": {
        "readOnlyPrefix": "Sorted by:",
        "readOnlySuffix": "🔒",
        "tapToModifyHint": "Tap to modify search filters"
      }
    },
    
    "pagination": {
      "urlPattern": "/advanced-search/page/{page}/",
      "paramName": "page"
    }
  },
  
  "scraping": {
    // ... existing scraping config
  }
}
```

---

### Phase 3: UI Components (Priority 3)

#### ✅ Task 3.1: Create DynamicSortingWidget

**New File**: `lib/presentation/widgets/dynamic_sorting_widget.dart`

See: `sorting-widget-implementation.md` for full code

Key features:
- Renders dropdown for `allowDynamicReSort: true`
- Renders readonly for `allowDynamicReSort: false`
- Maps icon strings to IconData
- Handles tap events appropriately

---

#### ✅ Task 3.2: Update main_screen_scrollable.dart

Replace existing `SortingWidget` usage with:

```dart
Widget _buildSortingSection() {
  if (!_isShowingSearchResults) return SizedBox.shrink();
  
  final sourceId = context.read<SourceCubit>().state.activeSource?.id;
  final sourceConfig = getIt<RemoteConfigService>().getSourceConfig(sourceId);
  final sortingConfig = sourceConfig?.searchConfig?.sortingConfig;
  
  if (sortingConfig == null) return SizedBox.shrink();
  
  return DynamicSortingWidget(
    currentSortValue: _getCurrentSortValue(),
    config: sortingConfig,
    onSortChanged: sortingConfig.allowDynamicReSort
        ? (newValue) => _handleSortChange(newValue, sortingConfig)
        : null,
    onNavigateToSearch: !sortingConfig.allowDynamicReSort
        ? () => _navigateToSearchToModify()
        : null,
  );
}
```

---

### Phase 4: Search Screen Revamp (Priority 4)

#### ✅ Task 4.1: Create QueryStringSearchUI

**New File**: `lib/presentation/widgets/query_string_search_ui.dart`

For nhentai - existing query input + tag chips

---

#### ✅ Task 4.2: Create FormBasedSearchUI

**New File**: `lib/presentation/widgets/form_based_search_ui.dart`

Dynamic form builder for crotpedia:
- Render `textFields` from config
- Render `radioGroups` from config
- Render `checkboxGroups` with tag data

---

#### ✅ Task 4.3: Update search_screen.dart

Add conditional rendering:

```dart
Widget build(BuildContext context) {
  final sourceConfig = _getSourceConfig();
  final searchConfig = sourceConfig?.searchConfig;
  
  if (searchConfig == null) {
    return _buildFallbackUI();
  }
  
  switch (searchConfig.searchMode) {
    case SearchMode.queryString:
      return QueryStringSearchUI(config: searchConfig);
    case SearchMode.formBased:
      return FormBasedSearchUI(config: searchConfig);
  }
}
```

---

### Phase 5: Scraper Updates (Priority 5)

#### ✅ Task 5.1: Update CrotpediaScraper

Add form query builder method

#### ✅ Task 5.2: Update NhentaiScraper

Ensure query string building works with config

---

## 🧪 Testing Checklist

### Nhentai Tests:
- [ ] Load config, verify `searchMode == query-string`
- [ ] sortingConfig.allowDynamicReSort == true
- [ ] Dropdown renders with all options
- [ ] Change sort → API called with correct param
- [ ] Icons render correctly

### Crotpedia Tests:
- [ ] Load config, verify `searchMode == form-based`
- [ ] textFields render from config
- [ ] radioGroups render from config
- [ ] checkboxGroups load genres from tags
- [ ] sortingConfig.allowDynamicReSort == false
- [ ] Readonly widget displays current sort
- [ ] Tap widget → navigates to search

### Source Switch Tests:
- [ ] Switch nhentai → crotpedia: UI changes
- [ ] Switch crotpedia → nhentai: UI changes
- [ ] Sorting widget adapts correctly

---

## 📊 Progress Tracking

| Phase | Tasks | Status |
|-------|-------|--------|
| 1. Config Models | 2 tasks | ⏳ Pending |
| 2. CDN Configs | 2 tasks | ⏳ Pending |
| 3. UI Components | 2 tasks | ⏳ Pending |
| 4. Search Screen | 3 tasks | ⏳ Pending |
| 5. Scrapers | 2 tasks | ⏳ Pending |
| **TOTAL** | **11 tasks** | **0% Complete** |

---

**Next Step**: Start with Phase 1 - Config Models
