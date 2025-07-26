import 'package:equatable/equatable.dart';

/// Download status entity for tracking download progress
class DownloadStatus extends Equatable {
  const DownloadStatus({
    required this.contentId,
    required this.state,
    this.downloadedPages = 0,
    this.totalPages = 0,
    this.startTime,
    this.endTime,
    this.error,
    this.downloadPath,
    this.fileSize = 0,
    this.speed = 0.0,
  });

  final String contentId;
  final DownloadState state;
  final int downloadedPages;
  final int totalPages;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? error;
  final String? downloadPath;
  final int fileSize; // in bytes
  final double speed; // bytes per second

  @override
  List<Object?> get props => [
        contentId,
        state,
        downloadedPages,
        totalPages,
        startTime,
        endTime,
        error,
        downloadPath,
        fileSize,
        speed,
      ];

  DownloadStatus copyWith({
    String? contentId,
    DownloadState? state,
    int? downloadedPages,
    int? totalPages,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
    String? downloadPath,
    int? fileSize,
    double? speed,
  }) {
    return DownloadStatus(
      contentId: contentId ?? this.contentId,
      state: state ?? this.state,
      downloadedPages: downloadedPages ?? this.downloadedPages,
      totalPages: totalPages ?? this.totalPages,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
      downloadPath: downloadPath ?? this.downloadPath,
      fileSize: fileSize ?? this.fileSize,
      speed: speed ?? this.speed,
    );
  }

  /// Get download progress as percentage (0.0 to 1.0)
  double get progress {
    if (totalPages == 0) return 0.0;
    return downloadedPages / totalPages;
  }

  /// Get download progress as percentage (0 to 100)
  int get progressPercentage {
    return (progress * 100).round();
  }

  /// Check if download is in progress
  bool get isInProgress => state == DownloadState.downloading;

  /// Check if download is completed
  bool get isCompleted => state == DownloadState.completed;

  /// Check if download is failed
  bool get isFailed => state == DownloadState.failed;

  /// Check if download is paused
  bool get isPaused => state == DownloadState.paused;

  /// Check if download is queued
  bool get isQueued => state == DownloadState.queued;

  /// Check if download is cancelled
  bool get isCancelled => state == DownloadState.cancelled;

  /// Check if download can be resumed
  bool get canResume => isPaused || isFailed;

  /// Check if download can be paused
  bool get canPause => isInProgress || isQueued;

  /// Check if download can be cancelled
  bool get canCancel => !isCompleted && !isCancelled;

  /// Get estimated time remaining
  Duration? get estimatedTimeRemaining {
    if (!isInProgress || speed <= 0 || totalPages == 0) return null;

    final remainingPages = totalPages - downloadedPages;
    if (remainingPages <= 0) return Duration.zero;

    // Estimate based on current speed (assuming average file size per page)
    final avgBytesPerPage =
        fileSize > 0 ? fileSize / downloadedPages : 1024 * 1024; // 1MB default
    final remainingBytes = remainingPages * avgBytesPerPage;
    final secondsRemaining = remainingBytes / speed;

    return Duration(seconds: secondsRemaining.round());
  }

  /// Get download duration
  Duration? get downloadDuration {
    if (startTime == null) return null;
    final endTimeToUse = endTime ?? DateTime.now();
    return endTimeToUse.difference(startTime!);
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var size = fileSize.toDouble();
    var suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  /// Get formatted download speed
  String get formattedSpeed {
    if (speed <= 0) return '0 B/s';

    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var currentSpeed = speed;
    var suffixIndex = 0;

    while (currentSpeed >= 1024 && suffixIndex < suffixes.length - 1) {
      currentSpeed /= 1024;
      suffixIndex++;
    }

    return '${currentSpeed.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  /// Get status display text
  String get statusText {
    switch (state) {
      case DownloadState.queued:
        return 'Queued';
      case DownloadState.downloading:
        return 'Downloading ($progressPercentage%)';
      case DownloadState.paused:
        return 'Paused ($progressPercentage%)';
      case DownloadState.completed:
        return 'Completed';
      case DownloadState.failed:
        return 'Failed';
      case DownloadState.cancelled:
        return 'Cancelled';
    }
  }

  /// Create initial download status
  factory DownloadStatus.initial(String contentId, int totalPages) {
    return DownloadStatus(
      contentId: contentId,
      state: DownloadState.queued,
      totalPages: totalPages,
      startTime: DateTime.now(),
    );
  }

  /// Create completed download status
  factory DownloadStatus.completed(
    String contentId,
    int totalPages,
    String downloadPath,
    int fileSize,
  ) {
    return DownloadStatus(
      contentId: contentId,
      state: DownloadState.completed,
      downloadedPages: totalPages,
      totalPages: totalPages,
      downloadPath: downloadPath,
      fileSize: fileSize,
      endTime: DateTime.now(),
    );
  }

  /// Create failed download status
  factory DownloadStatus.failed(String contentId, String error) {
    return DownloadStatus(
      contentId: contentId,
      state: DownloadState.failed,
      error: error,
      endTime: DateTime.now(),
    );
  }
}

/// Download states
enum DownloadState {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Extension for DownloadState display names
extension DownloadStateExtension on DownloadState {
  String get displayName {
    switch (this) {
      case DownloadState.queued:
        return 'Queued';
      case DownloadState.downloading:
        return 'Downloading';
      case DownloadState.paused:
        return 'Paused';
      case DownloadState.completed:
        return 'Completed';
      case DownloadState.failed:
        return 'Failed';
      case DownloadState.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if state is active (in progress)
  bool get isActive {
    return this == DownloadState.downloading || this == DownloadState.queued;
  }

  /// Check if state is terminal (finished)
  bool get isTerminal {
    return this == DownloadState.completed ||
        this == DownloadState.failed ||
        this == DownloadState.cancelled;
  }

  /// Check if state can be retried
  bool get canRetry {
    return this == DownloadState.failed || this == DownloadState.cancelled;
  }
}
