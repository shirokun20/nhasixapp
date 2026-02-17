import 'package:equatable/equatable.dart';

/// Entity for tracking reader position and progress
/// Used to persist reading state between app sessions
class ReaderPosition extends Equatable {
  const ReaderPosition({
    required this.contentId,
    required this.currentPage,
    required this.totalPages,
    required this.lastAccessed,
    this.readingProgress = 0.0,
    this.readingTimeMinutes = 0,
    this.title,
    this.coverUrl,
    this.chapterId,
    this.chapterIndex,
    this.chapterTitle,
  });

  /// Content ID (unique identifier)
  final String contentId;

  /// Current page being read (1-indexed)
  final int currentPage;

  /// Total pages in content
  final int totalPages;

  /// Last accessed timestamp
  final DateTime lastAccessed;

  /// Reading progress (0.0 to 1.0)
  final double readingProgress;

  /// Reading time in minutes
  final int readingTimeMinutes;

  /// Optional content title for display
  final String? title;

  /// Optional cover URL for display
  final String? coverUrl;

  /// Optional chapter ID for chapter-based content
  final String? chapterId;

  /// Optional chapter index for ordering
  final int? chapterIndex;

  /// Optional chapter title
  final String? chapterTitle;

  @override
  List<Object?> get props => [
        contentId,
        currentPage,
        totalPages,
        lastAccessed,
        readingProgress,
        readingTimeMinutes,
        title,
        coverUrl,
        chapterId,
        chapterIndex,
        chapterTitle,
      ];

  /// Copy with new values
  ReaderPosition copyWith({
    String? contentId,
    int? currentPage,
    int? totalPages,
    DateTime? lastAccessed,
    double? readingProgress,
    int? readingTimeMinutes,
    String? title,
    String? coverUrl,
    String? chapterId,
    int? chapterIndex,
    String? chapterTitle,
  }) {
    return ReaderPosition(
      contentId: contentId ?? this.contentId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      readingProgress: readingProgress ?? this.readingProgress,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      chapterId: chapterId ?? this.chapterId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
    );
  }

  /// Calculate progress from current page and total pages
  static double calculateProgress(int currentPage, int totalPages) {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  /// Get reading progress as percentage (0 to 100)
  int get progressPercentage {
    return (readingProgress * 100).round();
  }

  /// Check if reading is completed (reached last page)
  bool get isCompleted {
    return currentPage >= totalPages && totalPages > 0;
  }

  /// Check if reading has started (beyond first page)
  bool get isStarted {
    return currentPage > 1;
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage <= 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= totalPages && totalPages > 0;

  /// Create from basic parameters
  factory ReaderPosition.create({
    required String contentId,
    required int currentPage,
    required int totalPages,
    String? title,
    String? coverUrl,
    int readingTimeMinutes = 0,
    String? chapterId,
    int? chapterIndex,
    String? chapterTitle,
  }) {
    return ReaderPosition(
      contentId: contentId,
      currentPage: currentPage,
      totalPages: totalPages,
      lastAccessed: DateTime.now(),
      readingProgress: calculateProgress(currentPage, totalPages),
      readingTimeMinutes: readingTimeMinutes,
      title: title,
      coverUrl: coverUrl,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
    );
  }

  /// Create initial position (first page)
  factory ReaderPosition.initial({
    required String contentId,
    required int totalPages,
    String? title,
    String? coverUrl,
    String? chapterId,
    int? chapterIndex,
    String? chapterTitle,
  }) {
    return ReaderPosition.create(
      contentId: contentId,
      currentPage: 1,
      totalPages: totalPages,
      title: title,
      coverUrl: coverUrl,
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
    );
  }

  @override
  String toString() {
    return 'ReaderPosition('
        'contentId: $contentId, '
        'currentPage: $currentPage, '
        'totalPages: $totalPages, '
        'progress: $progressPercentage%, '
        'lastAccessed: $lastAccessed'
        ')';
  }
}
