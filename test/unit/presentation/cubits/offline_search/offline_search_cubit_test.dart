import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockLogger extends Mock implements Logger {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late OfflineSearchCubit cubit;
  late MockOfflineContentManager mockOfflineContentManager;
  late MockUserDataRepository mockUserDataRepository;
  late MockLogger mockLogger;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockOfflineContentManager = MockOfflineContentManager();
    mockUserDataRepository = MockUserDataRepository();
    mockLogger = MockLogger();
    mockPrefs = MockSharedPreferences();

    cubit = OfflineSearchCubit(
      offlineContentManager: mockOfflineContentManager,
      userDataRepository: mockUserDataRepository,
      logger: mockLogger,
      prefs: mockPrefs,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('OfflineSearchCubit Pagination', () {
    const tContentId = '123';
    const tDownloadStatus = DownloadStatus(
      contentId: tContentId,
      state: DownloadState.completed,
      title: 'Test Title',
      totalPages: 10,
      downloadPath: '/path/to/download',
      fileSize: 1024,
    );
    final tDownloadList = [tDownloadStatus];

    test('initial state is OfflineSearchInitial', () {
      expect(cubit.state, isA<OfflineSearchInitial>());
    });

    blocTest<OfflineSearchCubit, OfflineSearchState>(
      'getAllOfflineContent should load first page correctly',
      build: () {
        when(() => mockUserDataRepository.getAllDownloads(
              state: DownloadState.completed,
              limit: 20,
              offset: 0,
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => tDownloadList);

        when(() => mockUserDataRepository.getDownloadsCount(
              state: DownloadState.completed,
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => 1);

        when(() => mockOfflineContentManager.getOfflineFirstImagePath(
              any(),
              downloadPath: any(named: 'downloadPath'),
            )).thenAnswer((_) async => '/path/to/image.jpg');

        return cubit;
      },
      act: (cubit) => cubit.getAllOfflineContent(),
      expect: () => [
        isA<OfflineSearchLoading>(),
        isA<OfflineSearchLoaded>()
            .having((s) => s.results.length, 'results length', 1)
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<OfflineSearchCubit, OfflineSearchState>(
      'loadMoreContent should append items when hasMore is true',
      build: () {
        // Mock initial state as loaded
        final initialContent = Content(
          id: 'initial',
          title: 'Initial',
          coverUrl: '',
          sourceId: 'nhentai',
          tags: [],
          artists: [],
          characters: [],
          parodies: [],
          groups: [],
          language: '',
          pageCount: 0,
          imageUrls: [],
          uploadDate: DateTime.now(),
          favorites: 0,
        );

        // Setup mocks for loadMore call
        when(() => mockUserDataRepository.getAllDownloads(
              state: DownloadState.completed,
              limit: 20,
              offset: 1, // Offset is 1 because we have 1 item already
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => tDownloadList);

        when(() => mockUserDataRepository.getDownloadsCount(
              state: DownloadState.completed,
              sourceId: any(named: 'sourceId'),
            )).thenAnswer((_) async => 2); // Total 2 items

        when(() => mockOfflineContentManager.getOfflineFirstImagePath(
              any(),
              downloadPath: any(named: 'downloadPath'),
            )).thenAnswer((_) async => '/path/to/image.jpg');

        cubit.emit(OfflineSearchLoaded(
          query: '',
          results: [initialContent],
          totalResults: 2,
          currentPage: 1,
          hasMore: true,
          isLoadingMore: false,
        ));

        return cubit;
      },
      act: (cubit) => cubit.loadMoreContent(),
      expect: () => [
        isA<OfflineSearchLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<OfflineSearchLoaded>()
            .having((s) => s.results.length, 'results length', 2)
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.hasMore, 'hasMore', false)
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });
}
