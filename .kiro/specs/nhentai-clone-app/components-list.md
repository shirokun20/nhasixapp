# Components List - NhentaiApp

## Overview

Dokumen ini berisi daftar lengkap semua komponen yang ada dan akan diimplementasikan dalam aplikasi NhentaiApp. Komponen diorganisir berdasarkan layer Clean Architecture dan status implementasinya.

## Status Legend
- ✅ **Implemented**: Komponen sudah diimplementasikan dan berfungsi
- 🚧 **In Progress**: Komponen sedang dalam tahap pengembangan
- ⏳ **Planned**: Komponen direncanakan untuk diimplementasikan
- 🔧 **Needs Update**: Komponen perlu diperbarui atau diperbaiki

---

## 1. Presentation Layer

### 1.1 Pages/Screens

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| SplashScreen | 🔧 | Initial loading screen dengan progress indicator (Updated: ColorsConst + TextStyleConst) | `lib/presentation/pages/splash/splash_screen.dart` |
| MainScreen | 🔧 | Home screen dengan content grid dan tema hitam (Updated: Uses ContentListWidget + HomeBloc integration) | `lib/presentation/pages/main/main_screen.dart` |
| SearchScreen | ⏳ | Advanced search dengan filter options | `lib/presentation/pages/search/search_screen.dart` |
| DetailScreen | ⏳ | Content detail dengan metadata lengkap | `lib/presentation/pages/detail/detail_screen.dart` |
| ReaderScreen | ⏳ | Reading mode dengan zoom dan navigation | `lib/presentation/pages/reader/reader_screen.dart` |
| FavoritesScreen | ⏳ | Favorites management dengan categories | `lib/presentation/pages/favorites/favorites_screen.dart` |
| DownloadsScreen | ⏳ | Downloaded content management | `lib/presentation/pages/downloads/downloads_screen.dart` |
| SettingsScreen | ⏳ | App settings dan preferences | `lib/presentation/pages/settings/settings_screen.dart` |
| TagScreen | ⏳ | Tag browsing dan statistics | `lib/presentation/pages/tags/tag_screen.dart` |
| HistoryScreen | ⏳ | Reading history dan statistics | `lib/presentation/pages/history/history_screen.dart` |

### 1.2 Widgets

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| AppMainDrawerWidget | 🔧 | Navigation drawer dengan 4 menu utama (Updated: ColorsConst + TextStyleConst) | `lib/presentation/widgets/app_main_drawer_widget.dart` |
| AppMainHeaderWidget | 🔧 | Main header dengan search dan menu (Updated: ColorsConst + TextStyleConst) | `lib/presentation/widgets/app_main_header_widget.dart` |
| ContentListWidget | ✅ | Grid layout untuk content cards (Updated: Pagination-first with configurable infinite scroll) | `lib/presentation/widgets/content_list_widget.dart` |

| ContentCard | ⏳ | Individual content card component | `lib/presentation/widgets/content_card_widget.dart` |
| SearchFilter | ⏳ | Advanced search filter widget | `lib/presentation/widgets/search_filter_widget.dart` |
| ImageViewer | ⏳ | Zoomable image viewer component | `lib/presentation/widgets/image_viewer_widget.dart` |
| ProgressIndicator | ⏳ | Custom loading indicators | `lib/presentation/widgets/progress_indicator_widget.dart` |
| ErrorWidget | ⏳ | Standardized error display | `lib/presentation/widgets/error_widget.dart` |
| PaginationWidget | 🔧 | Advanced pagination dengan progress bar dan page input (Updated: ColorsConst + TextStyleConst) | `lib/presentation/widgets/pagination_widget.dart` |

### 1.3 BLoCs & Cubits (State Management)

#### Complex State Management (BLoCs)
| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| SplashBloc | ✅ | Initial loading dan bypass logic | `lib/presentation/blocs/splash/` |
| ContentBloc | ✅ | Content list dengan pagination kompleks | `lib/presentation/blocs/content/` |
| SearchBloc | ✅ | Search dengan debouncing dan filters | `lib/presentation/blocs/search/` |
| HomeBloc | ✅ | Main screen state management (integrated with MainScreen) | `lib/presentation/blocs/home/` |
| DownloadBloc | ⏳ | Download queue dan concurrent operations | `lib/presentation/blocs/download/` |

#### Simple State Management (Cubits)
| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| DetailCubit | ⏳ | Content detail dan favorite toggle | `lib/presentation/cubits/detail/` |
| ReaderCubit | ⏳ | Reader mode dan navigation | `lib/presentation/cubits/reader/` |
| FavoriteCubit | ⏳ | Favorites CRUD operations | `lib/presentation/cubits/favorite/` |
| SettingsCubit | ⏳ | App settings management | `lib/presentation/cubits/settings/` |
| NetworkCubit | ⏳ | Network connectivity status | `lib/presentation/cubits/network/` |

---

## 2. Domain Layer

### 2.1 Entities

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| Content | ✅ | Main content entity | `lib/domain/entities/content.dart` |
| Tag | ✅ | Tag entity dengan type dan count | `lib/domain/entities/tag.dart` |
| History | ✅ | Reading history entity | `lib/domain/entities/history.dart` |
| DownloadStatus | ✅ | Download status tracking | `lib/domain/entities/download_status.dart` |
| SearchFilter | ✅ | Search filter parameters | `lib/domain/entities/search_filter.dart` |
| UserPreferences | ✅ | User settings entity | `lib/domain/entities/user_preferences.dart` |
| ReadingStatistics | ✅ | Reading stats entity | `lib/domain/entities/reading_statistics.dart` |
| PaginationInfo | ✅ | Pagination information entity | `lib/domain/entities/pagination_info.dart` |

### 2.2 Value Objects

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ContentId | ✅ | Type-safe content identifier | `lib/domain/value_objects/content_id.dart` |
| ImageUrl | ✅ | Type-safe image URL | `lib/domain/value_objects/image_url.dart` |

### 2.3 Repository Interfaces

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ContentRepository | ✅ | Content data operations interface | `lib/domain/repositories/content_repository.dart` |
| UserDataRepository | ✅ | User data operations interface | `lib/domain/repositories/user_data_repository.dart` |
| SettingsRepository | ✅ | Settings operations interface | `lib/domain/repositories/settings_repository.dart` |

### 2.4 Use Cases

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| GetContentListUseCase | ✅ | Fetch content list dengan pagination | `lib/domain/usecases/content/get_content_list_usecase.dart` |
| GetContentDetailUseCase | ✅ | Fetch detailed content information | `lib/domain/usecases/content/get_content_detail_usecase.dart` |
| SearchContentUseCase | ✅ | Search content dengan filters | `lib/domain/usecases/content/search_content_usecase.dart` |
| GetRandomContentUseCase | ✅ | Get random content | `lib/domain/usecases/content/get_random_content_usecase.dart` |
| AddToFavoritesUseCase | ✅ | Add content to favorites | `lib/domain/usecases/favorites/add_to_favorites_usecase.dart` |
| GetFavoritesUseCase | ✅ | Get user favorites | `lib/domain/usecases/favorites/get_favorites_usecase.dart` |
| RemoveFromFavoritesUseCase | ✅ | Remove from favorites | `lib/domain/usecases/favorites/remove_from_favorites_usecase.dart` |
| DownloadContentUseCase | ✅ | Download content for offline | `lib/domain/usecases/downloads/download_content_usecase.dart` |
| GetDownloadStatusUseCase | ✅ | Get download status | `lib/domain/usecases/downloads/get_download_status_usecase.dart` |
| AddToHistoryUseCase | ✅ | Add to reading history | `lib/domain/usecases/history/add_to_history_usecase.dart` |

---

## 3. Data Layer

### 3.1 Models

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ContentModel | ✅ | Content data model dengan JSON serialization | `lib/data/models/content_model.dart` |
| TagModel | ✅ | Tag data model | `lib/data/models/tag_model.dart` |
| HistoryModel | ✅ | History data model | `lib/data/models/history_model.dart` |
| DownloadStatusModel | ✅ | Download status data model | `lib/data/models/download_status_model.dart` |
| PaginationModel | ✅ | Pagination data model | `lib/data/models/pagination_model.dart` |

### 3.2 Data Sources

#### 3.2.1 Remote Data Sources

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| RemoteDataSource | ✅ | Main remote data interface | `lib/data/datasources/remote/remote_data_source.dart` |
| RemoteDataSourceFactory | ✅ | Factory untuk remote data sources | `lib/data/datasources/remote/remote_data_source_factory.dart` |
| NhentaiScraper | ✅ | Web scraping implementation dengan pagination parsing | `lib/data/datasources/remote/nhentai_scraper.dart` |
| TagResolver | ✅ | Tag ID resolution dari local assets | `lib/data/datasources/remote/tag_resolver.dart` |
| AntiDetection | ✅ | Anti-detection measures | `lib/data/datasources/remote/anti_detection.dart` |

| CloudflareBypassNoWebView | ✅ | Cloudflare bypass tanpa webview (actively used) | `lib/data/datasources/remote/cloudflare_bypass_no_webview.dart` |
| Exceptions | ✅ | Custom exceptions untuk remote operations | `lib/data/datasources/remote/exceptions.dart` |

#### 3.2.2 Local Data Sources

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| LocalDataSource | ✅ | Local database operations (simplified) | `lib/data/datasources/local/local_data_source.dart` |
| DatabaseHelper | ✅ | SQLite database helper (simplified schema) | `lib/data/datasources/local/database_helper.dart` |
| ~~PaginationCacheKeys~~ | ❌ | Removed - not needed for simplified app | ~~`lib/data/datasources/local/pagination_cache_keys.dart`~~ |

### 3.3 Repository Implementations

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ContentRepositoryImpl | ✅ | Content repository dengan pagination cache integration | `lib/data/repositories/content_repository_impl.dart` |
| UserDataRepositoryImpl | ✅ | User data repository implementation | `lib/data/repositories/user_data_repository_impl.dart` |
| SettingsRepositoryImpl | ✅ | Settings repository implementation | `lib/data/repositories/settings_repository_impl.dart` |

---

## 4. Core Layer

### 4.1 Configuration

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| MultiBlocProviderConfig | ✅ | App-wide BLoC/Cubit providers configuration | `lib/core/config/multi_bloc_provider_config.dart` |

### 4.2 Constants

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ColorsConst | 🔧 | App color constants (Updated: Eye-friendly dark theme + semantic colors) | `lib/core/constants/colors_const.dart` |
| TextStyleConst | 🔧 | Text style constants (Updated: Semantic styles + utility methods) | `lib/core/constants/text_style_const.dart` |

### 4.3 Dependency Injection

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| ServiceLocator | ✅ | GetIt service locator setup | `lib/core/di/service_locator.dart` |

### 4.4 Network

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| HttpClientManager | ✅ | Dio HTTP client configuration | `lib/core/network/http_client_manager.dart` |

### 4.5 Utils

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| UrlNhentaiUtil | ✅ | URL utilities untuk nhentai | `lib/core/utils/url_nhentai_util.dart` |

---

## 5. Assets & Resources

### 5.1 JSON Data

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| tags.json | ✅ | Tag mapping data untuk TagResolver | `assets/json/tags.json` |

### 5.2 Images

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| App Icons | ✅ | Application icons | `assets/icons/` |
| Placeholder Images | ⏳ | Placeholder images untuk loading states | `assets/images/` |

---

## 6. Configuration Files

### 6.1 Project Configuration

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| pubspec.yaml | ✅ | Dependencies dan asset configuration | `pubspec.yaml` |
| analysis_options.yaml | ✅ | Dart analysis configuration | `analysis_options.yaml` |

### 6.2 Platform Specific

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| AndroidManifest.xml | ✅ | Android app configuration | `android/app/src/main/AndroidManifest.xml` |
| MainActivity.kt | ✅ | Android main activity | `android/app/src/main/kotlin/.../MainActivity.kt` |

---

## 7. Documentation

### 7.1 Existing Documentation

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| README.md | ✅ | Main project documentation | `README.md` |
| TUTORIAL_SCRAPER_CACHE.md | ✅ | Web scraping tutorial | `docs/TUTORIAL_SCRAPER_CACHE.md` |
| DEVELOPMENT_NOTES.md | ✅ | Development notes | `DEVELOPMENT_NOTES.md` |

### 7.2 Planned Documentation

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| TUTORIAL_CLEAN_ARCHITECTURE.md | ⏳ | Clean Architecture tutorial | `docs/TUTORIAL_CLEAN_ARCHITECTURE.md` |
| TUTORIAL_BLOC_STATE_MANAGEMENT.md | ⏳ | BLoC pattern tutorial | `docs/TUTORIAL_BLOC_STATE_MANAGEMENT.md` |
| TUTORIAL_DATABASE_OPERATIONS.md | ⏳ | Database operations tutorial | `docs/TUTORIAL_DATABASE_OPERATIONS.md` |
| TUTORIAL_UI_NAVIGATION.md | ⏳ | UI components tutorial | `docs/TUTORIAL_UI_NAVIGATION.md` |
| TUTORIAL_OFFLINE_FUNCTIONALITY.md | ⏳ | Offline functionality tutorial | `docs/TUTORIAL_OFFLINE_FUNCTIONALITY.md` |
| TUTORIAL_REAL_DEVICE_TESTING.md | ⏳ | Real device testing tutorial | `docs/TUTORIAL_REAL_DEVICE_TESTING.md` |

---

## 8. Testing Components

### 8.1 Test Structure (To be removed)

| Component | Status | Description | File Path |
|-----------|--------|-------------|-----------|
| test/ folder | 🔧 | Test folder yang akan dihapus | `test/` |

### 8.2 Real Device Testing

| Component | Status | Description | Notes |
|-----------|--------|-------------|-------|
| Performance Testing | ⏳ | Memory, CPU, battery usage testing | Pada perangkat Android fisik |
| Network Testing | ⏳ | Various network conditions testing | WiFi, 4G, 3G, offline scenarios |
| UI/UX Testing | ⏳ | Touch, gesture, orientation testing | Berbagai ukuran layar dan orientasi |
| Accessibility Testing | ⏳ | TalkBack, high contrast testing | Dengan pengguna nyata |

---

## 9. Key Features Implementation Status

### 9.1 Core Features

- ✅ **Web Scraping**: Implemented dengan anti-detection
- ✅ **Tag Resolution**: TagResolver sudah lengkap dengan local assets
- ✅ **Database Operations**: SQLite dengan simplified schema (favorites, downloads, history, preferences, search_history)
- ✅ **HTTP Client Management**: Dio dengan proper lifecycle
- ✅ **State Management**: BLoC pattern untuk complex features, Cubit untuk simple features
- 🚧 **UI Components**: Basic components implemented, advanced features simplified
- ⏳ **Reader Mode**: Planned dengan basic functionality
- ⏳ **Download Manager**: Planned dengan simplified queue system
- ✅ **Offline Functionality**: Basic offline support untuk favorites dan history

### 9.2 Simplified Features (Updated)

- ✅ **Simplified Database**: Removed complex content caching, tag management, dan pagination cache
- ✅ **Simplified Favorites**: Only stores ID dan cover URL untuk lightweight operation
- ✅ **Simplified Downloads**: Basic download tracking dengan title dan cover untuk display
- ✅ **Simplified History**: Basic reading history dengan progress tracking
- ✅ **Real Data Integration**: HTML parsing dengan accurate total pages extraction
- ✅ **Advanced UI Components**: PaginationWidget dengan progress bar dan page jumping
- ⏳ **Favorites Management**: Dengan category support
- ⏳ **Search & Filtering**: Advanced search dengan multiple filters (pagination ready)
- ⏳ **Settings & Customization**: Theme, layout, preferences
- ✅ **Performance Optimization**: Memory management, pagination caching, database optimization
- ⏳ **Real Device Testing**: Comprehensive testing pada perangkat fisik

---

## 10. BLoC vs Cubit Decision Matrix

### Menggunakan BLoC (Complex State Management)
| Component | Reason | Key Features |
|-----------|--------|--------------|
| ContentBloc | Multiple events (load, refresh, paginate, filter) | Event-driven, complex pagination |
| SearchBloc | Debouncing, history, multiple filters | Event-driven, async operations |
| DownloadBloc | Queue management, concurrent operations | Multiple events, complex state |
| SplashBloc | Multiple initialization paths, bypass logic | Event-driven, complex flow |

### Menggunakan Cubit (Simple State Management)
| Component | Reason | Key Features |
|-----------|--------|--------------|
| DetailCubit | Simple load + favorite toggle | Direct method calls, simple CRUD |
| ReaderCubit | Page navigation, settings update | Direct method calls, simple state |
| FavoriteCubit | CRUD operations only | Direct method calls, simple operations |
| SettingsCubit | Get/update preferences | Direct method calls, simple state |
| NetworkCubit | Connection status only | Direct method calls, boolean state |

### Benefits of This Approach
- **Reduced Boilerplate**: Cubit eliminates event classes for simple operations
- **Better Performance**: Less overhead for simple state changes
- **Cleaner Code**: Direct method calls are more intuitive for simple operations
- **Easier Testing**: Simpler to test direct method calls vs events
- **Appropriate Complexity**: Use the right tool for the right job

---

## 11. Next Priority Components

Berdasarkan task list dan completed pagination system, komponen berikut adalah prioritas selanjutnya:

1. **AppMainDrawerWidget Update** - Menu drawer dengan 4 item utama
2. **NetworkCubit & DetailCubit** - Simple state management components  
3. **ContentCard Widget** - Reusable content card dengan image caching
4. **SearchFilter Widget** - Advanced search interface (pagination-ready)
5. **DetailScreen dengan DetailCubit** - Content detail dengan simple state management
6. **ReaderScreen dengan ReaderCubit** - Reading mode dengan simple navigation

**Recently Completed:**
- ✅ **Complete Pagination System** - Real data integration dengan 22,114+ pages
- ✅ **Pagination Cache** - Offline-consistent pagination experience
- ✅ **Advanced PaginationWidget** - Progress bar, page jumping, accessibility support
- 🔧 **UI Constants Update** - ColorsConst & TextStyleConst modernization
- 🔧 **Consistent Styling** - All presentation components updated to use new constants
- 🔧 **ContentListWidget Integration** - MainScreen now uses advanced ContentListWidget in pagination mode
- 🔧 **Pagination-First Approach** - ContentListWidget updated to prioritize pagination over infinite scroll

---

## 11. Recent UI Constants Modernization

### 🎨 **ColorsConst Updates (Eye-friendly & Performance optimized):**
- **Dark Theme Colors**: GitHub-inspired dark colors yang nyaman untuk mata
- **Semantic Colors**: Tag categories, download status, reading progress
- **Interactive Colors**: Hover, pressed, focus states yang subtle
- **OLED Optimization**: True black colors untuk hemat battery
- **Utility Methods**: Dynamic color selection dan context-aware colors

### ✍️ **TextStyleConst Updates (Semantic & Consistent):**
- **Semantic Styles**: headingLarge, bodyMedium, caption, dll
- **Component-specific**: contentTitle, buttonMedium, navigationLabel
- **Status Styles**: statusSuccess, statusError, statusWarning
- **Utility Methods**: withColor(), withSize(), getContextualStyle()
- **Better Readability**: Line height 1.4 untuk semua text styles

### 🔧 **Updated Components:**
- ✅ **SplashScreen**: Modern colors + semantic text styles
- ✅ **MainScreen**: HomeBloc integration + ContentListWidget integration
- ✅ **AppMainDrawerWidget**: Navigation colors + semantic styles
- ✅ **AppMainHeaderWidget**: Header colors + consistent styling
- ✅ **ContentListWidget**: Pagination-first approach with configurable infinite scroll
- ✅ **PaginationWidget**: Interactive colors + semantic text styles

### 📄 **ContentListWidget Redesign:**
- **Pagination Mode**: Default behavior untuk konsistensi dengan PaginationWidget
- **Configurable**: `enableInfiniteScroll` parameter untuk flexibility
- **Pull-to-Refresh**: Tetap tersedia untuk user experience yang baik
- **Grid Layout**: Advanced grid dengan ContentCard components
- **Performance**: Optimized untuk pagination dengan large datasets

### 📱 **Benefits:**
- **Eye Comfort**: Reduced strain untuk extended usage
- **Performance**: OLED-optimized colors untuk battery efficiency
- **Consistency**: Unified styling across all components
- **Maintainability**: Semantic styles yang mudah diupdate
- **Accessibility**: High contrast ratios dan color-blind friendly

---

## 12. Real Device Testing Requirements

Setiap komponen yang diimplementasikan harus ditest pada perangkat Android fisik untuk memastikan:

- **Performance**: Memory usage, CPU usage, battery consumption
- **Network**: Berbagai kondisi jaringan (WiFi, 4G, 3G, offline)
- **UI/UX**: Touch responsiveness, gesture navigation, screen orientations
- **Compatibility**: Berbagai versi Android dan ukuran layar
- **Stability**: Extended usage, background behavior, crash recovery

---

*Dokumen ini akan diupdate seiring dengan progress implementasi komponen-komponen aplikasi.*