class ChapterIdClassifier {
  ChapterIdClassifier._();

  static bool isCrotpediaChapterId(
    String contentId, {
    String? sourceId,
  }) {
    final normalizedId = contentId.trim().toLowerCase();
    if (normalizedId.isEmpty) {
      return false;
    }

    if (RegExp(r'^\d+$').hasMatch(normalizedId)) {
      return false;
    }

    final normalizedSource = sourceId?.trim().toLowerCase();
    final sourceKnown = normalizedSource != null && normalizedSource.isNotEmpty;
    final isCrotpediaSource = normalizedSource == 'crotpedia';

    if (sourceKnown && !isCrotpediaSource) {
      return false;
    }

    if (normalizedId.contains('chapter') || normalizedId.contains('ch-')) {
      return true;
    }

    if (!isCrotpediaSource) {
      return false;
    }

    final dashCount = '-'.allMatches(normalizedId).length;
    return dashCount >= 3;
  }
}
