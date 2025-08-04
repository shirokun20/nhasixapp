# TagResolver untuk NhentaiScraper

TagResolver adalah helper class yang memungkinkan Anda untuk mengkonversi tag IDs (angka) yang ada di HTML nhentai menjadi Tag objects yang lengkap dengan nama, tipe, dan jumlah penggunaan.

## Fitur Utama

1. **Local Assets**: Menggunakan file lokal `assets/json/tags.json` untuk performa optimal
2. **Memory Caching**: Cache di memory untuk akses cepat
3. **Search & Filter**: Cari tags berdasarkan nama atau filter berdasarkan tipe
4. **Integration**: Terintegrasi dengan NhentaiScraper untuk parsing yang lebih lengkap

## Cara Penggunaan

### 1. Basic Setup

```dart
import 'lib/data/datasources/remote/tag_resolver.dart';
import 'lib/data/datasources/remote/nhentai_scraper.dart';

// Buat instance TagResolver
final tagResolver = TagResolver();

// Buat scraper dengan TagResolver
final scraper = NhentaiScraper(tagResolver: tagResolver);
```

### 2. Automatic Tag Resolution (Recommended)

Sekarang semua method parsing utama sudah otomatis melakukan tag resolution:

```dart
// Parse homepage dengan tags otomatis resolved
final homepage = await scraper.parseHomepage(htmlContent);

// Parse content list dengan tags otomatis resolved  
final contentList = await scraper.parseContentList(htmlContent);

// Parse search results dengan tags otomatis resolved
final searchResults = await scraper.parseSearchResults(htmlContent);

// Semua ContentModel yang dihasilkan sudah memiliki:
// - tags: List<Tag> yang sudah resolved
// - artists: List<String> dari tags bertipe 'artist'
// - characters: List<String> dari tags bertipe 'character'
// - parodies: List<String> dari tags bertipe 'parody'
// - groups: List<String> dari tags bertipe 'group'
// - language: String dari tags bertipe 'language'
```

### 3. Performance Options

Jika Anda tidak memerlukan tag resolution untuk performa yang lebih cepat:

```dart
// Gunakan versi sync tanpa tag resolution
final homepage = scraper.parseHomepageSync(htmlContent);
final contentList = scraper.parseContentListSync(htmlContent);
final searchResults = scraper.parseSearchResultsSync(htmlContent);

// ContentModel akan memiliki tags kosong tapi parsing lebih cepat
```

### 4. Manual Tag Resolution (Optional)

Jika Anda ingin melakukan tag resolution manual:

```dart
// Tag IDs dari HTML (data-tags attribute)
final tagIds = ['1818', '2937', '6817', '8010'];

// Resolve ke Tag objects
final tags = await tagResolver.resolveTagIds(tagIds);

for (final tag in tags) {
  print('${tag.name} (${tag.type}) - ${tag.count} uses');
}
```

### 5. Search Tags

```dart
// Cari tags yang mengandung kata "big"
final searchResults = await tagResolver.searchTags('big', limit: 10);

// Cari tags yang mengandung kata "school"
final schoolTags = await tagResolver.searchTags('school');
```

### 6. Filter by Type

```dart
// Get artist tags
final artists = await tagResolver.getTagsByType('artist', limit: 20);

// Get character tags
final characters = await tagResolver.getTagsByType('character', limit: 20);

// Get parody tags
final parodies = await tagResolver.getTagsByType('parody', limit: 20);
```

### 7. Cache Management

```dart
// Get cache statistics
final stats = await tagResolver.getCacheStats();
print('Total tags: ${stats['total_tags']}');
print('In-memory cache: ${stats['in_memory_cache']}');
print('Data source: ${stats['source']}');

// Clear memory cache
tagResolver.clearCache();
```

## Data Source

Tag mapping menggunakan file lokal `assets/json/tags.json` dengan format array:
```json
[
  [33172,"doujinshi",0,7],
  [33173,"manga",0,7],
  [2937,"big breasts",132000,3],
  [35762,"sole female",99000,3]
]
```

Format: `[id, name, count, type_code]`

Type codes:
- 0: category
- 1: artist  
- 2: parody
- 3: tag
- 4: character
- 5: group
- 6: language
- 7: category

## Tag Types

- `tag`: General tags
- `artist`: Artist names
- `character`: Character names
- `parody`: Parody/series names
- `group`: Circle/group names
- `language`: Language tags
- `category`: Content categories

## Caching Strategy

1. **Local Asset**: Data dimuat dari `assets/json/tags.json` (bundled dengan app)
2. **Memory Cache**: Data disimpan di memory untuk akses cepat
3. **No Network**: Tidak perlu koneksi internet, semua data sudah tersedia lokal

## Keuntungan Local Assets

- **Offline**: Bekerja tanpa koneksi internet
- **Fast**: Loading sangat cepat karena tidak perlu download
- **Reliable**: Tidak bergantung pada server eksternal
- **Consistent**: Data selalu tersedia dan konsisten

## Error Handling

TagResolver menangani error dengan graceful fallback:

```dart
try {
  final tags = await tagResolver.resolveTagIds(tagIds);
  // Use resolved tags
} catch (e) {
  // TagResolver akan return empty list jika ada error
  // Aplikasi tetap bisa berjalan
}
```

## Performance Tips

1. **Reuse Instance**: Gunakan satu instance TagResolver untuk seluruh aplikasi
2. **Batch Operations**: Resolve multiple tag IDs sekaligus daripada satu-satu
3. **Cache Warmup**: Panggil `getTagMapping()` di awal aplikasi untuk warmup cache
4. **Monitor Cache**: Cek cache stats secara berkala untuk optimasi

## Example: Complete Usage

```dart
void main() async {
  // Setup
  final tagResolver = TagResolver();
  final scraper = NhentaiScraper(tagResolver: tagResolver);
  
  // Load HTML
  final htmlContent = await File('halaman_utama.html').readAsString();
  
  // Parse dengan tags resolved
  final homepage = await scraper.parseHomepageWithTagsAsync(htmlContent);
  
  // Display results
  for (final content in homepage['popular'] ?? []) {
    print('Title: ${content.title}');
    print('Artists: ${content.artists.join(', ')}');
    print('Tags: ${content.tags.map((t) => t.name).take(5).join(', ')}');
    print('---');
  }
  
  // Cache info
  final stats = await tagResolver.getCacheStats();
  print('Cache contains ${stats['total_tags']} tags');
}
```

## Dependencies Required

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  path_provider: ^2.1.1
  logger: ^2.0.2+1
  html: ^0.15.4
  equatable: ^2.0.5
```