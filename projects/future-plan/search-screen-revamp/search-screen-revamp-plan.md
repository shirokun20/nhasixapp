# Search Screen Revamp - CDN-First Implementation

## 🎯 Objective
Revamp search screen untuk menggunakan data REAL dari CDN config dengan source-aware filtering. Support dual search modes: query-string (nhentai) dan form-based (crotpedia). **100% dynamic** - zero hardcoding.

## 📊 Current State Analysis

### Problems Identified:
1. ❌ Genre field added but no data (Crotpedia doesn't use genre, uses tag types instead)
2. ❌ Hardcoded filter options (language, category, genre)
3. ❌ No differentiation between nhentai & crotpedia filter capabilities
4. ❌ Include/exclude not source-aware
5. ❌ **CRITICAL**: Crotpedia uses **form-based search**, NOT query-string!
6. ❌ SortingWidget hardcoded for nhentai only

## 🔍 Source Search Architecture Analysis

### Nhentai - Query String Based
**URL Format**: `/search/?q=tag:"romance" -tag:"netorare" language:"english"&sort=popular&page=2`

**Features**:
- Single query string with prefixes
- Include/exclude via `-` prefix
- All filters in one `q` parameter
- **Dynamic re-sorting** after search (API supports `?sort=` param)

### Crotpedia - Form-Based Search  
**URL Format**: 
- Page 1: `/advanced-search/?title=&author=&artist=&yearx=&status=&type=&order=update&genre%5B%5D=ahegao&genre%5B%5D=vanilla`
- Page 2: `/advanced-search/page/2/?title&author&artist&yearx&status&type&order=title&genre%5B0%5D=blowjob`

**Form Fields**:
```html
<form action="https://crotpedia.net/advanced-search/" method="GET">
  <input name="title" type="text">           <!-- Title search -->
  <input name="author" type="text">          <!-- Author search -->
  <input name="artist" type="text">          <!-- Artist search -->
  <input name="yearx" type="number" min="4"> <!-- Year filter -->
  
  <!-- Status: radio (all/ongoing/completed) -->
  <!-- Type: radio (all/Manga/Image-set/Manhwa/One-shot/Doujinshi) -->
  <!-- Order: radio (title/titlereverse/update/latest/popular/rating) -->
  <!-- Genre: checkbox multi-select (100+ genres!) -->
</form>
```

**Features**:
- **NO query string concatenation**
- **NO include/exclude** (only include)
- **Separate form parameters**
- **Genre as checkbox array** `genre[]`
- **Order pre-selected in form** (cannot dynamically re-sort, must re-search)

## 📐 Revised Implementation Plan

### Phase 1: Config Model Updates

#### 1.1 Add SearchConfig to SourceConfig
```dart
@freezed
class SourceConfig with _$SourceConfig {
  const factory SourceConfig({
    required String version,
    required String minAppVersion,
    required String url,
    
    SearchConfig? searchConfig,  // NEW: Search configuration
    ScrapingConfig? scraping,
    // ...
  }) = _SourceConfig;
}
```

#### 1.2 Create SearchConfig Model
```dart
@freezed
class SearchConfig with _$SearchConfig {
  const factory SearchConfig({
    required SearchMode searchMode,  // query-string or form-based
    required String endpoint,
    
    // NEW: Sorting configuration for main screen
    SortingConfig? sortingConfig,
    
    // For query-string mode (nhentai)
    String? queryParam,
    Map<String, bool>? filterSupport,  // singleSelect/multiSelect/exclude
    
    // For form-based mode (crotpedia)
    List<TextField>? textFields,
    List<RadioGroup>? radioGroups,
    List<CheckboxGroup>? checkboxGroups,
    
    PaginationConfig? pagination,
  }) = _SearchConfig;
}
```

#### 1.3 Create SortingConfig Model
```dart
@freezed
class SortingConfig with _$SortingConfig {
  const factory SortingConfig({
    required bool allowDynamicReSort,
    required String defaultSort,
    required SortWidgetType widgetType,  // dropdown | chips | readonly
    required List<SortOption> options,
    required SortingMessages messages,
  }) = _SortingConfig;
}

@freezed
class SortOption with _$SortOption {
  const factory SortOption({
    required String value,
    required String apiValue,
    required String label,
    required String displayLabel,
    String? icon,
    @Default(false) bool isDefault,
  }) = _SortOption;
}
```

### Phase 2: CDN Config Updates

#### 2.1 nhentai-config.json
```json
{
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
        }
      ],
      "messages": {
        "dropdownLabel": "Sort by:",
        "noOptionsAvailable": "No sorting options"
      }
    }
  }
}
```

#### 2.2 crotpedia-config.json
```json
{
  "searchConfig": {
    "searchMode": "form-based",
    "endpoint": "/advanced-search/",
    
    "textFields": [
      {"name": "title", "label": "Title", "type": "text"},
      {"name": "author", "label": "Author", "type": "text"},
      {"name": "artist", "label": "Artist", "type": "text"},
      {"name": "yearx", "label": "Year", "type": "number", "min": 1900}
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
        "name": "order",
        "label": "Order By",
        "options": [
          {"value": "update", "label": "Latest Update", "default": true},
          {"value": "popular", "label": "Popular"},
          {"value": "title", "label": "A-Z"}
        ]
      }
    ],
    
    "checkboxGroups": [
      {
        "name": "genre",
        "label": "Genre",
        "paramName": "genre[]",
        "displayMode": "expandable",
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
          "value": "popular",
          "apiValue": "popular",
          "label": "Popular",
          "displayLabel": "Sorted by: Most Popular",
          "icon": "trending_up"
        }
      ],
      "messages": {
        "readOnlyPrefix": "Sorted by:",
        "readOnlySuffix": "🔒",
        "tapToModifyHint": "Tap to modify search filters"
      }
    }
  }
}
```

### Phase 3: UI Implementation

#### 3.1 Search Screen - Dynamic Form Builder
```dart
class SearchScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    final sourceConfig = getSourceConfig();
    final searchConfig = sourceConfig?.searchConfig;
    
    if (searchConfig == null) return FallbackSearchUI();
    
    switch (searchConfig.searchMode) {
      case SearchMode.queryString:
        return QueryStringSearchUI(config: searchConfig);
      case SearchMode.formBased:
        return FormBasedSearchUI(config: searchConfig);
    }
  }
}

class FormBasedSearchUI extends StatelessWidget {
  final SearchConfig config;
  
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Render text fields dynamically
        ...config.textFields?.map(_buildTextField) ?? [],
        
        // Render radio groups dynamically
        ...config.radioGroups?.map(_buildRadioGroup) ?? [],
        
        // Render checkbox groups dynamically
        ...config.checkboxGroups?.map(_buildCheckboxGroup) ?? [],
      ],
    );
  }
}
```

#### 3.2 Main Screen - Dynamic Sorting Widget
```dart
class DynamicSortingWidget extends StatelessWidget {
  final String currentSortValue;
  final SortingConfig config;
  final Function(String)? onSortChanged;
  final VoidCallback? onNavigateToSearch;
  
  Widget build(BuildContext context) {
    switch (config.widgetType) {
      case SortWidgetType.dropdown:
        return _buildDropdown();  // Interactive for nhentai
      case SortWidgetType.readonly:
        return _buildReadOnly();  // Display-only for crotpedia
      case SortWidgetType.chips:
        return _buildChips();     // Alternative UI
    }
  }
}
```

### Phase 4: Scraper Updates

#### 4.1 CrotpediaScraper - Form Query Builder
```dart
String buildAdvancedSearchUrl(SearchFilter filter, int page) {
  final params = <String, dynamic>{};
  
  // Text fields
  if (filter.title != null) params['title'] = filter.title;
  if (filter.author != null) params['author'] = filter.author;
  
  // Radio selections
  if (filter.status != null) params['status'] = filter.status.apiValue;
  if (filter.orderBy != null) params['order'] = filter.orderBy;
  
  // Checkbox array
  for (final genre in filter.genres) {
    // genre[] parameter
  }
  
  final path = page == 1 ? '/advanced-search/' : '/advanced-search/page/$page/';
  return Uri.https('crotpedia.net', path, params).toString();
}
```

## 🎯 Success Criteria

### Nhentai:
- [ ] Search screen: Query input + tag chips from config
- [ ] Main screen: Interactive dropdown sorting (can re-sort)
- [ ] Query: `tag:"romance" -tag:"netorare" language:"english"`
- [ ] Sort change: Re-fetch with `?sort=popular`

### Crotpedia:
- [ ] Search screen: Form fields from config (title, author, year, genre checkboxes)
- [ ] Main screen: Read-only sorting widget (shows current, tap to go back)
- [ ] Query: Form params `?title=xxx&genre[]=ahegao&order=update`
- [ ] Sort change: Navigate back to search, change order radio, re-submit

## 📝 Files to Modify

### Config Models:
- [ ] `lib/core/config/config_models.dart` - Add SearchConfig, SortingConfig, etc

### Search Screen:
- [ ] `lib/presentation/pages/search/search_screen.dart` - Dynamic form builder
- [ ] `lib/presentation/widgets/query_string_search_ui.dart` - NEW for nhentai
- [ ] `lib/presentation/widgets/form_based_search_ui.dart` - NEW for crotpedia

### Main Screen:
- [ ] `lib/presentation/pages/main/main_screen_scrollable.dart` - Use DynamicSortingWidget
- [ ] `lib/presentation/widgets/dynamic_sorting_widget.dart` - NEW universal widget

### Scrapers:
- [ ] `lib/data/datasources/remote/crotpedia_scraper.dart` - Form query builder
- [ ] `lib/data/datasources/remote/nhentai_scraper.dart` - Query string (existing)

### CDN Configs:
- [ ] `configs/nhentai-config.json` - Add searchConfig with sortingConfig
- [ ] `configs/crotpedia-config.json` - Add searchConfig with sortingConfig

## 🎨 UI/UX Comparison

### Nhentai Flow:
```
Search Screen (Query String)
┌─────────────────────────────┐
│ Search: [isekai          ]  │
│                             │
│ Tags: [romance] [+]         │
│ Exclude: [-netorare]        │
│                             │
│ Language: [English ▼]       │
│                             │
│ [Search Button]             │
└─────────────────────────────┘
         ↓ Submit
Main Screen (Results)
┌─────────────────────────────┐
│ 🔍 Search Results           │
│ Query: "isekai romance"     │
│                             │
│ Sort by: [Popular ▼]        │ ← Can change
│                             │
│ [Grid...]                   │
└─────────────────────────────┘
```

### Crotpedia Flow:
```
Search Screen (Form Based)
┌─────────────────────────────┐
│ Title: [isekai          ]   │
│ Author: [              ]    │
│ Year: [2024            ]    │
│                             │
│ Order By:                   │
│ ○ A-Z  ● Latest  ○ Popular  │
│                             │
│ Genre: [✓] Romance          │
│        [✓] Fantasy          │
│                             │
│ [Search Button]             │
└─────────────────────────────┘
         ↓ Submit with order=latest
Main Screen (Results)
┌─────────────────────────────┐
│ 🔍 Search Results           │
│ Title: "isekai"             │
│ Genre: Romance, Fantasy     │
│                             │
│ Sorted by: Latest Update 🔒 │ ← Read-only
│ Tap to modify filters       │
│                             │
│ [Grid...]                   │
└─────────────────────────────┘
```

## ✅ Benefits

1. **100% CDN-Driven**: Zero hardcoding, all from config
2. **Source-Aware**: UI adapts to source capabilities
3. **Flexible**: Support multiple widget types (dropdown/chips/readonly)
4. **Maintainable**: Update via CDN, no app release needed
5. **Localization Ready**: Labels in config, easy to translate
6. **Future-Proof**: New sources just need config file

---

## 📊 Status
**Stage**: Planning - Ready for Implementation
**Created**: 2026-01-13
**Updated**: 2026-01-13 (Added dynamic sorting config)
**Ready for**: Execution Phase


