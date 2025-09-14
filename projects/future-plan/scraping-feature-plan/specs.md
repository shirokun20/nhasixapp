# Scraping Feature Technical Specifications

## Architecture Overview

### Clean Architecture Implementation
```
lib/
├── domain/
│   ├── entities/
│   │   ├── scraped_content.dart
│   │   ├── search_query.dart
│   │   └── download_task.dart
│   ├── repositories/
│   │   └── scraping_repository.dart
│   └── usecases/
│       ├── search_content.dart
│       ├── download_content.dart
│       └── get_content_detail.dart
├── data/
│   ├── models/
│   │   ├── scraped_content_model.dart
│   │   ├── search_query_model.dart
│   │   └── download_task_model.dart
│   ├── repositories/
│   │   └── scraping_repository_impl.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── ehentai_scraper.dart
│   │   │   ├── hitomi_scraper.dart
│   │   │   └── pixhentai_scraper.dart
│   │   └── local/
│   │       └── content_cache_datasource.dart
│   └── services/
│       └── http_client_service.dart
├── presentation/
│   ├── blocs/
│   │   ├── search/
│   │   │   ├── search_bloc.dart
│   │   │   ├── search_event.dart
│   │   │   └── search_state.dart
│   │   ├── content_detail/
│   │   └── download/
│   ├── pages/
│   │   ├── search_page.dart
│   │   ├── gallery_page.dart
│   │   ├── content_detail_page.dart
│   │   └── downloads_page.dart
│   └── widgets/
│       ├── content_card.dart
│       ├── image_viewer.dart
│       └── download_progress.dart
└── core/
    ├── constants/
    │   └── scraping_constants.dart
    ├── utils/
    │   ├── html_parser.dart
    │   ├── rate_limiter.dart
    │   └── file_manager.dart
    ├── errors/
    │   ├── scraping_exceptions.dart
    └── di/
        └── scraping_module.dart
```

## Data Models Specifications

### ScrapedContent Entity
```dart
class ScrapedContent {
  final String id;
  final String title;
  final String source; // 'ehentai', 'hitomi', 'pixhentai'
  final List<String> tags;
  final List<String> imageUrls;
  final String thumbnailUrl;
  final int pageCount;
  final DateTime? uploadDate;
  final String? uploader;
  final String? description;
  final ContentRating rating;

  const ScrapedContent({
    required this.id,
    required this.title,
    required this.source,
    required this.tags,
    required this.imageUrls,
    required this.thumbnailUrl,
    required this.pageCount,
    this.uploadDate,
    this.uploader,
    this.description,
    this.rating = ContentRating.unknown,
  });

  factory ScrapedContent.fromModel(ScrapedContentModel model) {
    return ScrapedContent(
      id: model.id,
      title: model.title,
      source: model.source,
      tags: model.tags,
      imageUrls: model.imageUrls,
      thumbnailUrl: model.thumbnailUrl,
      pageCount: model.pageCount,
      uploadDate: model.uploadDate,
      uploader: model.uploader,
      description: model.description,
      rating: model.rating,
    );
  }
}

enum ContentRating {
  unknown,
  safe,
  questionable,
  explicit,
}
```

### SearchQuery Entity
```dart
class SearchQuery {
  final String keyword;
  final List<String> tags;
  final List<String> sources; // Multiple sources support
  final int page;
  final int limit;
  final SortOrder sortOrder;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const SearchQuery({
    required this.keyword,
    this.tags = const [],
    this.sources = const ['ehentai', 'hitomi', 'pixhentai'],
    this.page = 1,
    this.limit = 25,
    this.sortOrder = SortOrder.relevance,
    this.dateFrom,
    this.dateTo,
  });
}

enum SortOrder {
  relevance,
  dateDesc,
  dateAsc,
  popularity,
}
```

### DownloadTask Entity
```dart
class DownloadTask {
  final String id;
  final String contentId;
  final List<String> imageUrls;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String savePath;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const DownloadTask({
    required this.id,
    required this.contentId,
    required this.imageUrls,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    required this.savePath,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });
}

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}
```

## Scraper Specifications

### Base Scraper Interface
```dart
abstract class ContentScraper {
  final String source;
  final HttpClientService httpClient;
  final HtmlParser htmlParser;
  final RateLimiter rateLimiter;

  const ContentScraper({
    required this.source,
    required this.httpClient,
    required this.htmlParser,
    required this.rateLimiter,
  });

  Future<List<ScrapedContent>> search(SearchQuery query);
  Future<ScrapedContent?> getContentDetail(String contentId);
  Future<List<String>> getImageUrls(String contentId);
}
```

### E-Hentai Scraper Implementation
```dart
class EHentaiScraper extends ContentScraper {
  static const String baseUrl = 'https://e-hentai.org';
  static const Map<String, String> selectors = {
    'galleryItems': '.gl1t',
    'title': '.glname',
    'thumbnail': 'img',
    'tags': '.gt a',
    'pagination': '.ptt td a',
  };

  @override
  Future<List<ScrapedContent>> search(SearchQuery query) async {
    final url = _buildSearchUrl(query);
    final response = await httpClient.get(url);
    final document = htmlParser.parse(response.data);

    final galleries = document.querySelectorAll(selectors['galleryItems']!);
    final contents = <ScrapedContent>[];

    for (final gallery in galleries) {
      final content = await _parseGalleryItem(gallery);
      if (content != null) {
        contents.add(content);
      }
    }

    return contents;
  }

  String _buildSearchUrl(SearchQuery query) {
    final params = <String, String>{
      'f_search': query.keyword,
      'page': query.page.toString(),
    };
    return '$baseUrl/?${Uri(queryParameters: params).query}';
  }

  Future<ScrapedContent?> _parseGalleryItem(Element element) async {
    try {
      final titleElement = element.querySelector(selectors['title']!);
      final thumbnailElement = element.querySelector(selectors['thumbnail']!);
      final tagElements = element.querySelectorAll(selectors['tags']!);

      final title = titleElement?.text?.trim();
      final thumbnailUrl = thumbnailElement?.attributes['src'];
      final tags = tagElements.map((e) => e.text.trim()).toList();

      if (title == null || thumbnailUrl == null) return null;

      // Extract gallery ID from link
      final linkElement = element.querySelector('a');
      final href = linkElement?.attributes['href'];
      final galleryId = _extractGalleryId(href);

      return ScrapedContent(
        id: galleryId,
        title: title,
        source: 'ehentai',
        tags: tags,
        imageUrls: [], // To be filled by getImageUrls
        thumbnailUrl: thumbnailUrl,
        pageCount: 0, // To be determined
      );
    } catch (e) {
      return null;
    }
  }

  String _extractGalleryId(String? href) {
    // Extract ID from URL like /g/123456/abcdef/
    final regex = RegExp(r'/g/(\d+)/');
    final match = regex.firstMatch(href ?? '');
    return match?.group(1) ?? '';
  }
}
```

### Hitomi.la Scraper Implementation
```dart
class HitomiScraper extends ContentScraper {
  static const String baseUrl = 'https://hitomi.la';
  static const Map<String, String> selectors = {
    'galleryItems': '.gallery-content',
    'title': 'h3 a',
    'thumbnail': '.cover img',
    'tags': '.tag',
    'pagination': '.page-list a',
  };

  @override
  Future<List<ScrapedContent>> search(SearchQuery query) async {
    final url = query.keyword.isEmpty
        ? '$baseUrl/index-indonesian.html?page=${query.page}'
        : '$baseUrl/tag/${query.keyword}-1.html?page=${query.page}';

    final response = await httpClient.get(url);
    final document = htmlParser.parse(response.data);

    final galleries = document.querySelectorAll(selectors['galleryItems']!);
    final contents = <ScrapedContent>[];

    for (final gallery in galleries) {
      final content = _parseGalleryItem(gallery);
      if (content != null) {
        contents.add(content);
      }
    }

    return contents;
  }

  ScrapedContent? _parseGalleryItem(Element element) {
    try {
      final titleElement = element.querySelector(selectors['title']!);
      final thumbnailElement = element.querySelector(selectors['thumbnail']!);
      final tagElements = element.querySelectorAll(selectors['tags']!);

      final title = titleElement?.text?.trim();
      final thumbnailUrl = thumbnailElement?.attributes['src'];
      final tags = tagElements.map((e) => e.text.trim()).toList();

      if (title == null || thumbnailUrl == null) return null;

      final linkElement = element.querySelector('a');
      final href = linkElement?.attributes['href'];
      final contentId = _extractContentId(href);

      return ScrapedContent(
        id: contentId,
        title: title,
        source: 'hitomi',
        tags: tags,
        imageUrls: [],
        thumbnailUrl: thumbnailUrl,
        pageCount: 0,
      );
    } catch (e) {
      return null;
    }
  }

  String _extractContentId(String? href) {
    // Extract from URL like /manga/title-123456.html
    final regex = RegExp(r'/manga/.*-(\d+)\.html');
    final match = regex.firstMatch(href ?? '');
    return match?.group(1) ?? '';
  }
}
```

### PixHentai Scraper Implementation
```dart
class PixHentaiScraper extends ContentScraper {
  static const String baseUrl = 'https://pixhentai.com';
  static const Map<String, String> selectors = {
    'posts': 'article',
    'title': 'h2 a',
    'thumbnail': 'article img',
    'content': '.entry-content',
    'pagination': '.pagination a',
  };

  @override
  Future<List<ScrapedContent>> search(SearchQuery query) async {
    final url = query.keyword.isEmpty
        ? '$baseUrl/page/${query.page}/'
        : '$baseUrl/page/${query.page}/?s=${Uri.encodeComponent(query.keyword)}';

    final response = await httpClient.get(url);
    final document = htmlParser.parse(response.data);

    final posts = document.querySelectorAll(selectors['posts']!);
    final contents = <ScrapedContent>[];

    for (final post in posts) {
      final content = await _parsePost(post);
      if (content != null) {
        contents.add(content);
      }
    }

    return contents;
  }

  Future<ScrapedContent?> _parsePost(Element element) async {
    try {
      final titleElement = element.querySelector(selectors['title']!);
      final thumbnailElement = element.querySelector(selectors['thumbnail']!);
      final contentElement = element.querySelector(selectors['content']!);

      final title = titleElement?.text?.trim();
      final thumbnailUrl = thumbnailElement?.attributes['src'];

      if (title == null || thumbnailUrl == null) return null;

      final linkElement = element.querySelector('h2 a');
      final href = linkElement?.attributes['href'];
      final contentId = _extractContentId(href);

      // Extract images from content
      final imageUrls = contentElement != null
          ? _extractImageUrls(contentElement)
          : <String>[];

      return ScrapedContent(
        id: contentId,
        title: title,
        source: 'pixhentai',
        tags: [], // WordPress tags extraction
        imageUrls: imageUrls,
        thumbnailUrl: thumbnailUrl,
        pageCount: imageUrls.length,
      );
    } catch (e) {
      return null;
    }
  }

  List<String> _extractImageUrls(Element contentElement) {
    final images = contentElement.querySelectorAll('img');
    return images
        .map((img) => img.attributes['src'])
        .where((src) => src != null && src!.isNotEmpty)
        .cast<String>()
        .toList();
  }

  String _extractContentId(String? href) {
    // Extract from URL like /post-title/
    final uri = Uri.parse(href ?? '');
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  }
}
```

## HTTP Client Service
```dart
class HttpClientService {
  final Dio _dio;
  final RateLimiter _rateLimiter;

  HttpClientService({
    required Dio dio,
    required RateLimiter rateLimiter,
  }) : _dio = dio, _rateLimiter = rateLimiter;

  Future<Response> get(String url, {Map<String, dynamic>? headers}) async {
    await _rateLimiter.waitForSlot();

    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'User-Agent': ScrapingConstants.userAgent,
          ...?headers,
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    return response;
  }
}
```

## Rate Limiter Implementation
```dart
class RateLimiter {
  final int requestsPerMinute;
  final Queue<DateTime> _requestTimes = Queue();

  RateLimiter({this.requestsPerMinute = 60});

  Future<void> waitForSlot() async {
    final now = DateTime.now();

    // Remove old requests outside the time window
    while (_requestTimes.isNotEmpty &&
           now.difference(_requestTimes.first).inMinutes >= 1) {
      _requestTimes.removeFirst();
    }

    if (_requestTimes.length >= requestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = const Duration(minutes: 1) - now.difference(oldestRequest);
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
    }

    _requestTimes.add(now);
  }
}
```

## HTML Parser Utility
```dart
class HtmlParser {
  Document parse(String html) {
    return parseDocument(html);
  }

  String? extractText(Element element, String selector) {
    final selected = element.querySelector(selector);
    return selected?.text?.trim();
  }

  String? extractAttribute(Element element, String selector, String attribute) {
    final selected = element.querySelector(selector);
    return selected?.attributes[attribute];
  }

  List<String> extractTexts(Element element, String selector) {
    final elements = element.querySelectorAll(selector);
    return elements.map((e) => e.text.trim()).toList();
  }

  List<String> extractAttributes(Element element, String selector, String attribute) {
    final elements = element.querySelectorAll(selector);
    return elements
        .map((e) => e.attributes[attribute])
        .where((attr) => attr != null)
        .cast<String>()
        .toList();
  }
}
```

## File Manager Service
```dart
class FileManager {
  static const String cacheDir = 'scraping_cache';
  static const int maxCacheSizeMB = 500;

  Future<String> getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cachePath = '${appDir.path}/$cacheDir';
    await Directory(cachePath).create(recursive: true);
    return cachePath;
  }

  Future<String> getContentDirectory(String source, String contentId) async {
    final cacheDir = await getCacheDirectory();
    final contentDir = '$cacheDir/$source/$contentId';
    await Directory(contentDir).create(recursive: true);
    return contentDir;
  }

  Future<void> ensureCacheSize() async {
    final cacheDir = await getCacheDirectory();
    final dir = Directory(cacheDir);

    if (!await dir.exists()) return;

    final files = await dir.list(recursive: true)
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    int totalSize = 0;
    final fileInfos = <File, int>{};

    for (final file in files) {
      final size = await file.length();
      totalSize += size;
      fileInfos[file] = size;
    }

    const maxSizeBytes = maxCacheSizeMB * 1024 * 1024;

    if (totalSize > maxSizeBytes) {
      // Sort by modification time (oldest first)
      final sortedFiles = fileInfos.keys.toList()
        ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      int sizeToRemove = totalSize - maxSizeBytes;

      for (final file in sortedFiles) {
        if (sizeToRemove <= 0) break;

        final size = fileInfos[file]!;
        await file.delete();
        sizeToRemove -= size;
      }
    }
  }
}
```

## State Management (Bloc)

### Search Bloc
```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchContentUseCase _searchUseCase;
  final GetSearchHistoryUseCase _historyUseCase;

  SearchBloc({
    required SearchContentUseCase searchUseCase,
    required GetSearchHistoryUseCase historyUseCase,
  }) : _searchUseCase = searchUseCase,
       _historyUseCase = historyUseCase,
       super(SearchInitial()) {
    on<SearchContentEvent>(_onSearchContent);
    on<LoadSearchHistoryEvent>(_onLoadSearchHistory);
    on<ClearSearchHistoryEvent>(_onClearSearchHistory);
  }

  Future<void> _onSearchContent(
    SearchContentEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());

    try {
      final contents = await _searchUseCase.execute(event.query);
      emit(SearchLoaded(contents: contents, hasMore: contents.length >= event.query.limit));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final history = await _historyUseCase.execute();
      emit(SearchHistoryLoaded(history: history));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistoryEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _historyUseCase.clear();
      emit(SearchHistoryLoaded(history: []));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }
}
```

## Source-Specific Feature Specifications

### e-hentai.org Advanced Features
- **Filter Data Integration**: Reuse existing `FilterDataScreen` with tab-based filtering
- **Tag Namespace Support**: Handle namespaced tags (f:, m:, character:, etc.)
- **Complex Query Building**: Support for include/exclude filters, multiple tag combinations
- **Filter Persistence**: Save and restore filter states across sessions

### Other Sources Simplified Features
- **hitomi.la**: Basic keyword search + tag selection from available tags
- **pixhentai.com**: Category-based filtering + basic tag support
- **No Advanced UI**: Use simple dropdown/filter chips instead of complex tabbed interface

### Feature Toggle Logic
```dart
class ScrapingFeatureManager {
  bool isAdvancedFilteringAvailable(String source) {
    return source == 'ehentai';
  }

  List<String> getAvailableFilterTypes(String source) {
    switch (source) {
      case 'ehentai':
        return ['tag', 'artist', 'character', 'parody', 'group'];
      case 'hitomi':
        return ['tag'];
      case 'pixhentai':
        return ['category', 'tag'];
      default:
        return [];
    }
  }
}
```
```
┌─────────────────────────────────┐
│ ┌─────┐ ┌─────────────────────┐ │
│ │Icon │ │ Search Input        │ │
│ └─────┘ └─────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Source Selection Chips      │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Gallery Grid View           │ │
│ │ ┌─────┐ ┌─────┐ ┌─────┐     │ │
│ │ │Img1 │ │Img2 │ │Img3 │     │ │
│ │ └─────┘ └─────┘ └─────┘     │ │
│ │                             │ │
│ │ Loading Indicator           │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Content Detail Page Layout
```
┌─────────────────────────────────┐
│ ┌─────────┐ ┌─────────────────┐ │
│ │Back Btn │ │ Title           │ │
│ └─────────┘ └─────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Image Viewer                │ │
│ │ ┌─────────────────────────┐ │ │
│ │ │         Image          │ │ │
│ │ └─────────────────────────┘ │ │
│ │                             │ │
│ │ ◄ ●●●●●●●●●●●●●●●●●●●●► │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Metadata                    │ │
│ │ Tags: tag1, tag2, tag3      │ │
│ │ Source: e-hentai            │ │
│ │ Pages: 25                   │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Download Button             │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## Database Schema

### SQLite Tables
```sql
-- Content metadata table
CREATE TABLE scraped_content (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  source TEXT NOT NULL,
  tags TEXT, -- JSON array
  thumbnail_url TEXT,
  page_count INTEGER,
  upload_date TEXT,
  uploader TEXT,
  description TEXT,
  rating TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Download tasks table
CREATE TABLE download_tasks (
  id TEXT PRIMARY KEY,
  content_id TEXT NOT NULL,
  image_urls TEXT, -- JSON array
  status TEXT NOT NULL,
  progress REAL DEFAULT 0.0,
  save_path TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  error_message TEXT,
  FOREIGN KEY (content_id) REFERENCES scraped_content(id)
);

-- Search history table
CREATE TABLE search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyword TEXT,
  tags TEXT, -- JSON array
  sources TEXT, -- JSON array
  timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);

-- App settings table
CREATE TABLE scraping_settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
```

## Error Handling

### Custom Exceptions
```dart
class ScrapingException implements Exception {
  final String message;
  final String? source;
  final int? statusCode;

  const ScrapingException({
    required this.message,
    this.source,
    this.statusCode,
  });

  @override
  String toString() => 'ScrapingException: $message';
}

class NetworkException extends ScrapingException {
  const NetworkException({
    required String message,
    String? source,
    int? statusCode,
  }) : super(message: message, source: source, statusCode: statusCode);
}

class ParsingException extends ScrapingException {
  const ParsingException({
    required String message,
    String? source,
  }) : super(message: message, source: source);
}

class RateLimitException extends ScrapingException {
  final Duration retryAfter;

  const RateLimitException({
    required String message,
    required this.retryAfter,
    String? source,
  }) : super(message: message, source: source);
}
```

## Testing Specifications

### Unit Test Structure
```
test/
├── domain/
│   ├── entities/
│   └── usecases/
├── data/
│   ├── repositories/
│   ├── datasources/
│   └── services/
├── presentation/
│   └── blocs/
└── core/
    ├── utils/
    └── errors/
```

### Integration Test Example
```dart
void main() {
  group('ScrapingRepository Integration Tests', () {
    late ScrapingRepository repository;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      repository = ScrapingRepositoryImpl(
        ehentaiScraper: EHentaiScraper(
          httpClient: mockHttpClient,
          htmlParser: HtmlParser(),
          rateLimiter: RateLimiter(),
        ),
        hitomiScraper: HitomiScraper(
          httpClient: mockHttpClient,
          htmlParser: HtmlParser(),
          rateLimiter: RateLimiter(),
        ),
        pixhentaiScraper: PixHentaiScraper(
          httpClient: mockHttpClient,
          htmlParser: HtmlParser(),
          rateLimiter: RateLimiter(),
        ),
      );
    });

    test('should return search results from e-hentai', () async {
      // Arrange
      final query = SearchQuery(keyword: 'test', sources: ['ehentai']);

      when(() => mockHttpClient.get(any()))
          .thenAnswer((_) async => Response(
                data: mockEHentaiResponse,
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      // Act
      final result = await repository.search(query);

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.source, equals('ehentai'));
    });
  });
}
```

## Performance Benchmarks

### Target Metrics
- **Cold Start Time**: < 2 seconds
- **Search Response Time**: < 3 seconds for first page
- **Image Load Time**: < 500ms for cached images
- **Memory Usage**: < 150MB during normal operation
- **Storage Growth**: < 50MB/hour during active downloading

### Monitoring Points
- Network request latency
- HTML parsing performance
- Database query times
- UI rendering performance
- Memory leak detection