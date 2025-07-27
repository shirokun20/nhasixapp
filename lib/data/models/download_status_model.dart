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
  });

  /// Create DownloadStatusModel from DownloadStatus entity
  factory DownloadStatusModel.fromEntity(DownloadStatus status) {
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
    );
  }

  /// Create from database map
  factory DownloadStatusModel.fromMap(Map<String, dynamic> map) {
    return DownloadStatusModel(
      contentId: map['content_id'],
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
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'state': state.name,
      'downloaded_pages': downloadedPages,
      'total_pages': totalPages,
      'start_time': startTime?.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'error_message': error,
      'download_path': downloadPath,
      'file_size': fileSize,
    };
  }
}
