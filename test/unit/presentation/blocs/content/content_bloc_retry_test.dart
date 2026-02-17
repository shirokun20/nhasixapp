import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/repositories.dart';
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';

class MockGetContentListUseCase extends Mock implements GetContentListUseCase {}

class MockSearchContentUseCase extends Mock implements SearchContentUseCase {}

class MockGetRandomContentUseCase extends Mock
    implements GetRandomContentUseCase {}

class MockContentRepository extends Mock implements ContentRepository {}

class MockLogger extends Mock implements Logger {}

void main() {
  late ContentBloc contentBloc;
  late MockGetContentListUseCase mockGetContentListUseCase;
  late MockSearchContentUseCase mockSearchContentUseCase;
  late MockGetRandomContentUseCase mockGetRandomContentUseCase;
  late MockContentRepository mockContentRepository;
  late MockLogger mockLogger;

  setUp(() {
    mockGetContentListUseCase = MockGetContentListUseCase();
    mockSearchContentUseCase = MockSearchContentUseCase();
    mockGetRandomContentUseCase = MockGetRandomContentUseCase();
    mockContentRepository = MockContentRepository();
    mockLogger = MockLogger();

    contentBloc = ContentBloc(
      getContentListUseCase: mockGetContentListUseCase,
      searchContentUseCase: mockSearchContentUseCase,
      getRandomContentUseCase: mockGetRandomContentUseCase,
      contentRepository: mockContentRepository,
      logger: mockLogger,
    );

    registerFallbackValue(const GetContentListParams());
  });

  tearDown(() {
    contentBloc.close();
  });

  group('ContentBloc Retry Logic', () {
    const tPage = 3;
    const tSort = SortOption.newest;

    test('should extract page 3 from ContentEmpty and reload page 3', () async {
      // Arrange: Set initial state to ContentEmpty with page 3
      contentBloc.emit(const ContentEmpty(
        message: 'No content',
        currentPage: tPage,
        sortBy: tSort,
      ));

      // Mock successful reload
      when(() => mockGetContentListUseCase(any()))
          .thenAnswer((_) async => const ContentListResult(
                contents: [],
                currentPage: tPage,
                totalPages: 5,
                totalCount: 0,
                hasNext: true,
                hasPrevious: true,
              ));

      // Act
      contentBloc.add(const ContentRetryEvent());

      // Wait for event processing
      await Future.delayed(Duration.zero);

      // Assert
      // Verify that GetContentListUseCase was called with page 3
      verify(() => mockGetContentListUseCase(any(
          that: isA<GetContentListParams>()
              .having((p) => p.page, 'page', tPage)
              .having((p) => p.sortBy, 'sortBy', tSort)))).called(1);
    });
  });
}
