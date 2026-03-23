import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

class HitomiAdapter implements GenericAdapter {
  static const int _pageSize = 20;

  final Dio _dio;
  final Logger _logger;

  int _defaultOffset = 0;
  final Map<int, int> _offsetMap = <int, int>{};
  String _commonImageId = '';
  DateTime? _ggFetchedAt;

  HitomiAdapter({
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) async {
    final allIds = await _loadIds(filter.query, rawConfig);
    if (allIds.isEmpty) {
      return const AdapterSearchResult(
        items: <Content>[],
        hasNextPage: false,
        totalPages: 0,
        totalItems: 0,
      );
    }

    final page = filter.page < 1 ? 1 : filter.page;
    final start = (page - 1) * _pageSize;
    if (start >= allIds.length) {
      return AdapterSearchResult(
        items: const <Content>[],
        hasNextPage: false,
        totalPages: (allIds.length / _pageSize).ceil(),
        totalItems: allIds.length,
      );
    }

    final pageIds = allIds.skip(start).take(_pageSize).toList(growable: false);
    final items = await Future.wait(
      pageIds.map((id) => _fetchGallery(id.toString(), rawConfig)),
    );

    final compactItems = items.whereType<Content>().toList(growable: false);
    final totalPages = (allIds.length / _pageSize).ceil();
    return AdapterSearchResult(
      items: compactItems,
      hasNextPage: page < totalPages,
      totalPages: totalPages,
      totalItems: allIds.length,
    );
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    final content = await _fetchGallery(contentId, rawConfig);
    if (content == null) {
      throw const FormatException('Failed to load Hitomi gallery detail');
    }

    return AdapterDetailResult(
      content: content,
      imageUrls: content.imageUrls,
    );
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    try {
      final gallery = await _fetchGalleryJson(contentId, rawConfig);
      final related =
          (gallery['related'] as List?)?.cast<dynamic>() ?? const [];
      if (related.isEmpty) return const <Content>[];

      final ids = related.map((e) => e.toString()).toList(growable: false);
      final items =
          await Future.wait(ids.map((id) => _fetchGallery(id, rawConfig)));
      return items.whereType<Content>().toList(growable: false);
    } catch (_) {
      return const <Content>[];
    }
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    return const <Comment>[];
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) async {
    return null;
  }

  Future<List<int>> _loadIds(
    String query,
    Map<String, dynamic> rawConfig,
  ) async {
    final protocol = _protocol(rawConfig);
    final queryTrim = query.trim();

    final indexEndpoint = (protocol['indexNozomiEndpoint'] as String?) ??
        'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi';
    final tagEndpointTemplate = (protocol['tagNozomiEndpoint'] as String?) ??
        'https://ltn.gold-usergeneratedcontent.net/tag/{query}-all.nozomi';

    final nozomiUrl = queryTrim.isEmpty
        ? indexEndpoint
        : tagEndpointTemplate.replaceAll(
            '{query}', Uri.encodeComponent(queryTrim));

    final response = await _dio.get<List<int>>(
      nozomiUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return const <int>[];
    }

    return _decodeNozomiIds(Uint8List.fromList(bytes));
  }

  List<int> _decodeNozomiIds(Uint8List bytes) {
    if (bytes.length < 4) return const <int>[];

    final usableLength = bytes.length - (bytes.length % 4);
    final data = ByteData.sublistView(bytes, 0, usableLength);
    final ids = <int>[];

    for (var i = 0; i < usableLength; i += 4) {
      ids.add(data.getUint32(i, Endian.big));
    }

    return ids;
  }

  Future<Content?> _fetchGallery(
    String id,
    Map<String, dynamic> rawConfig,
  ) async {
    try {
      final gallery = await _fetchGalleryJson(id, rawConfig);
      return _toContent(gallery, rawConfig);
    } catch (e) {
      _logger.w('Hitomi gallery fetch failed for id=$id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchGalleryJson(
    String id,
    Map<String, dynamic> rawConfig,
  ) async {
    final protocol = _protocol(rawConfig);
    final endpointTemplate = (protocol['galleryJsEndpoint'] as String?) ??
        'https://ltn.gold-usergeneratedcontent.net/galleries/{id}.js';
    final endpoint = endpointTemplate.replaceAll('{id}', id);

    final response = await _dio.get<String>(
      endpoint,
      options: Options(responseType: ResponseType.plain),
    );
    final script = response.data ?? '';

    final jsonText = _extractGalleryJsonText(script);

    final decoded = _decodeGalleryJson(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Hitomi gallery payload is not a JSON object');
    }
    return decoded;
  }

  dynamic _decodeGalleryJson(String jsonText) {
    try {
      return jsonDecode(jsonText);
    } catch (_) {
      final normalized = jsonText
          .replaceAll('\\n', ' ')
          .replaceAll('\\r', ' ')
          .replaceAll('\\t', ' ')
          .replaceAll('\\"', '"')
          .trim();
      return jsonDecode(normalized);
    }
  }

  String _extractGalleryJsonText(String script) {
    final markerMatch = RegExp(r'galleryinfo\s*=\s*').firstMatch(script);
    if (markerMatch == null) {
      throw const FormatException('Hitomi gallery marker not found');
    }

    final start = script.indexOf('{', markerMatch.end);
    if (start < 0) {
      throw const FormatException('Hitomi gallery JSON start not found');
    }

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < script.length; i++) {
      final char = script[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == r'\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return script.substring(start, i + 1);
        }
      }
    }

    throw const FormatException('Hitomi gallery JSON end not found');
  }

  Future<Content> _toContent(
    Map<String, dynamic> gallery,
    Map<String, dynamic> rawConfig,
  ) async {
    await _refreshGg(rawConfig);

    final sourceId = (rawConfig['source'] as String?) ?? 'hitomi';
    final id = gallery['id']?.toString() ?? '';
    final title = gallery['title']?.toString() ?? 'Unknown';
    final galleryUrl = gallery['galleryurl']?.toString() ?? '';

    final dateRaw = gallery['date']?.toString() ?? '';
    final uploadDate = _parseDate(dateRaw);

    final files = (gallery['files'] as List?)?.cast<dynamic>() ?? const [];
    final imageUrls = <String>[];

    for (final item in files) {
      if (item is! Map) continue;
      final hash = item['hash']?.toString();
      final name = item['name']?.toString() ?? '';
      if (hash == null || hash.isEmpty) continue;
      imageUrls.add(_buildImageUrl(hash: hash, fileName: name));
    }

    final coverUrl = imageUrls.isNotEmpty
        ? imageUrls.first
        : _buildFallbackCover(files.isNotEmpty ? files.first as Map? : null);

    final tags =
        _parseTags((gallery['tags'] as List?)?.cast<dynamic>() ?? const []);

    return Content(
      id: id,
      sourceId: sourceId,
      title: title,
      coverUrl: coverUrl,
      tags: tags,
      artists: _collectNames(gallery['artists'], 'artist'),
      characters: _collectNames(gallery['characters'], 'character'),
      parodies: _collectNames(gallery['parodys'], 'parody'),
      groups: _collectNames(gallery['groups'], 'group'),
      language: gallery['language']?.toString() ?? 'unknown',
      pageCount: imageUrls.length,
      imageUrls: imageUrls,
      uploadDate: uploadDate,
      url: galleryUrl.isEmpty ? null : 'https://hitomi.la$galleryUrl',
      favorites: 0,
      contentType: ContentType.doujinshi,
      status: ContentStatus.completed,
      sourceUrl: galleryUrl.isEmpty ? null : 'https://hitomi.la$galleryUrl',
      totalChapters: 0,
    );
  }

  Future<void> _refreshGg(Map<String, dynamic> rawConfig) async {
    final now = DateTime.now();
    if (_ggFetchedAt != null && now.difference(_ggFetchedAt!).inMinutes < 30) {
      return;
    }

    final protocol = _protocol(rawConfig);
    final ggEndpoint = (protocol['ggJsEndpoint'] as String?) ??
        'https://ltn.gold-usergeneratedcontent.net/gg.js';

    final response = await _dio.get<String>(
      ggEndpoint,
      options: Options(responseType: ResponseType.plain),
    );
    final script = response.data ?? '';

    final defaultOffsetMatch =
        RegExp(r'var\s+o\s*=\s*(\d+)').firstMatch(script);
    _defaultOffset = int.tryParse(defaultOffsetMatch?.group(1) ?? '0') ?? 0;

    final caseOffsetMatch =
        RegExp(r'o\s*=\s*(\d+)\s*;\s*break;').firstMatch(script);
    final caseOffset = int.tryParse(caseOffsetMatch?.group(1) ?? '0') ?? 0;

    _offsetMap.clear();
    for (final m in RegExp(r'case\s+(\d+)\s*:').allMatches(script)) {
      final key = int.tryParse(m.group(1) ?? '');
      if (key != null) {
        _offsetMap[key] = caseOffset;
      }
    }

    final commonIdMatch = RegExp(r"b:\s*'([^']+)'").firstMatch(script);
    _commonImageId = commonIdMatch?.group(1) ?? '';

    _ggFetchedAt = now;
  }

  String _buildImageUrl({
    required String hash,
    required String fileName,
  }) {
    final imageId = _imageIdFromHash(hash);
    final offset = _offsetMap[imageId] ?? _defaultOffset;
    final isGif = fileName.endsWith('.gif') || fileName.endsWith('.webp');
    final type = isGif ? 'webp' : 'avif';
    final subDomain = isGif ? 'w${offset + 1}' : 'a${offset + 1}';

    return 'https://$subDomain.gold-usergeneratedcontent.net/$_commonImageId$imageId/$hash.$type';
  }

  String _buildFallbackCover(Map? firstFile) {
    if (firstFile == null) return '';
    final hash = firstFile['hash']?.toString() ?? '';
    if (hash.isEmpty) return '';

    final imageId = _imageIdFromHash(hash);
    final offset = _offsetMap[imageId] ?? _defaultOffset;
    final subDomain = 'a${offset + 1}tn';
    final thumbPath = _thumbPathFromHash(hash);

    return 'https://$subDomain.gold-usergeneratedcontent.net/webpbigtn/$thumbPath/$hash.webp';
  }

  int _imageIdFromHash(String hash) {
    final match = RegExp(r'(..)(.)$').firstMatch(hash);
    if (match == null) return 0;
    final merged = '${match.group(2)}${match.group(1)}';
    return int.tryParse(merged, radix: 16) ?? 0;
  }

  String _thumbPathFromHash(String hash) {
    final match = RegExp(r'^.*(..)(.)$').firstMatch(hash);
    if (match == null) return '';
    return '${match.group(2)}/${match.group(1)}';
  }

  Map<String, dynamic> _protocol(Map<String, dynamic> rawConfig) {
    return (rawConfig['hitomiProtocol'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
  }

  DateTime _parseDate(String dateRaw) {
    if (dateRaw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final normalized = dateRaw.replaceFirst(RegExp(r'-\d{2}$'), '');
    return DateTime.tryParse(normalized) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<String> _collectNames(dynamic value, String key) {
    if (value is! List) return const <String>[];

    return value
        .whereType<Map>()
        .map((e) => e[key]?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  List<Tag> _parseTags(List<dynamic> rawTags) {
    final tags = <Tag>[];

    for (final entry in rawTags) {
      if (entry is! Map) continue;
      final baseName = entry['tag']?.toString() ?? '';
      if (baseName.isEmpty) continue;

      final female = entry['female']?.toString() == '1';
      final male = entry['male']?.toString() == '1';
      final tagName = female
          ? 'female:$baseName'
          : male
              ? 'male:$baseName'
              : baseName;

      tags.add(
        Tag(
          id: 0,
          name: tagName,
          type: TagType.tag,
          count: 0,
          url: entry['url']?.toString() ?? '',
        ),
      );
    }

    return tags;
  }
}
