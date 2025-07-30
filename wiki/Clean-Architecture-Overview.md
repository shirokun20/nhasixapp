# 🧱 Clean Architecture Overview

This document provides a comprehensive overview of the Clean Architecture implementation in NhentaiApp.

## 📋 Table of Contents
- [Architecture Principles](#architecture-principles)
- [Layer Structure](#layer-structure)
- [Dependency Flow](#dependency-flow)
- [Implementation Details](#implementation-details)
- [Benefits & Trade-offs](#benefits--trade-offs)

---

## 🎯 Architecture Principles

### **Core Principles**
1. **Independence of Frameworks**: The architecture doesn't depend on specific frameworks
2. **Testability**: Business rules can be tested without UI, database, or external elements
3. **Independence of UI**: UI can change without changing business rules
4. **Independence of Database**: Business rules aren't bound to the database
5. **Independence of External Agencies**: Business rules don't know about the outside world

### **SOLID Principles Applied**
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Objects should be replaceable with instances of their subtypes
- **Interface Segregation**: Many client-specific interfaces are better than one general-purpose interface
- **Dependency Inversion**: Depend on abstractions, not concretions

---

## 🏗️ Layer Structure

```
┌─────────────────────────────────────────┐
│              Presentation               │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │   Widgets   │ │      BLoCs          ││
│  │   Pages     │ │   (State Mgmt)      ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────┐
│               Domain                    │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │  Entities   │ │    Use Cases        ││
│  │ Repositories│ │  (Business Logic)   ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────┐
│                Data                     │
│  ┌─────────────┐ ┌─────────────────────┐│
│  │ Repositories│ │   Data Sources      ││
│  │   Models    │ │ (Remote & Local)    ││
│  └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────┘
```

---

## 📁 Layer Implementation

### **1. Presentation Layer** (`lib/presentation/`)

**Responsibilities:**
- Handle user interactions
- Display data to users
- Manage UI state
- Navigate between screens

**Components:**
```dart
lib/presentation/
├── blocs/           # BLoC state management
│   ├── splash/      # SplashBloc for app initialization
│   ├── content/     # ContentBloc for content management
│   └── search/      # SearchBloc for search functionality
├── pages/           # Screen implementations
│   ├── splash/      # Splash screen
│   ├── home/        # Home screen
│   └── search/      # Search screen
└── widgets/         # Reusable UI components
    ├── content_card.dart
    ├── search_filter.dart
    └── loading_indicator.dart
```

**Key Features:**
- **BLoC Pattern**: Reactive state management with flutter_bloc
- **Responsive UI**: Adapts to different screen sizes
- **Reusable Widgets**: Modular UI components
- **Navigation**: Go Router for declarative routing

### **2. Domain Layer** (`lib/domain/`)

**Responsibilities:**
- Define business entities
- Implement business logic
- Define repository contracts
- Contain use cases

**Components:**
```dart
lib/domain/
├── entities/        # Core business entities
│   ├── content.dart
│   ├── tag.dart
│   └── search_filter.dart
├── repositories/    # Repository interfaces
│   ├── content_repository.dart
│   └── user_data_repository.dart
├── usecases/        # Business use cases
│   ├── content/
│   │   ├── get_content_list_usecase.dart
│   │   └── search_content_usecase.dart
│   └── favorites/
│       ├── add_to_favorites_usecase.dart
│       └── get_favorites_usecase.dart
└── value_objects/   # Value objects for type safety
    ├── content_id.dart
    └── search_query.dart
```

**Key Features:**
- **Pure Dart**: No Flutter dependencies
- **Business Logic**: All business rules centralized
- **Testable**: Easy to unit test
- **Abstractions**: Repository interfaces for dependency inversion

### **3. Data Layer** (`lib/data/`)

**Responsibilities:**
- Implement repository contracts
- Handle data sources
- Manage caching strategy
- Convert between models and entities

**Components:**
```dart
lib/data/
├── datasources/     # Data source implementations
│   ├── local/
│   │   ├── local_data_source.dart
│   │   └── database_helper.dart
│   └── remote/
│       ├── remote_data_source.dart
│       └── anti_detection.dart
├── models/          # Data models (DTOs)
│   ├── content_model.dart
│   ├── tag_model.dart
│   └── search_result_model.dart
└── repositories/    # Repository implementations
    ├── content_repository_impl.dart
    └── user_data_repository_impl.dart
```

**Key Features:**
- **Offline-First**: Local caching with remote fallback
- **Data Transformation**: Models ↔ Entities conversion
- **Error Handling**: Comprehensive error management
- **Web Scraping**: HTML parsing for data extraction

---

## 🔄 Dependency Flow

### **Dependency Rule**
Dependencies point inward. Inner layers don't know about outer layers.

```
Presentation → Domain ← Data
     ↓           ↑        ↑
   BLoCs    Use Cases  Repositories
     ↓           ↑        ↑
   Widgets   Entities   Data Sources
```

### **Dependency Injection**
Using `get_it` for service locator pattern:

```dart
// lib/core/di/service_locator.dart
final GetIt sl = GetIt.instance;

Future<void> setupLocator() async {
  // Data Sources
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(database: sl()),
  );
  
  sl.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(httpClient: sl()),
  );
  
  // Repositories
  sl.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  
  // Use Cases
  sl.registerLazySingleton(() => GetContentListUseCase(sl()));
  sl.registerLazySingleton(() => SearchContentUseCase(sl()));
  
  // BLoCs
  sl.registerFactory(() => ContentBloc(
    getContentListUseCase: sl(),
    searchContentUseCase: sl(),
  ));
}
```

---

## 🎯 Implementation Details

### **Entity Example**
```dart
// lib/domain/entities/content.dart
class Content extends Equatable {
  final String id;
  final String title;
  final String coverUrl;
  final List<Tag> tags;
  final List<String> artists;
  final String language;
  final int pageCount;
  final DateTime uploadDate;

  const Content({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.tags,
    required this.artists,
    required this.language,
    required this.pageCount,
    required this.uploadDate,
  });

  @override
  List<Object?> get props => [
    id, title, coverUrl, tags, artists, 
    language, pageCount, uploadDate
  ];
}
```

### **Use Case Example**
```dart
// lib/domain/usecases/content/get_content_list_usecase.dart
class GetContentListUseCase {
  final ContentRepository repository;

  GetContentListUseCase(this.repository);

  Future<ContentListResult> call(GetContentListParams params) async {
    try {
      return await repository.getContentList(
        page: params.page,
        sortBy: params.sortBy,
      );
    } catch (e) {
      throw ContentException('Failed to get content list: $e');
    }
  }
}

class GetContentListParams extends Equatable {
  final int page;
  final SortOption sortBy;

  const GetContentListParams({
    required this.page,
    required this.sortBy,
  });

  @override
  List<Object?> get props => [page, sortBy];
}
```

### **Repository Implementation**
```dart
// lib/data/repositories/content_repository_impl.dart
class ContentRepositoryImpl implements ContentRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;

  ContentRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<ContentListResult> getContentList({
    required int page,
    required SortOption sortBy,
  }) async {
    try {
      // Try local cache first
      final cachedResult = await localDataSource.getCachedContentList(
        page: page,
        sortBy: sortBy,
      );
      
      if (cachedResult.isNotEmpty && !_isCacheExpired(cachedResult)) {
        return ContentListResult(
          contents: cachedResult.map((model) => model.toEntity()).toList(),
          currentPage: page,
          hasNext: cachedResult.length >= 25,
        );
      }

      // Fetch from remote
      final remoteResult = await remoteDataSource.getContentList(
        page: page,
        sortBy: sortBy,
      );

      // Cache the result
      await localDataSource.cacheContentList(remoteResult);

      return ContentListResult(
        contents: remoteResult.map((model) => model.toEntity()).toList(),
        currentPage: page,
        hasNext: remoteResult.length >= 25,
      );
    } catch (e) {
      throw ContentException('Failed to get content list: $e');
    }
  }

  bool _isCacheExpired(List<ContentModel> cachedData) {
    if (cachedData.isEmpty) return true;
    
    final cacheTime = cachedData.first.cachedAt;
    final now = DateTime.now();
    const cacheExpiry = Duration(hours: 6);
    
    return now.difference(cacheTime) > cacheExpiry;
  }
}
```

### **BLoC Implementation**
```dart
// lib/presentation/blocs/content/content_bloc.dart
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final GetContentListUseCase getContentListUseCase;
  final SearchContentUseCase searchContentUseCase;

  ContentBloc({
    required this.getContentListUseCase,
    required this.searchContentUseCase,
  }) : super(const ContentInitial()) {
    on<ContentLoadEvent>(_onContentLoad);
    on<ContentLoadMoreEvent>(_onContentLoadMore);
    on<ContentSearchEvent>(_onContentSearch);
  }

  Future<void> _onContentLoad(
    ContentLoadEvent event,
    Emitter<ContentState> emit,
  ) async {
    try {
      emit(const ContentLoading());

      final params = GetContentListParams(
        page: 1,
        sortBy: event.sortBy,
      );

      final result = await getContentListUseCase(params);

      emit(ContentLoaded(
        contents: result.contents,
        currentPage: result.currentPage,
        hasNext: result.hasNext,
        sortBy: event.sortBy,
      ));
    } catch (e) {
      emit(ContentError(message: e.toString()));
    }
  }
}
```

---

## ✅ Benefits & Trade-offs

### **Benefits**
1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Clear separation of concerns
3. **Flexibility**: Easy to change implementations
4. **Scalability**: Can handle growing complexity
5. **Team Collaboration**: Different teams can work on different layers

### **Trade-offs**
1. **Initial Complexity**: More setup required
2. **Learning Curve**: Developers need to understand the architecture
3. **Boilerplate Code**: More files and interfaces
4. **Over-engineering**: Might be overkill for simple apps

### **When to Use Clean Architecture**
✅ **Good for:**
- Large, complex applications
- Long-term maintenance projects
- Team development
- Apps requiring high testability
- Business-critical applications

❌ **Avoid for:**
- Simple, short-term projects
- Prototypes or MVPs
- Single-developer projects
- Apps with minimal business logic

---

## 🧪 Testing Strategy

### **Layer-Specific Testing**
```dart
// Domain Layer Testing
test('should return content list when repository call is successful', () async {
  // Arrange
  final mockRepository = MockContentRepository();
  final useCase = GetContentListUseCase(mockRepository);
  final params = GetContentListParams(page: 1, sortBy: SortOption.newest);
  
  when(mockRepository.getContentList(page: 1, sortBy: SortOption.newest))
      .thenAnswer((_) async => mockContentListResult);

  // Act
  final result = await useCase(params);

  // Assert
  expect(result, equals(mockContentListResult));
  verify(mockRepository.getContentList(page: 1, sortBy: SortOption.newest));
});

// Presentation Layer Testing
blocTest<ContentBloc, ContentState>(
  'emits [ContentLoading, ContentLoaded] when ContentLoadEvent is added',
  build: () {
    when(mockGetContentListUseCase(any))
        .thenAnswer((_) async => mockContentListResult);
    return ContentBloc(getContentListUseCase: mockGetContentListUseCase);
  },
  act: (bloc) => bloc.add(ContentLoadEvent()),
  expect: () => [
    const ContentLoading(),
    ContentLoaded(
      contents: mockContentListResult.contents,
      currentPage: 1,
      hasNext: true,
      sortBy: SortOption.newest,
    ),
  ],
);
```

---

## 📚 Further Reading

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [BLoC Pattern Documentation](https://bloclibrary.dev/)
- [Dependency Injection in Flutter](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)

---

**Next Steps:**
- Learn about [BLoC State Management](BLoC-State-Management)
- Explore [Data Layer Implementation](Data-Layer-Implementation)
- Understand [Testing Strategy](Testing-Strategy)

---

**Last Updated**: July 30, 2025  
**Author**: NhentaiApp Development Team