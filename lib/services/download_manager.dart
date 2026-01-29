import 'dart:async';
import 'package:logger/logger.dart';

import '../domain/entities/download_task.dart';
import '../domain/entities/download_status.dart';
import 'native_download_service.dart';

/// Represents a progress update for a download
class DownloadProgressUpdate {
  const DownloadProgressUpdate({
    required this.contentId,
    required this.downloadedPages,
    required this.totalPages,
    this.downloadSpeed,
    this.estimatedTimeRemaining,
  });

  final String contentId;
  final int downloadedPages;
  final int totalPages;
  final double? downloadSpeed; // bytes per second
  final Duration? estimatedTimeRemaining;

  double get progressPercentage => 
      totalPages > 0 ? (downloadedPages / totalPages) * 100 : 0;

  @override
  String toString() {
    return 'DownloadProgressUpdate(contentId: $contentId, '
           'progress: ${progressPercentage.toStringAsFixed(1)}%, '
           'pages: $downloadedPages/$totalPages)';
  }
}

/// Global download manager for stream-based progress updates
/// Singleton service that coordinates real-time progress updates across the app
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal() {
    _logger = Logger();
    _logger.i('DownloadManager: Initialized');
    _initializeNativeListener();
  }

  late final Logger _logger;
  final StreamController<DownloadProgressUpdate> _progressController = 
      StreamController<DownloadProgressUpdate>.broadcast();
  final Map<String, DownloadTask> _tasks = {};
  
  // NEW: Listen to Native Download Service
  StreamSubscription? _nativeSubscription;
  
  void _initializeNativeListener() {
    try {
      _nativeSubscription = NativeDownloadService().getProgressStream().listen(
        (data) {
          try {
            final String contentId = data['contentId'] as String;
            final String status = data['status'] as String;
            // Native sends int, but safety cast is good
            final int downloaded = (data['downloadedPages'] as num).toInt();
            final int total = (data['totalPages'] as num).toInt();

            if (status == 'COMPLETED') {
               emitCompletion(contentId, DownloadState.completed);
               // Also emit 100% progress just in case
               emitProgress(DownloadProgressUpdate(
                 contentId: contentId,
                 downloadedPages: total > 0 ? total : downloaded, // Ensure full
                 totalPages: total,
               ));
            } else if (status == 'FAILED') {
               emitCompletion(contentId, DownloadState.failed);
            } else {
               // Progress
               emitProgress(DownloadProgressUpdate(
                  contentId: contentId,
                  downloadedPages: downloaded,
                  totalPages: total,
               ));
            }
          } catch (e) {
            _logger.e('Error processing native progress event', error: e);
          }
        },
        onError: (e) {
           _logger.e('Native progress stream error', error: e);
        }
      );
    } catch (e) {
      _logger.e('DownloadManager: Failed to initialize native listener', error: e);
    }
  }
  
  /// Stream for listening to download progress updates
  Stream<DownloadProgressUpdate> get progressStream => _progressController.stream;
  
  /// Register a download task
  void registerTask(DownloadTask task) {
    _tasks[task.contentId] = task;
    _logger.d('DownloadManager: Registered task: ${task.contentId}');
  }
  
  /// Unregister a download task
  void unregisterTask(String contentId) {
    _tasks.remove(contentId);
    _logger.d('DownloadManager: Unregistered task: $contentId');
  }
  
  /// Get a download task
  DownloadTask? getTask(String contentId) {
    return _tasks[contentId];
  }
  
  /// Check if a download is paused
  bool isPaused(String contentId) {
    final task = _tasks[contentId];
    return task?.isPaused ?? false;
  }
  
  /// Check if a download is cancelled
  bool isCancelled(String contentId) {
    final task = _tasks[contentId];
    return task?.isCancelled ?? false;
  }

  /// Pause a download via Native Service
  Future<void> pauseDownload(String contentId) async {
    _logger.d('DownloadManager: Pausing $contentId');
    try {
      // 1. Mark local task as paused
      final task = _tasks[contentId];
      task?.pause();
      
      // 2. Call native service
      await NativeDownloadService().pauseDownload(contentId);
      
      // 3. Emit update (status will be updated by stream mostly, but we can optimistically log)
    } catch (e) {
      _logger.e('DownloadManager: Failed to pause $contentId', error: e);
      rethrow;
    }
  }

  /// Resume a download via Native Service (which uses start logic)
  /// Note: Resume usually requires re-calling startDownload with params.
  /// If NativeService supports simple resume, use it. NativeDownloadService.pause usually cancels.
  /// To resume, we often need to restart.
  /// HOWEVER, the native worker checks existing files.
  /// So 'resume' is effectively 'start' again. 
  /// BUT `NativeDownloadService` does NOT have a parameterless `resume` method.
  /// So verify: the Bloc handles resume by calling `_onStart` again with params.
  /// So `DownloadManager.resume` might just be a state update or no-op if Bloc handles it.
  /// Let's keep it simple: Bloc handles the restart strategy. DownloadManager just updates state.
  void resumeTaskState(String contentId) {
     final task = _tasks[contentId];
     task?.resume();
  }

  /// Cancel a download via Native Service
  Future<void> cancelDownload(String contentId) async {
    _logger.d('DownloadManager: Cancelling $contentId');
    try {
      final task = _tasks[contentId];
      task?.cancel();
      
      await NativeDownloadService().cancelDownload(contentId);
      
      // Emit completion/cancelled event? 
      // The native stream should send "CANCELLED" or we just remove it.
      // NativeDownloadService doesn't seem to emit CANCELLED state in stream explicitly 
      // based on my read of NativeDownloadManager.kt (it maps CANCELLED, but does WorkManager emit it?)
      // We'll rely on the stream or manual cleanup in Bloc.
    } catch (e) {
      _logger.e('DownloadManager: Failed to cancel $contentId', error: e);
      rethrow;
    }
  }
  
  /// Emit a progress update to all listeners
  void emitProgress(DownloadProgressUpdate update) {
    if (!_progressController.isClosed) {
      _progressController.add(update);
      _logger.d('DownloadManager: Emitted progress update: $update');
    } else {
      _logger.w('DownloadManager: Cannot emit progress - controller is closed');
    }
  }
  
  /// Emit a completion event to notify listeners of download completion
  void emitCompletion(String contentId, DownloadState state) {
    if (!_progressController.isClosed) {
      // Create a completion update with special marker
      final completionUpdate = DownloadProgressUpdate(
        contentId: contentId,
        downloadedPages: -1, // Special marker for completion
        totalPages: -1,
        downloadSpeed: 0.0,
        estimatedTimeRemaining: Duration.zero,
      );
      _progressController.add(completionUpdate);
      _logger.d('DownloadManager: Emitted completion event for $contentId with state: $state');
    } else {
      _logger.w('DownloadManager: Cannot emit completion - controller is closed');
    }
  }
  
  /// Check if the stream is still active
  bool get isActive => !_progressController.isClosed;
  
  /// Close the stream controller
  void dispose() {
    _nativeSubscription?.cancel();
    if (!_progressController.isClosed) {
      _progressController.close();
      _logger.i('DownloadManager: Disposed');
    }
    _tasks.clear();
  }
}
