# CDN Config Updates for Crotpedia Form-Based Search

## 🎯 Required Configuration Updates

### File: `crotpedia-config.json`

**Location**: `configs/crotpedia-config.json` di CDN repo

**New Fields Needed**:

```json
{
  "version": "1.0.0",
  "minimumAppVersion": "0.7.0",
  "lastUpdated": "2026-01-13",
  
  "searchConfig": {
    "searchMode": "form-based",  // NEW: "query-string" or "form-based"
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
          { "value": "", "label": "All", "default": true },
          { "value": "ongoing", "label": "Ongoing" },
          { "value": "completed", "label": "Completed" }
        ]
      },
      {
        "name": "type",
        "label": "Type",
        "options": [
          { "value": "", "label": "All", "default": true },
          { "value": "Manga", "label": "Manga" },
          { "value": "Image-set", "label": "Image Set" },
          { "value": "Manhwa", "label": "Manhwa" },
          { "value": "One-shot", "label": "One Shot" },
          { "value": "Doujinshi", "label": "Doujinshi" }
        ]
      },
      {
        "name": "order",
        "label": "Order By",
        "options": [
          { "value": "title", "label": "A-Z", "default": true },
          { "value": "titlereverse", "label": "Z-A" },
          { "value": "update", "label": "Latest Update" },
          { "value": "latest", "label": "Latest Added" },
          { "value": "popular", "label": "Popular" },
          { "value": "rating", "label": "Rating" }
        ]
      }
    ],
    
    "checkboxGroups": [
      {
        "name": "genre",
        "label": "Genre",
        "paramName": "genre[]",  // Form parameter name
        "displayMode": "expandable",  // "expandable" or "inline"
        "columns": 3,  // Grid columns for checkboxes
        "loadFromTags": true,  // Load options from tags data
        "tagType": "genre"  // Which tag type to use
      }
    ],
    
    "pagination": {
      "urlPattern": "/advanced-search/page/{page}/",
      "paramName": "page"
    }
  },
  
  "scraping": {
    // ... existing selectors ...
  }
}
```

---

## 📝 Config Model Updates

### File: `lib/core/config/config_models.dart`

**New Classes Needed**:

```dart
/// Search configuration for source
@freezed
class SearchConfig with _$SearchConfig {
  const factory SearchConfig({
    required SearchMode searchMode,  // query-string or form-based
    required String endpoint,
    @Default([]) List<TextField> textFields,
    @Default([]) List<RadioGroup> radioGroups,
    @Default([]) List<CheckboxGroup> checkboxGroups,
    PaginationConfig? pagination,
  }) = _SearchConfig;
  
  factory SearchConfig.fromJson(Map<String, dynamic> json) =>
      _$SearchConfigFromJson(json);
}

enum SearchMode {
  @JsonValue('query-string')
  queryString,
  
  @JsonValue('form-based')
  formBased,
}

/// Text field configuration
@freezed
class TextField with _$TextField {
  const factory TextField({
    required String name,
    required String label,
    required String type,  // 'text' or 'number'
    String? placeholder,
    int? maxLength,
    int? min,
    int? max,
  }) = _TextField;
  
  factory TextField.fromJson(Map<String, dynamic> json) =>
      _$TextFieldFromJson(json);
}

/// Radio group configuration
@freezed
class RadioGroup with _$RadioGroup {
  const factory RadioGroup({
    required String name,
    required String label,
    required List<RadioOption> options,
  }) = _RadioGroup;
  
  factory RadioGroup.fromJson(Map<String, dynamic> json) =>
      _$RadioGroupFromJson(json);
}

@freezed
class RadioOption with _$RadioOption {
  const factory RadioOption({
    required String value,
    required String label,
    @Default(false) bool isDefault,
  }) = _RadioOption;
  
  factory RadioOption.fromJson(Map<String, dynamic> json) =>
      _$RadioOptionFromJson(json);
}

/// Checkbox group configuration
@freezed
class CheckboxGroup with _$CheckboxGroup {
  const factory CheckboxGroup({
    required String name,
    required String label,
    required String paramName,  // e.g., "genre[]"
    @Default('expandable') String displayMode,
    @Default(3) int columns,
    @Default(false) bool loadFromTags,
    String? tagType,
  }) = _CheckboxGroup;
  
  factory CheckboxGroup.fromJson(Map<String, dynamic> json) =>
      _$CheckboxGroupFromJson(json);
}

/// Pagination configuration
@freezed
class PaginationConfig with _$PaginationConfig {
  const factory PaginationConfig({
    required String urlPattern,  // e.g., "/advanced-search/page/{page}/"
    @Default('page') String paramName,
  }) = _PaginationConfig;
  
  factory PaginationConfig.fromJson(Map<String, dynamic> json) =>
      _$PaginationConfigFromJson(json);
}
```

---

## 🔄 Update Existing Model

### File: `lib/core/config/config_models.dart` - SourceConfig

Add `searchConfig`:

```dart
@freezed
class SourceConfig with _$SourceConfig {
  const factory SourceConfig({
    required String version,
    required String minAppVersion,
    required String url,
    
    // ADD THIS:
    SearchConfig? searchConfig,  // NEW field for search configuration
    
    // Existing fields:
    ScrapingConfig? scraping,
    // ...
  }) = _SourceConfig;
  
  factory SourceConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceConfigFromJson(json);
}
```

---

## 🎨 Usage Example

### In SearchScreen:

```dart
Widget _buildAdvancedFilters() {
  final sourceId = context.read<SourceCubit>().state.activeSource?.id;
  final sourceConfig = getIt<RemoteConfigService>()
    .getSourceConfig(sourceId);
  
  final searchConfig = sourceConfig?.searchConfig;
  
  if (searchConfig == null) {
    return _buildLegacyFilters();  // Fallback
  }
  
  switch (searchConfig.searchMode) {
    case SearchMode.queryString:
      return _buildQueryStringFilters(searchConfig);  // Nhentai
    case SearchMode.formBased:
      return _buildFormBasedFilters(searchConfig);    // Crotpedia
  }
}

Widget _buildFormBasedFilters(SearchConfig config) {
  return Column(
    children: [
      // Render text fields
      ...config.textFields.map(_buildTextFieldWidget),
      
      // Render radio groups
      ...config.radioGroups.map(_buildRadioGroupWidget),
      
      // Render checkbox groups
      ...config.checkboxGroups.map(_buildCheckboxGroupWidget),
    ],
  );
}
```

---

## 📊 Config File Structure

```
configs/
├── manifest.json                    (existing)
├── app-config.json                  (existing)
├── tags-config.json                 (existing)
├── nhentai-config.json              (existing)
└── crotpedia-config.json            (UPDATE with searchConfig)
```

---

## ✅ Checklist

### CDN Repo Updates:
- [ ] Add `searchConfig` object to `crotpedia-config.json`
- [ ] Define `textFields` (title, author, artist, yearx)
- [ ] Define `radioGroups` (status, type, order)
- [ ] Define `checkboxGroups` (genre with loadFromTags: true)
- [ ] Set `searchMode: "form-based"`
- [ ] Commit and push to CDN

### App Model Updates:
- [ ] Create `SearchConfig` freezed class
- [ ] Create `SearchMode` enum
- [ ] Create `TextField`, `RadioGroup`, `CheckboxGroup` models
- [ ] Update `SourceConfig` to include `searchConfig?`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`

### App Usage:
- [ ] `RemoteConfigService` exposes `getSourceConfig(sourceId)`
- [ ] `SearchScreen` reads `searchConfig` and renders dynamically
- [ ] `CrotpediaScraper` uses `searchConfig` to build URLs

---

## 🚀 Benefits

1. ✅ **100% Dynamic**: All form fields dari config CDN
2. ✅ **No Hardcoding**: Gampang update via CDN tanpa release app
3. ✅ **Future-Proof**: New sources tinggal tambah config
4. ✅ **Validation**: Min/max values dari config
5. ✅ **Localization Ready**: Labels bisa dibuat multi-language

---

**Next Step**: Implement config models dan update CDN.
