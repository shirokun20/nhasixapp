import 'dart:async';
import 'package:logger/logger.dart';

import '../domain/entities/download_task.dart';
import '../domain/entities/download_status.dart';

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
  }

  late final Logger _logger;
  final StreamController<DownloadProgressUpdate> _progressController = 
      StreamController<DownloadProgressUpdate>.broadcast();
  final Map<String, DownloadTask> _tasks = {};
  
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
    if (!_progressController.isClosed) {
      _progressController.close();
      _logger.i('DownloadManager: Disposed');
    }
    _tasks.clear();
  }
}
