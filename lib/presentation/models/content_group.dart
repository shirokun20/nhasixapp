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
    required List<Content> items,
    required this.totalSize,
    this.itemSizes = const {},
    this.readProgress = 0.0,
    this.isRead = false,
    this.isReading = false,
  }) : items = dedupeItems(items);

  static List<Content> dedupeItems(List<Content> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        // ponytail: title+sourceId is the semantic identity of a chapter;
        // id alone misses DB dups, coverPath was too aggressive (dropped valid chapters)
        if (seen.add('${item.sourceId}::${item.title.trim().toLowerCase()}'))
          item,
    ];
  }

  // ponytail: items already deduped in constructor
  List<Content> get uniqueItems => items;

  /// Get the representative content (usually the first chapter)
  Content get representativeContent {
    final unique = uniqueItems;
    if (unique.isEmpty) throw StateError('ContentGroup cannot be empty');
    // Sort logic could be applied here, but assume items are already sorted by the Cubit
    return unique.first;
  }

  /// Total chapters in this group
  int get chapterCount => uniqueItems.length;

  int sizeForContent(String contentId) => itemSizes[contentId] ?? 0;
}
