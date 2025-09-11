# GitHub Copilot Instructions for NhasixApp

## Project Overview

NhasixApp is a Flutter Android app using **Clean Architecture** with BLoC pattern for content browsing, downloading, and offline reading. The app scrapes nhentai.net with sophisticated anti-detection and Cloudflare bypass mechanisms.

## Architecture Patterns

### Clean Architecture Structure
```
lib/
├── presentation/     # UI Layer (BLoCs, Cubits, Widgets)
├── domain/          # Business Logic (Entities, Use Cases, Repository Interfaces)
├── data/            # Data Layer (Repository Implementations, Data Sources, Models)
├── core/            # Cross-cutting concerns (DI, Config, Utils)
└── services/        # External services (Downloads, PDF, Notifications)
```

**Key Rule**: Dependencies flow inward: `presentation` → `domain` ← `data`. Domain layer has NO dependencies on other layers.

### State Management Strategy
- **BLoCs**: Complex, multi-screen state (ContentBloc, SearchBloc, DownloadBloc)
- **Cubits**: Simple, screen-specific state (DetailCubit, ReaderCubit)
- **App-wide vs Local**: App-wide state in `core/config/multi_bloc_provider_config.dart`, screen-specific providers in individual screens

### Data Flow Pattern
1. **Models extend Entities**: `HistoryModel extends History` with `.fromEntity()`, `.toEntity()`, `.fromMap()`, `.toMap()`
2. **Repository Pattern**: Domain interfaces → Data implementations (e.g., `ContentRepository` → `ContentRepositoryImpl`)
3. **Use Cases**: Single responsibility business logic (`GetContentListUseCase`, `AddToFavoritesUseCase`)

## Critical Development Workflows

### Dependency Injection (GetIt)
All dependencies registered in `core/di/service_locator.dart`:
```dart
// Services → Data Sources → Repositories → Use Cases → BLoCs → Cubits
await setupLocator(); // Must be called before runApp()
```

### Build Commands
```bash
# Development
flutter run

# Optimized release builds (3 APK variants)
./build_optimized.sh          # ARM64, ARM, Universal APKs
./build_release.sh             # Quick single APK

# Testing & Analysis
flutter test                   # Run all tests
flutter analyze               # Static analysis
flutter clean && flutter pub get  # Reset environment
```

### Testing Strategy
- **BLoC Testing**: Use `bloc_test` package with mocked dependencies
- **Repository Testing**: Mock data sources, test offline-first scenarios
- **Integration Testing**: Critical flows like splash → content loading
- **Mock Generation**: `flutter packages pub run build_runner build`

## Project-Specific Conventions

### File Naming & Organization
- **snake_case**: Files, directories, database columns
- **PascalCase**: Classes, types
- **camelCase**: Variables, methods, parameters
- **Exports**: Each layer has `exports.dart` files (e.g., `domain/entities/entities.dart`)

### Import Ordering
```dart
// 1. Flutter packages
import 'package:flutter/material.dart';
// 2. External packages  
import 'package:bloc/bloc.dart';
// 3. Core utilities
import '../../core/utils/logger.dart';
// 4. Domain layer
import '../../domain/entities/content.dart';
// 5. Data layer (only in data layer)
import '../models/content_model.dart';
// 6. Presentation layer (only in presentation)
import '../widgets/content_widget.dart';
```

### Error Handling Patterns
- **Structured Exceptions**: `NetworkException`, `ServerException`, `CloudflareException`
- **BaseCubit**: Consistent error handling across cubits with `handleError()` method
- **BLoC Error States**: Include `canRetry`, `errorType`, `stackTrace` for debugging

## Critical Integration Points

### Web Scraping System
- **Anti-Detection**: `AntiDetection` class rotates user agents, manages request timing
- **Cloudflare Bypass**: `CloudflareBypassNoWebView` handles protection mechanisms  
- **Rate Management**: `RequestRateManager` prevents blocking with intelligent delays
- **Scraping Logic**: `NhentaiScraper` with CSS selectors, handles pagination, tag resolution

### Offline-First Architecture
- **Local Database**: SQLite with 5 simplified tables (favorites, downloads, history, settings, search_queries)
- **Caching Strategy**: Repository layer caches API responses, serves cached data when offline
- **Download System**: Background downloads with `.nomedia` privacy protection
- **Offline Search**: `OfflineSearchCubit` searches downloaded content when network unavailable

### State Persistence
- **Reader Settings**: `ReaderSettingsRepository` persists reading preferences via SharedPreferences
- **Search State**: SearchBloc persists filters and query history to local database
- **Download State**: DownloadBloc tracks progress, resumable downloads via local storage

## Development Gotchas

### BLoC/Cubit Provider Scope
- **App-wide**: Provided in `MultiBlocProviderConfig` (SplashBloc, ContentBloc, NetworkCubit)
- **Screen-specific**: Provided locally (DetailCubit, ReaderCubit) to avoid memory leaks

### Network & Connectivity
- **Always check**: `NetworkCubit` state before making API calls
- **Graceful degradation**: Show cached content when offline, queue operations when network returns
- **Cloudflare handling**: Automatic retry with bypass on detection

### Performance Considerations  
- **Image Loading**: Use `CachedNetworkImage` with custom cache manager
- **Pagination**: ContentBloc implements infinite scroll with `canLoadMore` checks
- **Memory Management**: Dispose ImageProviders, limit concurrent downloads
- **Asset Optimization**: `tags.json.gz` (1.1MB) vs `tags.json` (5MB) - always use compressed

### Android-Specific Features
- **File Privacy**: Downloads use `.nomedia` files to hide from gallery
- **Background Tasks**: `WakelockPlus` prevents sleep during reading
- **PDF Generation**: `PdfService` converts image galleries to PDFs
- **Notifications**: Local notifications for download progress

Remember: This is an Android-only app with adult content (18+). Always test on real devices, especially for download/storage features that behave differently in emulators.