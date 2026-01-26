# kuron_komiktap

KomikTap source implementation for Kuron app.

## Features

- ✅ Browse latest manga/manhwa updates
- ✅ Simple query-based search
- ✅ Genre/tag browsing
- ✅ Series detail with chapter list
- ✅ Chapter reader with image extraction
- ✅ Pagination support (dual pattern)
- ❌ No authentication required

## Architecture

Follows the same pattern as `kuron_crotpedia` but simplified:
- No auth manager (public content)
- Simple search (query-param based)
- WordPress-theme based scraping

## Usage

```dart
import 'package:kuron_komiktap/kuron_komiktap.dart';

// Create source instance
final komiktapSource = KomiktapSource();

// Get latest manga
final latest = await komiktapSource.getList(page: 1);

// Search
final searchFilter = SearchFilter(query: 'action');
final results = await komiktapSource.search(searchFilter);

// Get series detail
final detail = await komiktapSource.getDetail('manga-slug');

// Get chapter images
final images = await komiktapSource.getChapterImages('manga-slug-chapter-1');
```

## Configuration

CSS selectors are defined in `configs/komiktap-config.json` in the main app.

## Development

```bash
# Run tests
flutter test

# Generate mocks
flutter pub run build_runner build
```

## License

Proprietary - Part of Kuron app
