part of 'download_bloc.dart';

/// Base class for all download events
abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize download manager
class DownloadInitializeEvent extends DownloadEvent {
  const DownloadInitializeEvent();
}

/// Event to queue a new download
class DownloadQueueEvent extends DownloadEvent {
  const DownloadQueueEvent({
    required this.content,
    this.priority = 0,
  });

  final Content content;
  final int priority;

  @override
  List<Object?> get props => [content, priority];
}

/// Event to start/resume a download
class DownloadStartEvent extends DownloadEvent {
  const DownloadStartEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to pause a download
class DownloadPauseEvent extends DownloadEvent {
  const DownloadPauseEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to cancel a download
class DownloadCancelEvent extends DownloadEvent {
  const DownloadCancelEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to retry a failed download
class DownloadRetryEvent extends DownloadEvent {
  const DownloadRetryEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to resume a paused download
class DownloadResumeEvent extends DownloadEvent {
  const DownloadResumeEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to remove a download from the list
class DownloadRemoveEvent extends DownloadEvent {
  const DownloadRemoveEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}

/// Event to refresh download list
class DownloadRefreshEvent extends DownloadEvent {
  const DownloadRefreshEvent();
}

/// Event to update download progress in real-time
class DownloadProgressUpdateEvent extends DownloadEvent {
  const DownloadProgressUpdateEvent({
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
  List<Object?> get props => [
        contentId,
        downloadedPages,
        totalPages,
        downloadSpeed,
        estimatedTimeRemaining,
      ];
}

/// Event to update download settings
class DownloadSettingsUpdateEvent extends DownloadEvent {
  const DownloadSettingsUpdateEvent({
    this.maxConcurrentDownloads,
    this.downloadPath,
    this.imageQuality,
    this.autoRetry,
    this.retryAttempts,
  });

  final int? maxConcurrentDownloads;
  final String? downloadPath;
  final String? imageQuality;
  final bool? autoRetry;
  final int? retryAttempts;

  @override
  List<Object?> get props => [
        maxConcurrentDownloads,
        downloadPath,
        imageQuality,
        autoRetry,
        retryAttempts,
      ];
}

/// Event to pause all downloads
class DownloadPauseAllEvent extends DownloadEvent {
  const DownloadPauseAllEvent();
}

/// Event to resume all downloads
class DownloadResumeAllEvent extends DownloadEvent {
  const DownloadResumeAllEvent();
}

/// Event to cancel all downloads
class DownloadCancelAllEvent extends DownloadEvent {
  const DownloadCancelAllEvent();
}

/// Event to clear completed downloads
class DownloadClearCompletedEvent extends DownloadEvent {
  const DownloadClearCompletedEvent();
}

/// Event to cleanup storage
class DownloadCleanupStorageEvent extends DownloadEvent {
  const DownloadCleanupStorageEvent();
}

/// Event to export download list
class DownloadExportEvent extends DownloadEvent {
  const DownloadExportEvent();
}

/// Event to convert completed download to PDF
/// This triggers background PDF conversion with notifications
class DownloadConvertToPdfEvent extends DownloadEvent {
  const DownloadConvertToPdfEvent(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => [contentId];
}
