import '../../domain/entities/download_status.dart';

/// Data model for DownloadStatus entity with database serialization
class DownloadStatusModel extends DownloadStatus {
  const DownloadStatusModel({
    required super.contentId,
    required super.state,
    super.downloadedPages = 0,
    super.totalPages = 0,
    super.startTime,
    super.endTime,
    super.error,
    super.downloadPath,
    super.fileSize = 0,
    super.speed = 0.0,
    super.retryCount = 0,
    super.startPage,
    super.endPage,
    this.title,
    this.coverUrl,
  });

  final String? title;
  final String? coverUrl;

  /// Create DownloadStatusModel from DownloadStatus entity
  factory DownloadStatusModel.fromEntity(
    DownloadStatus status, {
    String? title,
    String? coverUrl,
  }) {
    return DownloadStatusModel(
      contentId: status.contentId,
      state: status.state,
      downloadedPages: status.downloadedPages,
      totalPages: status.totalPages,
      startTime: status.startTime,
      endTime: status.endTime,
      error: status.error,
      downloadPath: status.downloadPath,
      fileSize: status.fileSize,
      speed: status.speed,
      retryCount: status.retryCount,
      startPage: status.startPage,
      endPage: status.endPage,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Convert to DownloadStatus entity
  DownloadStatus toEntity() {
    return DownloadStatus(
      contentId: contentId,
      state: state,
      downloadedPages: downloadedPages,
      totalPages: totalPages,
      startTime: startTime,
      endTime: endTime,
      error: error,
      downloadPath: downloadPath,
      fileSize: fileSize,
      speed: speed,
      retryCount: retryCount,
      startPage: startPage,
      endPage: endPage,
    );
  }

  /// Create from database map
  factory DownloadStatusModel.fromMap(Map<String, dynamic> map) {
    return DownloadStatusModel(
      contentId: map['id'], // Changed from content_id to id
      state: DownloadState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => DownloadState.queued,
      ),
      downloadedPages: map['downloaded_pages'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      startTime: map['start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['start_time'])
          : null,
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      error: map['error_message'],
      downloadPath: map['download_path'],
      fileSize: map['file_size'] ?? 0,
      retryCount: map['retry_count'] ?? 0,
      startPage: map['start_page'],
      endPage: map['end_page'],
      title: map['title'],
      coverUrl: map['cover_url'],
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': contentId, // Changed from content_id to id
      'title': title,
      'cover_url': coverUrl,
      'state': state.name,
      'downloaded_pages': downloadedPages,
      'total_pages': totalPages,
      'start_time': startTime?.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'error_message': error,
      'download_path': downloadPath,
      'file_size': fileSize,
      'retry_count': retryCount,
      'start_page': startPage,
      'end_page': endPage,
    };
  }
}
