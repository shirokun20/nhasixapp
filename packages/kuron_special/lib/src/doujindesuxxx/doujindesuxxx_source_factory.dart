// DoujinDesu.xxx source — encrypted `_enc_resp_` API.
// Minimal: factory + time-windowed decrypt + adapter over GenericHttpSource.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

const String _appSecret = 'dfdf72051dbfdc7d76889ebd31324e74';
const String _salt =
    'doujindesu-scrapers-cannot-read-this-super-secret-salt-2026-v2';

class DoujinDesuXxxSourceFactory implements SourceFactory {
  final Dio _dio;
  final Logger _logger;

  DoujinDesuXxxSourceFactory({required Dio dio, required Logger logger})
      : _dio = dio,
        _logger = logger;

  @override
  String get sourceId => 'doujindesuxxx';

  @override
  ContentSource create(Map<String, dynamic> config) {
    final dio = Dio(_dio.options);
    try {
      dio.httpClientAdapter = _dio.httpClientAdapter;
    } catch (_) {}
    for (final i in _dio.interceptors) {
      try {
        dio.interceptors.add(i);
      } catch (_) {}
    }
    return GenericHttpSource(
      rawConfig: config,
      dio: dio,
      logger: _logger,
      adapterOverride: DoujinDesuXxxAdapter(
        dio: dio,
        sourceId: sourceId,
      ),
    );
  }
}

// Time-windowed decrypt of `_enc_resp_` payloads.
// Retries the current, previous, and next Unix-hour keys (mirrors the SPA's
// `Ln()`, tolerating clock drift). Returns `null` if none succeed.
dynamic doujinDesuDecrypt(String hex) {
  final slot = DateTime.now().millisecondsSinceEpoch ~/ 3600000;
  for (final slotKey in [_key(slot), _key(slot - 1), _key(slot + 1)]) {
    try {
      return jsonDecode(Uri.decodeComponent(_xor(hex, slotKey)));
    } catch (_) {}
  }
  return null;
}

// 32-char printable key for a Unix-hour slot: FNV-ish hash of `salt_slot`
// seeded into an LCG (same as the SPA bundle).
String _key(int slot) {
  final seed = '${_salt}_$slot';
  var hash = 0;
  for (final c in seed.codeUnits) {
    hash = (((hash << 5) - hash + c) & 0xFFFFFFFF).toSigned(32);
  }
  var m = hash.abs() == 0 ? 123456789 : hash.abs();
  final out = StringBuffer();
  for (var i = 0; i < 32; i++) {
    m = (m * 1664525 + 1013904223) % 4294967296;
    out.writeCharCode(33 + m % 93);
  }
  return out.toString();
}

// XOR stream with feedback: hex string, cycling key char, index*13, carry(n).
String _xor(String hex, String key) {
  final bytes = <int>[];
  for (var c = 0; c + 2 <= hex.length; c += 2) {
    bytes.add(int.parse(hex.substring(c, c + 2), radix: 16));
  }
  final out = StringBuffer();
  var n = 42;
  for (var c = 0; c < bytes.length; c++) {
    final b = bytes[c];
    out.writeCharCode(
      (b ^ key.codeUnitAt(c % key.length) ^ (c * 13) ^ n) & 0xFF,
    );
    n = (n + b) & 0xFF;
  }
  return out.toString();
}

class DoujinDesuXxxAdapter implements GenericAdapter {
  final Dio _dio;
  final String _sourceId;
  final String _base;
  final Map<String, String> _headers;

  DoujinDesuXxxAdapter({
    required Dio dio,
    required String sourceId,
    String base = 'https://doujin.desu.xxx',
  })  : _dio = dio,
        _sourceId = sourceId,
        _base = base,
        _headers = {
          'x-app-secret': _appSecret,
          'Referer': '$base/',
          'Origin': base,
        };

  Future<dynamic> _get(String path) async {
    final res = await _dio.get<dynamic>(
      path.startsWith('http') ? path : '$_base$path',
      options: Options(headers: _headers),
    );
    var data = res.data;
    if (data is String) data = jsonDecode(data);
    if (data is Map && data['_enc_resp_'] is String) {
      final dec = doujinDesuDecrypt(data['_enc_resp_'] as String);
      if (dec == null) {
        throw StateError('$_sourceId: failed to decrypt _enc_resp_');
      }
      return dec;
    }
    return data;
  }

  Map<int, String>? _genreSlugs;

  Future<Map<int, String>> _loadGenreSlugs() async {
    if (_genreSlugs != null) return _genreSlugs!;
    final data = await _get('/api/genres?limit=1000');
    final map = <int, String>{};
    if (data is List) {
      for (final g in data.whereType<Map>()) {
        final id = int.tryParse('${g['id']}');
        final slug = g['slug']?.toString();
        if (id != null && slug != null && slug.isNotEmpty) {
          map[id] = slug;
        }
      }
    }
    _genreSlugs = map;
    return map;
  }

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    // Genre navigation from a genre tag (numeric genre_id in raw params or
    // `genre:`/`tag:` prefixed slugs) resolves to the site's `genre=<slug>`.
    final q = filter.query.trim();
    var genreSlug = '';
    var textQuery = '';

    if (includeTagsGenre(filter) != null) {
      genreSlug = includeTagsGenre(filter)!;
    } else if (q.startsWith('raw:')) {
      final params = Uri.splitQueryString(q.substring(4));
      for (final key in const [
        'genre_id',
        'genreId',
        'tag_id',
        'tagId',
        'genre',
        'tag'
      ]) {
        final v = params[key]?.trim() ?? '';
        if (v.isNotEmpty) {
          genreSlug = v;
          break;
        }
      }
      if (genreSlug.isEmpty) {
        for (final key in const ['search', 'q', 's']) {
          final v = params[key]?.trim() ?? '';
          if (v.isNotEmpty) {
            textQuery = v;
            break;
          }
        }
      }
    } else if (q.startsWith('genre:') || q.startsWith('tag:')) {
      genreSlug = q.substring(q.indexOf(':') + 1).trim();
    } else if (q.isNotEmpty) {
      textQuery = q;
    }

    if (genreSlug.isNotEmpty && int.tryParse(genreSlug) != null) {
      final slugs = await _loadGenreSlugs();
      genreSlug = slugs[int.parse(genreSlug)] ?? '';
    }

    // API pagination: `offset` (0-based) + `limit`; `x-total-count` header
    // exists but the page-size heuristic below is sufficient.
    const pageSize = 30;
    final offset = (filter.page > 1 ? filter.page - 1 : 0) * pageSize;
    final query = genreSlug.isNotEmpty
        ? 'genre=${Uri.encodeQueryComponent(genreSlug)}'
        : textQuery.isNotEmpty
            ? 'search=${Uri.encodeQueryComponent(textQuery)}'
            : '';
    final path = '/api/manga?limit=$pageSize&offset=$offset${
        query.isEmpty ? '' : '&$query'}';
    final data = await _get(path);
    final items = data is List ? data : const [];
    return AdapterSearchResult(
      items: items
          .whereType<Map>()
          .map((m) => _content(m.cast<String, dynamic>()))
          .toList(),
      hasNextPage: items.length >= pageSize,
    );
  }

  // First genre-type included tag, as a slug (name when no id is available).
  String? includeTagsGenre(SearchFilter filter) {
    for (final t in filter.includeTags) {
      if (t.type == 'genre' || t.type == 'tag') {
        final slug = t.name
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), '-')
            .replaceAll(RegExp(r'-+'), '-');
        return slug;
      }
    }
    return null;
  }

  // Builds a Kuron Content from a decoded manga object. `slug` is the content
  // id (detail endpoint is keyed by slug).
  Content _content(Map<String, dynamic> m) {
    final chapters = (m['chapters'] as List?) ?? const [];
    final type = switch (m['type']?.toString()) {
      'manga' => ContentType.manga,
      'manhwa' => ContentType.manhwa,
      'manhua' => ContentType.manhua,
      'doujinshi' => ContentType.doujinshi,
      _ => ContentType.unknown,
    };
    final tags = <Tag>[];
    final artists = <String>[];
    final characters = <String>[];
    final parodies = <String>[];
    final groups = <String>[];
    final genresRaw = m['manga_genres'];
    if (genresRaw is List) {
      for (final g in genresRaw) {
        if (g is! Map) continue;
        final genreMap = g['genres'];
        if (genreMap is! Map) continue;
        final name = genreMap['name']?.toString() ?? '';
        if (name.isEmpty || name == 'N/A') continue;
        tags.add(Tag(
          id: int.tryParse('${g['genre_id']}') ?? 0,
          name: name,
          type: 'genre',
          count: 0,
          slug: genreMap['slug']?.toString() ?? '',
        ));
      }
    }
    for (final term in ((m['term_list'] ?? '').toString().split('|'))) {
      final parts = term.split(':');
      if (parts.length < 2) continue;
      final name = parts[0].trim();
      final type = parts[1].trim();
      if (name.isEmpty || name == 'N/A') continue;
      final slug = parts.length > 2 ? parts[2].trim() : '';
      switch (type) {
        case 'character':
          characters.add(name);
          break;
        case 'group':
          groups.add(name);
          break;
        case 'series':
          parodies.add(name);
          break;
        case 'author':
          artists.add(name);
          break;
        default:
          if (type == 'genre' &&
              !tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
            tags.add(
                Tag(id: 0, name: name, type: 'genre', count: 0, slug: slug));
          }
      }
    }
    return Content(
      id: (m['slug'] ?? m['id'] ?? '').toString(),
      sourceId: _sourceId,
      title: (m['title'] ?? '').toString(),
      coverUrl: (m['cover_url'] ?? '').toString(),
      tags: tags,
      artists: artists,
      characters: characters,
      parodies: parodies,
      groups: groups,
      language: 'id',
      pageCount: m['chapter_count'] is int
          ? m['chapter_count'] as int
          : chapters.length,
      imageUrls: const [],
      uploadDate:
          DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime(0),
      contentType: type,
      status: m['status']?.toString() == 'completed'
          ? ContentStatus.completed
          : ContentStatus.unknown,
    );
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final data = await _get('/api/manga/$contentId');
    final map = (data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{});
    return AdapterDetailResult(content: _content(map), imageUrls: const []);
  }

  @override
  Future<List<Chapter>> fetchChapters(
    String contentId,
    Map<String, dynamic> rawConfig, {
    String? language,
    String? scanGroup,
    int? page,
    int? offset,
    int? limit,
  }) async {
    final data = await _get('/api/manga/$contentId');
    final map = (data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{});
    final list = (map['chapters'] as List?) ?? const [];
    final mangaTitle = (map['title'] ?? '').toString();
    return list.whereType<Map>().map((c) {
      final id = (c['id'] ?? '').toString();
      final title = (c['title'] ?? '').toString();
      return Chapter(
        id: id,
        title: title.isEmpty ? mangaTitle : title,
        url: id,
        uploadDate: DateTime.tryParse((c['created_at'] ?? '').toString()),
      );
    }).toList();
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) async {
    final data = await _get('/api/chapters/$chapterId');
    final map = (data is Map
        ? data.cast<String, dynamic>()
        : const <String, dynamic>{});
    final urls = (map['content_urls'] as List?)
            ?.whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    return ChapterData(
      images: urls,
      prevChapterId: map['prev_id']?.toString(),
      nextChapterId: map['next_id']?.toString(),
    );
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async =>
      const [];

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async =>
      const [];
}
