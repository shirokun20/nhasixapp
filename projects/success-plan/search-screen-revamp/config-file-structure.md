# CDN Config File Structure - Clarification

## 📁 Config File Locations & Purpose

### 1. **Source-Specific Configs** (where `searchConfig` goes)

#### `nhentai-config.json`
**URL**: `https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs/nhentai-config.json`

**Purpose**: Nhentai-specific configuration (scraping, search, etc)

**Add searchConfig**:
```json
{
  "version": "1.0.0",
  "minimumAppVersion": "0.7.0",
  "url": "https://nhentai.net",
  
  "searchConfig": {
    "searchMode": "query-string",
    "endpoint": "/search/",
    "queryParam": "q",
    
    "filters": {
      "singleSelect": ["language", "category"],
      "multiSelect": ["tag", "artist", "character", "parody", "group"],
      "supportsExclude": true
    },
    
    "sortOptions": [
      { "value": "", "label": "Recent", "default": true },
      { "value": "popular", "label": "Popular" },
      { "value": "popular-week", "label": "Popular This Week" },
      { "value": "popular-today", "label": "Popular Today" }
    ],
    
    "pagination": {
      "urlPattern": "/search/?{query}&page={page}",
      "paramName": "page"
    }
  },
  
  "scraping": {
    // ... existing selectors ...
  }
}
```

---

#### `crotpedia-config.json`
**URL**: `https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs/crotpedia-config.json`

**Purpose**: Crotpedia-specific configuration (scraping, search, etc)

**Add searchConfig**:
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
        "paramName": "genre[]",
        "displayMode": "expandable",
        "columns": 3,
        "loadFromTags": true,
        "tagType": "genre"
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

### 2. **Cross-Source Config** (separate purpose)

#### `tags-config.json`
**URL**: `https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs/tags-config.json`

**Purpose**: Tag data management ONLY (version, sources, migration URLs)

**DO NOT add searchConfig here** - this is only for tag data!

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-01-13T13:24:00+07:00",
  "sources": {
    "nhentai": {
      "type": "bundled",
      "assetPath": "assets/json/tags.json",
      "format": "array",
      "structure": ["id", "name", "slug", "typeCode"],
      "typeCodeMapping": {
        "0": "category",
        "1": "artist",
        "2": "parody",
        "3": "tag",
        "4": "character",
        "5": "group",
        "6": "language",
        "7": "category"
      },
      "multiSelectSupport": {
        "tag": true,
        "artist": true,
        "character": true,
        "parody": true,
        "group": true,
        "language": false,
        "category": false
      },
      "migration": {
        "enabled": true,
        "remoteUrl": "https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@configs/configs/tags/tags_nhentai.json",
        "fallbackUrl": "...",
        "compression": "none",
        "cacheTtlSeconds": 86400
      }
    },
    "crotpedia": {
      "type": "remote",
      "format": "array",
      "structure": ["id", "name", "slug", "typeCode"],
      "migration": {
        "enabled": true,
        "remoteUrl": "https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@configs/configs/tags/tags_crotpedia.json",
        "compression": "none",
        "cacheTtlSeconds": 86400
      }
    }
  }
}
```

---

## 📊 Config Responsibility Matrix

| File | Purpose | Contains searchConfig? | Contains tag data? |
|------|---------|----------------------|-------------------|
| `nhentai-config.json` | Nhentai scraping & search | ✅ YES | ❌ NO |
| `crotpedia-config.json` | Crotpedia scraping & search | ✅ YES | ❌ NO |
| `tags-config.json` | Tag data management | ❌ NO | ✅ YES (metadata only) |
| `tags/tags_nhentai.json` | Actual nhentai tags | ❌ NO | ✅ YES (actual data) |
| `tags/tags_crotpedia.json` | Actual crotpedia tags | ❌ NO | ✅ YES (actual data) |

---

## 🔄 How It Works Together

### 1. **App Initialization** (Splash Screen):
```dart
// Load all configs
await remoteConfigService.smartInitialize();

// Downloads:
// - nhentai-config.json (includes searchConfig for nhentai)
// - crotpedia-config.json (includes searchConfig for crotpedia)
// - tags-config.json (metadata about tags)

// Then downloads tag data:
// - tags_nhentai.json (actual tag list)
// - tags_crotpedia.json (actual tag list)
```

### 2. **Search Screen**:
```dart
// Get source-specific config
final sourceConfig = remoteConfigService.getSourceConfig('crotpedia');

// Get searchConfig from source config
final searchConfig = sourceConfig?.searchConfig;

// Build UI based on searchMode
if (searchConfig.searchMode == SearchMode.formBased) {
  // Render Crotpedia form (textFields, radioGroups, etc)
} else {
  // Render Nhentai query string UI
}

// Get genres for checkbox
final genres = await tagDataManager.getTagsByType('genre', source: 'crotpedia');
```

---

## ✅ Summary

**WHERE to add searchConfig**:
- ✅ `nhentai-config.json` → Add searchConfig for nhentai (query-string mode)
- ✅ `crotpedia-config.json` → Add searchConfig for crotpedia (form-based mode)
- ❌ `tags-config.json` → Keep as is (only tag metadata)

**WHAT each config does**:
- **Source configs** (`*-config.json`): How to scrape & search that source
- **Tags config** (`tags-config.json`): Where to get tag data for all sources
- **Tag data** (`tags/*.json`): Actual list of tags

**WHY separate**:
- Tags are shared concern (nhentai & crotpedia both need tags)
- Search UI is source-specific (totally different between sources)
- Scraping is source-specific (different selectors per source)

---

**Next Step**: Update both source configs (nhentai & crotpedia) dengan searchConfig.
