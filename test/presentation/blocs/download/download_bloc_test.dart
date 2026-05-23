import 'dart:async'; // Add async import for StreamController
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kuron_core/kuron_core.dart'
    show ChapterData, Content, ContentSourceRegistry;
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/content/get_chapter_images_usecase.dart';
import 'package:nhasixapp/domain/usecases/downloads/downloads_usecases.dart';
import 'package:nhasixapp/domain/repositories/repositories.dart'
    hide DownloadSettings;
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';
import 'package:nhasixapp/services/notification_service.dart';
import 'package:nhasixapp/services/pdf_conversion_queue_manager.dart';
import 'package:nhasixapp/services/pdf_conversion_service.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/services/download_manager.dart'; // Import DownloadManager
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockDownloadContentUseCase extends Mock
    implements DownloadContentUseCase {}

class MockGetContentDetailUseCase extends Mock
    implements GetContentDetailUseCase {}

class MockGetChapterImagesUseCase extends Mock
    implements GetChapterImagesUseCase {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockLogger extends Mock implements Logger {}

class MockConnectivity extends Mock implements Connectivity {}

class MockNotificationService extends Mock implements NotificationService {}

class MockPdfConversionService extends Mock implements PdfConversionService {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class MockDownloadManager extends Mock
    implements DownloadManager {} // Add MockDownloadManager

class MockOfflineContentManager extends Mock implements OfflineContentManager {}

class MockPdfConversionQueueManager extends Mock
    implements PdfConversionQueueManager {} // Add MockDownloadManager

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('DownloadBloc Completion Logic', () {
    late DownloadBloc downloadBloc;
    late MockDownloadContentUseCase mockDownloadContentUseCase;
    late MockGetContentDetailUseCase mockGetContentDetailUseCase;
    late MockGetChapterImagesUseCase mockGetChapterImagesUseCase;
    late MockUserDataRepository mockRepo;
    late MockConnectivity mockConnectivity;
    late MockNotificationService mockNotificationService;
    late MockPdfConversionService mockPdfConversionService;
    late MockRemoteConfigService mockRemoteConfigService;
    late MockDownloadManager mockDownloadManager; // Add MockDownloadManager
    late MockOfflineContentManager mockOfflineContentManager;
    late MockPdfConversionQueueManager mockPdfConversionQueueManager;
    late MockLogger mockLogger;

    // Stream controller for DownloadManager progress
    late StreamController<DownloadProgressUpdate> progressController;

    const testContentId = '123';
    const testDownloadStatus = DownloadStatus(
      contentId: testContentId,
      state: DownloadState.downloading,
      downloadedPages: 10,
      totalPages: 10,
      title: 'Test Manga',
      sourceId: 'src',
    );

    setUp(() async {
      mockDownloadContentUseCase = MockDownloadContentUseCase();
      mockGetContentDetailUseCase = MockGetContentDetailUseCase();
      mockGetChapterImagesUseCase = MockGetChapterImagesUseCase();
      mockRepo = MockUserDataRepository();
      mockConnectivity = MockConnectivity();
      mockNotificationService = MockNotificationService();
      mockPdfConversionService = MockPdfConversionService();
      mockRemoteConfigService = MockRemoteConfigService();
      mockDownloadManager = MockDownloadManager();
      mockOfflineContentManager = MockOfflineContentManager();
      mockPdfConversionQueueManager = MockPdfConversionQueueManager();
      mockLogger = MockLogger();
      progressController = StreamController<DownloadProgressUpdate>.broadcast();

      registerFallbackValue(
        GetContentDetailParams.fromString('fallback-content-id'),
      );
      registerFallbackValue(
        GetChapterImagesParams.fromString('fallback-chapter-id'),
      );
      registerFallbackValue(
        DownloadContentParams.immediate(
          Content(
            id: 'fallback-content-id',
            sourceId: 'fallback-source',
            title: 'Fallback Content',
            coverUrl: '',
            tags: const [],
            artists: const [],
            characters: const [],
            parodies: const [],
            groups: const [],
            language: 'en',
            pageCount: 1,
            imageUrls: const ['https://example.com/page-1.jpg'],
            uploadDate: DateTime(2026, 1, 1),
          ),
          savePath: '/tmp/fallback-content',
        ),
      );

      // Stub DownloadManager properties
      when(() => mockDownloadManager.progressStream)
          .thenAnswer((_) => progressController.stream);
      when(() => mockDownloadManager.unregisterTask(any())).thenReturn(null);

      // Register fallback values
      registerFallbackValue(testDownloadStatus);

      // Default mocks
      // Note: mocktail matches named arguments by matching the value passed to the name
      when(() => mockRepo.getAllDownloads(limit: any(named: 'limit')))
          .thenAnswer((_) async => [testDownloadStatus]);
      when(() => mockRepo.getUserPreferences()).thenAnswer(
          (_) async => const UserPreferences()); // Use default constructor
      when(() => mockRepo.saveDownloadStatus(any()))
          .thenAnswer((_) async => {});
      when(() => mockRepo.getDownloadStatus(any()))
          .thenAnswer((_) async => testDownloadStatus);

      // Notification service mocks
      when(() => mockNotificationService.initialize())
          .thenAnswer((_) async => {});
      when(() => mockNotificationService.setCallbacks(
            onDownloadPause: any(named: 'onDownloadPause'),
            onDownloadResume: any(named: 'onDownloadResume'),
            onDownloadCancel: any(named: 'onDownloadCancel'),
            onDownloadRetry: any(named: 'onDownloadRetry'),
            onPdfRetry: any(named: 'onPdfRetry'),
            onOpenDownload: any(named: 'onOpenDownload'),
            onNavigateToDownloads: any(named: 'onNavigateToDownloads'),
          )).thenReturn(null);

      when(() => mockNotificationService.showDownloadCompleted(
            contentId: any(named: 'contentId'),
            title: any(named: 'title'),
            downloadPath: any(named: 'downloadPath'),
          )).thenAnswer((_) async => {});
      when(() => mockNotificationService.showDownloadStarted(
            contentId: any(named: 'contentId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => {});
      when(() => mockOfflineContentManager
              .reconcileChapterMetadataForCompletedDownload(
            contentId: any(named: 'contentId'),
            contentPath: any(named: 'contentPath'),
          )).thenAnswer((_) async => {});
      when(() => mockRemoteConfigService.getRawConfig(any())).thenReturn({
        'network': {
          'headers': {
            'User-Agent': 'UnitTest',
            'Referer': 'https://e-hentai.org/',
          },
        },
      });

      await getIt.reset();
      getIt.registerSingleton<RemoteConfigService>(mockRemoteConfigService);
      getIt.registerSingleton<ContentSourceRegistry>(ContentSourceRegistry());

      downloadBloc = DownloadBloc(
        downloadContentUseCase: mockDownloadContentUseCase,
        getContentDetailUseCase: mockGetContentDetailUseCase,
        getChapterImagesUseCase: mockGetChapterImagesUseCase,
        userDataRepository: mockRepo,
        offlineContentManager: mockOfflineContentManager,
        logger: mockLogger,
        connectivity: mockConnectivity,
        notificationService: mockNotificationService,
        pdfConversionService: mockPdfConversionService,
        remoteConfigService: mockRemoteConfigService,
        downloadManager: mockDownloadManager,
        pdfConversionQueueManager: mockPdfConversionQueueManager,
      );

      // Initialize to get into Loaded state
      // Instead of async setup, we will use seed in blocTest
    });

    tearDown(() async {
      await progressController.close();
      await downloadBloc.close();
      await getIt.reset();
    });

    blocTest<DownloadBloc, DownloadBlocState>(
      'emits completed state and saves to DB when DownloadCompletedEvent is added',
      build: () => downloadBloc,
      seed: () => DownloadLoaded(
        downloads: [testDownloadStatus],
        settings: DownloadSettings.defaultSettings(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const DownloadCompletedEvent(testContentId)),
      verify: (bloc) {
        // Verify saving to DB
        verify(() => mockRepo.saveDownloadStatus(any(
            that: predicate<DownloadStatus>((d) =>
                d.contentId == testContentId &&
                d.state == DownloadState.completed &&
                d.endTime != null)))).called(1);

        verify(() => mockOfflineContentManager
                .reconcileChapterMetadataForCompletedDownload(
              contentId: testContentId,
              contentPath: any(named: 'contentPath'),
            )).called(1);

        // Verify notification
        verify(() => mockNotificationService.showDownloadCompleted(
              contentId: testContentId,
              title: any(named: 'title'),
              downloadPath: any(named: 'downloadPath'),
            )).called(1);
      },
      expect: () => [
        isA<DownloadLoaded>().having(
          (state) => state.downloads
              .firstWhere((d) => d.contentId == testContentId)
              .state,
          'download state',
          DownloadState.completed,
        ),
        isA<DownloadLoaded>(),
      ],
    );

    blocTest<DownloadBloc, DownloadBlocState>(
      'ignores regressive progress updates from retried workers',
      build: () => downloadBloc,
      seed: () => DownloadLoaded(
        downloads: const [
          DownloadStatus(
            contentId: testContentId,
            state: DownloadState.downloading,
            downloadedPages: 4,
            totalPages: 8,
            title: 'Test Manga',
            sourceId: 'src',
          ),
        ],
        settings: DownloadSettings.defaultSettings(),
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const DownloadProgressUpdateEvent(
        contentId: testContentId,
        downloadedPages: 2,
        totalPages: 8,
      )),
      expect: () => <DownloadBlocState>[],
      verify: (_) {
        verifyNever(() => mockRepo.saveDownloadStatus(any(
              that: predicate<DownloadStatus>(
                (d) => d.contentId == testContentId && d.downloadedPages == 2,
              ),
            )));
      },
    );

    blocTest<DownloadBloc, DownloadBlocState>(
      'downloads only the selected EHentai part instead of traversing next parts',
      build: () => downloadBloc,
      seed: () => DownloadLoaded(
        downloads: const [
          DownloadStatus(
            contentId: '__ehpart__:123456:tokenabc:0',
            state: DownloadState.queued,
            totalPages: 0,
            title: 'Part 1',
            sourceId: 'ehentai',
            downloadPath: '/tmp/ehentai-part-1',
          ),
        ],
        settings: const DownloadSettings(
          enableNotifications: false,
          customStorageRoot: '/tmp/downloads',
        ),
        lastUpdated: DateTime(2026, 5, 23),
      ),
      setUp: () {
        when(() => mockGetContentDetailUseCase.call(any())).thenAnswer(
          (_) async => Content(
            id: '__ehpart__:123456:tokenabc:0',
            sourceId: 'ehentai',
            title: 'Gallery Title',
            coverUrl: 'https://example.com/cover.jpg',
            tags: const [],
            artists: const [],
            characters: const [],
            parodies: const [],
            groups: const [],
            language: 'en',
            pageCount: 0,
            imageUrls: const [],
            uploadDate: DateTime(2026, 5, 23),
            url: 'https://e-hentai.org/g/123456/tokenabc/',
          ),
        );
        when(() => mockGetChapterImagesUseCase.call(any()))
            .thenAnswer((inv) async {
          final params =
              inv.positionalArguments.single as GetChapterImagesParams;
          final chapterId = params.chapterId.value;
          if (chapterId == '__ehpart__:123456:tokenabc:0') {
            return const ChapterData(
              images: [
                'https://img.e-hentai.org/part-1-page-1.jpg',
                'https://img.e-hentai.org/part-1-page-2.jpg',
              ],
              nextChapterId: '__ehpart__:123456:tokenabc:1',
              nextChapterTitle: 'Part 2',
            );
          }
          if (chapterId == '__ehpart__:123456:tokenabc:1') {
            return const ChapterData(
              images: ['https://img.e-hentai.org/part-2-page-1.jpg'],
            );
          }
          throw StateError('Unexpected chapter id: $chapterId');
        });
        when(() => mockDownloadContentUseCase.call(any())).thenAnswer(
          (_) async => const DownloadStatus(
            contentId: '__ehpart__:123456:tokenabc:0',
            state: DownloadState.downloading,
            totalPages: 2,
            title: 'Part 1',
            sourceId: 'ehentai',
          ),
        );
      },
      act: (bloc) =>
          bloc.add(const DownloadStartEvent('__ehpart__:123456:tokenabc:0')),
      verify: (_) {
        verify(
          () => mockGetChapterImagesUseCase.call(
            any(
              that: predicate<GetChapterImagesParams>(
                (params) =>
                    params.chapterId.value == '__ehpart__:123456:tokenabc:0' &&
                    params.sourceId == 'ehentai',
              ),
            ),
          ),
        ).called(1);
        verifyNever(
          () => mockGetChapterImagesUseCase.call(
            any(
              that: predicate<GetChapterImagesParams>(
                (params) =>
                    params.chapterId.value == '__ehpart__:123456:tokenabc:1',
              ),
            ),
          ),
        );

        final captured = verify(
          () => mockDownloadContentUseCase.call(captureAny()),
        ).captured.single as DownloadContentParams;

        expect(captured.content.imageUrls, const [
          'https://img.e-hentai.org/part-1-page-1.jpg',
          'https://img.e-hentai.org/part-1-page-2.jpg',
        ]);
        expect(captured.content.pageCount, 2);
        expect(captured.content.title, 'Part 1');

        verify(
          () => mockRepo.saveDownloadStatus(
            any(
              that: predicate<DownloadStatus>(
                (status) =>
                    status.contentId == '__ehpart__:123456:tokenabc:0' &&
                    status.totalPages == 2,
              ),
            ),
          ),
        ).called(1);
      },
    );
  });
}
