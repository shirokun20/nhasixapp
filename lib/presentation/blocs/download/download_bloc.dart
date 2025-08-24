import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/entities/download_task.dart';
import '../../../domain/usecases/downloads/downloads_usecases.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../services/notification_service.dart';
import '../../../services/download_manager.dart';
import '../../../services/pdf_conversion_service.dart';

part 'download_event.dart';
part 'download_state.dart';

/// BLoC for managing downloads with queue system and concurrent downloads
class DownloadBloc extends Bloc<DownloadEvent, DownloadBlocState> {
  DownloadBloc({
    required DownloadContentUseCase downloadContentUseCase,
    required GetDownloadStatusUseCase getDownloadStatusUseCase,
    required GetContentDetailUseCase getContentDetailUseCase,
    required UserDataRepository userDataRepository,
    required ContentRepository contentRepository,
    required Dio httpClient,
    required Logger logger,
    required Connectivity connectivity,
    required NotificationService notificationService,
    required PdfConversionService pdfConversionService,
  })  : _downloadContentUseCase = downloadContentUseCase,
        _getDownloadStatusUseCase = getDownloadStatusUseCase,
        _getContentDetailUseCase = getContentDetailUseCase,
        _userDataRepository = userDataRepository,
        _contentRepository = contentRepository,
        _httpClient = httpClient,
        _logger = logger,
        _connectivity = connectivity,
        _notificationService = notificationService,
        _pdfConversionService = pdfConversionService,
        super(const DownloadInitial()) {
    // Register event handlers
    on<DownloadInitializeEvent>(_onInitialize);
    on<DownloadQueueEvent>(_onQueue);
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
    on<DownloadCleanupStorageEvent>(_onCleanupStorage);
    on<DownloadExportEvent>(_onExport);

    // Initialize notifications
    _notificationService.initialize();
    
    // Initialize progress stream subscription
    _initializeProgressStream();
  }

  final DownloadContentUseCase _downloadContentUseCase;
  final GetDownloadStatusUseCase _getDownloadStatusUseCase;
  final GetContentDetailUseCase _getContentDetailUseCase;
  final UserDataRepository _userDataRepository;
  final ContentRepository _contentRepository;
  final Dio _httpClient;
  final Logger _logger;
  final Connectivity _connectivity;
  final NotificationService _notificationService;
  final PdfConversionService _pdfConversionService;

  // Internal state
  DownloadSettings _settings = DownloadSettings.defaultSettings();
  final Map<String, DownloadTask> _activeTasks = {};
  StreamSubscription<DownloadProgressUpdate>? _progressSubscription;

  // Constants
  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Download progress notifications';

  /// Initialize progress stream subscription for real-time updates
  void _initializeProgressStream() {
    _progressSubscription = DownloadManager().progressStream.listen(
      (update) {
        _logger.d('DownloadBloc: Received progress update: $update');
        
        // Check if this is a completion event (special marker)
        if (update.downloadedPages == -1 && update.totalPages == -1) {
          _logger.d('DownloadBloc: Received completion event for ${update.contentId}');
          add(DownloadRefreshEvent());
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

    /// Initialize download manager
  Future<void> _onInitialize(
    DownloadInitializeEvent event,
    Emitter<DownloadBlocState> emit,
  ) async {
    try {
      _logger.i('DownloadBloc: Initializing download manager');
      emit(const DownloadInitializing());

      // Load existing downloads
      final downloads = await _userDataRepository.getAllDownloads();
      
      // Load settings (use existing settings)
      final userPrefs = await _userDataRepository.getUserPreferences();
      _settings = DownloadSettings(
        maxConcurrentDownloads: userPrefs.maxConcurrentDownloads,
        imageQuality: userPrefs.imageQuality,
        autoRetry: true, // Default to true
        retryAttempts: 3,  // Default to 3
        enableNotifications: true, // Default to true
        wifiOnly: false,   // Default to false
      );

      emit(DownloadLoaded(
        downloads: downloads,
        settings: _settings,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('DownloadBloc: Initialized with ${downloads.length} downloads');
      
      // Process queue - auto-start any queued downloads if needed
      _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error initializing',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to initialize download manager: ${e.toString()}',
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
        _logger.d('DownloadBloc: Already at max concurrent downloads: $maxConcurrent');
        return;
      }
      
      // Sort queued downloads by priority (implement priority later)
      final sortedQueue = List<DownloadStatus>.from(queuedDownloads);
      
      // Calculate how many new downloads we can start
      final availableSlots = maxConcurrent - activeDownloads.length;
      final toStart = sortedQueue.take(availableSlots).toList();
      
      _logger.i('DownloadBloc: Starting ${toStart.length} downloads from queue');
      
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

      // Check if already exists
      final existingDownload = currentState.downloads
          .where((d) => d.contentId == event.content.id)
          .firstOrNull;

      if (existingDownload != null) {
        _logger.w('DownloadBloc: Content ${event.content.id} already in download list');
        
        // If download failed or was cancelled, retry it
        if (existingDownload.canRetry) {
          _logger.i('DownloadBloc: Retrying existing download for ${event.content.id}');
          add(DownloadRetryEvent(event.content.id));
        }
        
        return;
      }

      // Create download status with priority
      final downloadStatus = DownloadStatus.initial(
        event.content.id,
        event.content.pageCount,
      );

      // Save to database
      await _userDataRepository.saveDownloadStatus(downloadStatus);

      // Update state with new download added
      final updatedDownloads = [...currentState.downloads, downloadStatus];
      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Send notification
      if (currentState.settings.enableNotifications) {
        _notificationService.showDownloadStarted(
          contentId: event.content.id,
          title: event.content.title,
        );
      }

      _logger.i('DownloadBloc: Queued download for ${event.content.id}');
      
      // Check if we can start downloading right away
      _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error queuing download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to queue download: ${e.toString()}',
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
        _logger.i('DownloadBloc: Download already in progress: ${event.contentId}');
        return;
      }

      // Check WiFi requirement before starting download
      if (currentState.settings.wifiOnly) {
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.wifi) {
          _logger.i('DownloadBloc: WiFi required but not connected, queuing download for ${event.contentId}');
          
          final waitingDownload = download.copyWith(
            state: DownloadState.queued,
            error: 'Waiting for WiFi connection',
          );
          
          await _userDataRepository.saveDownloadStatus(waitingDownload);
          add(const DownloadRefreshEvent());
          return;
        }
      }

      // Update status to downloading
      var updatedDownload = download.copyWith(
        state: DownloadState.downloading,
        startTime: DateTime.now(),
        error: null,
      );
      
      await _userDataRepository.saveDownloadStatus(updatedDownload);
      
      // Update state immediately to show downloading
      final updatedDownloads = currentState.downloads.map((d) => 
        d.contentId == event.contentId ? updatedDownload : d
      ).toList();
      
      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Get content details for download
      final content = await _getContentDetailUseCase.call(
        GetContentDetailParams.fromString(event.contentId),
      );

      // Create download task for this download
      final task = DownloadTask(
        contentId: event.contentId,
        title: content.title,
      );
      _activeTasks[event.contentId] = task;
      
      // Register task with DownloadManager for global access
      DownloadManager().registerTask(task);
      
      // Show notification
      if (currentState.settings.enableNotifications) {
        _notificationService.showDownloadStarted(
          contentId: event.contentId,
          title: content.title,
        );
      }

      // Start actual download using use case
      final downloadParams = DownloadContentParams.immediate(
        content,
        imageQuality: currentState.settings.imageQuality,
        timeoutDuration: currentState.settings.timeoutDuration,
      );
      final result = await _downloadContentUseCase.call(downloadParams);

      // Remove task
      _activeTasks.remove(event.contentId);
      
      // Unregister task from DownloadManager
      DownloadManager().unregisterTask(event.contentId);
      
      // Show completion notification
      if (currentState.settings.enableNotifications && result.isCompleted) {
        _notificationService.showDownloadCompleted(
          contentId: event.contentId,
          title: content.title,
          downloadPath: result.downloadPath ?? '',
        );
      }

      // Process queue to start next download
      _processQueue();

      _logger.i('DownloadBloc: Completed download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error starting download',
          error: e, stackTrace: stackTrace);

      // Remove task on error
      _activeTasks.remove(event.contentId);
      
      // Unregister task from DownloadManager
      DownloadManager().unregisterTask(event.contentId);
      
      // Update download status to failed
      if (currentState.getDownload(event.contentId) != null) {
        final currentDownload = currentState.getDownload(event.contentId)!;
        
        // Check if auto retry is enabled and we haven't exceeded retry attempts
        if (currentState.settings.autoRetry && 
            currentDownload.retryCount < currentState.settings.retryAttempts) {
          
          _logger.i('DownloadBloc: Auto-retrying download ${event.contentId} (attempt ${currentDownload.retryCount + 1}/${currentState.settings.retryAttempts})');
          
          final retryDownload = currentDownload.copyWith(
            retryCount: currentDownload.retryCount + 1,
            state: DownloadState.queued,
            error: 'Retrying... (${currentDownload.retryCount + 1}/${currentState.settings.retryAttempts})',
            endTime: null, // Reset end time for retry
          );
          
          await _userDataRepository.saveDownloadStatus(retryDownload);
          
          // Update state with retry download
          final updatedDownloads = currentState.downloads.map((d) => 
            d.contentId == event.contentId ? retryDownload : d
          ).toList();
          
          emit(currentState.copyWith(
            downloads: updatedDownloads,
            lastUpdated: DateTime.now(),
          ));
          
          // Schedule retry with delay
          Timer(Duration(milliseconds: currentState.settings.retryDelay.inMilliseconds), () {
            if (!isClosed) { // Check if bloc is still active
              add(DownloadStartEvent(event.contentId));
            }
          });
          
          return;
        }
        
        // If no retry or max attempts reached, mark as failed
        final failedDownload = currentDownload.copyWith(
          state: DownloadState.failed,
          error: e.toString(),
          endTime: DateTime.now(),
        );
        
        await _userDataRepository.saveDownloadStatus(failedDownload);
        
        // Show error notification
        if (currentState.settings.enableNotifications) {
          _notificationService.showDownloadError(
            contentId: event.contentId,
            title: failedDownload.contentId, // Use content ID if we don't have title
            error: e.toString(),
          );
        }
        
        // Update state with failed download
        final updatedDownloads = currentState.downloads.map((d) => 
          d.contentId == event.contentId ? failedDownload : d
        ).toList();
        
        emit(currentState.copyWith(
          downloads: updatedDownloads,
          lastUpdated: DateTime.now(),
        ));
        
        // Process queue to start next download
        _processQueue();
      } else {
        // Emit error state only if we can't update the download status
        emit(DownloadError(
          message: 'Failed to start download: ${e.toString()}',
          errorType: _determineErrorType(e),
          previousState: currentState,
          stackTrace: stackTrace,
        ));
      }
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

      // Pause the download task
      final task = _activeTasks[event.contentId];
      if (task != null) {
        task.pause();
        _logger.i('DownloadBloc: Paused task for ${event.contentId}');
      }

      // Update status to paused
      final updatedDownload = download.copyWith(
        state: DownloadState.paused,
        endTime: DateTime.now(),
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // ✅ NEW: Immediately update notification to show paused status with current progress
      if (currentState.settings.enableNotifications) {
        final progressPercentage = updatedDownload.progressPercentage.round();
        _notificationService.updateDownloadProgress(
          contentId: event.contentId,
          progress: progressPercentage,
          title: updatedDownload.contentId, // Use contentId as fallback for title
          isPaused: true,
        ).catchError((e) {
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
        message: 'Failed to pause download: ${e.toString()}',
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

      // Cancel the download task
      _cancelDownloadTask(event.contentId);

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
      _logger.e('DownloadBloc: Error cancelling download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to cancel download: ${e.toString()}',
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
      final updatedDownload = download.copyWith(
        state: DownloadState.queued,
        error: null,
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Queued retry for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error retrying download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to retry download: ${e.toString()}',
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

      // Resume the task if it exists
      final task = _activeTasks[event.contentId];
      if (task != null) {
        task.resume();
        _logger.i('DownloadBloc: Resumed task for ${event.contentId}');
      }

      // Update status to queued for resume
      final updatedDownload = download.copyWith(
        state: DownloadState.queued,
        startTime: DateTime.now(),
        endTime: null,
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

      // ✅ NEW: Update notification to show resumed status with current progress
      if (currentState.settings.enableNotifications) {
        final progressPercentage = updatedDownload.progressPercentage.round();
        _notificationService.updateDownloadProgress(
          contentId: event.contentId,
          progress: progressPercentage,
          title: updatedDownload.contentId, // Use contentId as fallback for title
          isPaused: false, // Resume means no longer paused
        ).catchError((e) {
          _logger.w('DownloadBloc: Failed to update resume notification: $e');
        });
      }

      // Refresh downloads and process queue
      add(const DownloadRefreshEvent());
      _processQueue();

      _logger.i('DownloadBloc: Resumed download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error resuming download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to resume download: ${e.toString()}',
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

      // Remove from database
      await _userDataRepository.deleteDownloadStatus(event.contentId);
      await _downloadContentUseCase.deleteCall(event.contentId);

      // Refresh downloads
      add(const DownloadRefreshEvent());

      _logger.i('DownloadBloc: Removed download for ${event.contentId}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error removing download',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to remove download: ${e.toString()}',
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

      // Reload downloads from database
      final downloads = await _userDataRepository.getAllDownloads();
      
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
      _processQueue();
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error refreshing downloads',
          error: e, stackTrace: stackTrace);
          
      // Only emit error if we don't have a valid state to preserve
      if (currentState is! DownloadLoaded) {
        emit(DownloadError(
          message: 'Failed to refresh downloads: ${e.toString()}',
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
      _logger.d('DownloadBloc: Not in updatable state, refreshing downloads for progress update');
      add(const DownloadRefreshEvent());
      return;
    }

    try {
      // Find the download and update its progress
      final downloadIndex = downloads.indexWhere(
        (d) => d.contentId == event.contentId,
      );

      if (downloadIndex == -1) {
        _logger.w('DownloadBloc: Download not found for progress update: ${event.contentId}');
        return;
      }

      final currentDownload = downloads[downloadIndex];
      
      // Update progress only if download is still in progress
      if (!currentDownload.isInProgress) {
        _logger.d('DownloadBloc: Ignoring progress update for non-active download: ${event.contentId}');
        return;
      }

      // Create updated download with new progress
      final updatedDownload = currentDownload.copyWith(
        downloadedPages: event.downloadedPages,
        speed: event.downloadSpeed,
      );

      // ✅ FIXED: Only update if progress actually changed to prevent unnecessary updates
      if (currentDownload.downloadedPages == event.downloadedPages) {
        _logger.d('DownloadBloc: Ignoring duplicate progress update for ${event.contentId}');
        return;
      }

      // ✅ FIXED: Check if download should be completed (progress = 100%)
      // This helps handle completion status immediately
      if (event.downloadedPages >= event.totalPages && 
          event.downloadSpeed == 0.0 && 
          event.estimatedTimeRemaining == Duration.zero) {
        _logger.i('DownloadBloc: Download appears completed, refreshing status for ${event.contentId}');
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
      _userDataRepository.saveDownloadStatus(updatedDownload).catchError((e) {
        _logger.w('DownloadBloc: Failed to save progress to database: $e');
      });

      // ✅ NEW: Update notification progress through DownloadBloc for synchronization
      if (currentState.settings.enableNotifications && updatedDownload.isInProgress) {
        final progressPercentage = updatedDownload.progressPercentage.round();
        _notificationService.updateDownloadProgress(
          contentId: event.contentId,
          progress: progressPercentage,
          title: updatedDownload.contentId, // Use contentId as fallback for title
          isPaused: false,
        ).catchError((e) {
          _logger.w('DownloadBloc: Failed to update notification progress: $e');
        });
      }

      _logger.d('DownloadBloc: Updated progress for ${event.contentId}: ${event.downloadedPages}/${event.totalPages}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error updating progress',
          error: e, stackTrace: stackTrace);
      // Don't emit error state for progress updates to avoid disrupting downloads
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
      );

      // Update state
      emit(currentState.copyWith(settings: _settings));

      _logger.i('DownloadBloc: Updated download settings - concurrent: ${_settings.maxConcurrentDownloads}, quality: ${_settings.imageQuality}, wifiOnly: ${_settings.wifiOnly}, notifications: ${_settings.enableNotifications}');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error updating settings',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to update settings: ${e.toString()}',
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
        message: 'Failed to pause all downloads: ${e.toString()}',
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
      _processQueue();

      _logger.i('DownloadBloc: Resumed all paused downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error resuming all downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to resume all downloads: ${e.toString()}',
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
        message: 'Failed to cancel all downloads: ${e.toString()}',
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

      _logger.i('DownloadBloc: Cleared ${completedDownloads.length} completed downloads');
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error clearing completed downloads',
          error: e, stackTrace: stackTrace);
      emit(DownloadError(
        message: 'Failed to clear completed downloads: ${e.toString()}',
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
        orElse: () => throw Exception('Download not found for content: ${event.contentId}'),
      );

      // Check if download is completed
      if (!download.isCompleted) {
        _logger.w('DownloadBloc: Cannot convert incomplete download to PDF: ${event.contentId}');
        await _notificationService.showPdfConversionError(
          contentId: event.contentId,
          title: event.contentId,
          error: 'Download is not completed yet',
        );
        return;
      }

      // Get content details for proper title
      final content = await _getContentDetailUseCase.call(
        GetContentDetailParams.fromString(event.contentId),
      );

      // Get downloaded image paths from content repository or download service
      // For now, we'll use a placeholder path construction
      final imagePaths = await _getDownloadedImagePaths(event.contentId);
      
      if (imagePaths.isEmpty) {
        _logger.w('DownloadBloc: No downloaded images found for PDF conversion: ${event.contentId}');
        await _notificationService.showPdfConversionError(
          contentId: event.contentId,
          title: content.title,
          error: 'No images found for conversion',
        );
        return;
      }

      // Start PDF conversion in background using PdfConversionService
      await _pdfConversionService.convertToPdfInBackground(
        contentId: event.contentId,
        title: content.title,
        imagePaths: imagePaths,
        maxPagesPerFile: 50, // Split into 50-page chunks
      );

      _logger.i('DownloadBloc: PDF conversion started for ${event.contentId}');
      
      // The actual conversion happens in background via PdfConversionService
      // User will be notified via notifications about progress and completion
      
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during PDF conversion for ${event.contentId}', 
          error: e, stackTrace: stackTrace);
      
      // Show error notification to user
      await _notificationService.showPdfConversionError(
        contentId: event.contentId,
        title: event.contentId,
        error: e.toString(),
      );
    }
  }

  /// Helper method to get downloaded image paths for a content
  /// This method retrieves all image files from the download directory
  Future<List<String>> _getDownloadedImagePaths(String contentId) async {
    try {
      _logger.d('DownloadBloc: Getting image paths for content: $contentId');
      
      // Use smart Downloads directory detection (same as DownloadService)
      final downloadsPath = await _getDownloadsDirectory();
      final imagesDir = Directory(path.join(
        downloadsPath, 
        'nhasix', 
        contentId, 
        'images'
      ));
      
      // Check if directory exists
      if (!await imagesDir.exists()) {
        _logger.w('DownloadBloc: Images directory does not exist: ${imagesDir.path}');
        return <String>[];
      }
      
      // List all files in the images directory
      final files = await imagesDir.list().toList();
      
      // Filter only image files and sort them
      final imagePaths = files
          .whereType<File>()
          .where((file) {
            final extension = path.extension(file.path).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
          })
          .map((file) => file.path)
          .toList();
      
      // Sort by filename to maintain page order
      imagePaths.sort();
      
      _logger.i('DownloadBloc: Found ${imagePaths.length} image files for content: $contentId');
      
      if (imagePaths.isEmpty) {
        _logger.w('DownloadBloc: No downloaded images found for PDF conversion: $contentId, folder download image ada di ${imagesDir.path}');
      } else {
        _logger.d('DownloadBloc: Image files: ${imagePaths.take(5).join(', ')}${imagePaths.length > 5 ? '...' : ''}');
      }
      
      return imagePaths;
    } catch (e) {
      _logger.e('DownloadBloc: Error getting downloaded image paths: $e');
      return <String>[];
    }
  }

  /// Smart Downloads directory detection (same as DownloadService)
  /// Tries multiple possible Downloads folder names and locations
  Future<String> _getDownloadsDirectory() async {
    try {
      // First, try to get external storage directory
      Directory? externalDir;
      try {
        externalDir = await getExternalStorageDirectory();
      } catch (e) {
        _logger.w('Could not get external storage directory: $e');
      }

      if (externalDir != null) {
        // Try to find Downloads folder in external storage root
        final externalRoot = externalDir.path.split('/Android')[0];
        
        // Common Downloads folder names (English, Indonesian, Spanish, etc.)
        final downloadsFolderNames = [
          'Download',     // English (most common)
          'Downloads',    // English alternative
          'Unduhan',      // Indonesian
          'Descargas',    // Spanish
          'Téléchargements', // French
          'Downloads',    // German uses English
          'ダウンロード',     // Japanese
        ];

        // Try each possible Downloads folder
        for (final folderName in downloadsFolderNames) {
          final downloadsDir = Directory(path.join(externalRoot, folderName));
          if (await downloadsDir.exists()) {
            _logger.d('DownloadBloc: Found Downloads directory: ${downloadsDir.path}');
            return downloadsDir.path;
          }
        }

        // If no Downloads folder found, check for app-specific external storage
        final appDownloadsDir = Directory(path.join(externalDir.path, 'downloads'));
        if (await appDownloadsDir.exists()) {
          _logger.d('DownloadBloc: Using app-specific downloads directory: ${appDownloadsDir.path}');
          return appDownloadsDir.path;
        }
      }

      // Fallback 1: Try hardcoded common paths
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/emulated/0/Unduhan',
        '/sdcard/Download',
        '/sdcard/Downloads',
      ];

      for (final commonPath in commonPaths) {
        final dir = Directory(commonPath);
        if (await dir.exists()) {
          _logger.d('DownloadBloc: Found Downloads directory at common path: $commonPath');
          return commonPath;
        }
      }

      // Fallback 2: Use application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final documentsDownloadsDir = Directory(path.join(documentsDir.path, 'downloads'));
      _logger.d('DownloadBloc: Using app documents downloads directory: ${documentsDownloadsDir.path}');
      return documentsDownloadsDir.path;

    } catch (e) {
      _logger.e('DownloadBloc: Error detecting Downloads directory: $e');
      
      // Emergency fallback: use app documents
      final documentsDir = await getApplicationDocumentsDirectory();
      final emergencyDir = Directory(path.join(documentsDir.path, 'downloads'));
      _logger.w('DownloadBloc: Using emergency fallback directory: ${emergencyDir.path}');
      return emergencyDir.path;
    }
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
      final downloadsPath = await _getDownloadsDirectory();
      final nhasixDir = Directory(path.join(downloadsPath, 'nhasix'));
      
      if (!await nhasixDir.exists()) {
        _logger.i('DownloadBloc: No nhasix directory found, nothing to cleanup');
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
            final dirSize = await _getDirectorySize(contentDir);
            
            // Delete the directory
            await contentDir.delete(recursive: true);
            
            cleanedFiles++;
            freedSpaceBytes += dirSize;
            
            _logger.d('DownloadBloc: Cleaned up ${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB from: $contentId');
          } catch (e) {
            _logger.w('DownloadBloc: Failed to delete directory: ${contentDir.path}, error: $e');
          }
        } else {
          // For active downloads, clean up temporary files
          await _cleanupTempFiles(contentDir);
        }
      }

      _logger.i('DownloadBloc: Storage cleanup completed. Cleaned $cleanedFiles directories, freed ${(freedSpaceBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Show success notification (could implement showNotification method later)
      // For now just log success
      _logger.i('Storage Cleanup Complete: Cleaned $cleanedFiles items, freed ${(freedSpaceBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during storage cleanup', error: e, stackTrace: stackTrace);
      
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
        'downloads': currentState.downloads.map((download) => {
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
        }).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get export file path
      final downloadsPath = await _getDownloadsDirectory();
      final exportFileName = 'nhasix_downloads_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final exportFile = File(path.join(downloadsPath, exportFileName));
      
      // Write to file
      await exportFile.writeAsString(jsonString);
      
      _logger.i('DownloadBloc: Export completed: ${exportFile.path}');
      
      // Show success notification (could implement showNotification method later) 
      // For now just log success
      _logger.i('Export Complete: Downloads exported to $exportFileName');
      
    } catch (e, stackTrace) {
      _logger.e('DownloadBloc: Error during export', error: e, stackTrace: stackTrace);
      
      // Show error notification (could implement showNotification method later)
      // For now just log error
      _logger.e('Export Failed: ${e.toString()}');
    }
  }

  /// Helper method to calculate directory size
  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      _logger.w('DownloadBloc: Error calculating directory size: $e');
    }
    return size;
  }

  /// Helper method to clean up temporary files in a directory
  Future<void> _cleanupTempFiles(Directory directory) async {
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          // Delete temporary files (those ending with .tmp, .temp, .part, etc.)
          if (fileName.endsWith('.tmp') || 
              fileName.endsWith('.temp') || 
              fileName.endsWith('.part') ||
              fileName.startsWith('.')) {
            try {
              await entity.delete();
              _logger.d('DownloadBloc: Deleted temp file: ${entity.path}');
            } catch (e) {
              _logger.w('DownloadBloc: Failed to delete temp file: ${entity.path}, error: $e');
            }
          }
        }
      }
    } catch (e) {
      _logger.w('DownloadBloc: Error cleaning temp files in: ${directory.path}, error: $e');
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
