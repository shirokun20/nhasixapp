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
  });

  final String contentId;
  final DateTime lastViewed;
  final int lastPage;
  final int totalPages;
  final Duration timeSpent;
  final bool isCompleted;

  @override
  List<Object> get props => [
        contentId,
        lastViewed,
        lastPage,
        totalPages,
        timeSpent,
        isCompleted,
      ];

  History copyWith({
    String? contentId,
    DateTime? lastViewed,
    int? lastPage,
    int? totalPages,
    Duration? timeSpent,
    bool? isCompleted,
  }) {
    return History(
      contentId: contentId ?? this.contentId,
      lastViewed: lastViewed ?? this.lastViewed,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      timeSpent: timeSpent ?? this.timeSpent,
      isCompleted: isCompleted ?? this.isCompleted,
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
  factory History.initial(String contentId, int totalPages) {
    return History(
      contentId: contentId,
      lastViewed: DateTime.now(),
      totalPages: totalPages,
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
    );
  }
}

/// Reading statistics entity
class ReadingStatistics extends Equatable {
  const ReadingStatistics({
    this.totalContentRead = 0,
    this.totalPagesRead = 0,
    this.totalTimeSpent = Duration.zero,
    this.favoriteArtists = const {},
    this.favoriteTags = const {},
    this.favoriteLanguages = const {},
    this.readingStreak = 0,
    this.longestStreak = 0,
    this.averageReadingTime = Duration.zero,
  });

  final int totalContentRead;
  final int totalPagesRead;
  final Duration totalTimeSpent;
  final Map<String, int> favoriteArtists;
  final Map<String, int> favoriteTags;
  final Map<String, int> favoriteLanguages;
  final int readingStreak; // Current streak in days
  final int longestStreak; // Longest streak in days
  final Duration averageReadingTime; // Average per content

  @override
  List<Object> get props => [
        totalContentRead,
        totalPagesRead,
        totalTimeSpent,
        favoriteArtists,
        favoriteTags,
        favoriteLanguages,
        readingStreak,
        longestStreak,
        averageReadingTime,
      ];

  ReadingStatistics copyWith({
    int? totalContentRead,
    int? totalPagesRead,
    Duration? totalTimeSpent,
    Map<String, int>? favoriteArtists,
    Map<String, int>? favoriteTags,
    Map<String, int>? favoriteLanguages,
    int? readingStreak,
    int? longestStreak,
    Duration? averageReadingTime,
  }) {
    return ReadingStatistics(
      totalContentRead: totalContentRead ?? this.totalContentRead,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      favoriteLanguages: favoriteLanguages ?? this.favoriteLanguages,
      readingStreak: readingStreak ?? this.readingStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      averageReadingTime: averageReadingTime ?? this.averageReadingTime,
    );
  }

  /// Get formatted total time spent
  String get formattedTotalTime {
    final hours = totalTimeSpent.inHours;
    final minutes = totalTimeSpent.inMinutes.remainder(60);

    if (hours > 24) {
      final days = hours ~/ 24;
      final remainingHours = hours.remainder(24);
      return '${days}d ${remainingHours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get formatted average reading time
  String get formattedAverageTime {
    final minutes = averageReadingTime.inMinutes;
    final seconds = averageReadingTime.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get top favorite artists (limited to top N)
  List<MapEntry<String, int>> getTopArtists([int limit = 5]) {
    final entries = favoriteArtists.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get top favorite tags (limited to top N)
  List<MapEntry<String, int>> getTopTags([int limit = 10]) {
    final entries = favoriteTags.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get top favorite languages (limited to top N)
  List<MapEntry<String, int>> getTopLanguages([int limit = 5]) {
    final entries = favoriteLanguages.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get average pages per content
  double get averagePagesPerContent {
    if (totalContentRead == 0) return 0.0;
    return totalPagesRead / totalContentRead;
  }

  /// Check if user has reading streak
  bool get hasStreak => readingStreak > 0;

  /// Check if current streak is the longest
  bool get isLongestStreak => readingStreak == longestStreak;
}
