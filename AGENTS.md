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

## Code Style Guidelines
- **Imports**: Group by type: `package:flutter` → external packages → `core/` → `domain/` → `data/` → `presentation/`
- **Naming**: snake_case files, PascalCase classes, camelCase variables/methods, private fields prefixed with `_`
- **Models**: Data models extend domain entities, include `.fromEntity()`, `.toEntity()`, `.fromMap()`, `.toMap()` methods
- **Error Handling**: Use structured exception hierarchy (`NetworkException`, `ServerException`, etc.), categorize errors in BaseCubit
- **Documentation**: Class-level comments for all entities, repositories, and complex business logic
- **Architecture**: Clean Architecture with strict separation: `domain/` → `data/` → `presentation/`
- **State Management**: flutter_bloc for complex state, Cubit for simple local state, extend BaseCubit for error handling
- **Dependency Injection**: All dependencies registered in `core/di/service_locator.dart` using GetIt