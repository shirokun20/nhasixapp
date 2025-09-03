# Flutter NhasixApp - Agent Guidelines

## Build/Test Commands
- `flutter clean && flutter pub get` - Clean and install dependencies
- `flutter run --debug` - Run in debug mode
- `flutter test` - Run all tests
- `flutter test test/specific_test.dart` - Run single test file
- `flutter analyze` - Run static analysis/linting
- `flutter build apk --release` - Build release APK
- `./build_release.sh` - Build release with custom naming
- `dart run build_runner build` - Generate freezed/json_serializable code

## Architecture & Layer Structure
- **Clean Architecture**: Strict separation: `domain/` (entities, repositories, usecases) → `data/` (models, datasources, repositories_impl) → `presentation/` (blocs, cubits, pages, widgets)
- **Dependency Injection**: All dependencies registered in `core/di/service_locator.dart` using GetIt
- **State Management**: flutter_bloc for complex state, Cubit for simple local state, extend BaseCubit for error handling
- **Services Layer**: Standalone services in `services/` for cross-cutting concerns (download, notifications, PDF, etc.)

## Code Style Guidelines
- **Imports**: Group by type: `package:flutter` → external packages → `core/` → `domain/` → `data/` → `presentation/`
- **Naming**: snake_case files, PascalCase classes, camelCase variables/methods, private fields prefixed with `_`
- **Models**: Data models extend domain entities, include `.fromEntity()`, `.toEntity()`, `.fromMap()`, `.toMap()` methods
- **Error Handling**: Use structured exception hierarchy (`NetworkException`, `ServerException`, etc.), categorize errors in BaseCubit
- **Documentation**: Class-level comments for all entities, repositories, and complex business logic

## UseCase Patterns
- **Base Classes**: Extend `UseCase<ReturnType, Params>`, `NoParamsUseCase<ReturnType>`, or stream variants
- **Parameters**: Create Params classes extending `UseCaseParams` with `Equatable`, include helper methods like `nextPage()`
- **Results**: Use `UseCaseResult<T>` wrapper with `.success()`, `.failure()`, functional methods (`.map()`, `.fold()`)
- **Pagination**: Use `PaginatedResult<T>` for paginated endpoints with `.hasNext`, `.hasPrevious` flags
- **Validation**: Validate parameters in use case `.call()` method, throw `ValidationException` for invalid inputs

## State Management Patterns  
- **BaseCubit**: All Cubits extend BaseCubit with Logger injection, use `.handleError()`, `.logInfo()`, error categorization
- **BLoC Structure**: Use part files for events/states (`part 'filename_event.dart'`), require Logger in constructor
- **Error States**: Include error type classification (network, server, cloudflare, rateLimit, parsing), implement retry logic
- **Progress Tracking**: Use structured progress objects with percentage, status, and cancel tokens for long operations

## Data Layer Conventions
- **Models**: Extend domain entities, add cache timestamps, implement `.isCacheExpired()` for cache management
- **Repositories**: Abstract interfaces in domain, implementations in data layer with both remote and local data sources
- **HTTP Client**: Use singleton `HttpClientManager.instance` with proper headers, timeouts, and lifecycle management
- **Database**: Models include `.fromMap()` and `.toMap()` for SQLite serialization, handle JSON encoding for lists

## Key Patterns
- **Entities**: Use `Equatable` for value comparison, immutable data classes
- **Dependency Registration**: Register services as singletons, BLoCs/Cubits as factories in service locator
- **File Organization**: Group related files in feature folders, use barrel exports (`entities.dart`, `repositories.dart`)
- **Cache Management**: Include cache timestamps, expiration checks, and cache invalidation strategies
- **Resource Management**: Proper disposal in BLoCs/Cubits, cancel tokens for HTTP requests, cleanup services