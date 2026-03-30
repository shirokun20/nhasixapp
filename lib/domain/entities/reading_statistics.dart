import 'package:equatable/equatable.dart';

/// Entity representing user's reading statistics
class ReadingStatistics extends Equatable {
  const ReadingStatistics({
    required this.totalContentRead,
    required this.totalPagesRead,
    required this.totalTimeSpent,
    required this.favoriteArtists,
    required this.favoriteTags,
    required this.favoriteLanguages,
    required this.averageReadingTime,
    required this.completedContent,
    required this.readingStreak,
    this.lastReadDate,
  });

  /// Total number of content items read
  final int totalContentRead;

  /// Total number of pages read across all content
  final int totalPagesRead;

  /// Total time spent reading
  final Duration totalTimeSpent;

  /// Map of favorite artists and their read count
  final Map<String, int> favoriteArtists;

  /// Map of favorite tags and their occurrence count
  final Map<String, int> favoriteTags;

  /// Map of favorite languages and their read count
  final Map<String, int> favoriteLanguages;

  /// Average time spent reading per content
  final Duration averageReadingTime;

  /// Number of completed content items
  final int completedContent;

  /// Current reading streak in days
  final int readingStreak;

  /// Date of last reading session
  final DateTime? lastReadDate;

  /// Get completion rate as percentage
  double get completionRate {
    if (totalContentRead == 0) return 0.0;
    return (completedContent / totalContentRead) * 100;
  }

  /// Get average pages per content
  double get averagePagesPerContent {
    if (totalContentRead == 0) return 0.0;
    return totalPagesRead / totalContentRead;
  }

  /// Get most read artist
  String? get mostReadArtist {
    if (favoriteArtists.isEmpty) return null;
    return favoriteArtists.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most encountered tag
  String? get mostEncounteredTag {
    if (favoriteTags.isEmpty) return null;
    return favoriteTags.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get most read language
  String? get mostReadLanguage {
    if (favoriteLanguages.isEmpty) return null;
    return favoriteLanguages.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get reading efficiency (pages per minute)
  double get readingEfficiency {
    if (totalTimeSpent.inMinutes == 0) return 0.0;
    return totalPagesRead / totalTimeSpent.inMinutes;
  }

  /// Check if user is an active reader (read in last 7 days)
  bool get isActiveReader {
    if (lastReadDate == null) return false;
    return DateTime.now().difference(lastReadDate!).inDays <= 7;
  }

  /// Get reading level based on total content read
  String get readingLevel {
    if (totalContentRead < 10) return 'Beginner';
    if (totalContentRead < 50) return 'Casual';
    if (totalContentRead < 100) return 'Regular';
    if (totalContentRead < 500) return 'Enthusiast';
    return 'Expert';
  }

  /// Create copy with updated values
  ReadingStatistics copyWith({
    int? totalContentRead,
    int? totalPagesRead,
    Duration? totalTimeSpent,
    Map<String, int>? favoriteArtists,
    Map<String, int>? favoriteTags,
    Map<String, int>? favoriteLanguages,
    Duration? averageReadingTime,
    int? completedContent,
    int? readingStreak,
    DateTime? lastReadDate,
  }) {
    return ReadingStatistics(
      totalContentRead: totalContentRead ?? this.totalContentRead,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      favoriteArtists: favoriteArtists ?? this.favoriteArtists,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      favoriteLanguages: favoriteLanguages ?? this.favoriteLanguages,
      averageReadingTime: averageReadingTime ?? this.averageReadingTime,
      completedContent: completedContent ?? this.completedContent,
      readingStreak: readingStreak ?? this.readingStreak,
      lastReadDate: lastReadDate ?? this.lastReadDate,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalContentRead': totalContentRead,
      'totalPagesRead': totalPagesRead,
      'totalTimeSpent': totalTimeSpent.inMilliseconds,
      'favoriteArtists': favoriteArtists,
      'favoriteTags': favoriteTags,
      'favoriteLanguages': favoriteLanguages,
      'averageReadingTime': averageReadingTime.inMilliseconds,
      'completedContent': completedContent,
      'readingStreak': readingStreak,
      'lastReadDate': lastReadDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReadingStatistics.fromJson(Map<String, dynamic> json) {
    return ReadingStatistics(
      totalContentRead: json['totalContentRead'] ?? 0,
      totalPagesRead: json['totalPagesRead'] ?? 0,
      totalTimeSpent: Duration(milliseconds: json['totalTimeSpent'] ?? 0),
      favoriteArtists: Map<String, int>.from(json['favoriteArtists'] ?? {}),
      favoriteTags: Map<String, int>.from(json['favoriteTags'] ?? {}),
      favoriteLanguages: Map<String, int>.from(json['favoriteLanguages'] ?? {}),
      averageReadingTime:
          Duration(milliseconds: json['averageReadingTime'] ?? 0),
      completedContent: json['completedContent'] ?? 0,
      readingStreak: json['readingStreak'] ?? 0,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.parse(json['lastReadDate'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        totalContentRead,
        totalPagesRead,
        totalTimeSpent,
        favoriteArtists,
        favoriteTags,
        favoriteLanguages,
        averageReadingTime,
        completedContent,
        readingStreak,
        lastReadDate,
      ];

  @override
  String toString() {
    return 'ReadingStatistics('
        'totalContentRead: $totalContentRead, '
        'totalPagesRead: $totalPagesRead, '
        'totalTimeSpent: $totalTimeSpent, '
        'completedContent: $completedContent, '
        'readingStreak: $readingStreak, '
        'completionRate: ${completionRate.toStringAsFixed(1)}%'
        ')';
  }
}
