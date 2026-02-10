import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/remote_config_service.dart';

import 'package:kuron_crotpedia/kuron_crotpedia.dart';
import 'package:kuron_nhentai/kuron_nhentai.dart';
import 'package:kuron_komiktap/kuron_komiktap.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/entities/download_task.dart';
import '../../../domain/usecases/downloads/downloads_usecases.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/usecases/content/get_chapter_images_usecase.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../services/native_pdf_reader_service.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/notification_service.dart';
import '../../../services/download_manager.dart';
import '../../../services/pdf_conversion_service.dart';
import '../../../services/pdf_conversion_queue_manager.dart';
import '../../../core/utils/download_storage_utils.dart';
import '../../../core/utils/storage_settings.dart';
import '../../widgets/content_list_widget.dart';

import 'package:nhasixapp/services/workers/background_download_utils.dart';
// import 'package:nhasixapp/services/workers/download_worker.dart'; // REMOVED
import '../../../services/native_download_service.dart';

part 'download_event.dart';
part 'download_state.dart';

/// BLoC for managing downloads with queue system and concurrent downloads
class DownloadBloc extends Bloc<DownloadEvent, DownloadBlocState> {
  DownloadBloc({
    required DownloadContentUseCase downloadContentUseCase,
    required GetContentDetailUseCase getContentDetailUseCase,
    required GetChapterImagesUseCase getChapterImagesUseCase,
    required UserDataRepository userDataRepository,
    required Logger logger,
    required Connectivity connectivity,
    required NotificationService notificationService,
    required PdfConversionService pdfConversionService,
    required PdfConversionQueueManager pdfConversionQueueManager,
    required RemoteConfigService remoteConfigService,
    AppLocalizations? appLocalizations,
    CrotpediaAuthManager?
        crotpediaAuthManager, // NEW: Optional for cookie extraction
    DownloadManager? downloadManager, // NEW: Optional for testing
  })  : _downloadContentUseCase = downloadContentUseCase,
        _getContentDetailUseCase = getContentDetailUseCase,
        _getChapterImagesUseCase = getChapterImagesUseCase,
        _userDataRepository = userDataRepository,
        _logger = logger,
        _connectivity = connectivity,
        _notificationService = notificationService,
        // _pdfConversionService = pdfConversionService,
        _pdfConversionQueueManager = pdfConversionQueueManager,
        _remoteConfigService = remoteConfigService,
        _appLocalizations = appLocalizations,
        _crotpediaAuthManager = crotpediaAuthManager,
        _downloadManager = downloadManager ??
            DownloadManager(), // Use injected or default singleton
        super(const DownloadInitial()) {
    // Register event handlers
    on<DownloadInitializeEvent>(_onInitialize);
    on<DownloadQueueEvent>(_onQueue);
    on<DownloadRangeEvent>(_onRange);
    on<DownloadStartEvent>(_onStart);
    on<DownloadPauseEvent>(_onPause);
    on<DownloadCancelEvent>(_onCancel);
    on<DownloadRetryEvent>(_onRetry);
    on<DownloadResumeEvent>(_onResume);
    on<DownloadRemoveEvent>(_onRemove);
    on<DownloadRefreshEvent>(_onRefresh);
    on<DownloadProgressUpdateEvent>(_onProgressUpdate);
    on<DownloadSettingsUpdateEvent>(_onSettingsUpdate);
    on<DownloadPauseAllEvent>(_onPauseAll);
    on<DownloadResumeAllEvent>(_onResumeAll);
    on<DownloadCancelAllEvent>(_onCancelAll);
    on<DownloadClearCompletedEvent>(_onClearCompleted);
    on<DownloadConvertToPdfEvent>(_onConvertToPdf);
    on<DownloadOpenContentEvent>(_onOpenContent);
    on<DownloadCleanupStorageEvent>(_onCleanupStorage);
    on<DownloadExportEvent>(_onExport);
    on<DownloadToggleSelectionModeEvent>(_onToggleSelectionMode);
    on<DownloadSelectItemEvent>(_onSelectItem);
    on<DownloadSelectAllEvent>(_onSelectAll);
    on<DownloadClearSelectionEvent>(_onClearSelection);
    on<DownloadBulkDeleteEvent>(_onBulkDelete);
    on<DownloadCompletedEvent>(_onCompleted);

    // Initialize notifications (checks existing permission, doesn't request)
    // If permission not granted, service will be initialized later when user grants permission
    _notificationService.initialize();

    // Setup notification action callbacks
    _setupNotificationCallbacks();

    // Initialize progress stream subscription
    _initializeProgressStream();
  }

  final DownloadContentUseCase _downloadContentUseCase;
  final GetContentDetailUseCase _getContentDetailUseCase;
  final GetChapterImagesUseCase _getChapterImagesUseCase;
  final UserDataRepository _userDataRepository;
  final Logger _logger;
  final Connectivity _connectivity;
  final NotificationService _notificationService;
  // final PdfConversionService _pdfConversionService;
  final PdfConversionQueueManager _pdfConversionQueueManager;
  final RemoteConfigService _remoteConfigService;
  final AppLocalizations? _appLocalizations;
  final CrotpediaAuthManager? _crotpediaAuthManager;
  final DownloadManager
      _downloadManager; // Use instance variable instead of singleton directly

  /// Helper to generate fallback URL based on source
  String _generateFallbackUrl(String? sourceId, String contentId) {
    if (sourceId == SourceType.nhentai.id ||
        (sourceId == null && contentId.length <= 6)) {
      return NhentaiUrlBuilder.buildContentUrl(contentId);
    } else if (sourceId == SourceType.crotpedia.id) {
      // Check if it's a chapter slug
      if (contentId.contains('chapter')) {
        return CrotpediaUrlBuilder.chapterReader(contentId);
      }
      return CrotpediaUrlBuilder.seriesDetail(contentId);
    } else if (sourceId == SourceType.komiktap.id) {
      // Check if it's a chapter slug
      if (contentId.contains('chapter')) {
        return KomiktapUrlBuilder.buildChapterUrlFromSlug(contentId);
      }
      return KomiktapUrlBuilder.buildSeriesDetailUrl(contentId);
    }
    return ''; // Unknown source
  }

  /// Helper method to get localized string with fallback
  String _getLocalizedString(
      String Function(AppLocalizations) getter, String fallback) {
    if (_appLocalizations != null) {
      return getter(_appLocalizations);
    }
    return fallback;
  }

  // Internal state
  DownloadSettings _settings = DownloadSettings.defaultSettings();
  final Map<String, DownloadTask> _activeTasks = {};
  StreamSubscription<DownloadProgressUpdate>? _progressSubscription;

  /// Initialize progress stream subscription for real-time updates
  void _initializeProgressStream() {
    _progressSubscription = _downloadManager.progressStream.listen(
      (update) {
        _logger.d('DownloadBloc: Received progress update: $update');

        // Check if this is a completion event (special marker)
        if (update.downloadedPages == -1 && update.totalPages == -1) {
          _logger.d(
              'DownloadBloc: Received completion event for ${update.contentId}');
          add(DownloadCompletedEvent(update.contentId));
        } else {
          // Regular progress update
          add(DownloadProgressUpdateEvent(
            contentId: update.contentId,
            downloadedPages: update.downloadedPages,
            totalPages: update.totalPages,
            downloadSpeed: update.downloadSpeed,
            estimatedTimeRemaining: update.estimatedTimeRemaining,
          ));
        }
      },
      onError: (error) {
        _logger.e('DownloadBloc: Progress stream error: $error');
      },
    );

    _logger.i('DownloadBloc: Progress stream subscription initialized');
  }

  /// Setup notification action callbacks to handle user interactions from notifications
  void _setupNotificationCallbacks() {
    _notificationService.setCallbacks(
      onDownloadPause: (contentId) {
        _logger.i('NotificationAction: Pause requested for $contentId');
        add(DownloadPauseEvent(contentId));
      },
      onDownloadResume: (contentId) {
        _logger.i('NotificationAction: Resume requested for $contentId');
        add(DownloadResumeEvent(contentId));
      },
      onDownloadCancel: (contentId) {
        _logger.i('NotificationAction: Cancel requested for $contentId');
        add(DownloadCancelEvent(contentId));
      },
      onDownloadRetry: (contentId) {
        _logger.i('NotificationAction: Retry requested for $contentId');
        add(DownloadRetryEvent(contentId));
      },
      onPdfRetry: (contentId) {
        _logger.i('NotificationAction: PDF retry requested for $contentId');
        // Get content and retry PDF conversion
        _retryPdfConversion(contentId);
      },
      onOpenDownload: (contentId) {
        _logger.i('NotificationAction: Open download requested for $contentId');
        // Open the downloaded content folder or file
        _openDownloadedContent(contentId);
      },
      onNavigateToDownloads: (contentId) {
        _logger.i(
            'NotificationAction: Navigate to downloads requested for $contentId');
        // Navigate to downloads screen - this should be handled by the UI layer
        // For now, just log and potentially show the downloads list via BLoC state
        add(const DownloadRefreshEvent());
      },
    );
    _logger.i('DownloadBloc: Notification callbacks configured');
  }

  /// Initialize download manager
  Future<void> _onInitialize(
    DownloadInitializeEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    try {
      _logger.i('DownloadBloc: Initializing download manager');
      emit(const DownloadInitializing());

      // Load existing downloads
      final downloads = await _userDataRepository.getAllDownloads(
          limit: AppLimits.maxBatchSize);

      // Load settings (use existing settings)
      final userPrefs = await _userDataRepository.getUserPreferences();
      final remoteMaxConcurrent =
          _remoteConfigService.appConfig?.limits?.maxConcurrentDownloads ?? 3;

      final customRoot = await StorageSettings.getCustomRootPath();
      _logger.i('DownloadBloc: Custom storage root loaded: $customRoot');
      debugPrint(
          '📁 DOWNLOAD_BLOC: Loading customStorageRoot from StorageSettings');
      debugPrint('📁 DOWNLOAD_BLOC: customRoot value: $customRoot');

      _settings = DownloadSettings(
        maxConcurrentDownloads: userPrefs.maxConcurrentDownloads != 3
            ? userPrefs.maxConcurrentDownloads
            : remoteMaxConcurrent,
        imageQuality: userPrefs.imageQuality,
        // Load from UserPreferences (with fallback to defaults)
        autoRetry: userPrefs.autoRetry,
        retryAttempts: userPrefs.retryAttempts,
        retryDelay: userPrefs.retryDelay,
        timeoutDuration: userPrefs.timeoutDuration,
        enableNotifications: userPrefs.enableNotifications,
        wifiOnly: userPrefs.wifiOnly,
        customStorageRoot: customRoot,
      );
      debugPrint(
          '📁 DOWNLOAD_BLOC: DownloadSettings created with customStorageRoot: ${_settings.customStorageRoot}');

      emit(DownloadLoaded(
        downloads: downloads,
        settings: _settings,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('DownloadBloc: Initialized with ${downloads.length} downloads');

      // 1. ZOMBIE STATE FIX: Reset any downloads stuck in "downloading" state
      // This happens if the app was killed while downloading.
      final correctedDownloads = <DownloadStatus>[];
      for (final download in downloads) {
        if (download.state == DownloadState.downloading) {
          _logger.w(
              'DownloadBloc: Found zombie download stuck in downloading state: ${download.contentId}. Resetting to Paused.');
          // Reset to paused so user can resume later
          final fixedDownload = download.copyWith(
            state: DownloadState.paused,
            error: 'Download interrupted (App Restart)',
          );
          // Save correction to DB
          await _userDataRepository.saveDownloadStatus(fixedDownload);
          correctedDownloads.add(fixedDownload);
        } else {
          correctedDownloads.add(download);
        }
      }

      // Re-emit loaded state with corrected list
      emit(DownloadLoaded(
        downloads: correctedDownloads,
        settings: _settings,
        lastUpdated: DateTime.now(),
      ));

      // Process queue - auto-start any queued downloads if needed
      await _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error initializing',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToInitializeDownloadManager(e.toString()),
          'Failed to initialize download manager: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        stackTrace: stackTrace,
      ));
    }
  }

  /// Process the download queue, starting downloads if possible
  Future<void> _processQueue() async {
    if (state is! DownloadLoaded) return;
    final currentState = state as DownloadLoaded;

    try {
      // Get queued and active downloads
      final queuedDownloads = currentState.queuedDownloads;
      final activeDownloads = currentState.activeDownloads;

      // Check if we can start more downloads
      if (queuedDownloads.isEmpty) {
        _logger.d('DownloadBloc: No queued downloads to process');
        return;
      }

      // Get max concurrent downloads from settings
      final maxConcurrent = currentState.settings.maxConcurrentDownloads;

      // Check if we're at the limit
      if (activeDownloads.length >= maxConcurrent) {
        _logger.d(
            'DownloadBloc: Already at max concurrent downloads: $maxConcurrent');
        return;
      }

      // Sort queued downloads by priority (implement priority later)
      final sortedQueue = List<DownloadStatus>.from(queuedDownloads);

      // Calculate how many new downloads we can start
      final availableSlots = maxConcurrent - activeDownloads.length;
      final toStart = sortedQueue.take(availableSlots).toList();

      _logger
          .i('DownloadBloc: Starting ${toStart.length} downloads from queue');

      // Start each download
      for (final download in toStart) {
        add(DownloadStartEvent(download.contentId));
      }
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error processing queue',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Queue a new download
  Future<void> _onQueue(
    DownloadQueueEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger.w('DownloadBloc: Cannot queue download - not in loaded state');
      return;
    }

    try {
      _logger.i('DownloadBloc: Queuing download for ${event.content.id}');

      // STRICT CHECK: Verify storage root is set before queuing
      if (currentState.settings.customStorageRoot == null ||
          currentState.settings.customStorageRoot!.isEmpty) {
        _logger.e('❌ Download blocked: No custom storage root selected.');
        emit(DownloadError(
          message:
              'Storage location not set. Please select a folder in Settings.',
          errorType: DownloadErrorType.storage,
          previousState: currentState,
        ));
        return;
      }

      // Check if this is chapter-based content (Crotpedia manga)
      // We now ALLOW this, but we need to ensure the UI handles it correctly
      // (e.g. by downloading individual chapters if they are passed as content)
      /*
      if (event.content.imageUrls.isEmpty &&
          event.content.chapters != null &&
          event.content.chapters!.isNotEmpty) {
        _logger.w(
            'DownloadBloc: Cannot download chapter-based content ${event.content.id}');
        
        // ... Error emission logic removed ...
        return;
      }
      */

      // Validate that content has downloadable images
      // Exception: For chapter-based content (Crotpedia), images may be fetched lazily during download
      // We check for slug-based IDs which indicate chapter content that will have images fetched during _onStart
      final isSlugBasedContent = !RegExp(r'^\d+$').hasMatch(event.content.id);

      if (event.content.imageUrls.isEmpty &&
          event.content.pageCount == 0 &&
          !isSlugBasedContent) {
        _logger.w(
            'DownloadBloc: Content ${event.content.id} has no downloadable images');

        emit(DownloadError(
          message: 'This content has no downloadable images.',
          errorType: DownloadErrorType.unknown,
          previousState: currentState,
        ));
        return;
      }

      // Log if this is slug-based content that will fetch images later
      if (isSlugBasedContent && event.content.imageUrls.isEmpty) {
        _logger.i(
            'DownloadBloc: Slug-based content ${event.content.id} - images will be fetched during download');
      }
      // Check if already exists
      final existingDownload = currentState.downloads
          .where((d) => d.contentId == event.content.id)
          .firstOrNull;

      if (existingDownload != null) {
        _logger.w(
            'DownloadBloc: Content ${event.content.id} already in download list');

        // If download failed or was cancelled, retry it
        if (existingDownload.canRetry) {
          _logger.i(
              'DownloadBloc: Retrying existing download for ${event.content.id}');
          add(DownloadRetryEvent(event.content.id));
        }

        return;
      }

      // Create download status with range support
      final downloadStatus = DownloadStatus.initial(
        event.content.id,
        event.content.pageCount,
        startPage: event.startPage,
        endPage: event.endPage,
        title: event.content.title,
        coverUrl: event.content.coverUrl,
        sourceId: event.content.sourceId,
      );

      // Save to database
      await _userDataRepository.saveDownloadStatus(downloadStatus);

      // Update state with new download added
      final updatedDownloads = [...currentState.downloads, downloadStatus];
      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Send notification (Flutter-side)
      if (currentState.settings.enableNotifications) {
        final title = event.content.title;
        final rangeText = downloadStatus.isRangeDownload
            ? ' (Pages ${downloadStatus.startPage}-${downloadStatus.endPage})'
            : '';
        await _notificationService.showDownloadStarted(
          contentId: event.content.id,
          title: '$title$rangeText',
        );
      }

      _logger.i('DownloadBloc: Queued download for ${event.content.id}');

      // Check if we can start downloading right away
      await _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error queuing download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToQueueDownload(e.toString()),
          'Failed to queue download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Queue a range download (specific pages)
  Future<void> _onRange(
    DownloadRangeEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger
          .w('DownloadBloc: Cannot queue range download - not in loaded state');
      return;
    }

    try {
      _logger.i(
          'DownloadBloc: Queuing range download for ${event.content.id} (pages ${event.startPage}-${event.endPage})');

      // STRICT CHECK: Verify storage root is set before queuing
      if (currentState.settings.customStorageRoot == null ||
          currentState.settings.customStorageRoot!.isEmpty) {
        _logger.e('❌ Range download blocked: No custom storage root selected.');
        emit(DownloadError(
          message:
              'Storage location not set. Please select a folder in Settings.',
          errorType: DownloadErrorType.storage,
          previousState: currentState,
        ));
        return;
      }

      // Validate page range
      if (!event.isValidRange) {
        throw ArgumentError(
            'Invalid page range: ${event.startPage}-${event.endPage} (total: ${event.content.pageCount})');
      }

      // Check if already exists
      final existingDownload = currentState.downloads
          .where((d) => d.contentId == event.content.id)
          .firstOrNull;

      if (existingDownload != null) {
        _logger.w(
            'DownloadBloc: Content ${event.content.id} already in download list');

        // If download failed or was cancelled, retry it
        if (existingDownload.canRetry) {
          _logger.i(
              'DownloadBloc: Retrying existing download for ${event.content.id}');
          add(DownloadRetryEvent(event.content.id));
        }

        return;
      }

      // Create download status for range download
      final downloadStatus = DownloadStatus.initial(
        event.content.id,
        event.content.pageCount,
        startPage: event.startPage,
        endPage: event.endPage,
        title: event.content.title,
        coverUrl: event.content.coverUrl,
        sourceId: event.content.sourceId,
      );

      // Save to database
      await _userDataRepository.saveDownloadStatus(downloadStatus);

      // Update state with new download added
      final updatedDownloads = [...currentState.downloads, downloadStatus];
      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Send notification with range info (Flutter-side)
      if (currentState.settings.enableNotifications) {
        final title = event.content.title;
        final rangeText = ' (Pages ${event.startPage}-${event.endPage})';
        await _notificationService.showDownloadStarted(
          contentId: event.content.id,
          title: '$title$rangeText',
        );
      }

      _logger.i('DownloadBloc: Queued range download for ${event.content.id}');

      // Check if we can start downloading right away
      await _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error queuing range download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToQueueRangeDownload(e.toString()),
          'Failed to queue range download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Start/resume a download
  Future<void> _onStart(
    DownloadStartEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger.w('DownloadBloc: Cannot start download - not in loaded state');
      return;
    }

    try {
      _logger.i('DownloadBloc: Starting download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null) {
        _logger.w('DownloadBloc: Download not found: ${event.contentId}');
        return;
      }

      // Skip if already downloading
      if (download.isInProgress) {
        _logger.i(
            'DownloadBloc: Download already in progress: ${event.contentId}');
        return;
      }

      // Check WiFi requirement before starting download
      if (currentState.settings.wifiOnly) {
        final connectivityResults = await _connectivity.checkConnectivity();
        final connectivityResult = connectivityResults.isNotEmpty
            ? connectivityResults.first
            : ConnectivityResult.none;

        if (connectivityResult != ConnectivityResult.wifi) {
          _logger.i(
              'DownloadBloc: WiFi required but not connected, queuing download for ${event.contentId}');

          final waitingDownload = download.copyWith(
            state: DownloadState.queued,
            error: _getLocalizedString(
              (l10n) => l10n.waitingForWifiConnection,
              'Waiting for WiFi connection',
            ),
          );

          await _userDataRepository.saveDownloadStatus(waitingDownload);
          add(const DownloadRefreshEvent());
          return;
        }
      }

      // Update status to downloading
      var updatedDownload = DownloadStatus(
        contentId: download.contentId,
        state: DownloadState.downloading,
        downloadedPages: download.downloadedPages,
        totalPages: download.totalPages,
        startTime: DateTime.now(), // New start time
        endTime: download.endTime,
        error: null, // Clear error
        downloadPath: download.downloadPath,
        fileSize: download.fileSize,
        speed: download.speed,
        retryCount: download.retryCount,
        startPage: download.startPage,
        endPage: download.endPage,
        title: download.title,
        sourceId: download.sourceId,
        coverUrl: download.coverUrl,
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // Update state immediately to show downloading
      final updatedDownloads = currentState.downloads
          .map((d) => d.contentId == event.contentId ? updatedDownload : d)
          .toList();

      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Get content details for download
      late Content content;
      try {
        content = await _getContentDetailUseCase.call(
          GetContentDetailParams.fromString(
            event.contentId,
            sourceId: updatedDownload.sourceId,
          ),
        );
      } catch (e) {
        // getContentDetail failed - fallback
        _logger.w(
            'DownloadBloc: getContentDetail failed for ${event.contentId}, will try getChapterImages fallback: $e');
        // Generate fallback URL based on source
        final fallbackUrl =
            _generateFallbackUrl(updatedDownload.sourceId, event.contentId);

        content = Content(
          id: event.contentId,
          title: event.contentId, // simplified title
          coverUrl: '',
          pageCount: 0,
          imageUrls: const [],
          tags: const [],
          artists: const [],
          characters: const [],
          parodies: const [],
          groups: const [],
          language: '', // Default to likely language
          url: fallbackUrl, // Populate URL
          uploadDate: DateTime.now(),
          favorites: 0,
          sourceId: updatedDownload.sourceId ?? SourceType.crotpedia.id,
        );
      }

      // Fallback chapter image logic
      if (content.imageUrls.isEmpty) {
        _logger.i(
            'DownloadBloc: Content has empty images, trying getChapterImages fallback for ${event.contentId}');
        try {
          final chapterImages = await _getChapterImagesUseCase.call(
            GetChapterImagesParams.fromString(event.contentId),
          );

          if (chapterImages.isNotEmpty) {
            content = content.copyWith(
              imageUrls: chapterImages,
              pageCount: chapterImages.length,
              // If URL is still empty after chapter fetch (unlikely but possible), try again
              url: (content.url?.isEmpty ?? true)
                  ? _generateFallbackUrl(
                      updatedDownload.sourceId, event.contentId)
                  : content.url,
            );

            // Update total pages
            updatedDownload = updatedDownload.copyWith(
              totalPages: chapterImages.length,
              sourceId: updatedDownload.sourceId ?? SourceType.crotpedia.id,
            );
            await _userDataRepository.saveDownloadStatus(updatedDownload);

            // Update state again
            final latestState = state;
            if (latestState is DownloadLoaded) {
              emit(latestState.copyWith(
                downloads: latestState.downloads
                    .map((d) =>
                        d.contentId == event.contentId ? updatedDownload : d)
                    .toList(),
                lastUpdated: DateTime.now(),
              ));
            }
          }
        } catch (e) {
          _logger.w('Fallback chapter image fetch failed: $e');
        }
      }

      // Create download task
      final task = DownloadTask(
        contentId: event.contentId,
        title: content.title,
      );
      _activeTasks[event.contentId] = task;

      // Register task with DownloadManager
      DownloadManager().registerTask(task);

      if (currentState.settings.enableNotifications) {
        await _notificationService.showDownloadStarted(
          contentId: event.contentId,
          title: content.title,
        );
      }

      // Prepare download path
      String? savePath;
      try {
        // Check if we already have a path for this download (e.g. retry/resume)
        if (updatedDownload.downloadPath != null &&
            updatedDownload.downloadPath!.isNotEmpty) {
          savePath = updatedDownload.downloadPath;
          _logger.d('Using existing download path: $savePath');
        } else if (currentState.settings.customStorageRoot != null &&
            currentState.settings.customStorageRoot!.isNotEmpty) {
          final baseDownloadPath = currentState.settings.customStorageRoot!;

          // Get backup folder name from AppConfig via RemoteConfigService (default: "nhasix")
          final remoteConfigService = getIt<RemoteConfigService>();
          final backupFolderName =
              remoteConfigService.appConfig?.storage?.folders?.backup ??
                  'nhasix';

          // Build path: [Root]/[backupFolderName]/[sourceId]/[contentId]
          savePath = path.join(baseDownloadPath, backupFolderName,
              content.sourceId, event.contentId);
        } else {
          // STRICT REQUIREMENT: If customStorageRoot is empty, DO NOT ALLOW DOWNLOAD.
          _logger.e('❌ Download blocked: No custom storage root selected.');

          // Remove from active tasks and cleanup immediately
          _activeTasks.remove(event.contentId);
          DownloadManager()
              .unregisterTask(event.contentId); // Ensure manager knows

          emit(DownloadError(
            message:
                'Storage location not set. Please select a folder in Settings.',
            // You might want a specific error type here if you have one,
            // or check string in UI to show DownloadStorageErrorWidget
            errorType: DownloadErrorType.storage,
            previousState: currentState,
          ));
          return;
        }

        // Only save resume state if we have a path, or rely on native worker's own resume capability
        if (savePath != null) {
          await BackgroundDownloadUtils.saveResumeState(
            event.contentId,
            downloadUrl:
                content.imageUrls.isNotEmpty ? content.imageUrls.first : '',
            savePath: savePath,
            title: content.title,
            totalImages: content.pageCount,
          );
        }
      } catch (e) {
        _logger.w('Failed to save resume state for worker: $e');
      }

      // NEW: Extract cookies for Crotpedia protected content
      Map<String, String>? cookies;

      // DEBUG: Log source and auth manager state
      _logger.i('🔍 Download sourceId: ${content.sourceId}');
      _logger.i('🔍 AuthManager null?: ${_crotpediaAuthManager == null}');

      if (content.sourceId == SourceType.crotpedia.id &&
          _crotpediaAuthManager != null) {
        _logger.i('✅ Entering cookie extraction block');
        try {
          cookies = await _crotpediaAuthManager.getCookiesForDomain(
              'https://crotpedia.net'); // Match actual baseUrl (.net not .com)

          _logger.i('🍪 Cookie Count: ${cookies.length}');
          _logger.i('🍪 Cookie Keys: ${cookies.keys.join(", ")}');

          if (cookies.isNotEmpty) {
            _logger.i(
                'DownloadBloc: Extracted ${cookies.length} cookies for protected download');
          }
        } catch (e) {
          _logger.w('DownloadBloc: Failed to extract cookies: $e');
          // Continue without cookies - may fail for protected content
        }
      } else {
        _logger.w(
            '❌ Skipped cookie extraction - sourceId: ${content.sourceId}, authManager null: ${_crotpediaAuthManager == null}');
      }

      // Start actual download
      final downloadParams = DownloadContentParams.immediate(
        content,
        imageQuality: currentState.settings.imageQuality,
        timeoutDuration: currentState.settings.timeoutDuration,
        startPage: updatedDownload.startPage,
        endPage: updatedDownload.endPage,
        cookies: cookies, // NEW: Pass cookies
        savePath: savePath, // NEW: Pass savePath
        enableNotifications:
            currentState.settings.enableNotifications, // NEW: Pass settings
      );

      // Call use case (Fire and Forget)
      // The result returned is just the initial status (Downloading), or Failed if immediate error
      final result = await _downloadContentUseCase.call(downloadParams);

      // Check for immediate failure during start
      if (result.isFailed) {
        _logger.w('Download failed immediately to start: ${result.error}');
        await _handleDownloadFailure(
            event.contentId, result.error ?? 'Unknown error', null, emit);
        return;
      }

      // If successful, the native download is running in background.
      // Progress/Completion will be handled by _onProgressUpdate via DownloadManager stream.

      // Cleanup task references (since we rely on stream)
      _activeTasks.remove(event.contentId);
      _downloadManager.unregisterTask(event.contentId);

      await _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error starting download',
          error: e, stackTrace: stackTrace);

      _activeTasks.remove(event.contentId);
      _downloadManager.unregisterTask(event.contentId);

      // Handle failure via helper
      await _handleDownloadFailure(event.contentId, e, stackTrace, emit);
    }
  }

  /// Handle download failure with auto-retry logic
  Future<void> _handleDownloadFailure(
    String contentId,
    Object error,
    StackTrace? stackTrace,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      if (error is! Exception) {
        emit(DownloadError(
          message: 'Failed to start download: ${error.toString()}',
          errorType: _determineErrorType(error),
          previousState: null,
          stackTrace: stackTrace,
        ));
      }
      return;
    }

    final currentDownload = currentState.getDownload(contentId);

    if (currentDownload != null) {
      // Check if auto retry is enabled and we haven't exceeded retry attempts
      if (currentState.settings.autoRetry &&
          currentDownload.retryCount < currentState.settings.retryAttempts) {
        _logger.i(
            'DownloadBloc: Auto-retrying download $contentId (attempt ${currentDownload.retryCount + 1}/${currentState.settings.retryAttempts})');

        final retryDownload = currentDownload.copyWith(
          retryCount: currentDownload.retryCount + 1,
          state: DownloadState.queued,
          error: _getLocalizedString(
            (l10n) => l10n.retryingDownload(currentDownload.retryCount + 1,
                currentState.settings.retryAttempts),
            'Retrying download (attempt ${currentDownload.retryCount + 1}/${currentState.settings.retryAttempts})',
          ),
          endTime: null, // Reset end time for retry
        );

        await _userDataRepository.saveDownloadStatus(retryDownload);

        // Update state with retry download
        final updatedDownloads = currentState.downloads
            .map((d) => d.contentId == contentId ? retryDownload : d)
            .toList();

        emit(currentState.copyWith(
          downloads: updatedDownloads,
          lastUpdated: DateTime.now(),
        ));

        // Schedule retry with delay
        Timer(
          Duration(
            milliseconds: currentState.settings.retryDelay.inMilliseconds,
          ),
          () {
            if (!isClosed) {
              add(DownloadStartEvent(contentId));
            }
          },
        );
        return;
      }

      // Mark as failed
      final failedDownload = currentDownload.copyWith(
        state: DownloadState.failed,
        error: error.toString(),
        endTime: DateTime.now(),
      );

      await _userDataRepository.saveDownloadStatus(failedDownload);

      // Show error notification
      // DISABLED: Using Native Notifications exclusively
      /*
      if (currentState.settings.enableNotifications) {
        _notificationService.showDownloadError(
          contentId: contentId,
          title: failedDownload.title ?? contentId,
          error: error.toString(),
        );
      }
      */

      final updatedDownloads = currentState.downloads
          .map((d) => d.contentId == contentId ? failedDownload : d)
          .toList();

      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      await _processQueue();
    } else {
      emit(DownloadError(
        message: 'Failed to start download: ${error.toString()}',
        errorType: _determineErrorType(error),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Pause a download
  Future<void> _onPause(
    DownloadPauseEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Pausing download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null || !download.canPause) {
        _logger.w('DownloadBloc: Cannot pause download: ${event.contentId}');
        return;
      }

      // Pause the download task (Dart side)
      final task = _activeTasks[event.contentId];
      if (task != null) {
        task.pause();
        _logger.i('DownloadBloc: Paused task for ${event.contentId}');
      }

      // Call Native Service to pause
      await NativeDownloadService().pauseDownload(event.contentId);

      // Update status to paused
      final updatedDownload = download.copyWith(
        state: DownloadState.paused,
        endTime: DateTime.now(),
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // Immediately update notification to show paused status with current progress
      if (currentState.settings.enableNotifications) {
        final progressPercentage = updatedDownload.progressPercentage.round();
        await _notificationService
            .updateDownloadProgress(
          contentId: event.contentId,
          progress: progressPercentage,
          title: updatedDownload.title ?? updatedDownload.contentId,
          isPaused: true,
        )
            .catchError((e) {
          _logger.w('DownloadBloc: Failed to update pause notification: $e');
        });
      }

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Paused download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error pausing download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToPauseDownload(e.toString()),
          'Failed to pause download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Cancel a download
  Future<void> _onCancel(
    DownloadCancelEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Cancelling download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null || !download.canCancel) {
        _logger.w('DownloadBloc: Cannot cancel download: ${event.contentId}');
        return;
      }

      // Cancel the download task (Dart side)
      _cancelDownloadTask(event.contentId);

      // Call Native Service to cancel
      await NativeDownloadService().cancelDownload(event.contentId);

      // Update status to cancelled
      final updatedDownload = download.copyWith(
        state: DownloadState.cancelled,
        endTime: DateTime.now(),
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Cancelled download for ${event.contentId}');
    } catch (e, stackTrace) {
      // ... error handling
      _logger.e('DownloadBloc: Error cancelling download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToCancelDownload(e.toString()),
          'Failed to cancel download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Retry a failed download
  Future<void> _onRetry(
    DownloadRetryEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    // ... retry logic, mostly resets state
    // Same logic as standard retry
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Retrying download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null) {
        _logger.w('DownloadBloc: Cannot retry download: ${event.contentId}');
        return;
      }

      // Update status to queued for retry
      final updatedDownload = DownloadStatus(
        contentId: download.contentId,
        state: DownloadState.queued,
        downloadedPages: download.downloadedPages,
        totalPages: download.totalPages,
        startTime: download.startTime,
        endTime: download.endTime,
        error: null, // Clear error
        downloadPath: download.downloadPath,
        fileSize: download.fileSize,
        speed: download.speed,
        retryCount: download.retryCount,
        startPage: download.startPage,
        endPage: download.endPage,
        title: download.title,
        sourceId: download.sourceId,
        coverUrl: download.coverUrl,
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // ✅ FIXED: Reset notification when retrying
      // This prevents the notification from being stuck at the last progress (e.g., 92%)
      /*
      if (currentState.settings.enableNotifications) {
        _notificationService
            .showDownloadStarted(
          contentId: event.contentId,
          title: download.title ?? download.contentId,
        )
            .catchError((e) {
          _logger.w('DownloadBloc: Failed to reset notification on retry: $e');
        });
        _logger
            .i('DownloadBloc: Reset notification for retry ${event.contentId}');
      }
      */

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Queued retry for ${event.contentId}');
    } catch (e, stackTrace) {
      // ...
      _logger.e('DownloadBloc: Error retrying download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToRetryDownload(e.toString()),
          'Failed to retry download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Resume a paused download
  Future<void> _onResume(
    DownloadResumeEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Resuming download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null || download.state != DownloadState.paused) {
        _logger.w('DownloadBloc: Cannot resume download: ${event.contentId}');
        return;
      }

      // Resume the task if it exists (Legacy)
      final task = _activeTasks[event.contentId];
      if (task != null) {
        task.resume();
        _logger.i('DownloadBloc: Resumed task for ${event.contentId}');
      }

      // Update status to queued for resume
      final updatedDownload = DownloadStatus(
        contentId: download.contentId,
        state: DownloadState.queued,
        downloadedPages: download.downloadedPages,
        totalPages: download.totalPages,
        startTime: DateTime.now(), // New start time
        endTime: null, // Clear end time
        error: null, // Clear error
        downloadPath: download.downloadPath,
        fileSize: download.fileSize,
        speed: download.speed,
        retryCount: download.retryCount,
        startPage: download.startPage,
        endPage: download.endPage,
        title: download.title,
        sourceId: download.sourceId,
        coverUrl: download.coverUrl,
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // Update notification to show resumed status with current progress
      if (currentState.settings.enableNotifications) {
        final progressPercentage = updatedDownload.progressPercentage.round();
        await _notificationService
            .updateDownloadProgress(
          contentId: event.contentId,
          progress: progressPercentage,
          title: updatedDownload.title ?? updatedDownload.contentId,
          isPaused: false, // Resume means no longer paused
        )
            .catchError((e) {
          _logger.w('DownloadBloc: Failed to update resume notification: $e');
        });
      }

      // Refresh downloads and process queue
      add(const DownloadRefreshEvent());
      await _processQueue();

      _logger.i('DownloadBloc: Resumed download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error resuming download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToResumeDownload(e.toString()),
          'Failed to resume download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Remove a download from the list
  Future<void> _onRemove(
    DownloadRemoveEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Removing download for ${event.contentId}');

      final download = currentState.downloads
          .where((d) => d.contentId == event.contentId)
          .firstOrNull;

      if (download == null) {
        _logger.w('DownloadBloc: Download not found: ${event.contentId}');
        return;
      }

      // Cancel if in progress
      if (download.isInProgress) {
        _cancelDownloadTask(event.contentId);
      }

      // Optimistic update: Remove from state immediately to prevent race conditions
      // if user tries to re-download while deletion is in progress
      final updatedDownloads = currentState.downloads
          .where((d) => d.contentId != event.contentId)
          .toList();

      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Remove from database
      await _userDataRepository.deleteDownloadStatus(event.contentId);

      // Resolve path for deletion if missing
      String? pathToDelete = download.downloadPath;
      if (pathToDelete == null || pathToDelete.isEmpty) {
        // Try to resolve based on settings and ID
        if (currentState.settings.customStorageRoot != null) {
          // Best guess reconstruction: root/nhasix/[source]/[id]
          // We might need sourceId, hopefully it's in the download object or we guess
          final sourceId = download.sourceId ??
              'unknown'; // Fallback might fail but worth a try or iterate sources
          pathToDelete = path.join(currentState.settings.customStorageRoot!,
              'nhasix', sourceId, event.contentId);
        }
      }

      // Pass download path if available to ensure accurate deletion
      await _downloadContentUseCase.deleteCall(event.contentId,
          dirPath: pathToDelete);

      // Invalidate download status cache to ensure UI reflects removal
      ContentDownloadCache.invalidateCache(event.contentId);

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Removed download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error removing download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToRemoveDownload(e.toString()),
          'Failed to remove download: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Refresh download list
  Future<void> _onRefresh(
    DownloadRefreshEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;

    try {
      _logger.i('DownloadBloc: Refreshing download list');

      // 🔄 CRITICAL: Reload customStorageRoot from StorageSettings
      // This ensures UI always shows correct storage location even if:
      // 1. DownloadBloc was initialized before storage location was set
      // 2. User changed storage location via settings dialog
      final customRoot = await StorageSettings.getCustomRootPath();
      debugPrint(
          '📁 DOWNLOAD_BLOC: Refreshing customStorageRoot from StorageSettings');
      debugPrint('📁 DOWNLOAD_BLOC: customRoot value on refresh: $customRoot');

      // Update settings with latest customStorageRoot
      _settings = _settings.copyWith(customStorageRoot: customRoot);
      debugPrint(
          '📁 DOWNLOAD_BLOC: Updated _settings.customStorageRoot: ${_settings.customStorageRoot}');

      // Reload downloads from database
      final downloads = await _userDataRepository.getAllDownloads(
          limit: AppLimits.maxBatchSize);

      if (currentState is DownloadLoaded) {
        // Update existing state with new downloads
        emit(currentState.copyWith(
          downloads: downloads,
          lastUpdated: DateTime.now(),
        ));
      } else {
        // Create new state if not in loaded state
        emit(DownloadLoaded(
          downloads: downloads,
          settings: _settings,
          lastUpdated: DateTime.now(),
        ));
      }

      _logger.i('DownloadBloc: Refreshed with ${downloads.length} downloads');

      // Process queue after refresh
      await _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error refreshing downloads',
          error: e, stackTrace: stackTrace);

      // Only emit error if we don't have a valid state to preserve
      if (currentState is! DownloadLoaded) {
        emit(DownloadError(
          message: _getLocalizedString(
            (l10n) => l10n.failedToRefreshDownloads(e.toString()),
            'Failed to refresh downloads: ${e.toString()}',
          ),
          errorType: _determineErrorType(e),
          previousState: currentState is DownloadLoaded ? currentState : null,
          stackTrace: stackTrace,
        ));
      }
    }
  }

  /// Update download progress in real-time
  Future<void> _onProgressUpdate(
    DownloadProgressUpdateEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;

    // Handle different state types more flexibly
    List<DownloadStatus> downloads;
    DownloadSettings settings;

    if (currentState is DownloadLoaded) {
      downloads = currentState.downloads;
      settings = currentState.settings;
    } else if (currentState is DownloadProcessing) {
      downloads = currentState.downloads;
      settings = currentState.settings;
    } else {
      // If not in a state where we can update progress, try to refresh first
      _logger.d(
          'DownloadBloc: Not in updatable state, refreshing downloads for progress update');
      add(const DownloadRefreshEvent());
      return;
    }

    try {
      // Find the download and update its progress
      final downloadIndex = downloads.indexWhere(
        (d) => d.contentId == event.contentId,
      );

      if (downloadIndex == -1) {
        _logger.w(
            'DownloadBloc: Download not found for progress update: ${event.contentId}');
        return;
      }

      final currentDownload = downloads[downloadIndex];

      // ============================================================
      // HANDLE VERIFICATION PROGRESS (Special Case)
      // ============================================================
      // downloadedPages = -2 signals verification progress
      // totalPages = verification percentage (0-100)
      if (event.downloadedPages == -2) {
        _logger.d(
            'DownloadBloc: Verification progress update for ${event.contentId}: ${event.totalPages}%');

        // Show verification notification
        // DISABLED: Using Native Notifications exclusively
        /*
        if (currentState.settings.enableNotifications) {
          final verificationPercentage = event.totalPages;

          // Show verification started on first progress update
          if (verificationPercentage == 0 || verificationPercentage == 1) {
            _notificationService
                .showVerificationStarted(
              contentId: event.contentId,
              title: currentDownload.title ?? currentDownload.contentId,
            )
                .catchError((e) {
              _logger.w(
                  'DownloadBloc: Failed to show verification started notification: $e');
            });
          }

          // Update verification progress (only every 20% to reduce spam)
          // ✅ FIXED: Don't update at 100% to avoid race condition with showDownloadCompleted
          if ((verificationPercentage % 20 == 0 ||
                  verificationPercentage >= 95) &&
              verificationPercentage < 100) {
            _notificationService
                .updateVerificationProgress(
              contentId: event.contentId,
              progress: verificationPercentage,
              title: currentDownload.title ?? currentDownload.contentId,
            )
                .catchError((e) {
              _logger.w(
                  'DownloadBloc: Failed to update verification progress: $e');
            });
          }

          // Cancel verification notification when complete
          if (verificationPercentage >= 100) {
            // ✅ FIXED: Explicitly cancel the verification notification first
            // This prevents "Verifying 100%" from sticking around
            if (currentState.settings.enableNotifications) {
              _notificationService
                  .cancelVerificationNotification(event.contentId);
            }

            // Explicitly show completion notification here
            // This fixes the issue where notification gets stuck at "Verifying 100%"
            // because the normal completion event might have been processed or missed
            if (currentState.settings.enableNotifications) {
              _notificationService
                  .showDownloadCompleted(
                contentId: event.contentId,
                title: currentDownload.title ?? currentDownload.contentId,
                downloadPath: currentDownload.downloadPath ?? '',
              )
                  .catchError((e) {
                _logger.w(
                    'DownloadBloc: Failed to show completion notification after verification: $e');
              });
            }

            _logger.i(
                'DownloadBloc: Verification complete, forced completion notification for ${event.contentId}');

            // Trigger refresh to ensure UI is up to date
            add(const DownloadRefreshEvent());
          }
        }
        */

        // Don't update download status for verification progress
        return;
      }

      // ============================================================
      // HANDLE NORMAL DOWNLOAD PROGRESS
      // ============================================================

      // Update progress only if download is still in progress
      if (!currentDownload.isInProgress) {
        _logger.d(
            'DownloadBloc: Ignoring progress update for non-active download: ${event.contentId}');
        return;
      }

      // Create updated download with new progress
      final updatedDownload = currentDownload.copyWith(
        downloadedPages: event.downloadedPages,
        totalPages: event
            .totalPages, // ✅ Update totalPages from event (crucial for Crotpedia)
        speed: event.downloadSpeed,
      );

      // ✅ FIXED: Only update if progress actually changed to prevent unnecessary updates
      if (currentDownload.downloadedPages == event.downloadedPages) {
        _logger.d(
            'DownloadBloc: Ignoring duplicate progress update for ${event.contentId}');
        return;
      }

      // ✅ FIXED: Check if download should be completed (progress = 100%)
      // This helps handle completion status immediately
      if (event.downloadedPages >= event.totalPages &&
          event.downloadSpeed == 0.0 &&
          event.estimatedTimeRemaining == Duration.zero) {
        _logger.i(
            'DownloadBloc: Download appears completed, refreshing status for ${event.contentId}');

        // REVAMP: If PDF conversion was part of the original request, we would trigger it here.
        // For now, we ensure the UI updates and the status is finalized.

        add(const DownloadRefreshEvent());
        return;
      }

      // Update downloads list
      final updatedDownloads = List<DownloadStatus>.from(downloads);
      updatedDownloads[downloadIndex] = updatedDownload;

      // Emit appropriate state based on current state type
      if (currentState is DownloadLoaded) {
        emit(currentState.copyWith(
          downloads: updatedDownloads,
          lastUpdated: DateTime.now(),
        ));
      } else if (currentState is DownloadProcessing) {
        emit(DownloadLoaded(
          downloads: updatedDownloads,
          settings: settings,
          lastUpdated: DateTime.now(),
        ));
      }

      // Save progress to database (but don't await to keep it fast)
      // Only save intermediate progress to DB (avoid overwriting completion status at 100%)
      if (updatedDownload.downloadedPages < updatedDownload.totalPages) {
        await _userDataRepository
            .saveDownloadStatus(updatedDownload)
            .catchError((e) {
          _logger.w('DownloadBloc: Failed to save progress to database: $e');
        });
      } else {
        // If progress is 100%, we should consider it complete
        // But we wait for the explicit completion event or the next check
        _logger.d(
            'DownloadBloc: 100% progress reached for ${event.contentId}, waiting for completion event or triggering it now');

        // Trigger completion event if we strictly reached 100%
        if (updatedDownload.progressPercentage >= 100) {
          add(DownloadCompletedEvent(event.contentId));
          return;
        }
      }

      // Update notification progress through DownloadBloc
      if (currentState.settings.enableNotifications) {
        final progressPercentage = updatedDownload.progressPercentage.round();

        // ✅ FIXED: Completion notification should trigger regardless of isInProgress
        // because when progress = 100%, download may already be marked as completed
        if (progressPercentage >= 100) {
          // Show completion notification
          // Show completion notification (Flutter-side)
          await _notificationService
              .showDownloadCompleted(
            contentId: event.contentId,
            title: updatedDownload.title ?? updatedDownload.contentId,
            downloadPath: updatedDownload.downloadPath ?? '',
          )
              .catchError((e) {
            _logger
                .w('DownloadBloc: Failed to show completion notification: $e');
          });
          _logger.i(
              'DownloadBloc: Triggered completion notification for ${event.contentId}');
        } else if (updatedDownload.isInProgress) {
          // Update progress notification only if still in progress (< 100%)
          // (Flutter-side notification)
          await _notificationService
              .updateDownloadProgress(
            contentId: event.contentId,
            progress: progressPercentage,
            title: updatedDownload.title ??
                updatedDownload.contentId, // Use title or fallback
            isPaused: false,
          )
              .catchError((e) {
            _logger
                .w('DownloadBloc: Failed to update notification progress: $e');
          });
        }
      }

      _logger.d(
          'DownloadBloc: Updated progress for ${event.contentId}: ${event.downloadedPages}/${event.totalPages}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error updating progress',
          error: e, stackTrace: stackTrace);
      // Don't emit error state for progress updates to avoid disrupting downloads
    }
  }

  /// Handle download completion
  Future<void> _onCompleted(
    DownloadCompletedEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;

    // We need to be in a loaded state to process this, or at least have access to the lists
    // If state is not loaded, we might just want to refresh to get latest state from DB
    // But importantly, we MUST update the DB to say "completed" first.

    try {
      _logger.i('🎯 DownloadBloc: Handling completion for ${event.contentId}');

      // 1. Mark as completed in Database
      // We need to fetch current status to preserve other fields (like title, etc)
      // If we are in Loaded state, use that. Otherwise fetch from DB.

      DownloadStatus? currentDownload;

      if (currentState is DownloadLoaded) {
        currentDownload = currentState.getDownload(event.contentId);
        _logger.d('Found download in state: ${currentDownload != null}');
      }

      // If not found in state or state not loaded, fetch from DB
      if (currentDownload == null) {
        _logger.d('Fetching download from database...');
        currentDownload =
            await _userDataRepository.getDownloadStatus(event.contentId);
      }

      if (currentDownload == null) {
        _logger
            .w('DownloadBloc: Completing unknown download ${event.contentId}');
        // Even if unknown, we should probably run refresh to sync up
        add(const DownloadRefreshEvent());
        return;
      }

      // Update status to completed
      int totalSize = currentDownload.fileSize;
      String? downloadPath = currentDownload.downloadPath;

      // FALLBACK: If downloadPath is missing, try to get it from NativeDownloadService
      if (downloadPath == null || downloadPath.isEmpty) {
        _logger.w(
            '⚠️ Download path is missing, attempting fallback via NativeDownloadService');
        try {
          downloadPath =
              await NativeDownloadService().getDownloadPath(event.contentId);
          _logger.i('✅ Retrieved path from native: $downloadPath');
        } catch (e) {
          _logger.e('Failed to get download path from native', error: e);
        }
      }

      // Calculate final size if path exists
      if (downloadPath != null && downloadPath.isNotEmpty) {
        _logger.d('Calculating file size for path: $downloadPath');

        // Try multiple times with delays in case filesystem is still syncing
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            final dir = Directory(downloadPath);
            if (!dir.existsSync()) {
              _logger.w(
                  'Directory does not exist (attempt $attempt): $downloadPath');
              if (attempt < 3) {
                await Future.delayed(Duration(milliseconds: 100 * attempt));
                continue;
              }
            }

            totalSize = await DownloadStorageUtils.getDirectorySize(dir);
            _logger.i(
                '💾 Calculated final size for ${event.contentId}: ${DownloadStorageUtils.formatBytes(totalSize)} ($totalSize bytes)');
            break; // Success, exit retry loop
          } catch (e) {
            _logger.w('Failed to calculate size (attempt $attempt/3): $e');
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 100 * attempt));
            }
          }
        }
      } else {
        _logger
            .e('❌ Cannot calculate file size: downloadPath is null or empty');
      }

      final completedDownload = DownloadStatus(
        contentId: currentDownload.contentId,
        state: DownloadState.completed,
        downloadedPages: currentDownload.totalPages, // Ensure full count
        totalPages: currentDownload.totalPages,
        startTime: currentDownload.startTime,
        endTime: DateTime.now(),
        error: null, // Clear error explicitly
        downloadPath: downloadPath, // Update path if retrieved
        fileSize: totalSize, // Save calculated size
        speed: currentDownload.speed,
        retryCount: currentDownload.retryCount,
        startPage: currentDownload.startPage,
        endPage: currentDownload.endPage,
        title: currentDownload.title,
        sourceId: currentDownload.sourceId,
        coverUrl: currentDownload.coverUrl,
      );

      _logger.d('Saving completed download to database...');
      await _userDataRepository.saveDownloadStatus(completedDownload);
      _logger.i(
          '✅ Saved "completed" status to DB for ${event.contentId} with size: ${DownloadStorageUtils.formatBytes(totalSize)}');

      // 2. Remove from active tasks
      _activeTasks.remove(event.contentId);
      _downloadManager.unregisterTask(event.contentId);
      _logger.d('Removed ${event.contentId} from active tasks');

      // 3. Update State
      if (currentState is DownloadLoaded) {
        final updatedDownloads = currentState.downloads
            .map((d) => d.contentId == event.contentId ? completedDownload : d)
            .toList();

        emit(currentState.copyWith(
          downloads: updatedDownloads,
          lastUpdated: DateTime.now(),
        ));
        _logger.d('Updated state with completed download');
      }

      // 4. Trigger Notifications
      if (currentState is DownloadLoaded &&
          currentState.settings.enableNotifications) {
        _logger.d('Showing completion notification');
        await _notificationService.showDownloadCompleted(
          contentId: event.contentId,
          title: completedDownload.title ?? event.contentId,
          downloadPath: completedDownload.downloadPath ?? '',
        );
      }

      // 5. Force refresh to update offline content screen with correct file sizes
      _logger.d('Triggering refresh to sync offline content...');
      add(const DownloadRefreshEvent());

      // 6. Check if we need to process queue (free slot opened up)
      await _processQueue();

      _logger.i('🎉 Completion handling finished for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('❌ DownloadBloc: Error handling completion',
          error: e, stackTrace: stackTrace);
      // Ensure we at least leave a consistent state
      add(const DownloadRefreshEvent());
    }
  }

  /// Update download settings
  Future<void> _onSettingsUpdate(
    DownloadSettingsUpdateEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Updating download settings');

      // Update settings with all available fields
      _settings = _settings.copyWith(
        maxConcurrentDownloads: event.maxConcurrentDownloads,
        imageQuality: event.imageQuality,
        autoRetry: event.autoRetry,
        retryAttempts: event.retryAttempts,
        retryDelay: event.retryDelay,
        timeoutDuration: event.timeoutDuration,
        enableNotifications: event.enableNotifications,
        wifiOnly: event.wifiOnly,
        customStorageRoot: event.customStorageRoot,
      );

      // Update state
      emit(currentState.copyWith(settings: _settings));

      // Updated user preferences
      final currentUserPrefs = await _userDataRepository.getUserPreferences();
      final updatedUserPrefs = currentUserPrefs.copyWith(
        maxConcurrentDownloads: event.maxConcurrentDownloads,
        imageQuality: event.imageQuality,
        customStorageRoot: event.customStorageRoot,
        // NEW: Save all download settings to UserPreferences
        autoRetry: event.autoRetry,
        retryAttempts: event.retryAttempts,
        retryDelaySeconds: event.retryDelay?.inSeconds,
        timeoutDurationSeconds: event.timeoutDuration?.inSeconds,
        enableNotifications: event.enableNotifications,
        wifiOnly: event.wifiOnly,
      );

      // Save to repository (only supported fields)
      await _userDataRepository.saveUserPreferences(updatedUserPrefs);

      _logger.i(
          'DownloadBloc: Updated download settings - concurrent: ${_settings.maxConcurrentDownloads}, quality: ${_settings.imageQuality}, wifiOnly: ${_settings.wifiOnly}, notifications: ${_settings.enableNotifications}, customRoot: ${_settings.customStorageRoot}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error updating settings',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToUpdateDownloadSettings(e.toString()),
          'Failed to update download settings: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  // Helper methods

  /// Cancel download task
  void _cancelDownloadTask(String contentId) {
    final task = _activeTasks[contentId];
    if (task != null && !task.isCancelled) {
      task.cancel('Download cancelled by user');
      _activeTasks.remove(contentId);

      // Unregister task from DownloadManager
      DownloadManager().unregisterTask(contentId);
      _logger.d('DownloadBloc: Cancelled task for $contentId');
    }
  }

  /// Determine error type from exception
  DownloadErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return DownloadErrorType.network;
    } else if (errorString.contains('storage') ||
        errorString.contains('space') ||
        errorString.contains('disk')) {
      return DownloadErrorType.storage;
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return DownloadErrorType.permission;
    } else if (errorString.contains('server') || errorString.contains('5')) {
      return DownloadErrorType.server;
    } else if (errorString.contains('parse') ||
        errorString.contains('format')) {
      return DownloadErrorType.parsing;
    } else if (errorString.contains('timeout')) {
      return DownloadErrorType.timeout;
    } else if (errorString.contains('cancel')) {
      return DownloadErrorType.cancelled;
    } else {
      return DownloadErrorType.unknown;
    }
  }

  /// Pause all active downloads
  Future<void> _onPauseAll(
    DownloadPauseAllEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Pausing all downloads');

      emit(DownloadProcessing(
        downloads: currentState.downloads,
        settings: currentState.settings,
        operation: 'Pausing all downloads',
        lastUpdated: currentState.lastUpdated,
      ));

      // Get all active downloads
      final activeDownloads = currentState.activeDownloads;

      if (activeDownloads.isEmpty) {
        _logger.i('DownloadBloc: No active downloads to pause');
        emit(currentState.copyWith(lastUpdated: DateTime.now()));
        return;
      }

      // Cancel all active download tasks
      for (final download in activeDownloads) {
        _cancelDownloadTask(download.contentId);

        // Update status to paused
        final updatedDownload = download.copyWith(
          state: DownloadState.paused,
          endTime: DateTime.now(),
        );

        await _userDataRepository.saveDownloadStatus(updatedDownload);
      }

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Paused all downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error pausing all downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToPauseAllDownloads(e.toString()),
          'Failed to pause all downloads: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Resume all paused downloads
  Future<void> _onResumeAll(
    DownloadResumeAllEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Resuming all paused downloads');

      emit(DownloadProcessing(
        downloads: currentState.downloads,
        settings: currentState.settings,
        operation: 'Resuming all downloads',
        lastUpdated: currentState.lastUpdated,
      ));

      // Get all paused downloads
      final pausedDownloads = currentState.pausedDownloads;

      if (pausedDownloads.isEmpty) {
        _logger.i('DownloadBloc: No paused downloads to resume');
        emit(currentState.copyWith(lastUpdated: DateTime.now()));
        return;
      }

      // Update each paused download to queued
      for (final download in pausedDownloads) {
        final updatedDownload = download.copyWith(
          state: DownloadState.queued,
          startTime: DateTime.now(),
          endTime: null,
        );

        await _userDataRepository.saveDownloadStatus(updatedDownload);
      }

      // Refresh downloads and process queue
      add(const DownloadRefreshEvent());
      await _processQueue();

      _logger.i('DownloadBloc: Resumed all paused downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error resuming all downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToResumeAllDownloads(e.toString()),
          'Failed to resume all downloads: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Cancel all active downloads
  Future<void> _onCancelAll(
    DownloadCancelAllEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Cancelling all downloads');

      emit(DownloadProcessing(
        downloads: currentState.downloads,
        settings: currentState.settings,
        operation: 'Cancelling all downloads',
        lastUpdated: currentState.lastUpdated,
      ));

      // Get all active and queued downloads
      final activeDownloads = [
        ...currentState.activeDownloads,
        ...currentState.queuedDownloads
      ];

      if (activeDownloads.isEmpty) {
        _logger.i('DownloadBloc: No active or queued downloads to cancel');
        emit(currentState.copyWith(lastUpdated: DateTime.now()));
        return;
      }

      // Cancel all active download tasks
      for (final download in activeDownloads) {
        _cancelDownloadTask(download.contentId);

        // Update status to cancelled
        final updatedDownload = download.copyWith(
          state: DownloadState.cancelled,
          endTime: DateTime.now(),
        );

        await _userDataRepository.saveDownloadStatus(updatedDownload);
      }

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Cancelled all downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error cancelling all downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToCancelAllDownloads(e.toString()),
          'Failed to cancel all downloads: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Clear completed downloads
  Future<void> _onClearCompleted(
    DownloadClearCompletedEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Clearing completed downloads');

      emit(DownloadProcessing(
        downloads: currentState.downloads,
        settings: currentState.settings,
        operation: 'Clearing completed downloads',
        lastUpdated: currentState.lastUpdated,
      ));

      // Get all completed downloads
      final completedDownloads = currentState.completedDownloads;

      if (completedDownloads.isEmpty) {
        _logger.i('DownloadBloc: No completed downloads to clear');
        emit(currentState.copyWith(lastUpdated: DateTime.now()));
        return;
      }

      // Remove each completed download
      for (final download in completedDownloads) {
        await _userDataRepository.deleteDownloadStatus(download.contentId);
      }

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i(
          'DownloadBloc: Cleared ${completedDownloads.length} completed downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error clearing completed downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToClearCompletedDownloads(e.toString()),
          'Failed to clear completed downloads: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Convert completed download to PDF with background processing
  /// This handler triggers PDF conversion using PdfConversionService
  /// which handles splitting, notifications, and background processing
  Future<void> _onConvertToPdf(
    DownloadConvertToPdfEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger.w('DownloadBloc: Cannot convert to PDF - not in loaded state');
      return;
    }

    try {
      _logger.i('DownloadBloc: Starting PDF conversion for ${event.contentId}');

      // Find the download status for this content
      final download = currentState.downloads.firstWhere(
        (d) => d.contentId == event.contentId,
        orElse: () => throw Exception(
            'Download not found for content: ${event.contentId}'),
      );

      // Check if download is completed
      if (!download.isCompleted) {
        _logger.w(
            'DownloadBloc: Cannot convert incomplete download to PDF: ${event.contentId}');
        await _notificationService.showPdfConversionError(
          contentId: event.contentId,
          title: event.contentId,
          error: _getLocalizedString(
            (l10n) => l10n.downloadNotCompletedYet,
            'Download not completed yet',
          ),
        );
        return;
      }

      // Determine sourceId
      String? sourceId = event.sourceId;

      // If sourceId is not provided, try to discover it from known sources
      if (sourceId == null) {
        _logger.d(
            'DownloadBloc: sourceId not provided, attempting discovery for ${event.contentId}');
        for (final source in AppStorage.knownSources) {
          final metadata = await DownloadStorageUtils.readLocalMetadata(
            event.contentId,
            sourceId: source,
          );
          if (metadata != null) {
            sourceId = source;
            _logger.i(
                'DownloadBloc: Discovered sourceId for ${event.contentId}: $sourceId');
            break;
          }
        }
      }

      // Try to get content details from local metadata first
      String contentTitle = event.contentId; // Fallback title
      final localMetadata = await DownloadStorageUtils.readLocalMetadata(
        event.contentId,
        sourceId: sourceId,
      );

      if (localMetadata != null) {
        // Use local metadata for offline support
        contentTitle = localMetadata['title'] as String? ?? event.contentId;
        // If sourceId was still null (legacy path), try to get it from metadata
        if (sourceId == null && localMetadata['source'] != null) {
          sourceId = localMetadata['source'] as String;
        }
        _logger.i(
            'DownloadBloc: Using local metadata for PDF conversion - Title: $contentTitle, Source: $sourceId');
      } else {
        // Fallback to API if no local metadata (online mode)
        try {
          final content = await _getContentDetailUseCase.call(
            GetContentDetailParams.fromString(event.contentId),
            // Pass sourceId if known
          );
          contentTitle = content.title;
          sourceId ??= content.sourceId;
          _logger.i(
              'DownloadBloc: Using API content details for PDF conversion - Title: $contentTitle, Source: $sourceId');
        } catch (e) {
          _logger.w(
              'DownloadBloc: Failed to get content details from API, using contentId as title: $e');
          // Keep using contentId as fallback title
        }
      }

      // Get downloaded image paths from content repository or download service
      final imagePaths = await DownloadStorageUtils.getDownloadedImagePaths(
        event.contentId,
        sourceId: sourceId,
      );

      if (imagePaths.isEmpty) {
        _logger.w(
            'DownloadBloc: No downloaded images found for PDF conversion: ${event.contentId}');
        await _notificationService.showPdfConversionError(
          contentId: event.contentId,
          title: contentTitle,
          error: _getLocalizedString(
            (l10n) => l10n.noImagesFoundForConversion,
            'No images found for conversion',
          ),
        );
        return;
      }

      // Start PDF conversion in background using PdfConversionQueueManager
      // This queues the conversion instead of starting it immediately
      // Queue manager will process conversions sequentially to avoid resource contention
      await _pdfConversionQueueManager.queueConversion(
        contentId: event.contentId,
        title: contentTitle,
        imagePaths: imagePaths,
        sourceId: sourceId,
      );

      _logger.i('DownloadBloc: PDF conversion queued for ${event.contentId}');

      // The actual conversion happens in background via PdfConversionService
      // User will be notified via notifications about progress and completion
    } catch (e, stackTrace) {
      _logger.e(
          'DownloadBloc: Error during PDF conversion for ${event.contentId}',
          error: e,
          stackTrace: stackTrace);

      // Show error notification to user
      await _notificationService.showPdfConversionError(
        contentId: event.contentId,
        title: event.contentId, // Use contentId as fallback title in error case
        error: e.toString(),
      );
    }
  }

  /// Handle open downloaded content event
  Future<void> _onOpenContent(
    DownloadOpenContentEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    await _openDownloadedContent(event.contentId);
  }

  /// Handle cleanup storage event
  /// This will clean up old downloads and temporary files
  Future<void> _onCleanupStorage(
    DownloadCleanupStorageEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger.w('DownloadBloc: Cannot cleanup storage - not in loaded state');
      return;
    }

    try {
      _logger.i('DownloadBloc: Starting storage cleanup');

      // Get the downloads directory
      final downloadsPath = await DownloadStorageUtils.getDownloadsDirectory();
      final nhasixDir = Directory(path.join(downloadsPath, 'nhasix'));

      if (!await nhasixDir.exists()) {
        _logger
            .i('DownloadBloc: No nhasix directory found, nothing to cleanup');
        return;
      }

      int cleanedFiles = 0;
      int freedSpaceBytes = 0;

      // Get all content directories
      final contentDirs = <Directory>[];
      await for (final entity in nhasixDir.list()) {
        if (entity is Directory) {
          contentDirs.add(entity);
        }
      }

      for (final contentDir in contentDirs) {
        final contentId = path.basename(contentDir.path);

        // Check if this content is still in downloads list
        final isActiveDownload = currentState.downloads
            .any((download) => download.contentId == contentId);

        if (!isActiveDownload) {
          // This is an orphaned download, safe to delete
          _logger.d('DownloadBloc: Cleaning up orphaned download: $contentId');

          try {
            // Calculate directory size before deletion
            final dirSize =
                await DownloadStorageUtils.getDirectorySize(contentDir);

            // Delete the directory
            await contentDir.delete(recursive: true);

            cleanedFiles++;
            freedSpaceBytes += dirSize;

            _logger.d(
                'DownloadBloc: Cleaned up ${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB from: $contentId');
          } catch (e) {
            _logger.w(
                'DownloadBloc: Failed to delete directory: ${contentDir.path}, error: $e');
          }
        } else {
          // For active downloads, clean up temporary files
          await DownloadStorageUtils.cleanupTempFiles(contentDir);
        }
      }

      _logger.i(
          'DownloadBloc: Storage cleanup completed. Cleaned $cleanedFiles directories, freed ${(freedSpaceBytes / 1024 / 1024).toStringAsFixed(2)} MB');

      // Show success notification (could implement showNotification method later)
      // For now just log success
      _logger.i(
          'Storage Cleanup Complete: Cleaned $cleanedFiles items, freed ${(freedSpaceBytes / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during storage cleanup',
          error: e, stackTrace: stackTrace);

      // Show error notification (could implement showNotification method later)
      // For now just log error
      _logger.e('Storage Cleanup Failed: ${e.toString()}');
    }
  }

  /// Handle export event
  /// This will export downloads list or specific content
  Future<void> _onExport(
    DownloadExportEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) {
      _logger.w('DownloadBloc: Cannot export - not in loaded state');
      return;
    }

    try {
      _logger.i('DownloadBloc: Starting export operation');

      // Create export data
      final exportData = <String, dynamic>{
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // You can get this from package_info_plus
        'total_downloads': currentState.downloads.length,
        'downloads': currentState.downloads
            .map((download) => {
                  'content_id': download.contentId,
                  'state': download.state.toString(),
                  'progress': download.progress,
                  'downloaded_pages': download.downloadedPages,
                  'total_pages': download.totalPages,
                  'file_size': download.fileSize,
                  'speed': download.speed,
                  'start_time': download.startTime?.toIso8601String(),
                  'end_time': download.endTime?.toIso8601String(),
                  'download_path': download.downloadPath,
                  'error': download.error,
                  'is_completed': download.isCompleted,
                  'is_paused': download.isPaused,
                  'is_cancelled': download.isCancelled,
                  'is_failed': download.isFailed,
                })
            .toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get export file path
      final downloadsPath = await DownloadStorageUtils.getDownloadsDirectory();
      final exportFileName =
          'nhasix_downloads_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final exportFile = File(path.join(downloadsPath, exportFileName));

      // Write to file
      await exportFile.writeAsString(jsonString);

      _logger.i('DownloadBloc: Export completed: ${exportFile.path}');

      // Show success notification (could implement showNotification method later)
      // For now just log success
      _logger.i('Export Complete: Downloads exported to $exportFileName');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during export',
          error: e, stackTrace: stackTrace);

      // Show error notification (could implement showNotification method later)
      // For now just log error
      _logger.e('Export Failed: ${e.toString()}');
    }
  }

  /// Helper method untuk retry PDF conversion dari notification action
  Future<void> _retryPdfConversion(String contentId) async {
    try {
      final downloads = await _userDataRepository.getAllDownloads(
          limit: AppLimits.maxBatchSize);
      final download = downloads.firstWhere(
        (d) => d.contentId == contentId,
        orElse: () =>
            throw Exception('Download not found for content: $contentId'),
      );

      if (download.state == DownloadState.completed) {
        // Trigger PDF conversion event
        add(DownloadConvertToPdfEvent(contentId));
        _logger.i('DownloadBloc: PDF retry initiated for $contentId');
      } else {
        _logger.w(
            'DownloadBloc: Cannot retry PDF - download not completed for $contentId');
      }
    } catch (e) {
      _logger.e('DownloadBloc: Error retrying PDF conversion: $e');
    }
  }

  /// Helper method untuk open downloaded content dari notification action
  Future<void> _openDownloadedContent(String contentId) async {
    try {
      final downloads = await _userDataRepository.getAllDownloads(
          limit: AppLimits.maxBatchSize);

      final download =
          downloads.where((d) => d.contentId == contentId).firstOrNull;

      if (download == null) {
        _logger.w('DownloadBloc: Download not found for content: $contentId');
        return;
      }

      // Robust path resolution
      String? downloadPath = download.downloadPath;
      if (downloadPath == null || downloadPath.isEmpty) {
        // Try to reconstruct path
        if (_settings.customStorageRoot != null &&
            _settings.customStorageRoot!.isNotEmpty) {
          final sourceId = download.sourceId ?? SourceType.crotpedia.id;
          downloadPath = path.join(
              _settings.customStorageRoot!, 'nhasix', sourceId, contentId);
          _logger.d('DownloadBloc: Reconstructed path for open: $downloadPath');
        }
      }

      if (downloadPath != null) {
        final directory = Directory(downloadPath);
        // Relaxed check: Exist on disk is enough, even if state is not "Completed"
        if (await directory.exists()) {
          _logger.i('DownloadBloc: Opening download directory: $downloadPath');

          // Check if this is a PDF file (has pdf/ subdirectory with .pdf files)
          final pdfDir = Directory(path.join(downloadPath, 'pdf'));
          if (await pdfDir.exists()) {
            try {
              final pdfFiles = await pdfDir
                  .list()
                  .where((entity) => entity.path.endsWith('.pdf'))
                  .toList();

              if (pdfFiles.isNotEmpty) {
                _logger.i(
                    'DownloadBloc: Found PDF file, opening with native reader');
                final pdfReaderService = getIt<NativePdfReaderService>();
                // Sort by name to get the latest/main one if multiple
                final sortedFiles = pdfFiles.toList()
                  ..sort((a, b) => b.path.compareTo(a.path));

                await pdfReaderService.openPdf(sortedFiles.first.path);
                return;
              }
            } catch (e) {
              _logger.w('DownloadBloc: Error checking for PDF: $e');
            }
          }

          // Try multiple strategies to open the downloaded content on Android
          bool opened = false;

          // Strategy 1: Try to open the main download directory
          try {
            final result = await OpenFile.open(downloadPath);
            if (result.type == ResultType.done) {
              _logger.i('DownloadBloc: Successfully opened download directory');
              opened = true;
            } else {
              _logger.w(
                  'DownloadBloc: Failed to open directory: ${result.message}');
            }
          } catch (e) {
            _logger.w('DownloadBloc: Error opening directory: $e');
          }

          // Strategy 2: If directory opening failed, try opening the images subdirectory
          if (!opened) {
            try {
              final imagesDir = Directory(path.join(downloadPath, 'images'));
              if (await imagesDir.exists()) {
                final result = await OpenFile.open(imagesDir.path);
                if (result.type == ResultType.done) {
                  _logger
                      .i('DownloadBloc: Successfully opened images directory');
                  opened = true;
                } else {
                  _logger.w(
                      'DownloadBloc: Failed to open images directory: ${result.message}');
                }
              }
            } catch (e) {
              _logger.w('DownloadBloc: Error opening images directory: $e');
            }
          }

          // Strategy 3: If still not opened, try opening the first image file
          if (!opened) {
            try {
              final imagePaths =
                  await DownloadStorageUtils.getDownloadedImagePaths(contentId);
              if (imagePaths.isNotEmpty) {
                final firstImage = imagePaths.first;
                final result = await OpenFile.open(firstImage);
                if (result.type == ResultType.done) {
                  _logger.i(
                      'DownloadBloc: Successfully opened first image: $firstImage');
                  opened = true;
                } else {
                  _logger.w(
                      'DownloadBloc: Failed to open first image: ${result.message}');
                }
              }
            } catch (e) {
              _logger.w('DownloadBloc: Error opening first image: $e');
            }
          }

          // If all strategies failed, show error
          if (!opened) {
            _logger.e(
                'DownloadBloc: All strategies failed to open downloaded content for $contentId');
          }
        } else {
          _logger
              .w('DownloadBloc: Download directory not found: $downloadPath');
        }
      } else {
        _logger.w(
            'DownloadBloc: Cannot open - path missing and could not be reconstructed for $contentId');
      }
    } catch (e) {
      _logger.e('DownloadBloc: Error opening downloaded content: $e');
    }
  }

  /// Handle toggle selection mode event
  Future<void> _onToggleSelectionMode(
    DownloadToggleSelectionModeEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Toggling selection mode');

      emit(currentState.copyWith(
        isSelectionMode: !currentState.isSelectionMode,
        selectedItems: const {},
        lastUpdated: DateTime.now(),
      ));

      _logger.i(
          'DownloadBloc: Selection mode toggled to ${!currentState.isSelectionMode}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error toggling selection mode',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle select item event
  Future<void> _onSelectItem(
    DownloadSelectItemEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i(
          'DownloadBloc: Selecting item ${event.contentId}: ${event.isSelected}');

      final updatedSelectedItems = Set<String>.from(currentState.selectedItems);
      if (event.isSelected) {
        updatedSelectedItems.add(event.contentId);
      } else {
        updatedSelectedItems.remove(event.contentId);
      }

      emit(currentState.copyWith(
        selectedItems: updatedSelectedItems,
        lastUpdated: DateTime.now(),
      ));

      _logger.i(
          'DownloadBloc: Selected items count: ${updatedSelectedItems.length}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error selecting item',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle select all event
  Future<void> _onSelectAll(
    DownloadSelectAllEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Selecting all items in current tab');

      // Get current tab's downloads (this would need to be passed or determined)
      // For now, select all downloads
      final allContentIds =
          currentState.downloads.map((d) => d.contentId).toSet();

      emit(currentState.copyWith(
        selectedItems: allContentIds,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('DownloadBloc: Selected all ${allContentIds.length} items');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error selecting all items',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle clear selection event
  Future<void> _onClearSelection(
    DownloadClearSelectionEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i('DownloadBloc: Clearing all selections');

      emit(currentState.copyWith(
        selectedItems: const {},
        lastUpdated: DateTime.now(),
      ));

      _logger.i('DownloadBloc: All selections cleared');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error clearing selections',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle bulk delete event
  Future<void> _onBulkDelete(
    DownloadBulkDeleteEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DownloadLoaded) return;

    try {
      _logger.i(
          'DownloadBloc: Starting bulk delete of ${event.contentIds.length} items');

      emit(DownloadProcessing(
        downloads: currentState.downloads,
        settings: currentState.settings,
        operation: 'Deleting ${event.contentIds.length} downloads',
        lastUpdated: currentState.lastUpdated,
      ));

      int successCount = 0;
      int failureCount = 0;
      final errors = <String>[];

      for (final contentId in event.contentIds) {
        try {
          // Cancel if in progress
          if (currentState.getDownload(contentId)?.isInProgress == true) {
            _cancelDownloadTask(contentId);
          }

          // Remove from database
          await _userDataRepository.deleteDownloadStatus(contentId);
          await _downloadContentUseCase.deleteCall(contentId);

          // Invalidate download status cache
          ContentDownloadCache.invalidateCache(contentId);

          successCount++;
          _logger.d('DownloadBloc: Successfully deleted $contentId');
        } catch (e) {
          failureCount++;
          errors.add('$contentId: $e');
          _logger.w('DownloadBloc: Failed to delete $contentId: $e');
        }
      }

      // Create updated downloads list without deleted items
      final updatedDownloads = currentState.downloads
          .where((d) => !event.contentIds.contains(d.contentId))
          .toList();

      // Emit DownloadLoaded immediately with updated data and exit selection mode
      emit(DownloadLoaded(
        downloads: updatedDownloads,
        settings: currentState.settings,
        isSelectionMode: false, // Exit selection mode
        selectedItems: const {}, // Clear selections
        lastUpdated: DateTime.now(),
      ));

      // Show result notification
      if (currentState.settings.enableNotifications) {
        if (failureCount == 0) {
          await _notificationService.showDownloadCompleted(
            contentId: 'bulk_delete',
            title: 'Bulk Delete Completed',
            downloadPath: '',
          );
        } else {
          await _notificationService.showDownloadError(
            contentId: 'bulk_delete',
            title: 'Bulk Delete Partial',
            error: 'Deleted $successCount items, failed $failureCount items',
          );
        }
      }

      _logger.i(
          'DownloadBloc: Bulk delete completed. Success: $successCount, Failures: $failureCount');

      // Optionally trigger refresh for data consistency (but UI is already updated)
      add(const DownloadRefreshEvent());

      if (errors.isNotEmpty) {
        throw BulkDeleteException(
          'Bulk delete completed with $failureCount failures: ${errors.join(', ')}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during bulk delete',
          error: e, stackTrace: stackTrace);

      // Emit error state
      emit(DownloadError(
        message: _getLocalizedString(
          (l10n) => l10n.failedToRemoveDownload(e.toString()),
          'Bulk delete failed: ${e.toString()}',
        ),
        errorType: _determineErrorType(e),
        previousState: currentState,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Cleanup resources when BLoC is closed
  @override
  Future<void> close() {
    // Cancel progress stream subscription
    _progressSubscription?.cancel();
    _logger.i('DownloadBloc: Progress stream subscription cancelled');

    // Cancel all active downloads
    for (final task in _activeTasks.values) {
      if (!task.isCancelled) {
        task.cancel('BLoC is closing');
      }
      // Unregister from DownloadManager
      DownloadManager().unregisterTask(task.contentId);
    }
    _activeTasks.clear();

    return super.close();
  }
}

/// Exception for bulk delete operations
class BulkDeleteException implements Exception {
  final String message;
  const BulkDeleteException(this.message);

  @override
  String toString() => message;
}
