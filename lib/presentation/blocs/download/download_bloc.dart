import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/downloads/downloads_usecases.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../services/notification_service.dart';

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
  })  : _downloadContentUseCase = downloadContentUseCase,
        _getDownloadStatusUseCase = getDownloadStatusUseCase,
        _getContentDetailUseCase = getContentDetailUseCase,
        _userDataRepository = userDataRepository,
        _contentRepository = contentRepository,
        _httpClient = httpClient,
        _logger = logger,
        _connectivity = connectivity,
        _notificationService = notificationService,
        super(const DownloadInitial()) {
    // Register event handlers
    on<DownloadInitializeEvent>(_onInitialize);
    on<DownloadQueueEvent>(_onQueue);
    on<DownloadStartEvent>(_onStart);
    on<DownloadPauseEvent>(_onPause);
    on<DownloadCancelEvent>(_onCancel);
    on<DownloadRetryEvent>(_onRetry);
    on<DownloadRemoveEvent>(_onRemove);
    on<DownloadRefreshEvent>(_onRefresh);
    on<DownloadProgressUpdateEvent>(_onProgressUpdate);
    on<DownloadSettingsUpdateEvent>(_onSettingsUpdate);
    on<DownloadPauseAllEvent>(_onPauseAll);
    on<DownloadResumeAllEvent>(_onResumeAll);
    on<DownloadCancelAllEvent>(_onCancelAll);
    on<DownloadClearCompletedEvent>(_onClearCompleted);

    // Initialize notifications
    _notificationService.initialize();
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

  // Internal state
  DownloadSettings _settings = DownloadSettings.defaultSettings();
  final Map<String, CancelToken> _activeCancelTokens = {};

  // Constants
  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Download progress notifications';

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
        downloadPath: userPrefs.downloadPath ?? '',
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

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _activeCancelTokens[event.contentId] = cancelToken;
      
      // Show notification
      if (currentState.settings.enableNotifications) {
        _notificationService.showDownloadStarted(
          contentId: event.contentId,
          title: content.title,
        );
      }

      // Start actual download using use case
      final downloadParams = DownloadContentParams.immediate(content);
      final result = await _downloadContentUseCase.call(downloadParams);

      // Remove cancel token
      _activeCancelTokens.remove(event.contentId);
      
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

      // Remove cancel token on error
      _activeCancelTokens.remove(event.contentId);
      
      // Update download status to failed
      if (currentState.getDownload(event.contentId) != null) {
        final failedDownload = currentState.getDownload(event.contentId)!.copyWith(
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

      // Cancel the download task
      _cancelDownloadTask(event.contentId);

      // Update status to paused
      final updatedDownload = download.copyWith(
        state: DownloadState.paused,
        endTime: DateTime.now(),
      );

      await _userDataRepository.saveDownloadStatus(updatedDownload);

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
    if (currentState is! DownloadLoaded) return;

    try {
      // Find the download and update its progress
      final downloadIndex = currentState.downloads.indexWhere(
        (d) => d.contentId == event.contentId,
      );

      if (downloadIndex == -1) {
        _logger.w('DownloadBloc: Download not found for progress update: ${event.contentId}');
        return;
      }

      final currentDownload = currentState.downloads[downloadIndex];
      
      // Update progress only if download is still in progress
      if (!currentDownload.isInProgress) {
        _logger.d('DownloadBloc: Ignoring progress update for non-active download: ${event.contentId}');
        return;
      }

      // Create updated download with new progress
      final updatedDownload = currentDownload.copyWith(
        downloadedPages: event.downloadedPages,
      );

      // Update downloads list
      final updatedDownloads = List<DownloadStatus>.from(currentState.downloads);
      updatedDownloads[downloadIndex] = updatedDownload;

      // Emit new state with updated progress
      emit(currentState.copyWith(
        downloads: updatedDownloads,
        lastUpdated: DateTime.now(),
      ));

      // Save progress to database (but don't await to keep it fast)
      _userDataRepository.saveDownloadStatus(updatedDownload).catchError((e) {
        _logger.w('DownloadBloc: Failed to save progress to database: $e');
      });

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

      // Update settings
      _settings = _settings.copyWith(
        maxConcurrentDownloads: event.maxConcurrentDownloads,
        downloadPath: event.downloadPath,
        imageQuality: event.imageQuality,
        autoRetry: event.autoRetry,
        retryAttempts: event.retryAttempts,
      );

      // Update state
      emit(currentState.copyWith(settings: _settings));

      _logger.i('DownloadBloc: Updated download settings');
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
    final cancelToken = _activeCancelTokens[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      _activeCancelTokens.remove(contentId);
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

  /// Cleanup resources when BLoC is closed
  @override
  Future<void> close() {
    // Cancel all active downloads
    for (final cancelToken in _activeCancelTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('BLoC is closing');
      }
    }
    _activeCancelTokens.clear();

    return super.close();
  }
}
