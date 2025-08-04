# Dependencies yang Diperlukan

Untuk menggunakan TagResolver dan NhentaiScraper yang sudah diupdate, Anda perlu menambahkan dependencies berikut ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client untuk download tag mapping
  http: ^1.1.0
  
  # HTML parsing
  html: ^0.15.4
  
  # Logging
  logger: ^2.0.2+1
  
  # Path provider untuk cache file
  path_provider: ^2.1.1
  
  # Equatable untuk entities
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## Cara Penggunaan

### 1. Basic Usage (tanpa tag resolution)
```dart
final scraper = NhentaiScraper();
final homepage = scraper.parseHomepage(htmlContent);
```

### 2. Advanced Usage (dengan tag resolution)
```dart
final tagResolver = TagResolver();
final scraper = NhentaiScraper(tagResolver: tagResolver);

// Parse dengan tags yang sudah di-resolve
final homepageWithTags = await scraper.parseHomepageWithTagsAsync(htmlContent);
```

### 3. Direct Tag Operations
```dart
final tagResolver = TagResolver();

// Search tags
final searchResults = await tagResolver.searchTags('big breasts');

// Get tags by type
final artistTags = await tagResolver.getTagsByType('artist');

// Resolve specific tag IDs
final tags = await tagResolver.resolveTagIds(['1818', '2937']);

// Get cache stats
final stats = await tagResolver.getCacheStats();

// Clear cache
await tagResolver.clearCache();

// Force refresh
await tagResolver.refreshCache();
```

## Fitur TagResolver

1. **Auto Download**: Otomatis download tag mapping dari GitHub
2. **File Cache**: Cache ke file lokal (7 hari)
3. **Memory Cache**: Cache di memory untuk performa
4. **Search**: Fuzzy search tags berdasarkan nama
5. **Filter by Type**: Filter tags berdasarkan tipe (artist, character, dll)
6. **Cache Management**: Clear dan refresh cache
7. **Statistics**: Info tentang cache dan mapping

## File Cache Location

Cache disimpan di:
- Android: `/data/data/[package]/app_flutter/cache/nhentai_tags_mapping.json`
- iOS: `Documents/cache/nhentai_tags_mapping.json`
- Desktop: `Documents/cache/nhentai_tags_mapping.json`