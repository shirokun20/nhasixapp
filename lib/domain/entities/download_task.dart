import 'package:dio/dio.dart';

/// Represents a download task with proper state management for pause/cancel operations
class DownloadTask {
  DownloadTask({
    required this.contentId,
    required this.title,
    CancelToken? cancelToken,
  }) : cancelToken = cancelToken ?? CancelToken();

  final String contentId;
  final String title;
  final CancelToken cancelToken;
  
  bool _isPaused = false;
  bool _isCancelled = false;
  DateTime? _pausedAt;
  DateTime? _cancelledAt;

  /// Check if the task is paused
  bool get isPaused => _isPaused;

  /// Check if the task is cancelled
  bool get isCancelled => _isCancelled || cancelToken.isCancelled;

  /// Check if the task is active (not paused and not cancelled)
  bool get isActive => !isPaused && !isCancelled;

  /// Get when the task was paused
  DateTime? get pausedAt => _pausedAt;

  /// Get when the task was cancelled
  DateTime? get cancelledAt => _cancelledAt;

  /// Pause the download task
  void pause() {
    if (!_isCancelled && !_isPaused) {
      _isPaused = true;
      _pausedAt = DateTime.now();
    }
  }

  /// Resume the download task
  void resume() {
    if (!_isCancelled && _isPaused) {
      _isPaused = false;
      _pausedAt = null;
    }
  }

  /// Cancel the download task
  void cancel([String? reason]) {
    if (!_isCancelled) {
      _isCancelled = true;
      _cancelledAt = DateTime.now();
      
      if (!cancelToken.isCancelled) {
        cancelToken.cancel(reason ?? 'Download cancelled by user');
      }
    }
  }

  /// Get current status text
  String get statusText {
    if (isCancelled) return 'Cancelled';
    if (isPaused) return 'Paused';
    return 'Active';
  }

  @override
  String toString() {
    return 'DownloadTask(contentId: $contentId, title: $title, status: $statusText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DownloadTask &&
            runtimeType == other.runtimeType &&
            contentId == other.contentId;
  }

  @override
  int get hashCode => contentId.hashCode;
}
