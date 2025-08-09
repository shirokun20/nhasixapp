# Design Document

## Overview

NhentaiApp adalah aplikasi Flutter yang mengimplementasikan Clean Architecture dengan BLoC pattern untuk state management. Aplikasi ini dirancang untuk memberikan pengalaman browsing yang optimal dengan fitur offline-first, caching yang efisien, dan UI yang responsif. Aplikasi menggunakan Dio HTTP client untuk web scraping dan mengambil data langsung dari HTML nhentai.net.

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│              Presentation               │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │   Widgets   │ │      BLoCs          ││
│  │   Pages     │ │   (State Mgmt)      ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│               Domain                    │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │  Entities   │ │    Use Cases        ││
│  │             │ │                     ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│                Data                     │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │ Repositories│ │   Data Sources      ││
│  │   Models    │ │ (Remote & Local)    ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
```

### State Management Pattern

Aplikasi menggunakan BLoC (Business Logic Component) pattern dengan flutter_bloc untuk:
- Separation of concerns antara UI dan business logic
- Reactive programming dengan streams
- Testable dan maintainable code
- Consistent state management across the app

## Components and Interfaces

### 1. Presentation Layer

#### Pages
- **SplashScreen**: Menangani initial loading
- **MainScreen**: Menampilkan konten terbaru dengan tema hitam default, navigasi sederhana, dan sorting options
- **SearchScreen**: Interface untuk pencarian dengan filter advanced yang tidak langsung trigger API
- **FilterDataScreen**: Halaman terpisah modern untuk mencari dan memilih Tags, Artists, Characters, Parodies, Groups
- **DetailScreen**: Menampilkan detail konten dan metadata lengkap
- **ReaderScreen**: Mode baca dengan navigasi halaman dan zoom
- **FavoritesScreen**: Daftar konten yang di-bookmark dengan kategori
- **DownloadsScreen**: Konten yang tersimpan offline dengan status
- **SettingsScreen**: Pengaturan aplikasi lengkap
- **TagScreen**: Daftar semua tag dengan popularity count
- **ArtistScreen**: Daftar artist dengan karya mereka
- **RandomScreen**: Random content discovery
- **HistoryScreen**: Riwayat konten yang pernah dibuka
- **StatusScreen**: Status download dan background tasks

#### Widgets
- **ContentCard**: Card component untuk menampilkan preview konten
- **SearchFilter**: Widget untuk filter pencarian (simplified)
- **FilterDataWidget**: Modern widget untuk filter data selection dengan search
- **SortingWidget**: Widget untuk sorting options di MainScreen
- **ImageViewer**: Component untuk menampilkan gambar dengan zoom
- **ProgressIndicator**: Custom loading indicators
- **ErrorWidget**: Standardized error display
- **NavigationDrawer**: Side navigation menu

#### BLoCs & Cubits
```dart
// Complex State Management (BLoCs)
ContentBloc: Mengelola state untuk daftar konten dengan pagination kompleks dan sorting
SearchBloc: Mengelola pencarian dan filter tanpa langsung mengirim API request, dengan events UpdateSearchFilter dan SearchSubmitted
DownloadBloc: Mengelola download queue dan concurrent operations
SplashBloc: Mengelola initial loading dan bypass logic

// Simple State Management (Cubits)
DetailCubit: Mengelola detail konten dan favorite toggle
ReaderCubit: Mengelola state reader mode dan navigation
FavoriteCubit: Mengelola bookmark/favorites CRUD operations
SettingsCubit: Mengelola pengaturan aplikasi
NetworkCubit: Mengelola status koneksi sederhana
FilterDataCubit: Mengelola state untuk halaman filter data terpisah
```

### 2. Domain Layer

#### Entities
```dart
class Content {
  final String id;
  final String title;
  final String coverUrl;
  final List<Tag> tags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final String language;
  final int pageCount;
  final List<String> imageUrls;
  final DateTime uploadDate;
  final int favorites; // Popularity count
  final String? englishTitle;
  final String? japaneseTitle;
}

class Tag {
  final String name;
  final String type; // tag, artist, character, parody, group, language, category
  final int count; // Popularity count
  final String url;
}

class FilterItem {
  final String value;
  final bool isExcluded; // true = exclude, false = include

  FilterItem({required this.value, this.isExcluded = false});
  
  // Factory constructors for clarity
  FilterItem.include(String value) : this(value: value, isExcluded: false);
  FilterItem.exclude(String value) : this(value: value, isExcluded: true);
  
  // Helper methods
  String get prefix => isExcluded ? '-' : '';
  String toQueryString(String filterType) => '$prefix$filterType:"$value"';
}

class SearchFilter {
  final String? query;
  final List<FilterItem> tags;
  final List<FilterItem> artists;
  final List<FilterItem> characters;
  final List<FilterItem> parodies;
  final List<FilterItem> groups;
  final String? language;   // Single select only
  final String? category;   // Single select only
  final int page;
  final SortOption sortBy;
  final bool popular; // Popular filter
  final IntRange? pageCountRange;
}

class UserPreferences {
  final String theme; // light, dark, amoled (default: dark)
  final String defaultLanguage;
  final String imageQuality; // low, medium, high, original
  final bool autoDownload;
  final bool showTitles; // Show titles on cards
  final bool blurThumbnails; // Blur NSFW thumbnails
  final bool usePagination; // Use next/previous buttons instead of infinite scroll
  final int columnsPortrait;
  final int columnsLandscape;
  final bool useVolumeKeys; // For reader navigation
  final ReadingDirection readingDirection;
  final bool keepScreenOn;
  final bool showSystemUI; // In reader mode
}

class DownloadStatus {
  final String contentId;
  final DownloadState state;
  final int downloadedPages;
  final int totalPages;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? error;
}

enum DownloadState {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

enum ReadingDirection {
  leftToRight,
  rightToLeft,
  vertical,
}

class History {
  final String contentId;
  final DateTime lastViewed;
  final int lastPage;
  final int totalPages;
}
```

#### Use Cases
```dart
// Content Use Cases (Unchanged)
GetContentListUseCase: Mengambil daftar konten dengan pagination
GetContentDetailUseCase: Mengambil detail konten lengkap
SearchContentUseCase: Mencari konten dengan filter advanced
GetRandomContentUseCase: Mengambil konten random

// Favorites Use Cases (Simplified)
AddToFavoritesUseCase: Menambah ke favorites (hanya id + cover_url)
RemoveFromFavoritesUseCase: Menghapus dari favorites
GetFavoritesUseCase: Mengambil favorites (return Map<String, dynamic>)

// Downloads Use Cases (Simplified)
DownloadContentUseCase: Queue download dan save status
GetDownloadStatusUseCase: Mengambil status download

// History Use Cases (Simplified)
AddToHistoryUseCase: Menambah ke history (dengan title + cover_url)

// Settings Use Cases (Simplified)
SaveUserPreferencesUseCase: Save user preferences
GetUserPreferencesUseCase: Get user preferences
SavePreferenceUseCase: Save single preference
GetPreferenceUseCase: Get single preference

// Search History Use Cases (New)
AddSearchHistoryUseCase: Add search query to history
GetSearchHistoryUseCase: Get search history
ClearSearchHistoryUseCase: Clear search history
DeleteSearchHistoryUseCase: Delete specific search entry
```

### 3. Data Layer

#### Repositories
```dart
abstract class ContentRepository {
  Future<ContentListResult> getContentList({int page = 1, SortOption sortBy = SortOption.newest});
  Future<Content> getContentDetail(String id);
  Future<ContentListResult> searchContent(SearchFilter filter);
}

abstract class FilterDataRepository {
  Future<List<Tag>> searchTags(String query, {int limit = 20});
  Future<List<Tag>> getTagsByType(String type, {int limit = 50});
  Future<List<Tag>> getAllTags();
  Future<void> cacheTagData();
}

abstract class UserDataRepository {
  // Favorites (Simplified)
  Future<void> addToFavorites({required String id, required String coverUrl});
  Future<void> removeFromFavorites(String id);
  Future<List<Map<String, dynamic>>> getFavorites({int page = 1, int limit = 20});
  Future<bool> isFavorite(String id);
  Future<int> getFavoritesCount();

  // Downloads (Simplified)
  Future<void> saveDownloadStatus(DownloadStatus status);
  Future<DownloadStatus?> getDownloadStatus(String id);
  Future<List<DownloadStatus>> getAllDownloads({DownloadState? state, int page = 1, int limit = 20});
  Future<void> deleteDownloadStatus(String id);
  Future<int> getDownloadsCount({DownloadState? state});

  // History (Simplified)
  Future<void> saveHistory(History history);
  Future<List<History>> getHistory({int page = 1, int limit = 50});
  Future<History?> getHistoryEntry(String id);
  Future<void> removeFromHistory(String id);
  Future<void> clearHistory();
  Future<int> getHistoryCount();

  // Preferences & Search History
  Future<void> saveUserPreferences(UserPreferences preferences);
  Future<UserPreferences> getUserPreferences();
  Future<void> addSearchHistory(String query);
  Future<List<String>> getSearchHistory({int limit = 20});
  Future<void> clearSearchHistory();
  
  // Search State Persistence
  Future<void> saveSearchFilter(SearchFilter filter);
  Future<SearchFilter?> getLastSearchFilter();
  Future<void> clearSearchFilter();
  
  // Sorting Preferences
  Future<void> saveSortingPreference(SortOption sortBy);
  Future<SortOption> getSortingPreference();
}
```

#### Data Sources

**Remote Data Source (Web Scraping)**
```dart
class RemoteDataSource {
  final Dio httpClient;
  final TagResolver tagResolver; // Already implemented
  
  // Web scraping methods
  Future<List<ContentModel>> scrapeContentList(int page);
  Future<ContentModel> scrapeContentDetail(String id);
  Future<List<ContentModel>> scrapeSearchResults(SearchFilter filter);
  
  // HTML parsing utilities
  Future<String> getPageHtml(String url);
  List<ContentModel> parseContentListHtml(String html);
  ContentModel parseContentDetailHtml(String html);
  List<String> extractImageUrls(String html);
  
  // Tag resolution (using existing TagResolver)
  Future<List<Tag>> resolveTagIds(List<String> tagIds);
  Future<List<Tag>> searchTags(String query);
  Future<List<Tag>> getTagsByType(String type);
}
```

**Local Data Source (Simplified)**
```dart
class LocalDataSource {
  final DatabaseHelper _databaseHelper;
  
  // Favorites (Simplified)
  Future<void> addToFavorites(String id, String coverUrl);
  Future<void> removeFromFavorites(String id);
  Future<List<Map<String, dynamic>>> getFavorites({int page = 1, int limit = 20});
  Future<bool> isFavorited(String id);
  Future<int> getFavoritesCount();

  // Downloads (Simplified)
  Future<void> saveDownloadStatus(DownloadStatusModel status);
  Future<DownloadStatusModel?> getDownloadStatus(String id);
  Future<List<DownloadStatusModel>> getAllDownloads({DownloadState? state, int page = 1, int limit = 20});
  Future<void> deleteDownloadStatus(String id);
  Future<int> getDownloadsCount({DownloadState? state});

  // History (Simplified)
  Future<void> saveHistory(HistoryModel history);
  Future<HistoryModel?> getHistory(String id);
  Future<List<HistoryModel>> getAllHistory({int page = 1, int limit = 50});
  Future<void> clearHistory();
  Future<void> deleteHistory(String id);
  Future<int> getHistoryCount();

  // Preferences & Search History
  Future<void> saveUserPreferences(UserPreferences preferences);
  Future<UserPreferences> getUserPreferences();
  Future<void> addSearchHistory(String query);
  Future<List<String>> getSearchHistory({int limit = 20});
  Future<void> clearSearchHistory();
  Future<void> deleteSearchHistory(String query);
}
```

## Data Models

### Database Schema

```sql
-- SIMPLIFIED DATABASE SCHEMA (removed complex caching and tag management)
-- REMOVED: Contents table (no longer needed for simplified app)
-- REMOVED: Tags table (no longer needed for simplified app)  
-- REMOVED: Content tags relationship (no longer needed for simplified app)
-- REMOVED: Favorite categories (no longer needed for simplified app)

-- Favorites table (simplified - only id and cover_url)
CREATE TABLE favorites (
  id TEXT PRIMARY KEY,
  cover_url TEXT,
  added_at INTEGER
);

-- Downloads table (with title and cover_url for display)
CREATE TABLE downloads (
  id TEXT PRIMARY KEY,
  title TEXT,
  cover_url TEXT,
  download_path TEXT,
  state TEXT NOT NULL, -- queued, downloading, paused, completed, failed, cancelled
  downloaded_pages INTEGER DEFAULT 0,
  total_pages INTEGER,
  start_time INTEGER,
  end_time INTEGER,
  file_size INTEGER,
  error_message TEXT
);

-- History table (with title and cover_url for display)
CREATE TABLE history (
  id TEXT PRIMARY KEY,
  title TEXT,
  cover_url TEXT,
  last_viewed INTEGER,
  last_page INTEGER DEFAULT 1,
  total_pages INTEGER,
  time_spent INTEGER DEFAULT 0, -- in milliseconds
  is_completed INTEGER DEFAULT 0 -- boolean as integer
);

-- User preferences
CREATE TABLE preferences (
  key TEXT PRIMARY KEY,
  value TEXT
);

-- Search history
CREATE TABLE search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  query TEXT NOT NULL,
  searched_at INTEGER
);

-- Search filter state persistence
CREATE TABLE search_filter_state (
  id INTEGER PRIMARY KEY DEFAULT 1,
  filter_data TEXT, -- JSON serialized SearchFilter
  saved_at INTEGER
);
```

### Web Scraping Models

```dart
class ScrapedContentList {
  final List<ContentModel> contents;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  
  // Factory constructor untuk parsing dari HTML
  factory ScrapedContentList.fromHtml(String html);
}

class ScrapedContentDetail {
  final ContentModel content;
  final List<String> relatedIds;
  final List<String> imageUrls;
  
  // Factory constructor untuk parsing dari HTML
  factory ScrapedContentDetail.fromHtml(String html);
}

// HTML Parsing utilities
class HtmlParser {
  static List<ContentModel> parseContentCards(String html);
  static ContentModel parseContentDetail(String html);
  static List<String> parseImageUrls(String html);
  static Map<String, String> parseMetadata(String html);
}
```

## Error Handling

### Error Types
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
}

class NetworkException extends AppException {
  // No internet connection
}

class ServerException extends AppException {
  // Server error (5xx)
}

class CloudflareException extends AppException {
  // Cloudflare protection active
}

class ParseException extends AppException {
  // Data parsing error
}

class CacheException extends AppException {
  // Local storage error
}
```

### Error Handling Strategy
1. **Network Errors**: Show retry button with offline fallback
2. **Cloudflare Errors**: Trigger bypass process automatically
3. **Parse Errors**: Log for debugging, show generic error to user
4. **Cache Errors**: Clear corrupted cache, reload from network
5. **Server Errors**: Show maintenance message with retry option

## Testing Strategy

### Unit Tests
- Use Cases testing with mock repositories
- BLoC testing with mock use cases
- Repository testing with mock data sources
- Utility functions testing
- TagResolver testing with mock data

### Integration Tests
- Database operations
- API integration with mock server
- BLoC integration with real repositories
- TagResolver integration with local assets

### Widget Tests
- Individual widget rendering
- User interaction testing
- Navigation testing

### End-to-End Tests
- Complete user flows
- Offline functionality
- Error scenarios

### Real Device Testing
- Performance testing on physical Android devices
- Memory and CPU usage monitoring
- Network connectivity testing with real internet conditions
- Gesture navigation testing on actual touchscreens
- Background task verification on physical devices
- Battery usage optimization testing
- Different screen sizes and orientations testing
- Real-world user interaction patterns testing

## Dependencies & Libraries

### Required Dependencies
```yaml
# Core Flutter & State Management
flutter_bloc: ^9.1.1
bloc: ^9.0.0
equatable: ^2.0.7
get_it: ^8.0.2

# Networking & Web Scraping
dio: ^5.7.0
html: ^0.15.4
connectivity_plus: ^5.0.2

# Navigation & Routing
go_router: ^15.1.1

# Local Storage & Caching
sqflite: ^2.4.1
shared_preferences: ^2.3.3
path_provider: ^2.1.5

# Image Handling
cached_network_image: ^3.3.1
photo_view: ^0.14.0
image: ^4.1.7

# UI Components
flutter_staggered_grid_view: ^0.7.0  # For masonry grid layout
pull_to_refresh: ^2.0.0              # Pull to refresh
flutter_slidable: ^3.0.1             # Swipe actions
badges: ^3.1.2                       # Badge indicators

# Background Tasks & Notifications
workmanager: ^0.5.2                  # Background downloads
flutter_local_notifications: ^17.2.2 # Local notifications
wakelock_plus: ^1.2.8                # Keep screen on

# File Management
file_picker: ^8.1.2                  # File picker for import/export
share_plus: ^10.0.2                  # Share functionality
open_file: ^3.5.7                    # Open downloaded files

# Utilities
logger: ^2.5.0
permission_handler: ^11.3.1
crypto: ^3.0.3
intl: ^0.19.0                        # Internationalization
package_info_plus: ^8.0.2            # App info
device_info_plus: ^10.1.2            # Device info

# Advanced Features
flutter_colorpicker: ^1.1.0          # Color picker for themes
flutter_speed_dial: ^7.0.0           # Floating action button menu
animations: ^2.0.11                  # Advanced animations
lottie: ^3.1.2                       # Lottie animations
shimmer: ^3.0.0                      # Shimmer loading effect
flutter_rating_bar: ^4.0.1           # Rating widget
url_launcher: ^6.3.1                 # Launch URLs
flutter_cache_manager: ^3.4.1        # Advanced cache management

# Comment & Community Features
flutter_mentions: ^2.0.0             # Mention support in comments
flutter_html: ^3.0.0                 # HTML rendering for comments
timeago: ^3.6.1                      # Time ago formatting

# Performance & Analytics
flutter_performance_monitor: ^1.0.0  # Performance monitoring
memory_info: ^1.0.0                  # Memory usage tracking
battery_plus: ^6.0.2                 # Battery optimization

# Advanced UI Components
flutter_expandable: ^5.0.1           # Expandable widgets
flutter_sticky_header: ^0.6.5        # Sticky headers
flutter_reorderable_list: ^1.3.1     # Reorderable lists
flutter_swipe_action_cell: ^3.1.3    # Swipe actions
context_menus: ^1.0.2                # Context menus
```

## Web Scraping Strategy

### HTML Parsing Approach
- Menggunakan package `html` untuk parsing HTML
- CSS selector untuk mengekstrak elemen spesifik
- Robust parsing yang tahan terhadap perubahan minor pada struktur HTML
- Fallback parsing jika struktur berubah

### Scraping Patterns
```dart
class NhentaiScraper {
  // Main page scraping
  static const String CONTENT_LIST_SELECTOR = '.gallery';
  static const String TITLE_SELECTOR = '.caption';
  static const String COVER_SELECTOR = '.cover img';
  
  // Detail page scraping  
  static const String DETAIL_TITLE_SELECTOR = '#info h1';
  static const String TAGS_SELECTOR = '.tag-container .tag';
  static const String PAGES_SELECTOR = '.thumb-container img';
  
  // Image URL patterns
  static String getImageUrl(String galleryId, int page) {
    return 'https://i.nhentai.net/galleries/$galleryId/$page.jpg';
  }
}
```

### Anti-Detection Measures
- Random delays between requests (1-3 seconds)
- User-Agent rotation
- Cookie persistence across requests
- Respect robots.txt guidelines
- Implement circuit breaker for failed requests

### Error Handling for Scraping
- Handle HTML structure changes gracefully
- Detect and handle rate limiting
- Fallback to cached data when scraping fails
- Log parsing errors for debugging

## Performance Considerations

### Image Loading
- Progressive loading with thumbnails
- Image caching with size limits
- Lazy loading for lists
- WebP format support for smaller file sizes

### Memory Management
- Dispose unused BLoCs and controllers
- Image memory cache with LRU eviction
- Pagination for large lists
- Background processing for downloads

### Storage Optimization
- Compress downloaded images
- Database cleanup for old cache
- User-configurable storage limits
- Efficient database queries with indexes

### Network Optimization
- Request debouncing for search
- HTML caching to reduce scraping load
- Connection pooling with cookie persistence
- Retry logic with exponential backoff
- User-Agent rotation to avoid detection
- Request rate limiting to prevent blocking

## Routing & Navigation

### Go Router Configuration
```dart
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/filter-data',
      builder: (context, state) => FilterDataScreen(
        filterType: state.uri.queryParameters['type'] ?? 'tag',
        selectedFilters: state.extra as List<FilterItem>? ?? [],
      ),
    ),
    GoRoute(
      path: '/content/:id',
      builder: (context, state) => ContentDetailScreen(
        contentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/reader/:id',
      builder: (context, state) => ReaderScreen(
        contentId: state.pathParameters['id']!,
        page: int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1,
      ),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/downloads',
      builder: (context, state) => const DownloadsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

### Deep Linking Support
- Content sharing dengan URL format: `nhasixapp://content/{id}`
- Reader deep linking: `nhasixapp://reader/{id}?page={pageNumber}`
- Search deep linking: `nhasixapp://search?q={query}&tags={tags}`

## Image Loading & Caching Strategy

### Progressive Image Loading
```dart
class ProgressiveImageWidget extends StatelessWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => thumbnailUrl != null
          ? CachedNetworkImage(imageUrl: thumbnailUrl!)
          : const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: 800, // Optimize memory usage
      memCacheHeight: 1200,
    );
  }
}
```

### Image Cache Management
- Memory cache: 100MB limit dengan LRU eviction
- Disk cache: 500MB limit dengan automatic cleanup
- Thumbnail cache: 50MB untuk quick loading
- Image compression: JPEG quality 85% untuk balance size/quality

## Offline-First Architecture

### Data Synchronization Strategy
```dart
class SyncManager {
  // Sync strategies
  Future<void> syncFavorites();
  Future<void> syncDownloads();
  Future<void> syncUserPreferences();
  
  // Conflict resolution
  Future<void> resolveConflicts();
  
  // Background sync
  void scheduleBackgroundSync();
}
```

### Offline Capabilities
- Cached content browsing tanpa internet
- Downloaded content reading offline
- Favorites management offline
- Search dalam cached content
- Settings changes offline dengan sync later

## Reading Experience Features

### Reader Modes
```dart
enum ReadingMode {
  singlePage,    // One page at a time
  continuousScroll, // Vertical scroll
  dualPage,      // Two pages side by side (landscape)
}

class ReaderSettings {
  final ReadingMode mode;
  final bool autoAdvance;
  final Duration autoAdvanceDelay;
  final bool keepScreenOn;
  final double brightness;
  final bool invertColors;
}
```

### Zoom & Pan Implementation
- Menggunakan `photo_view` package
- Pinch to zoom dengan smooth animation
- Double tap to fit/fill screen
- Pan dengan momentum scrolling
- Zoom level persistence per content

### Reading Progress Tracking
```dart
class ReadingProgress {
  final String contentId;
  final int currentPage;
  final int totalPages;
  final DateTime lastRead;
  final Duration timeSpent;
  
  double get progressPercentage => currentPage / totalPages;
}
```

## Content Categories & Sorting

### Sorting Options (Sesuai NClientV3)
```dart
enum SortOption {
  newest,
  popular, // Popular all time
  popularWeek, // Popular this week
  popularToday, // Popular today
  random,
}

enum ContentCategory {
  doujinshi,
  manga,
  artistCg,
  gameCg,
  western,
  nonH,
  imageSet,
  cosplay,
  asianPorn,
  misc,
}
```

### Advanced Filtering (NClientV3 Style)
```dart
class AdvancedSearchFilter {
  final String? query;
  final List<String> includeTags;
  final List<String> excludeTags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final List<ContentCategory> categories;
  final List<String> languages;
  final IntRange? pageCountRange;
  final SortOption sortBy;
  final bool onlyFavorites;
  final bool onlyDownloaded;
}

class IntRange {
  final int? min;
  final int? max;
  
  IntRange({this.min, this.max});
}
```

## NClientV3 Specific Features

### Download Manager
```dart
class DownloadManager {
  static const int maxConcurrentDownloads = 3;
  static const int maxRetries = 3;
  
  Future<void> queueDownload(String contentId);
  Future<void> pauseDownload(String contentId);
  Future<void> resumeDownload(String contentId);
  Future<void> cancelDownload(String contentId);
  Future<void> pauseAll();
  Future<void> resumeAll();
  
  Stream<DownloadProgress> getDownloadProgress(String contentId);
  Stream<List<DownloadStatus>> getAllDownloadStatus();
}

class DownloadProgress {
  final String contentId;
  final int currentPage;
  final int totalPages;
  final int bytesDownloaded;
  final int totalBytes;
  final double speed; // bytes per second
  final Duration estimatedTimeRemaining;
}
```

### Favorite Categories Management
```dart
class FavoriteManager {
  Future<void> createCategory(String name);
  Future<void> deleteCategory(int categoryId);
  Future<void> renameCategory(int categoryId, String newName);
  Future<void> moveToCategory(String contentId, int categoryId);
  Future<List<FavoriteCategory>> getCategories();
  Future<List<Content>> getFavoritesByCategory(int categoryId);
}

class FavoriteCategory {
  final int id;
  final String name;
  final int count;
  final DateTime createdAt;
}
```

### Tag Management & Statistics
```dart
class TagManager {
  Future<List<Tag>> getAllTags();
  Future<List<Tag>> getTagsByType(String type);
  Future<List<Tag>> searchTags(String query);
  Future<List<Tag>> getPopularTags(int limit);
  Future<void> blacklistTag(String tagName);
  Future<void> removeFromBlacklist(String tagName);
  Future<List<String>> getBlacklistedTags();
}

class TagStatistics {
  final String tagName;
  final int totalContent;
  final int favoriteContent;
  final int downloadedContent;
  final DateTime lastUsed;
}
```

### Reading History & Statistics
```dart
class HistoryManager {
  Future<void> addToHistory(String contentId, int page);
  Future<List<History>> getHistory({int limit = 50});
  Future<void> clearHistory();
  Future<void> removeFromHistory(String contentId);
  Future<ReadingStatistics> getReadingStats();
}

class ReadingStatistics {
  final int totalContentRead;
  final int totalPagesRead;
  final Duration totalTimeSpent;
  final Map<String, int> favoriteArtists;
  final Map<String, int> favoriteTags;
  final Map<String, int> favoriteLanguages;
}
```

### Backup & Restore
```dart
class BackupManager {
  Future<String> exportData(); // Returns JSON string
  Future<void> importData(String jsonData);
  Future<File> exportToFile();
  Future<void> importFromFile(File file);
  
  // Selective backup
  Future<String> exportFavorites();
  Future<String> exportDownloads();
  Future<String> exportSettings();
  Future<String> exportHistory();
}
```

### Notification System
```dart
class NotificationManager {
  Future<void> showDownloadComplete(String contentTitle);
  Future<void> showDownloadFailed(String contentTitle, String error);
  Future<void> showDownloadProgress(String contentTitle, int progress);
  Future<void> scheduleDownloadNotification();
  Future<void> cancelAllNotifications();
}
```

## Filter Data Architecture

### FilterDataScreen Design
```dart
class FilterDataScreen extends StatefulWidget {
  final String filterType; // 'tag', 'artist', 'character', 'parody', 'group'
  final List<FilterItem> selectedFilters;
  
  const FilterDataScreen({
    required this.filterType,
    required this.selectedFilters,
  });
}

class FilterDataCubit extends Cubit<FilterDataState> {
  final TagResolver tagResolver;
  
  Future<void> searchFilterData(String query);
  Future<void> loadFilterDataByType(String type);
  void toggleFilterItem(FilterItem item);
  void clearAllFilters();
  List<FilterItem> getSelectedFilters();
}

class FilterDataState extends Equatable {
  final List<Tag> searchResults;
  final List<FilterItem> selectedFilters;
  final bool isLoading;
  final String? error;
  final String currentQuery;
}
```

### Modern Filter Data UI Components
```dart
class FilterDataSearchWidget extends StatelessWidget {
  // Modern search input dengan debouncing
  // Real-time search results dari assets/json/tags.json
  // Visual feedback untuk search state
}

class FilterItemCard extends StatelessWidget {
  // Modern card design untuk setiap filter item
  // Include/exclude toggle dengan visual yang jelas
  // Tag count dan popularity information
}

class SelectedFiltersWidget extends StatelessWidget {
  // Horizontal scrollable list dari selected filters
  // Easy removal dengan swipe atau tap
  // Visual distinction antara include dan exclude
}

class FilterTypeTabBar extends StatelessWidget {
  // Tab bar untuk switch antara Tags, Artists, Characters, dll
  // Modern design dengan smooth transitions
  // Badge indicators untuk selected count per type
}
```

### Matrix Filter Support Rules
Sesuai dengan `docs/perubahan-alur-search.md`, sistem harus mengikuti aturan berikut:

| Filter      | Multiple | Prefix Format   | Keterangan              |
|-------------|----------|------------------|--------------------------|
| Tag         | ✅       | `tag:"..."`     | Bisa include/exclude     |
| Artist      | ✅       | `artist:"..."`  | Bisa include/exclude     |
| Character   | ✅       | `character:"..."` | Bisa include/exclude     |
| Parody      | ✅       | `parody:"..."`    | Bisa include/exclude     |
| Group       | ✅       | `group:"..."`     | Bisa include/exclude     |
| Language    | ❎       | `language:"..."`  | Hanya satu boleh dipilih |
| Category    | ❎       | `category:"..."`  | Hanya satu boleh dipilih |

### Query Format Implementation
```dart
class SearchQueryBuilder {
  static String buildQuery(SearchFilter filter) {
    final queryParts = <String>[];
    
    // Add base query if exists
    if (filter.query != null && filter.query!.isNotEmpty) {
      queryParts.add(filter.query!);
    }
    
    // Add multiple filters with include/exclude support
    queryParts.addAll(_buildMultipleFilters('tag', filter.tags));
    queryParts.addAll(_buildMultipleFilters('artist', filter.artists));
    queryParts.addAll(_buildMultipleFilters('character', filter.characters));
    queryParts.addAll(_buildMultipleFilters('parody', filter.parodies));
    queryParts.addAll(_buildMultipleFilters('group', filter.groups));
    
    // Add single select filters
    if (filter.language != null) {
      queryParts.add('language:"${filter.language}"');
    }
    if (filter.category != null) {
      queryParts.add('category:"${filter.category}"');
    }
    
    return queryParts.join(' ');
  }
  
  static List<String> _buildMultipleFilters(String type, List<FilterItem> items) {
    return items.map((item) {
      final prefix = item.isExcluded ? '-' : '';
      return '$prefix$type:"${item.value}"';
    }).toList();
  }
}

// Example output: "+-tag:"a1"+-artist:"b1"+-tag:"a2"+language:"english"+-tag:"a3""
```

### Assets Integration
```dart
class TagDataManager {
  static const String TAGS_JSON_PATH = 'assets/json/tags.json';
  
  Future<List<Tag>> loadTagsFromAssets();
  Future<List<Tag>> searchTags(String query, String type);
  Future<List<Tag>> getPopularTags(String type, int limit);
  Future<void> cacheTagData();
  
  // Filter validation based on Matrix Filter Support
  bool isMultipleSelectionAllowed(String filterType) {
    return ['tag', 'artist', 'character', 'parody', 'group'].contains(filterType);
  }
  
  bool isSingleSelectionOnly(String filterType) {
    return ['language', 'category'].contains(filterType);
  }
}
```

## Advanced Reader Features

### Reader Enhancements
```dart
class ReaderSettings {
  final ReadingMode mode;
  final FitMode fitMode;
  final bool preloadPages;
  final int preloadCount;
  final PageTransition transition;
  final bool showPageNumber;
  final bool showBattery;
  final bool showClock;
  final double brightness;
  final bool invertColors;
  final bool useVolumeKeys;
  final bool tapToTurn;
  final TapZones tapZones;
}

enum FitMode {
  fitWidth,
  fitHeight,
  fitScreen,
  originalSize,
  smartFit,
}

enum PageTransition {
  slide,
  fade,
  curl,
  none,
}

class TapZones {
  final bool leftZone;    // Previous page
  final bool rightZone;   // Next page
  final bool centerZone;  // Toggle UI
}

class PageBookmark {
  final String contentId;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;
}
```

### Content Verification & Management
```dart
class ContentManager {
  Future<bool> verifyContentExists(String contentId);
  Future<List<String>> findDuplicateDownloads();
  Future<void> removeDuplicates();
  Future<void> batchDownload(List<String> contentIds);
  Future<void> batchAddToFavorites(List<String> contentIds);
  Future<List<Content>> getRecommendations(String contentId);
  Future<void> refreshContentMetadata(String contentId);
}

class DuplicateDetector {
  Future<List<DuplicateGroup>> findDuplicates();
  Future<void> mergeDuplicates(DuplicateGroup group);
}

class DuplicateGroup {
  final List<String> contentIds;
  final DuplicateReason reason;
  final double similarity;
}

enum DuplicateReason {
  sameTitle,
  sameArtist,
  similarContent,
  sameImages,
}
```

## Theme & Customization System

### Advanced Theming
```dart
class AppTheme {
  final String name;
  final ThemeMode mode;
  final ColorScheme colorScheme;
  final bool useAmoled;
  final double cardElevation;
  final BorderRadius cardRadius;
  final bool showShadows;
}

class CustomColorScheme {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onError;
}

class GridSettings {
  final int columnsPortrait;
  final int columnsLandscape;
  final double aspectRatio;
  final double spacing;
  final bool showTitles;
  final bool showTags;
  final bool showPageCount;
  final bool blurNsfw;
}
```

## Performance Optimization

### Image Management
```dart
class ImageCache {
  static const int memoryLimit = 100 * 1024 * 1024; // 100MB
  static const int diskLimit = 500 * 1024 * 1024;   // 500MB
  
  Future<void> preloadImages(List<String> urls);
  Future<void> clearMemoryCache();
  Future<void> clearDiskCache();
  Future<CacheInfo> getCacheInfo();
  Future<void> optimizeCache();
}

class PreloadManager {
  Future<void> preloadNextPages(String contentId, int currentPage);
  Future<void> preloadRelatedContent(String contentId);
  Future<void> preloadFavorites();
  void cancelPreloading();
}
```

### Background Sync
```dart
class SyncManager {
  Future<void> syncFavoritesInBackground();
  Future<void> syncDownloadStatusInBackground();
  Future<void> syncUserPreferencesInBackground();
  Future<void> schedulePeriodicSync();
  Future<void> cancelAllSync();
}
```

## Gesture & Navigation System

### Gesture Controls
```dart
class GestureSettings {
  final bool swipeToNavigate;
  final bool pinchToZoom;
  final bool doubleTapToZoom;
  final bool longPressActions;
  final SwipeDirection swipeDirection;
  final double swipeSensitivity;
}

enum SwipeDirection {
  horizontal,
  vertical,
  both,
}

class QuickActions {
  static const String addToFavorites = 'add_favorite';
  static const String download = 'download';
  static const String share = 'share';
  static const String viewDetails = 'view_details';
  static const String markAsRead = 'mark_read';
}
```

## Content Discovery & Recommendations

### Recommendation Engine
```dart
class RecommendationEngine {
  Future<List<Content>> getRecommendedContent(String userId);
  Future<List<Content>> getSimilarContent(String contentId);
  Future<List<Content>> getTrendingContent();
  Future<List<Content>> getContentByMood(String mood);
  Future<void> updateUserPreferences(UserInteraction interaction);
}

class UserInteraction {
  final String contentId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

enum InteractionType {
  view,
  favorite,
  download,
  share,
  rate,
  search,
}
```

## Comment System & Community Features

### Comment Management
```dart
class Comment {
  final String id;
  final String contentId;
  final String username;
  final String text;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final List<Comment> replies;
  final bool isEdited;
}

class CommentManager {
  Future<List<Comment>> getComments(String contentId);
  Future<Comment> addComment(String contentId, String text);
  Future<void> editComment(String commentId, String newText);
  Future<void> deleteComment(String commentId);
  Future<void> likeComment(String commentId);
  Future<void> dislikeComment(String commentId);
  Future<Comment> replyToComment(String commentId, String text);
}

class Rating {
  final String contentId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star -> count
}

class RatingManager {
  Future<void> rateContent(String contentId, int rating);
  Future<Rating> getContentRating(String contentId);
  Future<int?> getUserRating(String contentId);
  Future<List<Content>> getTopRatedContent();
}

class UserReview {
  final String id;
  final String contentId;
  final String username;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final int helpfulVotes;
}

class ReviewManager {
  Future<List<UserReview>> getReviews(String contentId);
  Future<UserReview> addReview(String contentId, int rating, String? text);
  Future<void> editReview(String reviewId, int rating, String? text);
  Future<void> deleteReview(String reviewId);
  Future<void> markReviewHelpful(String reviewId);
}
```

## Enhanced Reader Features

### Advanced Reading Modes
```dart
class ReaderEnhancements {
  final bool preloadPages;
  final int preloadCount;
  final bool smoothScrolling;
  final bool autoHideUI;
  final Duration autoHideDelay;
  final bool showReadingProgress;
  final bool showPageIndicator;
  final bool enablePageFlipAnimation;
}

class ReadingTimer {
  final String contentId;
  final DateTime startTime;
  final Duration totalTime;
  final Map<int, Duration> pageReadingTime;
  
  Future<void> startReading(String contentId);
  Future<void> pauseReading();
  Future<void> resumeReading();
  Future<void> stopReading();
  Future<ReadingSession> getReadingSession();
}

class ReadingSession {
  final String contentId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration totalDuration;
  final int pagesRead;
  final double averagePageTime;
}

class PageBookmarkManager {
  Future<void> addBookmark(String contentId, int page, String? note);
  Future<void> removeBookmark(String contentId, int page);
  Future<List<PageBookmark>> getBookmarks(String contentId);
  Future<void> updateBookmarkNote(String contentId, int page, String note);
}

class ReadingStatisticsDetailed {
  final int totalContentRead;
  final int totalPagesRead;
  final Duration totalReadingTime;
  final double averageReadingSpeed; // pages per minute
  final Map<String, int> readingTimeByHour;
  final Map<String, int> favoriteGenres;
  final Map<String, Duration> timeSpentByArtist;
  final List<ReadingStreak> readingStreaks;
}

class ReadingStreak {
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final int contentReadDuringStreak;
}
```

## Advanced Content Management

### Duplicate Detection & Management
```dart
class DuplicateDetectionEngine {
  Future<List<DuplicateGroup>> scanForDuplicates();
  Future<List<DuplicateGroup>> findDuplicatesByTitle();
  Future<List<DuplicateGroup>> findDuplicatesByArtist();
  Future<List<DuplicateGroup>> findDuplicatesByImages();
  Future<void> mergeDuplicateContent(DuplicateGroup group, String keepId);
  Future<void> ignoreDuplicate(DuplicateGroup group);
}

class ContentVerificationService {
  Future<ContentStatus> verifyContentAvailability(String contentId);
  Future<List<String>> findBrokenContent();
  Future<void> refreshContentMetadata(String contentId);
  Future<void> repairBrokenContent(String contentId);
  Future<ContentHealthReport> generateHealthReport();
}

enum ContentStatus {
  available,
  unavailable,
  moved,
  deleted,
  restricted,
}

class ContentHealthReport {
  final int totalContent;
  final int availableContent;
  final int unavailableContent;
  final int brokenContent;
  final List<String> brokenContentIds;
  final DateTime lastChecked;
}

class BatchOperationManager {
  Future<void> batchDownload(List<String> contentIds, {
    int maxConcurrent = 3,
    Function(String, double)? onProgress,
  });
  
  Future<void> batchAddToFavorites(List<String> contentIds, int categoryId);
  Future<void> batchRemoveFromFavorites(List<String> contentIds);
  Future<void> batchDelete(List<String> contentIds);
  Future<void> batchMove(List<String> contentIds, int newCategoryId);
  
  Stream<BatchOperationProgress> getBatchProgress();
}

class BatchOperationProgress {
  final String operationType;
  final int totalItems;
  final int completedItems;
  final int failedItems;
  final List<String> failedItemIds;
  final String? currentItem;
}

class SmartRecommendationEngine {
  Future<List<Content>> getPersonalizedRecommendations(String userId);
  Future<List<Content>> getRecommendationsBasedOnHistory();
  Future<List<Content>> getRecommendationsBasedOnFavorites();
  Future<List<Content>> getRecommendationsBasedOnTags(List<String> tags);
  Future<List<Content>> getTrendingRecommendations();
  Future<List<Content>> getSeasonalRecommendations();
  
  Future<void> trainRecommendationModel(List<UserInteraction> interactions);
  Future<void> updateUserProfile(UserProfile profile);
}

class UserProfile {
  final String userId;
  final Map<String, double> tagPreferences;
  final Map<String, double> artistPreferences;
  final Map<String, double> languagePreferences;
  final List<String> blacklistedTags;
  final ReadingBehavior behavior;
}

class ReadingBehavior {
  final double averageSessionDuration;
  final List<int> preferredReadingHours;
  final Map<String, int> genreReadingFrequency;
  final bool prefersLongContent;
  final bool prefersNewContent;
}
```

## Enhanced UI/UX Features

### Advanced Theme System
```dart
class ThemeManager {
  Future<void> createCustomTheme(CustomTheme theme);
  Future<void> deleteCustomTheme(String themeId);
  Future<List<CustomTheme>> getCustomThemes();
  Future<void> applyTheme(String themeId);
  Future<void> scheduleThemeChange(String themeId, TimeOfDay time);
  Future<void> enableAutoTheme(bool enable); // Based on time of day
}

class CustomTheme {
  final String id;
  final String name;
  final ThemeData themeData;
  final bool isDefault;
  final DateTime createdAt;
  final String? previewImage;
}

class AdvancedGridSettings {
  final GridLayoutType layoutType;
  final int columnsPortrait;
  final int columnsLandscape;
  final double aspectRatio;
  final EdgeInsets cardPadding;
  final BorderRadius cardRadius;
  final double cardElevation;
  final bool showShadows;
  final bool showTitles;
  final bool showArtist;
  final bool showTags;
  final bool showPageCount;
  final bool showLanguage;
  final bool blurNsfwContent;
  final double blurIntensity;
}

enum GridLayoutType {
  grid,
  staggered,
  list,
  carousel,
}

class GestureCustomization {
  final Map<GestureType, GestureAction> gestureMap;
  final double swipeSensitivity;
  final double pinchSensitivity;
  final bool hapticFeedback;
  final Duration longPressDuration;
}

enum GestureType {
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  doubleTap,
  longPress,
  pinchIn,
  pinchOut,
  twoFingerTap,
}

enum GestureAction {
  nextPage,
  previousPage,
  toggleUI,
  toggleFullscreen,
  addToFavorites,
  openMenu,
  zoomIn,
  zoomOut,
  fitToScreen,
  originalSize,
  none,
}

class QuickActionMenu {
  final List<QuickAction> actions;
  final QuickActionStyle style;
  final bool showLabels;
  final Duration animationDuration;
}

class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isEnabled;
}

enum QuickActionStyle {
  circular,
  linear,
  grid,
  contextMenu,
}
```

## Performance & Memory Optimization

### Advanced Caching System
```dart
class SmartCacheManager {
  Future<void> optimizeCacheSize();
  Future<void> preloadBasedOnUsage();
  Future<void> clearUnusedCache();
  Future<CacheAnalytics> getCacheAnalytics();
  Future<void> setCacheStrategy(CacheStrategy strategy);
}

enum CacheStrategy {
  aggressive,    // Cache everything
  balanced,      // Cache frequently used
  conservative,  // Cache only favorites
  minimal,       // Cache only currently viewing
}

class CacheAnalytics {
  final int totalCacheSize;
  final int memoryUsage;
  final int diskUsage;
  final double hitRate;
  final Map<String, int> mostCachedContent;
  final Map<String, int> cacheAccessFrequency;
}

class MemoryManager {
  Future<void> optimizeMemoryUsage();
  Future<void> clearUnusedImages();
  Future<void> compressImagesInMemory();
  Future<MemoryUsageReport> getMemoryReport();
  Future<void> setMemoryLimits(MemoryLimits limits);
}

class MemoryLimits {
  final int maxImageCacheSize;
  final int maxThumbnailCacheSize;
  final int maxPreloadedPages;
  final bool enableMemoryCompression;
}

class MemoryUsageReport {
  final int totalMemoryUsage;
  final int imageMemoryUsage;
  final int thumbnailMemoryUsage;
  final int otherMemoryUsage;
  final List<String> memoryHeavyContent;
}

class BackgroundTaskManager {
  Future<void> scheduleContentSync();
  Future<void> scheduleMetadataUpdate();
  Future<void> scheduleCacheCleanup();
  Future<void> scheduleBackup();
  Future<List<BackgroundTask>> getScheduledTasks();
  Future<void> cancelTask(String taskId);
}

class BackgroundTask {
  final String id;
  final String name;
  final TaskType type;
  final DateTime scheduledTime;
  final Duration interval;
  final bool isRecurring;
  final TaskStatus status;
}

enum TaskType {
  contentSync,
  metadataUpdate,
  cacheCleanup,
  backup,
  downloadQueue,
}

enum TaskStatus {
  scheduled,
  running,
  completed,
  failed,
  cancelled,
}
```

## Learning & Development Features

### Code Documentation & Examples
```dart
/// Comprehensive documentation untuk setiap class dan method
/// dengan contoh penggunaan yang jelas

/// Example: Content Repository Implementation
/// 
/// ```dart
/// final repository = ContentRepositoryImpl(
///   remoteDataSource: RemoteDataSource(),
///   localDataSource: LocalDataSource(),
/// );
/// 
/// // Fetch content with error handling
/// try {
///   final contents = await repository.getContentList(page: 1);
///   print('Loaded ${contents.length} contents');
/// } catch (e) {
///   print('Error loading content: $e');
/// }
/// ```
class DocumentationExamples {
  // Contoh implementasi untuk setiap pattern yang digunakan
  static void demonstrateCleanArchitecture() {}
  static void demonstrateBlocPattern() {}
  static void demonstrateRepositoryPattern() {}
  static void demonstrateWebScraping() {}
}

/// Learning utilities untuk memahami flow aplikasi
class LearningUtils {
  /// Log setiap step dalam clean architecture flow
  static void logArchitectureFlow(String layer, String action) {
    print('[${DateTime.now()}] $layer: $action');
  }
  
  /// Demonstrate BLoC state transitions
  static void logBlocTransition(String bloc, dynamic event, dynamic state) {
    print('$bloc: $event -> $state');
  }
  
  /// Show repository pattern in action
  static void logRepositoryCall(String method, String source) {
    print('Repository.$method called from $source');
  }
}
```

### Testing Examples & Patterns
```dart
/// Comprehensive testing examples untuk pembelajaran
class TestingExamples {
  /// Unit test example untuk Use Cases
  static void demonstrateUseCaseTesting() {
    /*
    test('GetContentListUseCase should return content list', () async {
      // Arrange
      final mockRepository = MockContentRepository();
      final useCase = GetContentListUseCase(mockRepository);
      final expectedContent = [Content(id: '1', title: 'Test')];
      
      when(mockRepository.getContentList(1))
          .thenAnswer((_) async => expectedContent);
      
      // Act
      final result = await useCase.call(1);
      
      // Assert
      expect(result, equals(expectedContent));
      verify(mockRepository.getContentList(1)).called(1);
    });
    */
  }
  
  /// BLoC testing example
  static void demonstrateBlocTesting() {
    /*
    blocTest<ContentBloc, ContentState>(
      'emits [ContentLoading, ContentLoaded] when content is fetched',
      build: () => ContentBloc(mockUseCase),
      act: (bloc) => bloc.add(LoadContentEvent()),
      expect: () => [
        ContentLoading(),
        ContentLoaded(contents: expectedContents),
      ],
    );
    */
  }
  
  /// Widget testing example
  static void demonstrateWidgetTesting() {
    /*
    testWidgets('ContentCard displays content information', (tester) async {
      // Arrange
      final content = Content(id: '1', title: 'Test Content');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: ContentCard(content: content)),
      );
      
      // Assert
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
    */
  }
  
  /// Integration testing example
  static void demonstrateIntegrationTesting() {
    /*
    testWidgets('Complete user flow: search -> view -> favorite', (tester) async {
      // Test complete user journey
      await tester.pumpAndSettle();
      
      // Navigate to search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      // Enter search query
      await tester.enterText(find.byType(TextField), 'test');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      // Tap on first result
      await tester.tap(find.byType(ContentCard).first);
      await tester.pumpAndSettle();
      
      // Add to favorites
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      
      // Verify favorite was added
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
    */
  }
}
```

### Architecture Learning Aids
```dart
/// Detailed architecture documentation dengan visual aids
class ArchitectureLearning {
  /// Demonstrate Clean Architecture layers
  static void showArchitectureLayers() {
    /*
    Presentation Layer (UI)
    ├── Pages (Screens)
    ├── Widgets (Reusable UI components)
    └── BLoCs (State Management)
    
    Domain Layer (Business Logic)
    ├── Entities (Core business objects)
    ├── Use Cases (Business rules)
    └── Repository Interfaces
    
    Data Layer (External concerns)
    ├── Repository Implementations
    ├── Data Sources (Remote & Local)
    └── Models (Data transfer objects)
    */
  }
  
  /// Show dependency injection setup
  static void demonstrateDependencyInjection() {
    /*
    // Service Locator setup
    void setupLocator() {
      // Data Sources
      getIt.registerLazySingleton<RemoteDataSource>(
        () => RemoteDataSourceImpl(dio: getIt()),
      );
      
      // Repositories
      getIt.registerLazySingleton<ContentRepository>(
        () => ContentRepositoryImpl(
          remoteDataSource: getIt(),
          localDataSource: getIt(),
        ),
      );
      
      // Use Cases
      getIt.registerLazySingleton<GetContentListUseCase>(
        () => GetContentListUseCase(getIt()),
      );
      
      // BLoCs
      getIt.registerFactory<ContentBloc>(
        () => ContentBloc(getIt()),
      );
    }
    */
  }
}
```

### Performance Learning & Monitoring
```dart
/// Performance monitoring untuk pembelajaran
class PerformanceLearning {
  /// Monitor dan log performance metrics
  static void monitorPerformance() {
    /*
    // Image loading performance
    final stopwatch = Stopwatch()..start();
    
    CachedNetworkImage(
      imageUrl: url,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          stopwatch.stop();
          print('Image loaded in ${stopwatch.elapsedMilliseconds}ms');
          return child;
        }
        return CircularProgressIndicator();
      },
    );
    */
  }
  
  /// Database query performance monitoring
  static void monitorDatabasePerformance() {
    /*
    Future<List<Content>> getContents() async {
      final stopwatch = Stopwatch()..start();
      
      final results = await database.query('contents');
      
      stopwatch.stop();
      print('Database query took ${stopwatch.elapsedMilliseconds}ms');
      print('Returned ${results.length} results');
      
      return results.map((e) => Content.fromMap(e)).toList();
    }
    */
  }
}
```

### Code Generation Examples
```dart
/// Examples of code generation untuk pembelajaran
@freezed
class Content with _$Content {
  const factory Content({
    required String id,
    required String title,
    required String coverUrl,
    required List<String> tags,
    required List<String> artists,
    required String language,
    required int pageCount,
    required DateTime uploadDate,
  }) = _Content;
  
  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);
}

/// JSON serialization example
@JsonSerializable()
class ContentModel {
  final String id;
  final String title;
  
  ContentModel({required this.id, required this.title});
  
  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContentModelToJson(this);
}
```

### Learning Resources & Documentation
```dart
/// Built-in learning resources
class LearningResources {
  static const Map<String, String> architecturePatterns = {
    'Clean Architecture': '''
    Memisahkan kode menjadi 3 layer:
    - Presentation: UI dan state management
    - Domain: Business logic dan entities
    - Data: External data sources
    ''',
    
    'Repository Pattern': '''
    Abstraksi untuk data access:
    - Interface di domain layer
    - Implementation di data layer
    - Memungkinkan easy testing dan switching data sources
    ''',
    
    'BLoC Pattern': '''
    Business Logic Component:
    - Events: User actions
    - States: UI states
    - BLoC: Business logic processor
    ''',
  };
  
  static const Map<String, String> flutterConcepts = {
    'State Management': '''
    BLoC pattern untuk predictable state management:
    - Reactive programming dengan streams
    - Separation of concerns
    - Easy testing
    ''',
    
    'Dependency Injection': '''
    GetIt untuk service locator pattern:
    - Loose coupling
    - Easy testing dengan mocks
    - Centralized dependency management
    ''',
  };
  
  static const List<String> learningPath = [
    '1. Understand Clean Architecture principles',
    '2. Learn BLoC pattern for state management',
    '3. Implement Repository pattern for data access',
    '4. Add dependency injection with GetIt',
    '5. Write comprehensive tests',
    '6. Implement web scraping techniques',
    '7. Add offline capabilities',
    '8. Optimize performance',
    '9. Add advanced features',
    '10. Deploy and maintain',
  ];
}
```

### Development Tools & Utilities
```dart
/// Development utilities untuk debugging dan learning
class DevTools {
  /// Network request logger
  static void logNetworkRequest(String url, String method) {
    print('🌐 $method: $url');
  }
  
  /// Database operation logger
  static void logDatabaseOperation(String operation, String table) {
    print('💾 $operation on $table');
  }
  
  /// BLoC event logger
  static void logBlocEvent(String bloc, String event) {
    print('🎯 $bloc: $event');
  }
  
  /// Performance timer
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      print('⏱️ $operationName took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
}
```

## Learning & Development Features

### Developer Tools & Debugging
```dart
class DeveloperTools {
  static bool get isDebugMode => kDebugMode;
  
  // Network debugging
  Future<void> enableNetworkLogging(bool enable);
  Future<List<NetworkRequest>> getNetworkLogs();
  Future<void> clearNetworkLogs();
  
  // Performance monitoring
  Future<PerformanceMetrics> getPerformanceMetrics();
  Future<void> startPerformanceMonitoring();
  Future<void> stopPerformanceMonitoring();
  
  // Memory debugging
  Future<MemorySnapshot> takeMemorySnapshot();
  Future<List<MemoryLeak>> detectMemoryLeaks();
  
  // Database debugging
  Future<void> exportDatabase();
  Future<void> viewDatabaseSchema();
  Future<List<DatabaseQuery>> getSlowQueries();
}

class NetworkRequest {
  final String url;
  final String method;
  final int statusCode;
  final Duration duration;
  final int requestSize;
  final int responseSize;
  final DateTime timestamp;
  final Map<String, String> headers;
  final String? error;
}

class PerformanceMetrics {
  final double averageFPS;
  final Duration averageFrameTime;
  final int memoryUsage;
  final int cpuUsage;
  final Map<String, Duration> widgetBuildTimes;
  final List<PerformanceIssue> issues;
}

class PerformanceIssue {
  final String type;
  final String description;
  final String location;
  final Severity severity;
  final String? suggestion;
}

enum Severity {
  low,
  medium,
  high,
  critical,
}
```

### Code Documentation & Examples
```dart
/// Comprehensive example implementations for learning
class LearningExamples {
  // BLoC Pattern Examples
  static void demonstrateBlocPattern() {
    // Example: How to implement BLoC with proper state management
    // Shows: Event handling, state transitions, error handling
  }
  
  // Clean Architecture Examples
  static void demonstrateCleanArchitecture() {
    // Example: Proper layer separation
    // Shows: Use cases, repositories, data sources
  }
  
  // Web Scraping Examples
  static void demonstrateWebScraping() {
    // Example: HTML parsing, error handling, rate limiting
    // Shows: CSS selectors, data extraction, anti-detection
  }
  
  // Caching Examples
  static void demonstrateCaching() {
    // Example: Multi-level caching strategy
    // Shows: Memory cache, disk cache, cache invalidation
  }
  
  // Database Examples
  static void demonstrateDatabase() {
    // Example: SQLite operations, migrations, relationships
    // Shows: CRUD operations, transactions, indexing
  }
}

/// Code quality and best practices
class CodeQualityTools {
  // Code metrics
  static Future<CodeMetrics> analyzeCodeQuality();
  static Future<List<CodeSmell>> detectCodeSmells();
  static Future<TestCoverage> getTestCoverage();
  
  // Architecture validation
  static Future<ArchitectureReport> validateArchitecture();
  static Future<List<DependencyViolation>> checkDependencies();
}

class CodeMetrics {
  final int linesOfCode;
  final int numberOfClasses;
  final int numberOfMethods;
  final double cyclomaticComplexity;
  final double maintainabilityIndex;
  final Map<String, int> codeDistribution; // per layer
}

class TestCoverage {
  final double overallCoverage;
  final Map<String, double> coverageByFile;
  final List<String> uncoveredLines;
  final List<String> criticalUncoveredPaths;
}
```

### Learning Resources & Tutorials
```dart
class LearningResources {
  // Interactive tutorials
  static List<Tutorial> getAvailableTutorials();
  static Future<void> startTutorial(String tutorialId);
  
  // Code walkthroughs
  static List<CodeWalkthrough> getCodeWalkthroughs();
  static Future<void> showCodeExplanation(String feature);
  
  // Best practices guide
  static List<BestPractice> getBestPractices();
  static Future<void> showBestPracticeExample(String practiceId);
}

class Tutorial {
  final String id;
  final String title;
  final String description;
  final List<TutorialStep> steps;
  final Difficulty difficulty;
  final Duration estimatedTime;
  final List<String> prerequisites;
}

class TutorialStep {
  final String title;
  final String description;
  final String? codeExample;
  final String? explanation;
  final List<String> keyPoints;
  final String? nextAction;
}

enum Difficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

class CodeWalkthrough {
  final String feature;
  final String description;
  final List<CodeSection> sections;
  final List<String> learningObjectives;
}

class CodeSection {
  final String title;
  final String filePath;
  final int startLine;
  final int endLine;
  final String explanation;
  final List<String> keyConceptsExplained;
}
```

### Testing & Quality Assurance
```dart
class TestingFramework {
  // Unit testing examples
  static List<UnitTestExample> getUnitTestExamples();
  static Future<void> runUnitTestSuite();
  
  // Integration testing examples
  static List<IntegrationTestExample> getIntegrationTestExamples();
  static Future<void> runIntegrationTests();
  
  // Widget testing examples
  static List<WidgetTestExample> getWidgetTestExamples();
  static Future<void> runWidgetTests();
  
  // E2E testing examples
  static List<E2ETestExample> getE2ETestExamples();
  static Future<void> runE2ETests();
}

class UnitTestExample {
  final String testName;
  final String description;
  final String codeExample;
  final List<String> conceptsExplained;
  final String expectedOutcome;
}

/// Mock data generators for testing
class MockDataGenerator {
  static List<Content> generateMockContent(int count);
  static List<Tag> generateMockTags(int count);
  static List<Comment> generateMockComments(int count);
  static UserPreferences generateMockPreferences();
  static List<DownloadStatus> generateMockDownloads(int count);
}
```

### Documentation & Learning Aids
```dart
class DocumentationSystem {
  // API documentation
  static Future<void> generateAPIDocumentation();
  static Future<void> showAPIReference(String className);
  
  // Architecture documentation
  static Future<void> showArchitectureDiagram();
  static Future<void> explainArchitectureLayer(String layer);
  
  // Feature documentation
  static Future<void> showFeatureDocumentation(String feature);
  static Future<void> showImplementationGuide(String feature);
}

/// Learning progress tracking
class LearningProgress {
  final String userId;
  final Map<String, bool> completedTutorials;
  final Map<String, int> featureUnderstanding; // 1-5 scale
  final List<String> masteredConcepts;
  final List<String> strugglingConcepts;
  final DateTime lastLearningSession;
  
  Future<void> markTutorialComplete(String tutorialId);
  Future<void> updateConceptUnderstanding(String concept, int level);
  Future<LearningRecommendation> getNextLearningStep();
}

class LearningRecommendation {
  final String title;
  final String description;
  final List<String> suggestedTutorials;
  final List<String> suggestedFeatures;
  final String reasoning;
}
```

### Experimental Features & Playground
```dart
class ExperimentalFeatures {
  // Feature flags for learning
  static bool isFeatureEnabled(String featureName);
  static Future<void> enableExperimentalFeature(String featureName);
  
  // A/B testing framework
  static Future<void> setupABTest(String testName, List<String> variants);
  static String getVariantForUser(String testName, String userId);
  
  // Code playground
  static Future<void> openCodePlayground();
  static Future<void> runCodeSnippet(String code);
  static Future<void> saveCodeSnippet(String name, String code);
}

/// Learning analytics
class LearningAnalytics {
  static Future<void> trackLearningEvent(String event, Map<String, dynamic> data);
  static Future<LearningReport> generateLearningReport();
  static Future<List<String>> getRecommendedTopics();
}

class LearningReport {
  final Duration totalLearningTime;
  final int tutorialsCompleted;
  final int featuresExplored;
  final Map<String, int> topicsStudied;
  final List<String> achievements;
  final double overallProgress;
}
```

Sekarang saya akan menambahkan dependencies untuk fitur pembelajaran:

<function_calls>
<invoke name="strReplace">
<parameter name="oldStr"># Advanced UI Components
flutter_expandable: ^5.0.1           # Expandable widgets
flutter_sticky_header: ^0.6.5        # Sticky headers
flutter_reorderable_list: ^1.3.1     # Reorderable lists
flutter_swipe_action_cell: ^3.1.3    # Swipe actions
context_menus: ^1.0.2                # Context menusvanced UI Components
flutter_expandable: ^5.0.1           # Expandable widgets
flutter_sticky_header: ^0.6.5        # Sticky headers
flutter_reorderable_list: ^1.3.1     # Reorderable lists
flutter_swipe_action_cell: ^3.1.3    # Swipe actions
context_menus: ^1.0.2                # Context menus

# Learning & Development Tools
flutter_test: ^1.0.0                 # Testing framework
mockito: ^5.4.4                      # Mocking for tests
bloc_test: ^9.1.7                    # BLoC testing utilities
golden_toolkit: ^0.15.0              # Golden tests
integration_test: ^1.0.0             # Integration testing
patrol: ^3.12.0                      # Advanced E2E testing

# Code Quality & Analysis
dart_code_metrics: ^5.7.6            # Code metrics
very_good_analysis: ^6.0.0           # Lint rules
coverage: ^1.9.2                     # Test coverage
dependency_validator: ^4.1.0         # Dependency analysis

# Documentation & Learning
dartdoc: ^8.1.0                      # Documentation generation
code_builder: ^4.10.0                # Code generation
source_gen: ^1.5.0                   # Source generation
json_serializable: ^6.8.0            # JSON serialization
freezed: ^2.5.7                      # Immutable classes

# Development Utilities
flutter_launcher_icons: ^0.14.2      # App icons
flutter_native_splash: ^2.4.1        # Splash screen
rename: ^3.0.2                       # App renaming
flutter_flavorizr: ^2.2.3            # Build flavors
```

## Data Persistence & Migration

### Database Migration Strategy
```dart
class DatabaseMigration {
  static const int currentVersion = 1;
  
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(db, version);
    }
  }
  
  static Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 1:
        await _createInitialTables(db);
        break;
      // Future migrations...
    }
  }
}
```

### Storage Quota Management
```dart
class StorageManager {
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int maxDownloadSize = 2 * 1024 * 1024 * 1024; // 2GB
  
  Future<void> cleanupOldCache();
  Future<void> enforceStorageQuota();
  Future<StorageInfo> getStorageInfo();
}
```

## Accessibility & Internationalization

### Accessibility Features
- Screen reader support dengan semantic labels
- High contrast mode support
- Font size scaling
- Voice navigation support
- Keyboard navigation untuk external keyboards

### Internationalization Support
```dart
// Supported languages
enum SupportedLanguage {
  english('en'),
  japanese('ja'),
  chinese('zh'),
  korean('ko'),
  indonesian('id');
  
  const SupportedLanguage(this.code);
  final String code;
}
```

### RTL Language Support
- Arabic dan Hebrew text support
- RTL layout mirroring
- RTL reading direction untuk manga

## Monitoring & Analytics

### Error Tracking
```dart
class ErrorTracker {
  static void logError(dynamic error, StackTrace stackTrace) {
    // Log to local storage for debugging
    Logger().e('Error: $error', error: error, stackTrace: stackTrace);
  }
  
  static void logScrapingError(String url, String error) {
    // Track scraping failures
  }
}
```

### Performance Monitoring
- App startup time tracking
- Image loading performance
- Database query performance
- Memory usage monitoring
- Network request timing

### User Behavior Analytics (Optional)
- Content view patterns (anonymous)
- Feature usage statistics
- Performance metrics
- Crash reporting
- User consent required

## Security Considerations

### Data Protection
- No sensitive user data storage
- Encrypted local database menggunakan `crypto` package
- Secure HTTP only (HTTPS)
- Cookie management for session persistence
- Respectful scraping dengan proper delays

### Content Filtering
- Age verification mechanism
- Content warning displays
- Parental control options
- Safe mode toggle
- Content reporting system

### Privacy
- No user tracking tanpa consent
- Local-only favorites dan downloads
- Optional analytics dengan explicit user consent
- Clear data deletion options
- GDPR compliance untuk EU users

### Anti-Detection & Ethical Scraping
- Respectful request rate limiting
- User-Agent rotation untuk avoid blocking
- Honor robots.txt guidelines
- Implement exponential backoff pada failures
- Cache aggressively untuk reduce server load