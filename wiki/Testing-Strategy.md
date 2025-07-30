# 🧪 Testing Strategy

This document outlines the comprehensive testing strategy used in NhentaiApp to ensure code quality, reliability, and maintainability.

## 📋 Table of Contents
- [Testing Philosophy](#testing-philosophy)
- [Testing Pyramid](#testing-pyramid)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [Widget Testing](#widget-testing)
- [End-to-End Testing](#end-to-end-testing)
- [Test Coverage](#test-coverage)
- [Mocking Strategy](#mocking-strategy)

---

## 🎯 Testing Philosophy

### **Core Principles**
1. **Test-Driven Development (TDD)**: Write tests before implementation when possible
2. **Comprehensive Coverage**: Aim for high test coverage across all layers
3. **Fast Feedback**: Tests should run quickly and provide immediate feedback
4. **Reliable Tests**: Tests should be deterministic and not flaky
5. **Maintainable Tests**: Tests should be easy to read, write, and maintain

### **Testing Goals**
- ✅ Ensure business logic correctness
- ✅ Prevent regressions during refactoring
- ✅ Document expected behavior
- ✅ Enable confident deployments
- ✅ Improve code design through testability

---

## 🏗️ Testing Pyramid

```
                    /\
                   /  \
                  / E2E \     ← Few, slow, expensive
                 /______\
                /        \
               / Widget   \    ← Some, medium speed
              /____________\
             /              \
            /  Integration   \  ← More, faster
           /________________\
          /                  \
         /    Unit Tests      \  ← Many, fast, cheap
        /____________________\
```

### **Test Distribution**
- **Unit Tests**: 70% - Fast, isolated, focused on single units
- **Integration Tests**: 20% - Medium speed, test component interactions
- **Widget Tests**: 8% - UI component testing
- **E2E Tests**: 2% - Full user journey testing

---

## 🔬 Unit Testing

### **What We Test**
- **BLoCs**: State management logic
- **Use Cases**: Business logic
- **Repositories**: Data access logic
- **Models**: Data transformation
- **Utilities**: Helper functions

### **Unit Test Structure**
```dart
// test/presentation/blocs/content/content_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'content_bloc_test.mocks.dart';

@GenerateMocks([GetContentListUseCase, SearchContentUseCase])
void main() {
  group('ContentBloc', () {
    late ContentBloc contentBloc;
    late MockGetContentListUseCase mockGetContentListUseCase;
    late MockSearchContentUseCase mockSearchContentUseCase;

    setUp(() {
      mockGetContentListUseCase = MockGetContentListUseCase();
      mockSearchContentUseCase = MockSearchContentUseCase();
      contentBloc = ContentBloc(
        getContentListUseCase: mockGetContentListUseCase,
        searchContentUseCase: mockSearchContentUseCase,
      );
    });

    tearDown(() {
      contentBloc.close();
    });

    group('ContentLoadEvent', () {
      final mockContentListResult = ContentListResult(
        contents: [mockContent1, mockContent2],
        currentPage: 1,
        totalPages: 5,
        totalCount: 100,
        hasNext: true,
        hasPrevious: false,
      );

      blocTest<ContentBloc, ContentState>(
        'emits [ContentLoading, ContentLoaded] when successful',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockContentListResult);
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          ContentLoaded(
            contents: mockContentListResult.contents,
            currentPage: 1,
            totalPages: 5,
            totalCount: 100,
            hasNext: true,
            hasPrevious: false,
            sortBy: SortOption.newest,
            lastUpdated: isA<DateTime>(),
          ),
        ],
        verify: (_) {
          verify(mockGetContentListUseCase(
            const GetContentListParams(page: 1, sortBy: SortOption.newest)
          )).called(1);
        },
      );

      blocTest<ContentBloc, ContentState>(
        'emits [ContentLoading, ContentError] when use case throws',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenThrow(const NetworkException('No internet connection'));
          return contentBloc;
        },
        act: (bloc) => bloc.add(const ContentLoadEvent()),
        expect: () => [
          const ContentLoading(),
          const ContentError(
            message: 'No internet connection',
            canRetry: true,
            errorType: ContentErrorType.network,
          ),
        ],
      );
    });

    group('ContentLoadMoreEvent', () {
      blocTest<ContentBloc, ContentState>(
        'loads more content when in ContentLoaded state with hasNext=true',
        build: () {
          when(mockGetContentListUseCase(any))
              .thenAnswer((_) async => mockContentListResult);
          return contentBloc;
        },
        seed: () => ContentLoaded(
          contents: [mockContent1],
          currentPage: 1,
          totalPages: 5,
          totalCount: 100,
          hasNext: true,
          hasPrevious: false,
          sortBy: SortOption.newest,
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const ContentLoadMoreEvent()),
        expect: () => [
          isA<ContentLoadingMore>(),
          isA<ContentLoaded>()
              .having((state) => state.contents.length, 'content count', 3)
              .having((state) => state.currentPage, 'current page', 2),
        ],
      );

      blocTest<ContentBloc, ContentState>(
        'does nothing when hasNext is false',
        build: () => contentBloc,
        seed: () => ContentLoaded(
          contents: [mockContent1],
          currentPage: 5,
          totalPages: 5,
          totalCount: 100,
          hasNext: false,
          hasPrevious: true,
          sortBy: SortOption.newest,
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const ContentLoadMoreEvent()),
        expect: () => [],
      );
    });
  });
}
```

### **Use Case Testing**
```dart
// test/domain/usecases/content/get_content_list_usecase_test.dart
void main() {
  group('GetContentListUseCase', () {
    late GetContentListUseCase useCase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      useCase = GetContentListUseCase(mockRepository);
    });

    test('should return content list when repository call is successful', () async {
      // Arrange
      const params = GetContentListParams(page: 1, sortBy: SortOption.newest);
      final expectedResult = ContentListResult(
        contents: [mockContent1, mockContent2],
        currentPage: 1,
        totalPages: 5,
        hasNext: true,
      );
      
      when(mockRepository.getContentList(page: 1, sortBy: SortOption.newest))
          .thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(expectedResult));
      verify(mockRepository.getContentList(page: 1, sortBy: SortOption.newest));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw ContentException when repository throws', () async {
      // Arrange
      const params = GetContentListParams(page: 1, sortBy: SortOption.newest);
      
      when(mockRepository.getContentList(page: 1, sortBy: SortOption.newest))
          .thenThrow(const NetworkException('Network error'));

      // Act & Assert
      expect(
        () => useCase(params),
        throwsA(isA<ContentException>()
            .having((e) => e.message, 'message', contains('Network error'))),
      );
    });

    test('should validate parameters', () async {
      // Arrange
      const invalidParams = GetContentListParams(page: 0, sortBy: SortOption.newest);

      // Act & Assert
      expect(
        () => useCase(invalidParams),
        throwsA(isA<ValidationException>()
            .having((e) => e.message, 'message', contains('Page must be greater than 0'))),
      );
    });
  });
}
```

### **Repository Testing**
```dart
// test/data/repositories/content_repository_impl_test.dart
void main() {
  group('ContentRepositoryImpl', () {
    late ContentRepositoryImpl repository;
    late MockLocalDataSource mockLocalDataSource;
    late MockRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockLocalDataSource = MockLocalDataSource();
      mockRemoteDataSource = MockRemoteDataSource();
      repository = ContentRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
      );
    });

    group('getContentList', () {
      test('should return cached data when available and not expired', () async {
        // Arrange
        final cachedModels = [mockContentModel1, mockContentModel2];
        final expectedEntities = cachedModels.map((m) => m.toEntity()).toList();
        
        when(mockLocalDataSource.getCachedContentList(
          page: 1, 
          sortBy: SortOption.newest
        )).thenAnswer((_) async => cachedModels);

        // Act
        final result = await repository.getContentList(
          page: 1, 
          sortBy: SortOption.newest
        );

        // Assert
        expect(result.contents, equals(expectedEntities));
        verify(mockLocalDataSource.getCachedContentList(
          page: 1, 
          sortBy: SortOption.newest
        ));
        verifyNever(mockRemoteDataSource.getContentList(any, any));
      });

      test('should fetch from remote when cache is expired', () async {
        // Arrange
        final expiredCachedModels = [
          mockContentModel1.copyWith(
            cachedAt: DateTime.now().subtract(const Duration(hours: 7))
          )
        ];
        final remoteModels = [mockContentModel1, mockContentModel2];
        
        when(mockLocalDataSource.getCachedContentList(
          page: 1, 
          sortBy: SortOption.newest
        )).thenAnswer((_) async => expiredCachedModels);
        
        when(mockRemoteDataSource.getContentList(1, SortOption.newest))
            .thenAnswer((_) async => remoteModels);
        
        when(mockLocalDataSource.cacheContentList(remoteModels))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getContentList(
          page: 1, 
          sortBy: SortOption.newest
        );

        // Assert
        expect(result.contents.length, equals(2));
        verify(mockRemoteDataSource.getContentList(1, SortOption.newest));
        verify(mockLocalDataSource.cacheContentList(remoteModels));
      });

      test('should throw ContentException when both cache and remote fail', () async {
        // Arrange
        when(mockLocalDataSource.getCachedContentList(any, any))
            .thenThrow(const CacheException('Cache error'));
        
        when(mockRemoteDataSource.getContentList(any, any))
            .thenThrow(const NetworkException('Network error'));

        // Act & Assert
        expect(
          () => repository.getContentList(page: 1, sortBy: SortOption.newest),
          throwsA(isA<ContentException>()),
        );
      });
    });
  });
}
```

---

## 🔗 Integration Testing

### **BLoC Integration Tests**
```dart
// test/presentation/blocs/content/content_bloc_integration_test.dart
void main() {
  group('ContentBloc Integration Tests', () {
    late ContentBloc contentBloc;
    late ContentRepository contentRepository;
    late LocalDataSource localDataSource;
    late Database database;

    setUp(() async {
      // Setup real database for integration testing
      database = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          await DatabaseHelper.createTables(db);
        },
      );

      localDataSource = LocalDataSourceImpl(database: database);
      final mockRemoteDataSource = MockRemoteDataSource();
      
      contentRepository = ContentRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: mockRemoteDataSource,
      );

      final getContentListUseCase = GetContentListUseCase(contentRepository);
      final searchContentUseCase = SearchContentUseCase(contentRepository);

      contentBloc = ContentBloc(
        getContentListUseCase: getContentListUseCase,
        searchContentUseCase: searchContentUseCase,
      );

      // Setup mock remote data
      when(mockRemoteDataSource.getContentList(any, any))
          .thenAnswer((_) async => mockContentModels);
    });

    tearDown(() async {
      await contentBloc.close();
      await database.close();
    });

    testWidgets('should load content and cache it locally', (tester) async {
      // Act
      contentBloc.add(const ContentLoadEvent());

      // Assert
      await expectLater(
        contentBloc.stream,
        emitsInOrder([
          const ContentLoading(),
          isA<ContentLoaded>()
              .having((state) => state.contents.length, 'content count', 10)
              .having((state) => state.currentPage, 'current page', 1),
        ]),
      );

      // Verify data was cached
      final cachedContent = await localDataSource.getCachedContentList(
        page: 1,
        sortBy: SortOption.newest,
      );
      expect(cachedContent.length, equals(10));
    });

    testWidgets('should load more content with pagination', (tester) async {
      // Setup initial state
      contentBloc.add(const ContentLoadEvent());
      await tester.pumpAndSettle();

      // Act - Load more
      contentBloc.add(const ContentLoadMoreEvent());

      // Assert
      await expectLater(
        contentBloc.stream,
        emitsInOrder([
          isA<ContentLoadingMore>(),
          isA<ContentLoaded>()
              .having((state) => state.contents.length, 'content count', 20)
              .having((state) => state.currentPage, 'current page', 2),
        ]),
      );
    });

    testWidgets('should search content with filters', (tester) async {
      // Arrange
      const searchFilter = SearchFilter(
        query: 'test',
        includeTags: ['tag1', 'tag2'],
        sortBy: SortOption.popular,
      );

      // Act
      contentBloc.add(const ContentSearchEvent(searchFilter));

      // Assert
      await expectLater(
        contentBloc.stream,
        emitsInOrder([
          const ContentLoading(message: 'Searching content...'),
          isA<ContentLoaded>()
              .having((state) => state.searchFilter, 'search filter', searchFilter)
              .having((state) => state.sortBy, 'sort by', SortOption.popular),
        ]),
      );
    });
  });
}
```

### **Database Integration Tests**
```dart
// test/data/datasources/local/local_data_source_integration_test.dart
void main() {
  group('LocalDataSource Integration Tests', () {
    late LocalDataSource dataSource;
    late Database database;

    setUp(() async {
      database = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: (db, version) async {
          await DatabaseHelper.createTables(db);
        },
      );
      dataSource = LocalDataSourceImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('should cache and retrieve content list', () async {
      // Arrange
      final contentModels = [mockContentModel1, mockContentModel2];

      // Act
      await dataSource.cacheContentList(contentModels);
      final retrieved = await dataSource.getCachedContentList(
        page: 1,
        sortBy: SortOption.newest,
      );

      // Assert
      expect(retrieved.length, equals(2));
      expect(retrieved.first.id, equals(mockContentModel1.id));
      expect(retrieved.first.title, equals(mockContentModel1.title));
    });

    test('should handle favorites operations', () async {
      // Arrange
      final content = mockContentModel1;
      await dataSource.cacheContent(content);

      // Act - Add to favorites
      await dataSource.addToFavorites(content.id, categoryId: 1);
      final favorites = await dataSource.getFavorites();

      // Assert
      expect(favorites.length, equals(1));
      expect(favorites.first.id, equals(content.id));

      // Act - Remove from favorites
      await dataSource.removeFromFavorites(content.id);
      final favoritesAfterRemoval = await dataSource.getFavorites();

      // Assert
      expect(favoritesAfterRemoval.length, equals(0));
    });

    test('should manage search history', () async {
      // Act
      await dataSource.addSearchHistory('query1');
      await dataSource.addSearchHistory('query2');
      await dataSource.addSearchHistory('query1'); // Duplicate

      final history = await dataSource.getSearchHistory();

      // Assert
      expect(history.length, equals(2)); // No duplicates
      expect(history.first, equals('query1')); // Most recent first
      expect(history.last, equals('query2'));
    });

    test('should handle tag operations', () async {
      // Arrange
      final tags = [mockTagModel1, mockTagModel2];

      // Act
      await dataSource.cacheTags(tags);
      final retrievedTags = await dataSource.searchTags('tag', limit: 10);

      // Assert
      expect(retrievedTags.length, equals(2));
      expect(retrievedTags.first.name, equals(mockTagModel1.name));
    });
  });
}
```

---

## 🎨 Widget Testing

### **Widget Test Structure**
```dart
// test/presentation/widgets/content_card_test.dart
void main() {
  group('ContentCard Widget Tests', () {
    late Content mockContent;

    setUp(() {
      mockContent = const Content(
        id: '123',
        title: 'Test Content',
        coverUrl: 'https://example.com/cover.jpg',
        tags: [],
        artists: ['Artist 1'],
        language: 'english',
        pageCount: 20,
        uploadDate: DateTime(2024, 1, 1),
      );
    });

    testWidgets('should display content information correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentCard(content: mockContent),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('20 pages'), findsOneWidget);
      expect(find.text('english'), findsOneWidget);
    });

    testWidgets('should handle tap events', (tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentCard(
              content: mockContent,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ContentCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should show loading placeholder when image is loading', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentCard(content: mockContent),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error widget when image fails to load', (tester) async {
      // Arrange
      final contentWithBadImage = mockContent.copyWith(
        coverUrl: 'https://invalid-url.com/image.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentCard(content: contentWithBadImage),
          ),
        ),
      );

      // Wait for image to fail loading
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
```

### **BLoC Widget Integration**
```dart
// test/presentation/pages/home/home_page_test.dart
void main() {
  group('HomePage Widget Tests', () {
    late MockContentBloc mockContentBloc;

    setUp(() {
      mockContentBloc = MockContentBloc();
    });

    testWidgets('should show loading indicator when ContentLoading', (tester) async {
      // Arrange
      when(() => mockContentBloc.state).thenReturn(const ContentLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContentBloc>.value(
            value: mockContentBloc,
            child: const HomePage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading content...'), findsOneWidget);
    });

    testWidgets('should show content grid when ContentLoaded', (tester) async {
      // Arrange
      final mockContents = [mockContent1, mockContent2];
      when(() => mockContentBloc.state).thenReturn(
        ContentLoaded(
          contents: mockContents,
          currentPage: 1,
          totalPages: 5,
          totalCount: 100,
          hasNext: true,
          hasPrevious: false,
          sortBy: SortOption.newest,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContentBloc>.value(
            value: mockContentBloc,
            child: const HomePage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ContentCard), findsNWidgets(2));
    });

    testWidgets('should show error message when ContentError', (tester) async {
      // Arrange
      when(() => mockContentBloc.state).thenReturn(
        const ContentError(
          message: 'Network error',
          canRetry: true,
          errorType: ContentErrorType.network,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContentBloc>.value(
            value: mockContentBloc,
            child: const HomePage(),
          ),
        ),
      );

      // Assert
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should trigger retry when retry button is tapped', (tester) async {
      // Arrange
      when(() => mockContentBloc.state).thenReturn(
        const ContentError(
          message: 'Network error',
          canRetry: true,
          errorType: ContentErrorType.network,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ContentBloc>.value(
            value: mockContentBloc,
            child: const HomePage(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockContentBloc.add(const ContentRetryEvent())).called(1);
    });
  });
}
```

---

## 🎭 Mocking Strategy

### **Mock Generation**
```dart
// test/helpers/test_helpers.dart
import 'package:mockito/annotations.dart';

// Generate mocks for these classes
@GenerateMocks([
  // Data Sources
  LocalDataSource,
  RemoteDataSource,
  
  // Repositories
  ContentRepository,
  UserDataRepository,
  SettingsRepository,
  
  // Use Cases
  GetContentListUseCase,
  SearchContentUseCase,
  AddToFavoritesUseCase,
  
  // External Dependencies
  Database,
  Dio,
  Logger,
  Connectivity,
])
void main() {}
```

### **Mock Data Helpers**
```dart
// test/helpers/mock_data.dart
class MockData {
  static const mockContent1 = Content(
    id: '123',
    title: 'Test Content 1',
    coverUrl: 'https://example.com/cover1.jpg',
    tags: [
      Tag(name: 'tag1', type: 'tag', count: 100, url: '/tag/tag1'),
      Tag(name: 'tag2', type: 'tag', count: 50, url: '/tag/tag2'),
    ],
    artists: ['Artist 1'],
    language: 'english',
    pageCount: 20,
    uploadDate: DateTime(2024, 1, 1),
  );

  static const mockContent2 = Content(
    id: '456',
    title: 'Test Content 2',
    coverUrl: 'https://example.com/cover2.jpg',
    tags: [
      Tag(name: 'tag3', type: 'tag', count: 75, url: '/tag/tag3'),
    ],
    artists: ['Artist 2'],
    language: 'japanese',
    pageCount: 15,
    uploadDate: DateTime(2024, 1, 2),
  );

  static final mockContentListResult = ContentListResult(
    contents: [mockContent1, mockContent2],
    currentPage: 1,
    totalPages: 5,
    totalCount: 100,
    hasNext: true,
    hasPrevious: false,
  );

  static final mockSearchFilter = SearchFilter(
    query: 'test',
    includeTags: ['tag1', 'tag2'],
    excludeTags: ['tag3'],
    artists: ['Artist 1'],
    language: 'english',
    sortBy: SortOption.popular,
    page: 1,
  );
}
```

### **Custom Matchers**
```dart
// test/helpers/custom_matchers.dart
class ContentMatcher extends Matcher {
  final Content expected;

  const ContentMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Content) return false;
    
    return item.id == expected.id &&
           item.title == expected.title &&
           item.coverUrl == expected.coverUrl &&
           listEquals(item.tags, expected.tags) &&
           listEquals(item.artists, expected.artists);
  }

  @override
  Description describe(Description description) {
    return description.add('Content with id: ${expected.id}');
  }
}

Matcher isContent(Content expected) => ContentMatcher(expected);
```

---

## 📊 Test Coverage

### **Coverage Goals**
- **Overall Coverage**: > 90%
- **Unit Tests**: > 95%
- **Integration Tests**: > 80%
- **Widget Tests**: > 85%

### **Coverage Commands**
```bash
# Generate coverage report
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View coverage report
open coverage/html/index.html  # macOS
start coverage/html/index.html  # Windows
xdg-open coverage/html/index.html  # Linux
```

### **Coverage Analysis**
```dart
// test/coverage_test.dart
void main() {
  test('should have high test coverage', () {
    // This test ensures we maintain high coverage
    // Run: flutter test --coverage
    // Check coverage/lcov.info for detailed results
    
    const expectedCoverage = 0.90; // 90%
    // Add actual coverage verification logic here
  });
}
```

---

## 🚀 Continuous Integration

### **GitHub Actions Workflow**
```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [ master, develop ]
  pull_request:
    branches: [ master ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.5.4'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Generate mocks
      run: flutter packages pub run build_runner build
      
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
        
    - name: Check coverage threshold
      run: |
        COVERAGE=$(lcov --summary coverage/lcov.info | grep -E "lines\.*:" | grep -oE "[0-9]+\.[0-9]+%" | head -1 | grep -oE "[0-9]+\.[0-9]+")
        echo "Coverage: $COVERAGE%"
        if (( $(echo "$COVERAGE < 90" | bc -l) )); then
          echo "Coverage is below 90%"
          exit 1
        fi
```

---

## 🔗 Related Documentation

- [Clean Architecture Overview](Clean-Architecture-Overview) - Architecture principles
- [BLoC State Management](BLoC-State-Management) - State management testing
- [Contributing Guidelines](Contributing-Guidelines) - How to contribute tests
- [Performance Optimization](Performance-Optimization) - Performance testing

---

**Next Steps:**
- Learn about [BLoC State Management](BLoC-State-Management) testing
- Explore [Contributing Guidelines](Contributing-Guidelines)
- Check [Performance Optimization](Performance-Optimization) testing strategies

---

**Last Updated**: July 30, 2025  
**Author**: NhentaiApp Development Team