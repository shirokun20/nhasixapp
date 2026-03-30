import 'package:equatable/equatable.dart';

/// Domain entity for pagination information
class PaginationInfo extends Equatable {
  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPage,
    this.previousPage,
    this.visiblePages = const [],
  });

  /// Current page number (1-based)
  final int currentPage;

  /// Total number of pages available
  final int totalPages;

  /// Whether there is a next page
  final bool hasNext;

  /// Whether there is a previous page
  final bool hasPrevious;

  /// Next page number (null if no next page)
  final int? nextPage;

  /// Previous page number (null if no previous page)
  final int? previousPage;

  /// List of visible page numbers in pagination UI
  final List<int> visiblePages;

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

  /// Get page range for display (e.g., "1-25 of 2500")
  String getItemRangeString(int itemsPerPage) {
    final startItem = (currentPage - 1) * itemsPerPage + 1;
    final endItem = currentPage * itemsPerPage;
    final totalItems = totalPages * itemsPerPage;

    return '$startItem-$endItem of $totalItems';
  }

  /// Copy with new values
  PaginationInfo copyWith({
    int? currentPage,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    int? nextPage,
    int? previousPage,
    List<int>? visiblePages,
  }) {
    return PaginationInfo(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      nextPage: nextPage ?? this.nextPage,
      previousPage: previousPage ?? this.previousPage,
      visiblePages: visiblePages ?? this.visiblePages,
    );
  }

  /// Create empty pagination info
  factory PaginationInfo.empty() {
    return const PaginationInfo(
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    );
  }

  /// Create single page pagination info
  factory PaginationInfo.singlePage() {
    return const PaginationInfo(
      currentPage: 1,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
      visiblePages: [1],
    );
  }

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
    return 'PaginationInfo('
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
