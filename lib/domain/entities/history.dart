import 'package:equatable/equatable.dart';

/// History entity for tracking reading history
class History extends Equatable {
  const History({
    required this.contentId,
    required this.lastViewed,
    this.lastPage = 1,
    this.totalPages = 0,
    this.timeSpent = Duration.zero,
    this.isCompleted = false,
    this.title,
    this.coverUrl,
  });

  final String contentId;
  final DateTime lastViewed;
  final int lastPage;
  final int totalPages;
  final Duration timeSpent;
  final bool isCompleted;
  final String? title;
  final String? coverUrl;

  @override
  List<Object?> get props => [
        contentId,
        lastViewed,
        lastPage,
        totalPages,
        timeSpent,
        isCompleted,
        title,
        coverUrl,
      ];

  History copyWith({
    String? contentId,
    DateTime? lastViewed,
    int? lastPage,
    int? totalPages,
    Duration? timeSpent,
    bool? isCompleted,
    String? title,
    String? coverUrl,
  }) {
    return History(
      contentId: contentId ?? this.contentId,
      lastViewed: lastViewed ?? this.lastViewed,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      timeSpent: timeSpent ?? this.timeSpent,
      isCompleted: isCompleted ?? this.isCompleted,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
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
      {String? title, String? coverUrl}) {
    return History(
      contentId: contentId,
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
      'lastViewed': lastViewed.millisecondsSinceEpoch,
      'lastPage': lastPage,
      'totalPages': totalPages,
      'timeSpent': timeSpent.inMilliseconds,
      'isCompleted': isCompleted,
      'title': title,
      'coverUrl': coverUrl,
    };
  }

  /// Create from JSON map
  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      contentId: json['contentId'],
      lastViewed: DateTime.fromMillisecondsSinceEpoch(json['lastViewed']),
      lastPage: json['lastPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      timeSpent: Duration(milliseconds: json['timeSpent'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
      title: json['title'],
      coverUrl: json['coverUrl'],
    );
  }
}
