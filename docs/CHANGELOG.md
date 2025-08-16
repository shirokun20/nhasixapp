# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive dependency injection setup using get_it for better scalability
- Added external dependencies like SharedPreferences and Connectivity
- Configured core utilities including Logger, Dio HTTP client, CacheManager, TagDataManager
- Setup data sources for remote scraping, anti-detection, cloudflare bypass, and local database
- Implemented repository registrations for content, user data, reader settings, and offline content management
- Registered use cases for content, favorites, downloads, and history management
- Configured BLoCs for splash, home, content, search, and download features
- Setup Cubits for network, settings, detail, filter data, reader, offline search, and favorites
- Updated MultiBlocProvider configuration for all BLoCs and Cubits
- Updated dependencies in pubspec.yaml to support new features


## [0.7.0] - 2024-12-15

### Added
- **Complete Reader System Implementation** 📖
  - ReaderScreen with 3 reading modes: single page, vertical page, continuous scroll
  - ReaderCubit for simple state management with settings persistence
  - Advanced features: progress tracking, reading timer, page jumping, keep screen on
  - Gesture navigation with tap zones for previous/next/toggle UI
  - Modal settings with reading mode selection and reset functionality
  - Controller synchronization for smooth mode switching
  - Comprehensive error handling with AppErrorWidget

- **Advanced Search & Filter System** 🔍
  - FilterDataScreen with modern UI for advanced filter selection
  - FilterDataCubit for filter data state management
  - TagDataManager integration with local assets (assets/json/tags.json)
  - Matrix Filter Support with include/exclude functionality
  - Search state persistence across app restarts
  - FilterItemCard, SelectedFiltersWidget, FilterTypeTabBar widgets
  - SearchQueryBuilder for proper query formatting

- **Comprehensive UI Framework** 🎨
  - Updated ColorsConst with eye-friendly dark theme and semantic colors
  - Enhanced TextStyleConst with semantic styles and utility methods
  - ContentListWidget with pagination-first approach and configurable infinite scroll
  - PaginationWidget with progress bar, page jumping, and accessibility support
  - SortingWidget for MainScreen with modern design
  - AppProgressIndicator and AppErrorWidget for consistent UX

### Enhanced
- **MainScreen Integration**
  - HomeBloc integration for screen-level state management
  - Search results display with active filters header
  - Sorting functionality moved from SearchScreen to MainScreen
  - Search state loading from local storage on app startup
  - Clear search results functionality with database cleanup

- **Navigation & Routing**
  - Go Router configuration with FilterDataScreen route
  - Parameter passing for filter type and selected filters
  - Deep linking support with proper back navigation
  - AppRouter methods for FilterDataScreen navigation

- **Database & Persistence**
  - Search filter state table for persistence
  - Reader settings model for preferences storage
  - Simplified database schema with 6 tables
  - Search state serialization/deserialization

### Technical Improvements
- **State Management Architecture**
  - Proper BLoC vs Cubit separation (Complex vs Simple features)
  - ContentBloc for complex pagination and search results
  - SearchBloc for advanced search with state persistence
  - HomeBloc for main screen initialization
  - DetailCubit, ReaderCubit, FilterDataCubit for simple state management

- **Performance Optimizations**
  - Pagination-first approach for better performance
  - Image caching with CachedNetworkImage
  - Memory management with proper disposal
  - Database optimization with efficient queries

### Testing
- **Real Device Testing Requirements**
  - All features must be tested on physical Android devices
  - Performance monitoring on real hardware
  - Network connectivity testing with various conditions
  - UI/UX validation on different screen sizes and orientations

## [0.6.0] - 2024-12-01

### Added
- **Complete Search Flow Implementation** 🔍
  - SearchScreen with comprehensive search interface
  - Advanced filter support without immediate API calls
  - Search button to trigger SearchSubmitted event
  - Navigation integration with FilterDataScreen
  - Single select filters (language, category) with validation
  - Search results display with pagination support

- **Core UI Components** 🎨
  - AppMainDrawerWidget with 4 main menu items
  - AppMainHeaderWidget with search and menu navigation
  - ContentListWidget with grid layout and pagination support
  - Modern design implementation with ColorsConst and TextStyleConst
  - Responsive layout with SliverGrid and adaptive widgets

### Enhanced
- **ContentBloc Advanced Features**
  - Search results integration with normal content display
  - Sorting functionality with ContentSortChangedEvent
  - Pagination support with overlay loading for page changes
  - Pull-to-refresh functionality with SmartRefresher
  - Error handling with retry mechanisms and cached content fallback

- **Database Integration**
  - Search state persistence with LocalDataSource
  - Sorting preferences storage with UserDataRepository
  - Database schema updates for search functionality
  - Migration support for new tables

## [0.5.0] - 2024-11-15

### Added
- **Core BLoC State Management System** 🏗️
  - HomeBloc for main screen state management and initialization
  - Enhanced ContentBloc with pagination, sorting, and search results
  - Comprehensive state management with proper error handling
  - MultiBlocProviderConfig for app-wide BLoC/Cubit providers

- **Simplified Database Architecture** 💾
  - Reduced database schema from 10+ tables to 6 tables
  - Simplified favorites storage (ID + cover URL only)
  - Basic download tracking with title and cover for display
  - Streamlined history management with progress tracking
  - Optimized database operations for better performance

## [0.3.0] - 2025-01-30

### Added
- **Advanced SearchBloc Implementation** 🔍
  - Comprehensive search functionality with advanced filtering capabilities
  - Debounced search with 500ms delay for optimal performance
  - Search history management with local storage integration
  - Tag suggestions and autocomplete functionality
  - Popular searches tracking and display
  - Search presets for saving and loading custom filter configurations
  - Advanced search mode toggle for power users
  - Quick filter application for tags, artists, languages, and categories
  - Pagination support with load more functionality
  - Pull-to-refresh capability for search results
  - Smart retry mechanism with error type detection

### Enhanced
- **Search State Management**
  - Multiple specialized states: `SearchInitial`, `SearchLoading`, `SearchLoaded`, `SearchEmpty`, `SearchError`
  - Advanced loading states: `SearchLoadingMore`, `SearchRefreshing`
  - Comprehensive error handling with specific error types (network, server, cloudflare, rate limit, parsing)
  - Search suggestions state with real-time query matching
  - Search history state with popular searches integration

- **Search Features**
  - Real-time search suggestions from history and popular searches
  - Tag-based autocomplete with database integration
  - Search filter persistence and management
  - Sort options with dynamic re-searching
  - Search result caching and optimization
  - Maximum 50 history items with automatic cleanup
  - Maximum 10 suggestions per query for performance

- **Error Handling & UX**
  - Intelligent error type detection and categorization
  - Retry functionality with context-aware error messages
  - Graceful degradation for different error scenarios
  - Loading states with descriptive messages
  - Empty state handling with search suggestions

### Testing
- **Comprehensive Unit Tests**
  - Complete SearchBloc testing suite with `flutter_test`
  - Mock implementations for use cases and data sources
  - State transition testing for all search scenarios
  - Error handling and edge case testing
  - Search history and suggestion testing
  - Integration tests for real-world scenarios

### Technical Improvements
- **Stream Management**
  - Custom debounce transformer for search events
  - Proper stream subscription handling and cleanup
  - Memory leak prevention with timer cancellation
  - Efficient event processing with async/await patterns

- **Data Layer Integration**
  - Enhanced LocalDataSource integration for search history
  - Tag search functionality with database queries
  - Search filter serialization and persistence
  - Optimized database operations for search performance

### Dependencies
- Enhanced integration with existing `logger`, `equatable`, and `bloc` packages
- Improved compatibility with local data source implementations
- Better error handling integration with domain layer exceptions

## [0.2.0] - 2025-01-28

### Added
- **Enhanced SplashBloc Implementation** 🎯
  - Comprehensive state management for app initialization process
  - Integrated Cloudflare bypass with proper dependency injection
  - Network connectivity validation before bypass attempts
  - Bypass verification to ensure successful connection
  - Smart retry mechanism with proper error handling
  - Enhanced UI with loading states and progress indicators
  - Improved WebView integration with better status tracking

### Enhanced
- **State Management**
  - Added multiple states: `SplashInitializing`, `SplashBypassInProgress`, `SplashSuccess`, `SplashError`
  - Implemented proper state transitions with user feedback
  - Added retry functionality with `SplashRetryBypassEvent`

- **User Experience**
  - Loading indicators with progress messages
  - Error states with actionable retry buttons
  - Informative snackbars with success/error feedback
  - Non-dismissible WebView modal during bypass process

- **Error Handling**
  - Network connectivity validation
  - Detailed error messages with suggested solutions
  - Graceful degradation for different error scenarios
  - User-friendly error presentation

### Testing
- **Comprehensive Unit Tests**
  - Added BLoC testing with `bloc_test` package
  - Implemented mocking with `mockito` for reliable tests
  - Created test scenarios for all state transitions
  - Added connectivity and bypass verification testing

### Dependencies
- Added `bloc_test: ^10.0.0` for BLoC testing utilities
- Added `mockito: ^5.4.4` for mock generation
- Updated service locator with proper dependency injection

### Technical Improvements
- Enhanced dependency injection in `service_locator.dart`
- Improved WebView widget with better status tracking
- Updated splash screen with comprehensive state handling
- Fixed deprecated `withOpacity` usage to `withValues`
- Resolved connectivity API compatibility issues

## [0.1.0] - 2025-01-20

### Added
- **Project Foundation**
  - Clean Architecture setup with 3 layers (data, domain, presentation)
  - Core dependencies and project structure
  - Basic routing with GoRouter

- **Domain Layer**
  - Core entities and value objects
  - Repository interfaces
  - Use cases with comprehensive business logic

- **Data Layer**
  - Repository implementations with offline-first architecture
  - Local data sources with SQLite integration
  - Remote data sources with web scraping capabilities
  - Data models with entity conversion
  - Caching strategy and error handling
  - Cloudflare bypass implementation

### Technical Stack
- Flutter SDK (>=3.5.4)
- Clean Architecture pattern
- BLoC for state management
- SQLite for local storage
- Dio for HTTP requests
- WebView for Cloudflare bypass
- 40+ carefully selected dependencies

---

## Development Progress

- ✅ **Task 1-7**: Core features completed (70% of project)
  - ✅ Project structure and dependencies
  - ✅ Domain and data layer implementation
  - ✅ BLoC/Cubit state management system
  - ✅ Core UI components and widgets
  - ✅ Advanced search and filter system
  - ✅ Complete reader functionality
- 🎯 **Task 8**: Favorites and download system (next priority)
- 📅 **Task 9**: Settings and preferences
- 📅 **Task 10**: Advanced features and network management
- 📅 **Task 11**: Performance optimization and testing
- 📅 **Task 12**: UI polish and accessibility
- 📅 **Task 13**: Deployment preparation

---

**Current Status**: 70% Complete (7/13 tasks)  
**Implementation Status**: Core features operational  
**Next Milestone**: Favorites and Download System Implementation