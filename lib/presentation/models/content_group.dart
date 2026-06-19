import 'package:kuron_core/kuron_core.dart';

class ContentGroup {
  final String baseTitle;
  final List<Content> items;
  final int totalSize;
  final Map<String, int> itemSizes;

  // History properties
  final double readProgress; // 0.0 to 1.0
  final bool isRead;
  final bool isReading;

  ContentGroup({
    required this.baseTitle,
    required this.items,
    required this.totalSize,
    this.itemSizes = const {},
    this.readProgress = 0.0,
    this.isRead = false,
    this.isReading = false,
  });

  /// Get the representative content (usually the first chapter)
  Content get representativeContent {
    if (items.isEmpty) throw StateError('ContentGroup cannot be empty');
    // Sort logic could be applied here, but assume items are already sorted by the Cubit
    return items.first;
  }

  /// Total chapters in this group
  int get chapterCount => items.length;

  int sizeForContent(String contentId) => itemSizes[contentId] ?? 0;
}
