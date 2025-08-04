import 'package:equatable/equatable.dart';

import '../../domain/entities/pagination_info.dart';

/// Data model for pagination information
class PaginationModel extends Equatable {
  const PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPage,
    this.previousPage,
    this.visiblePages = const [],
  });

  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final int? nextPage;
  final int? previousPage;
  final List<int> visiblePages;

  /// Create from JSON
  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
      nextPage: json['nextPage'] as int?,
      previousPage: json['previousPage'] as int?,
      visiblePages: (json['visiblePages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'nextPage': nextPage,
      'previousPage': previousPage,
      'visiblePages': visiblePages,
    };
  }

  /// Convert to domain entity
  PaginationInfo toEntity() {
    return PaginationInfo(
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
      nextPage: nextPage,
      previousPage: previousPage,
      visiblePages: visiblePages,
    );
  }

  /// Create from domain entity
  factory PaginationModel.fromEntity(PaginationInfo entity) {
    return PaginationModel(
      currentPage: entity.currentPage,
      totalPages: entity.totalPages,
      hasNext: entity.hasNext,
      hasPrevious: entity.hasPrevious,
      nextPage: entity.nextPage,
      previousPage: entity.previousPage,
      visiblePages: entity.visiblePages,
    );
  }

  /// Create from scraper result
  factory PaginationModel.fromScraperResult(
      Map<String, dynamic> scraperResult) {
    return PaginationModel(
      currentPage: scraperResult['currentPage'] as int? ?? 1,
      totalPages: scraperResult['totalPages'] as int? ?? 1,
      hasNext: scraperResult['hasNext'] as bool? ?? false,
      hasPrevious: scraperResult['hasPrevious'] as bool? ?? false,
      nextPage: scraperResult['nextPage'] as int?,
      previousPage: scraperResult['previousPage'] as int?,
      visiblePages: const [], // Will be populated separately if needed
    );
  }

  /// Copy with new values
  PaginationModel copyWith({
    int? currentPage,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    int? nextPage,
    int? previousPage,
    List<int>? visiblePages,
  }) {
    return PaginationModel(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      nextPage: nextPage ?? this.nextPage,
      previousPage: previousPage ?? this.previousPage,
      visiblePages: visiblePages ?? this.visiblePages,
    );
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage == totalPages;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalPages <= 1) return 1.0;
    return currentPage / totalPages;
  }

  /// Get remaining pages
  int get remainingPages => totalPages - currentPage;

  /// Get page range string (e.g., "Page 1 of 100")
  String get pageRangeString => 'Page $currentPage of $totalPages';

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        hasNext,
        hasPrevious,
        nextPage,
        previousPage,
        visiblePages,
      ];

  @override
  String toString() {
    return 'PaginationModel('
        'currentPage: $currentPage, '
        'totalPages: $totalPages, '
        'hasNext: $hasNext, '
        'hasPrevious: $hasPrevious, '
        'nextPage: $nextPage, '
        'previousPage: $previousPage, '
        'visiblePages: $visiblePages'
        ')';
  }
}
