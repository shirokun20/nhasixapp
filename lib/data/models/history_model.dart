import '../../domain/entities/history.dart';

/// Data model for History entity with database serialization
class HistoryModel extends History {
  const HistoryModel({
    required super.contentId,
    super.sourceId = 'nhentai',
    required super.lastViewed,
    super.lastPage = 1,
    super.totalPages = 0,
    super.timeSpent = Duration.zero,
    super.isCompleted = false,
    super.title,
    super.coverUrl,
    super.parentId,
    super.chapterId,
    super.chapterIndex,
    super.chapterTitle,
  });

  /// Create HistoryModel from History entity
  factory HistoryModel.fromEntity(
    History history, {
    String? title,
    String? coverUrl,
    String? parentId,
  }) {
    return HistoryModel(
      contentId: history.contentId,
      sourceId: history.sourceId,
      lastViewed: history.lastViewed,
      lastPage: history.lastPage,
      totalPages: history.totalPages,
      timeSpent: history.timeSpent,
      isCompleted: history.isCompleted,
      title: title,
      coverUrl: coverUrl,
      parentId: parentId ?? history.parentId,
      chapterId: history.chapterId,
      chapterIndex: history.chapterIndex,
      chapterTitle: history.chapterTitle,
    );
  }

  /// Convert to History entity
  History toEntity() {
    return History(
      contentId: contentId,
      sourceId: sourceId,
      lastViewed: lastViewed,
      lastPage: lastPage,
      totalPages: totalPages,
      timeSpent: timeSpent,
      isCompleted: isCompleted,
      title: title,
      coverUrl: coverUrl,
      parentId: parentId,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
    );
  }

  /// Create from database map
  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      contentId: map['id'], // Changed from content_id to id
      sourceId: map['source_id'] ?? 'nhentai',
      lastViewed: DateTime.fromMillisecondsSinceEpoch(map['last_viewed']),
      lastPage: map['last_page'] ?? 1,
      totalPages: map['total_pages'] ?? 0,
      timeSpent: Duration(milliseconds: map['time_spent'] ?? 0),
      isCompleted: (map['is_completed'] ?? 0) == 1,
      title: map['title'],
      coverUrl: map['cover_url'],
      parentId: map['parent_id'] as String?,
      chapterId: map['chapter_id'] as String?,
      chapterIndex: map['chapter_index'] as int?,
      chapterTitle: map['chapter_title'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': contentId, // Changed from content_id to id
      'source_id': sourceId,
      'title': title,
      'cover_url': coverUrl,
      'parent_id': parentId,
      'last_viewed': lastViewed.millisecondsSinceEpoch,
      'last_page': lastPage,
      'total_pages': totalPages,
      'time_spent': timeSpent.inMilliseconds,
      'is_completed': isCompleted ? 1 : 0,
      'chapter_id': chapterId ?? '',
      'chapter_index': chapterIndex ?? 0,
      'chapter_title': chapterTitle,
    };
  }
}
