# Clean Architecture Skill

## 📐 Architecture Overview

This project follows **Clean Architecture** principles with Flutter-specific adaptations.

### Layer Structure

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── constants/           # App-wide constants
│   ├── di/                  # Dependency Injection (GetIt)
│   ├── network/             # HTTP, DNS, connectivity
│   ├── utils/               # Utilities, extensions, helpers
│   └── theme/               # Theme configuration
│
├── domain/                  # Business logic layer (PURE DART)
│   ├── entities/            # Core business objects
│   ├── repositories/        # Repository interfaces (abstract)
│   └── usecases/            # Business use cases
│
├── data/                    # Data layer
│   ├── datasources/         # Remote/Local data sources
│   ├── models/              # Data models (extend entities)
│   └── repositories/        # Repository implementations
│
└── presentation/            # UI layer
    ├── screens/             # Page/screens
    ├── widgets/             # Reusable widgets
    └── cubits/              # State management (BLoC/Cubit)
```

---

## 🏗️ Core Principles

### 1. Dependency Rule
**Source code dependencies ONLY point inward:**
- Presentation → Domain (use cases, entities)
- Data → Domain (repositories, entities)
- Domain → **NO external dependencies** (pure Dart)

### 2. Entity Pattern
Entities are pure Dart classes with NO Flutter dependencies:

```dart
// domain/entities/comic.dart
class Comic extends Equatable {
  final String id;
  final String title;
  final String? coverImage;
  final DateTime createdAt;

  const Comic({
    required this.id,
    required this.title,
    this.coverImage,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, coverImage, createdAt];
}
```

### 3. Model Pattern
Models extend entities and implement serialization:

```dart
// data/models/comic_model.dart
class ComicModel extends Comic {
  const ComicModel({
    required super.id,
    required super.title,
    super.coverImage,
    required super.createdAt,
  });

  factory ComicModel.fromEntity(Comic entity) => ComicModel(
        id: entity.id,
        title: entity.title,
        coverImage: entity.coverImage,
        createdAt: entity.createdAt,
      );

  Comic toEntity() => Comic(
        id: id,
        title: title,
        coverImage: coverImage,
        createdAt: createdAt,
      );

  factory ComicModel.fromMap(Map<String, dynamic> map) => ComicModel(
        id: map['id'] as String,
        title: map['title'] as String,
        coverImage: map['cover_image'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'cover_image': coverImage,
        'created_at': createdAt.toIso8601String(),
      };
}
```

### 4. Repository Pattern

**Domain Layer (Interface):**
```dart
// domain/repositories/comic_repository.dart
abstract class ComicRepository {
  Future<List<Comic>> getComics({int page = 1});
  Future<Comic> getComicById(String id);
  Future<void> addToFavorites(Comic comic);
}
```

**Data Layer (Implementation):**
```dart
// data/repositories/comic_repository_impl.dart
class ComicRepositoryImpl implements ComicRepository {
  final ComicRemoteDataSource remoteDataSource;
  final ComicLocalDataSource localDataSource;

  ComicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Comic>> getComics({int page = 1}) async {
    // Try cache first
    final cached = await localDataSource.getComics(page: page);
    if (cached.isNotEmpty) return cached;

    // Fallback to remote
    final comics = await remoteDataSource.getComics(page: page);
    await localDataSource.cacheComics(comics);
    return comics;
  }
}
```

### 5. Use Case Pattern

```dart
// domain/usecases/get_comics.dart
class GetComics implements UseCase<List<Comic>, GetComicsParams> {
  final ComicRepository repository;

  GetComics(this.repository);

  @override
  Future<List<Comic>> call(GetComicsParams params) async {
    return repository.getComics(page: params.page);
  }
}

// Value object for parameters
class GetComicsParams extends Equatable {
  final int page;

  const GetComicsParams({this.page = 1});

  @override
  List<Object> get props => [page];
}
```

---

## 📦 Dependency Injection

All DI is configured in `lib/core/di/service_locator.dart`:

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // 1. Register external instances first (Logger, SharedPreferences)
  getIt.registerLazySingleton<Logger>(() => Logger());
  getIt.registerLazySingleton<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );

  // 2. Register services in dependency order
  getIt.registerLazySingleton<ComicRemoteDataSource>(
    () => ComicRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<ComicLocalDataSource>(
    () => ComicLocalDataSourceImpl(database: getIt<Database>()),
  );

  // 3. Register repositories
  getIt.registerLazySingleton<ComicRepository>(
    () => ComicRepositoryImpl(
      remoteDataSource: getIt<ComicRemoteDataSource>(),
      localDataSource: getIt<ComicLocalDataSource>(),
    ),
  );

  // 4. Register use cases
  getIt.registerLazySingleton<GetComics>(() => GetComics(getIt<ComicRepository>()));

  // 5. Register cubits
  getIt.registerFactory<ComicCubit>(
    () => ComicCubit(getComics: getIt<GetComics>()),
  );
}
```

---

## 🎯 Best Practices

### DO ✅
- Keep domain layer PURE (no Flutter, no HTTP, no database)
- Use `Equatable` for value equality
- Prefix implementation classes with their layer (e.g., `ComicRepositoryImpl`)
- Use `freezed` for immutable models when possible
- Handle errors at data layer, present at presentation layer
- Use `Either<Failure, Success>` pattern for error handling (optional)

### DON'T ❌
- Import Flutter in domain layer
- Pass models across layer boundaries (use entities)
- Put business logic in presentation layer
- Directly call HTTP/database from UI
- Use singletons instead of DI

---

## 🔧 File Naming Conventions

| Layer | Pattern | Example |
|-------|---------|---------|
| Entities | `snake_case.dart` | `comic.dart`, `user.dart` |
| Models | `snake_case_model.dart` | `comic_model.dart` |
| Repositories | `snake_case_repository.dart` | `comic_repository.dart` |
| Use Cases | `verb_noun.dart` | `get_comics.dart`, `add_to_favorites.dart` |
| Data Sources | `snake_case_data_source.dart` | `comic_remote_data_source.dart` |
| Cubits | `snake_case_cubit.dart` | `comic_cubit.dart` |
| Screens | `snake_case_screen.dart` | `comic_list_screen.dart` |

---

## 📝 Code Templates

### New Feature Checklist
- [ ] Create entity in `domain/entities/`
- [ ] Create model in `data/models/` (extend entity)
- [ ] Create repository interface in `domain/repositories/`
- [ ] Create repository implementation in `data/repositories/`
- [ ] Create data sources in `data/datasources/`
- [ ] Create use cases in `domain/usecases/`
- [ ] Create cubit in `presentation/cubits/`
- [ ] Create screen in `presentation/screens/`
- [ ] Register in `core/di/service_locator.dart`
- [ ] Write tests for domain and data layers

---

## 🧪 Testing Strategy

| Layer | Test Type | Tools |
|-------|-----------|-------|
| Domain | Unit tests | `mocktail`, `bloc_test` |
| Data | Unit + Integration | `mocktail`, `mockito` |
| Presentation | Widget tests | `flutter_test`, `mocktail` |

Example domain test:
```dart
// test/domain/usecases/get_comics_test.dart
group('GetComics', () {
  late GetComics useCase;
  late MockComicRepository mockRepository;

  setUp(() {
    mockRepository = MockComicRepository();
    useCase = GetComics(mockRepository);
  });

  test('should get comics from repository', () async {
    // Arrange
    when(() => mockRepository.getComics(page: 1))
        .thenAnswer((_) async => [tComic]);

    // Act
    final result = await useCase(const GetComicsParams(page: 1));

    // Assert
    expect(result, [tComic]);
    verify(() => mockRepository.getComics(page: 1)).called(1);
  });
});
```

---

## 📚 References

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Starter](https://github.com/ResoCoder/flutter-clean-architecture)
- [GetIt Package](https://pub.dev/packages/get_it)
- [Equatable Package](https://pub.dev/packages/equatable)
