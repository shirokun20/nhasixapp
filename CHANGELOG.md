# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

- ✅ **Task 1**: Project structure and core dependencies setup
- ✅ **Task 2**: Core domain layer implementation  
- ✅ **Task 3**: Data layer foundation
- ✅ **Task 4.1**: Enhanced SplashBloc implementation ← **Latest**
- 🚧 **Task 4**: Core BLoC state management (25% complete)
- 📅 **Task 5**: Core UI components (upcoming)

---

**Current Status**: 25% Complete (4.1/12 tasks)  
**Next Milestone**: Complete remaining BLoC implementations for core features