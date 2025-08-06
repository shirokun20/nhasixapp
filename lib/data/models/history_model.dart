import '../../domain/entities/history.dart';

/// Data model for History entity with database serialization
class HistoryModel extends History {
  const HistoryModel({
    required super.contentId,
    required super.lastViewed,
    super.lastPage = 1,
    super.totalPages = 0,
    super.timeSpent = Duration.zero,
    super.isCompleted = false,
    this.title,
    this.coverUrl,
  });

  final String? title;
  final String? coverUrl;

  /// Create HistoryModel from History entity
  factory HistoryModel.fromEntity(
    History history, {
    String? title,
    String? coverUrl,
  }) {
    return HistoryModel(
      contentId: history.contentId,
      lastViewed: history.lastViewed,
      lastPage: history.lastPage,
      totalPages: history.totalPages,
      timeSpent: history.timeSpent,
      isCompleted: history.isCompleted,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Convert to History entity
  History toEntity() {
    return History(
      contentId: contentId,
      lastViewed: lastViewed,
      lastPage: lastPage,
      totalPages: totalPages,
      timeSpent: timeSpent,
      isCompleted: isCompleted,
    );
  }

  /// Create from database map
  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      contentId: map['id'], // Changed from content_id to id
      lastViewed: DateTime.fromMillisecondsSinceEpoch(map['last_viewed']),
      lastPage: map['last_page'] ?? 1,
      totalPages: map['total_pages'] ?? 0,
      timeSpent: Duration(milliseconds: map['time_spent'] ?? 0),
      isCompleted: (map['is_completed'] ?? 0) == 1,
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
      'last_viewed': lastViewed.millisecondsSinceEpoch,
      'last_page': lastPage,
      'total_pages': totalPages,
      'time_spent': timeSpent.inMilliseconds,
      'is_completed': isCompleted ? 1 : 0,
    };
  }
}
