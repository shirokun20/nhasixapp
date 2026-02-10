import 'dart:async'; // Add async import for StreamController
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/usecases/content/content_usecases.dart';
import 'package:nhasixapp/domain/usecases/content/get_chapter_images_usecase.dart';
import 'package:nhasixapp/domain/usecases/downloads/downloads_usecases.dart';
import 'package:nhasixapp/domain/repositories/repositories.dart'
    hide DownloadSettings;
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';
import 'package:nhasixapp/services/notification_service.dart';
import 'package:nhasixapp/services/pdf_conversion_queue_manager.dart';
import 'package:nhasixapp/services/pdf_conversion_service.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/services/download_manager.dart'; // Import DownloadManager
import 'package:connectivity_plus/connectivity_plus.dart';

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

class MockPdfConversionQueueManager extends Mock
    implements PdfConversionQueueManager {} // Add MockDownloadManager

void main() {
  group('DownloadBloc Completion Logic', () {
    late DownloadBloc downloadBloc;
    late MockUserDataRepository mockRepo;
    late MockNotificationService mockNotificationService;
    late MockDownloadManager mockDownloadManager; // Add MockDownloadManager
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
      mockRepo = MockUserDataRepository();
      mockNotificationService = MockNotificationService();
      mockDownloadManager = MockDownloadManager();
      mockLogger = MockLogger();
      progressController = StreamController<DownloadProgressUpdate>.broadcast();

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
          (_) async => UserPreferences()); // Use default constructor
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

      downloadBloc = DownloadBloc(
        downloadContentUseCase: MockDownloadContentUseCase(),
        getContentDetailUseCase: MockGetContentDetailUseCase(),
        getChapterImagesUseCase: MockGetChapterImagesUseCase(),
        userDataRepository: mockRepo,
        logger: mockLogger,
        connectivity: MockConnectivity(),
        notificationService: mockNotificationService,
        pdfConversionService: MockPdfConversionService(),
        remoteConfigService: MockRemoteConfigService(),
        downloadManager: mockDownloadManager,
        pdfConversionQueueManager:
            MockPdfConversionQueueManager(), // Inject MockDownloadManager
      );

      // Initialize to get into Loaded state
      // Instead of async setup, we will use seed in blocTest
    });

    tearDown(() {
      progressController.close();
      downloadBloc.close();
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
      ],
    );
  });
}
