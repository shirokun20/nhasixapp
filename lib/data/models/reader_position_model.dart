import '../../domain/entities/reader_position.dart';

/// Data model for ReaderPosition entity
/// Handles conversion between entity and database map format
class ReaderPositionModel extends ReaderPosition {
  const ReaderPositionModel({
    required super.contentId,
    required super.currentPage,
    required super.totalPages,
    required super.lastAccessed,
    super.readingProgress = 0.0,
    super.readingTimeMinutes = 0,
    super.title,
    super.coverUrl,
  });

  /// Create model from entity
  factory ReaderPositionModel.fromEntity(ReaderPosition entity) {
    return ReaderPositionModel(
      contentId: entity.contentId,
      currentPage: entity.currentPage,
      totalPages: entity.totalPages,
      lastAccessed: entity.lastAccessed,
      readingProgress: entity.readingProgress,
      readingTimeMinutes: entity.readingTimeMinutes,
      title: entity.title,
      coverUrl: entity.coverUrl,
    );
  }

  /// Convert model to entity
  ReaderPosition toEntity() {
    return ReaderPosition(
      contentId: contentId,
      currentPage: currentPage,
      totalPages: totalPages,
      lastAccessed: lastAccessed,
      readingProgress: readingProgress,
      readingTimeMinutes: readingTimeMinutes,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Create model from database map
  factory ReaderPositionModel.fromMap(Map<String, dynamic> map) {
    return ReaderPositionModel(
      contentId: map['content_id'] as String,
      currentPage: map['current_page'] as int,
      totalPages: map['total_pages'] as int,
      lastAccessed:
          DateTime.fromMillisecondsSinceEpoch(map['last_accessed'] as int),
      readingProgress: (map['reading_progress'] as num).toDouble(),
      readingTimeMinutes: map['reading_time_minutes'] as int,
      title: map['title'] as String?,
      coverUrl: map['cover_url'] as String?,
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'current_page': currentPage,
      'total_pages': totalPages,
      'last_accessed': lastAccessed.millisecondsSinceEpoch,
      'reading_progress': readingProgress,
      'reading_time_minutes': readingTimeMinutes,
      'title': title,
      'cover_url': coverUrl,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Create model from JSON
  factory ReaderPositionModel.fromJson(Map<String, dynamic> json) {
    return ReaderPositionModel(
      contentId: json['contentId'] as String,
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      readingProgress: (json['readingProgress'] as num).toDouble(),
      readingTimeMinutes: json['readingTimeMinutes'] as int,
      title: json['title'] as String?,
      coverUrl: json['coverUrl'] as String?,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'lastAccessed': lastAccessed.toIso8601String(),
      'readingProgress': readingProgress,
      'readingTimeMinutes': readingTimeMinutes,
      'title': title,
      'coverUrl': coverUrl,
    };
  }
}
