/// Central mapping layer: extracted field maps → kuron_core domain entities.
///
/// Both [GenericScraperAdapter] and [GenericRestAdapter] extract raw field
/// values from HTML / JSON according to the source config and store them in a
/// plain `Map<String, dynamic>`.  This class converts those maps into typed
/// [Content] and [Chapter] objects **without knowing anything about the
/// extraction mechanism or the source-specific config keys**.
///
/// ### Supported field names (keys in the extracted map)
/// Scalar strings: `id`, `title`, `coverUrl`, `language`, `pageCount`,
/// `uploadDate`, `mediaId`, `englishTitle`, `japaneseTitle`, `favorites`.
///
/// String lists: `artists`, `characters`, `parodies`, `groups`.
///
/// Tag variants:
/// - `tags`       — `List<String>` of tag names → typed as `type: "tag"`.
/// - `tagObjects` — `List<Map<String, dynamic>>` of full nhentai tag objects
///                  `{id, name, type, count}`.  Processed by [splitTagObjects].
library;

import 'package:kuron_core/kuron_core.dart';

class GenericContentMapper {
  const GenericContentMapper._();

  // ── Public factory methods ─────────────────────────────────────────────────

  /// Build a [Content] entity for **list / search result** items.
  ///
  /// [fields] keys should use the canonical field names documented in the
  /// library-level doc-comment above.
  static Content toListItem(
    Map<String, dynamic> fields, {
    required String sourceId,
  }) {
    final tagsResolved = _resolveTags(fields);

    return Content(
      id: _str(fields, 'id'),
      sourceId: sourceId,
      title: _extractTitle(fields),
      coverUrl: _str(fields, 'coverUrl'),
      tags: tagsResolved.tags,
      artists: tagsResolved.artists.isNotEmpty
          ? tagsResolved.artists
          : _strList(fields, 'artists'),
      characters: tagsResolved.characters.isNotEmpty
          ? tagsResolved.characters
          : _strList(fields, 'characters'),
      parodies: tagsResolved.parodies.isNotEmpty
          ? tagsResolved.parodies
          : _strList(fields, 'parodies'),
      groups: tagsResolved.groups.isNotEmpty
          ? tagsResolved.groups
          : _strList(fields, 'groups'),
      language: tagsResolved.language.isNotEmpty
          ? tagsResolved.language
          : _resolveLanguage(fields),
      pageCount: _int(fields, 'pageCount'),
      imageUrls: const [],
      uploadDate: _date(fields, 'uploadDate'),
      favorites: _int(fields, 'favorites'),
      status: _status(fields),
      totalChapters: _intOrNull(fields, 'pageCount'),
      mediaId: fields['mediaId'] as String?,
    );
  }

  /// Build a [Content] entity for **detail pages** (superset of list fields).
  ///
  /// [imageUrls] and [chapters] are passed in separately because they are
  /// resolved after the main fields are extracted.
  static Content toDetail(
    String contentId,
    Map<String, dynamic> fields, {
    required String sourceId,
    List<String> imageUrls = const [],
    List<Chapter>? chapters,
  }) {
    final tagsResolved = _resolveTags(fields);
    final coverUrl = _str(fields, 'coverUrl').let(
      (s) => s.isNotEmpty ? s : (imageUrls.isNotEmpty ? imageUrls.first : ''),
    );
    final id = _str(fields, 'id').let((s) => s.isNotEmpty ? s : contentId);
    final rawPageCount = _int(fields, 'pageCount');
    final pageCount = chapters != null
        ? chapters.length
        : (rawPageCount > 0 ? rawPageCount : imageUrls.length);

    return Content(
      id: id,
      sourceId: sourceId,
      title: _extractTitle(fields),
      coverUrl: coverUrl,
      tags: tagsResolved.tags,
      artists: tagsResolved.artists.isNotEmpty
          ? tagsResolved.artists
          : _strList(fields, 'artists'),
      characters: tagsResolved.characters.isNotEmpty
          ? tagsResolved.characters
          : _strList(fields, 'characters'),
      parodies: tagsResolved.parodies.isNotEmpty
          ? tagsResolved.parodies
          : _strList(fields, 'parodies'),
      groups: tagsResolved.groups.isNotEmpty
          ? tagsResolved.groups
          : _strList(fields, 'groups'),
      language: tagsResolved.language.isNotEmpty
          ? tagsResolved.language
          : _resolveLanguage(fields),
      pageCount: pageCount,
      imageUrls: imageUrls,
      chapters: chapters,
      uploadDate: _date(fields, 'uploadDate'),
      favorites: _int(fields, 'favorites'),
      mediaId: fields['mediaId'] as String?,
      englishTitle: fields['englishTitle'] as String?,
      japaneseTitle: fields['japaneseTitle'] as String?,
      subTitle: _extractDescription(fields),
      status: _status(fields),
      totalChapters: rawPageCount > 0 ? rawPageCount : null,
    );
  }

  /// Build a [Chapter] entity from extracted fields.
  ///
  /// Supported keys: `id`, `title`, `url`, `date`.
  static Chapter toChapter(Map<String, dynamic> fields) {
    final id = _str(fields, 'id');
    final url = _str(fields, 'url');
    return Chapter(
      id: id.isNotEmpty ? id : url,
      title: _buildChapterTitle(fields),
      url: url,
      uploadDate: _dateNullable(fields, 'date'),
    );
  }

  // ── Tag processing ─────────────────────────────────────────────────────────

  /// Split nhentai-style `tagObjects` (unified array with `type` field) into
  /// typed lists.  Used by REST sources that return a single `tags[]` array.
  static TagSplit splitTagObjects(List<Map<String, dynamic>> objects) {
    final tags = <Tag>[];
    final artists = <String>[];
    final characters = <String>[];
    final parodies = <String>[];
    final groups = <String>[];
    final languages = <String>[];

    for (final obj in objects) {
      final name = obj['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final type = obj['type']?.toString() ?? 'tag';
      final id = (obj['id'] as num?)?.toInt() ?? 0;
      final count = (obj['count'] as num?)?.toInt() ?? 0;

      switch (type) {
        case 'artist':
          artists.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'character':
          characters.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'parody':
          parodies.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'group':
          groups.add(name);
          tags.add(Tag(id: id, name: name, type: type, count: count));
        case 'language':
          if (name != 'translated') {
            languages.add(name);
            tags.add(Tag(id: id, name: name, type: type, count: count));
          }
        default:
          tags.add(Tag(id: id, name: name, type: type, count: count));
      }
    }

    return TagSplit(
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: languages.isNotEmpty ? languages.first : '',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static TagSplit _resolveTags(Map<String, dynamic> fields) {
    // Priority 1: pre-split tagObjects
    final rawTagObjects = fields['tagObjects'];
    if (rawTagObjects is List && rawTagObjects.isNotEmpty) {
      final objects = rawTagObjects.whereType<Map<String, dynamic>>().toList();
      if (objects.isNotEmpty) return splitTagObjects(objects);
    }

    // Priority 2: List<Tag> already resolved (e.g. from detail page)
    final rawTags = fields['tags'];
    if (rawTags is List<Tag>) {
      return TagSplit(
        tags: rawTags,
        artists: const [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: '',
      );
    }

    // Priority 3: List<String> tag names
    final tagNames = _strList(fields, 'tags');
    return TagSplit(
      tags: tagNames
          .map((n) => Tag(id: 0, name: n, type: 'tag', count: 0))
          .toList(),
      artists: const [],
      characters: const [],
      parodies: const [],
      groups: const [],
      language: '',
    );
  }

  static String _str(
    Map<String, dynamic> f,
    String key, {
    String fallback = '',
  }) {
    final v = f[key];
    if (v is String) return v.isEmpty ? fallback : v;
    if (v is Map && v.isNotEmpty) {
      final firstVal = v.values.first;
      if (firstVal is String && firstVal.isNotEmpty) return firstVal;
    }
    if (v is List && v.isNotEmpty) {
      final firstVal = v.first;
      if (firstVal is String && firstVal.isNotEmpty) return firstVal;
    }
    return fallback;
  }

  static List<String> _strList(Map<String, dynamic> f, String key) {
    final v = f[key];
    if (v is List<String>) return v;
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  static String _extractTitle(Map<String, dynamic> fields) {
    // 1. Try the main title object, prioritize english if available.
    final t = fields['title'];
    if (t is Map && t['en'] != null && t['en'].toString().isNotEmpty) {
      return t['en'].toString();
    }

    // 2. Try to find an English title in altTitles.
    final altTitles = fields['altTitles'];
    if (altTitles is List) {
      for (final alt in altTitles) {
        if (alt is Map &&
            alt['en'] != null &&
            alt['en'].toString().isNotEmpty) {
          return alt['en'].toString();
        }
      }
    }

    // 3. Fallback to generic map/list-aware string extraction.
    return _str(fields, 'title', fallback: 'Unknown');
  }

  static String _extractDescription(Map<String, dynamic> fields) {
    final subtitle = _str(fields, 'subTitle');
    if (subtitle.isNotEmpty) return subtitle;

    final raw = fields['description'];
    if (raw is String) return raw;
    if (raw is Map) {
      final en = raw['en'];
      if (en != null && en.toString().isNotEmpty) {
        return en.toString();
      }
      for (final value in raw.values) {
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return '';
  }

  static String _resolveLanguage(Map<String, dynamic> fields) {
    final language = _str(fields, 'language');
    if (language.isNotEmpty) return language;

    final originalLanguage = _str(fields, 'originalLanguage');
    if (originalLanguage.isNotEmpty) return originalLanguage;

    final available = _strList(fields, 'availableTranslatedLanguages');
    if (available.isNotEmpty) return available.first;

    return 'unknown';
  }

  static String _buildChapterTitle(Map<String, dynamic> fields) {
    final chapterNum = _str(fields, 'chapterNum').trim();
    final volume = _str(fields, 'volume').trim();
    final title = _str(fields, 'title').trim();

    if (volume.isNotEmpty && chapterNum.isNotEmpty) {
      return 'Vol.$volume Ch.$chapterNum';
    }
    if (chapterNum.isNotEmpty) {
      return 'Ch.$chapterNum';
    }
    if (volume.isNotEmpty) {
      return 'Vol.$volume';
    }
    return title;
  }

  static ContentStatus _status(Map<String, dynamic> fields) {
    final raw = _str(fields, 'status').toLowerCase().trim();
    switch (raw) {
      case 'ongoing':
        return ContentStatus.ongoing;
      case 'completed':
        return ContentStatus.completed;
      case 'licensed':
        return ContentStatus.licensed;
      case 'publishing_finished':
      case 'publishingfinished':
      case 'publishing-finished':
        return ContentStatus.publishingFinished;
      case 'cancelled':
      case 'canceled':
        return ContentStatus.cancelled;
      case 'hiatus':
      case 'on_hiatus':
      case 'on-hiatus':
        return ContentStatus.onHiatus;
      default:
        return ContentStatus.unknown;
    }
  }

  static int _int(Map<String, dynamic> f, String key) {
    final v = f[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _intOrNull(Map<String, dynamic> f, String key) {
    final value = _int(f, key);
    return value > 0 ? value : null;
  }

  static DateTime _date(Map<String, dynamic> f, String key) {
    return _dateNullable(f, key) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _dateNullable(Map<String, dynamic> f, String key) {
    final v = f[key];
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      final cleaned = v.trim();

      final seconds = int.tryParse(v);
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }

      final absolute = DateTime.tryParse(cleaned);
      if (absolute != null) return absolute;

      final relative = _parseRelativeDate(cleaned);
      if (relative != null) return relative;
    }
    return null;
  }

  static DateTime? _parseRelativeDate(String raw) {
    if (raw.isEmpty) return null;

    final now = DateTime.now();
    final normalized = raw
        .toLowerCase()
        .replaceFirst(RegExp(r'^(posted|uploaded|upload date|date)\s*:\s*'), '')
        .trim();

    if (normalized == 'just now' || normalized == 'today') {
      return now;
    }
    if (normalized == 'yesterday') {
      return now.subtract(const Duration(days: 1));
    }

    final match = RegExp(
      r'^(\d+|a|an)\s+(second|minute|hour|day|week|month|year)s?\s+ago$',
    ).firstMatch(normalized);
    if (match == null) return null;

    final quantityRaw = match.group(1) ?? '0';
    final unit = match.group(2) ?? '';
    final quantity = (quantityRaw == 'a' || quantityRaw == 'an')
        ? 1
        : (int.tryParse(quantityRaw) ?? 0);
    if (quantity <= 0) return null;

    switch (unit) {
      case 'second':
        return now.subtract(Duration(seconds: quantity));
      case 'minute':
        return now.subtract(Duration(minutes: quantity));
      case 'hour':
        return now.subtract(Duration(hours: quantity));
      case 'day':
        return now.subtract(Duration(days: quantity));
      case 'week':
        return now.subtract(Duration(days: quantity * 7));
      case 'month':
        return now.subtract(Duration(days: quantity * 30));
      case 'year':
        return now.subtract(Duration(days: quantity * 365));
      default:
        return null;
    }
  }
}

// ── Internal DTOs ─────────────────────────────────────────────────────────────

/// Result of splitting a unified nhentai-style tag array by type.
class TagSplit {
  const TagSplit({
    required this.tags,
    required this.artists,
    required this.characters,
    required this.parodies,
    required this.groups,
    required this.language,
  });

  final List<Tag> tags;
  final List<String> artists;
  final List<String> characters;
  final List<String> parodies;
  final List<String> groups;
  final String language;
}

extension _StringX on String {
  /// Apply [fn] to this string and return its result.
  T let<T>(T Function(String) fn) => fn(this);
}
