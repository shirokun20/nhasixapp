import 'package:equatable/equatable.dart';

/// History entity for tracking reading history
class History extends Equatable {
  const History({
    required this.contentId,
    this.sourceId = 'nhentai', // Default to nhentai for backward compatibility
    required this.lastViewed,
    this.lastPage = 1,
    this.totalPages = 0,
    this.timeSpent = Duration.zero,
    this.isCompleted = false,
    this.title,
    this.coverUrl,
    this.parentId, // Series/parent content ID for chapter mode
    this.chapterId,
    this.chapterIndex,
    this.chapterTitle,
  });

  final String contentId;
  final String sourceId;
  final DateTime lastViewed;
  final int lastPage;
  final int totalPages;
  final Duration timeSpent;
  final bool isCompleted;
  final String? title;
  final String? coverUrl;

  // Chapter support
  final String? parentId; // Series/parent content ID for chapter mode
  final String? chapterId;
  final int? chapterIndex;
  final String? chapterTitle;

  /// Check if this is chapter-based content
  /// Chapter mode is detected if:
  /// 1. chapterId is set and not empty, OR
  /// 2. chapterIndex is not null, OR
  /// 3. chapterTitle is set and not empty, OR
  /// 4. contentId contains chapter pattern (e.g., "manga-name-chapter-1")
  bool get isChapterMode {
    // Direct chapter metadata check
    if (chapterId != null && chapterId!.isNotEmpty) return true;
    if (chapterIndex != null) return true;
    if (chapterTitle != null && chapterTitle!.isNotEmpty) return true;

    // Pattern-based detection for komiktap/crotpedia
    // Chapter IDs typically contain "chapter" or "ch-" and are not purely numeric
    if (!RegExp(r'^\d+$').hasMatch(contentId)) {
      if (contentId.contains('chapter') || contentId.contains('ch-')) {
        return true;
      }
      // Additional check: multiple dashes suggest slug-based chapter ID
      final dashCount = '-'.allMatches(contentId).length;
      if (dashCount >= 3) return true;
    }

    return false;
  }

  @override
  List<Object?> get props => [
        contentId,
        sourceId,
        lastViewed,
        lastPage,
        totalPages,
        timeSpent,
        isCompleted,
        title,
        coverUrl,
        parentId,
        chapterId,
        chapterIndex,
        chapterTitle,
      ];

  History copyWith({
    String? contentId,
    String? sourceId,
    DateTime? lastViewed,
    int? lastPage,
    int? totalPages,
    Duration? timeSpent,
    bool? isCompleted,
    String? title,
    String? coverUrl,
    String? parentId,
    String? chapterId,
    int? chapterIndex,
    String? chapterTitle,
  }) {
    return History(
      contentId: contentId ?? this.contentId,
      sourceId: sourceId ?? this.sourceId,
      lastViewed: lastViewed ?? this.lastViewed,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      timeSpent: timeSpent ?? this.timeSpent,
      isCompleted: isCompleted ?? this.isCompleted,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      parentId: parentId ?? this.parentId,
      chapterId: chapterId ?? this.chapterId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterTitle: chapterTitle ?? this.chapterTitle,
    );
  }

  /// Get reading progress as percentage (0.0 to 1.0)
  double get progress {
    if (totalPages == 0) return 0.0;
    return lastPage / totalPages;
  }

  /// Get reading progress as percentage (0 to 100)
  int get progressPercentage {
    return (progress * 100).round();
  }

  /// Check if content was just started
  bool get isJustStarted => lastPage <= 1;

  /// Check if content is in progress
  bool get isInProgress => lastPage > 1 && !isCompleted;

  /// Get remaining pages
  int get remainingPages {
    if (totalPages == 0) return 0;
    return totalPages - lastPage + 1;
  }

  /// Get pages read
  int get pagesRead => lastPage;

  /// Get formatted time spent
  String get formattedTimeSpent {
    final hours = timeSpent.inHours;
    final minutes = timeSpent.inMinutes.remainder(60);
    final seconds = timeSpent.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get reading status text
  String get statusText {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'Reading ($progressPercentage%)';
    if (isJustStarted) return 'Started';
    return 'Not started';
  }

  /// Get time since last viewed
  String get timeSinceLastViewed {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Update reading progress
  History updateProgress(int newPage, {Duration? additionalTime}) {
    final newTimeSpent =
        additionalTime != null ? timeSpent + additionalTime : timeSpent;

    final newIsCompleted = totalPages > 0 && newPage >= totalPages;

    return copyWith(
      lastPage: newPage,
      lastViewed: DateTime.now(),
      timeSpent: newTimeSpent,
      isCompleted: newIsCompleted,
    );
  }

  /// Mark as completed
  History markCompleted() {
    return copyWith(
      isCompleted: true,
      lastPage: totalPages > 0 ? totalPages : lastPage,
      lastViewed: DateTime.now(),
    );
  }

  /// Reset progress
  History reset() {
    return copyWith(
      lastPage: 1,
      timeSpent: Duration.zero,
      isCompleted: false,
      lastViewed: DateTime.now(),
    );
  }

  /// Create initial history entry
  factory History.initial(String contentId, int totalPages,
      {String? title, String? coverUrl, String sourceId = 'nhentai'}) {
    return History(
      contentId: contentId,
      sourceId: sourceId,
      lastViewed: DateTime.now(),
      totalPages: totalPages,
      title: title,
      coverUrl: coverUrl,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'sourceId': sourceId,
      'lastViewed': lastViewed.millisecondsSinceEpoch,
      'lastPage': lastPage,
      'totalPages': totalPages,
      'timeSpent': timeSpent.inMilliseconds,
      'isCompleted': isCompleted,
      'title': title,
      'coverUrl': coverUrl,
      'parentId': parentId,
      'chapterId': chapterId,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
    };
  }

  /// Create from JSON map
  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      contentId: json['contentId'],
      sourceId: json['sourceId'] ?? 'nhentai',
      lastViewed: DateTime.fromMillisecondsSinceEpoch(json['lastViewed']),
      lastPage: json['lastPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      timeSpent: Duration(milliseconds: json['timeSpent'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
      title: json['title'],
      coverUrl: json['coverUrl'],
      parentId: json['parentId'],
      chapterId: json['chapterId'],
      chapterIndex: json['chapterIndex'],
      chapterTitle: json['chapterTitle'],
    );
  }
}
