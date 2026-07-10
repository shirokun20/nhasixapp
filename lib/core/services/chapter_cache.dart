import 'package:kuron_core/kuron_core.dart';

/// Simple in-memory cache for expanded chapter list shared between
/// bottom-sheet and reader. Scoped by source+language+scanGroup.
/// Cleared when detail screen is popped (see DetailScreen.dispose).
class ChapterCache {
  ChapterCache._();

  static final Map<String, List<Chapter>> _store = {};

  static String _key(
          {String? sourceId, String? language, String? scanGroup}) =>
      '${sourceId ?? ''}:${language ?? ''}:${scanGroup ?? ''}';

  static List<Chapter>? chapters(
          {String? sourceId, String? language, String? scanGroup}) =>
      _store[_key(sourceId: sourceId, language: language, scanGroup: scanGroup)];

  static void set(List<Chapter> chapters,
      {String? sourceId, String? language, String? scanGroup}) {
    _store[_key(sourceId: sourceId, language: language, scanGroup: scanGroup)] =
        chapters;
  }

  static void clear() => _store.clear();
}
