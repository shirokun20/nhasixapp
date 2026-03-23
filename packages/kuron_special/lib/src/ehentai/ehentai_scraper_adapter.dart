import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

/// E-Hentai adapter that delegates generic scraping and adds per-page image
/// extraction from reader links (`/s/{hash}/{gid}-{page}`).
class EHentaiScraperAdapter implements GenericAdapter {
  final Dio _dio;
  final GenericScraperAdapter _delegate;

  EHentaiScraperAdapter({
    required Dio dio,
    required GenericUrlBuilder urlBuilder,
    required GenericHtmlParser parser,
    required Logger logger,
    required String sourceId,
  })  : _dio = dio,
        _delegate = GenericScraperAdapter(
          dio: dio,
          urlBuilder: urlBuilder,
          parser: parser,
          logger: logger,
          sourceId: sourceId,
        );

  @override
  Future<AdapterSearchResult> search(
    SearchFilter filter,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.search(filter, rawConfig);
  }

  @override
  Future<AdapterDetailResult> fetchDetail(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) async {
    var normalizedContent = _emptyContent(contentId, rawConfig);
    const fallbackImages = <String>[];

    try {
      final scraperMap =
          (rawConfig['scraper'] as Map?)?.cast<String, dynamic>();
      final urlPatterns =
          (scraperMap?['urlPatterns'] as Map?)?.cast<String, dynamic>() ?? {};
      final detailPattern = _patternUrl(urlPatterns, 'detail').isNotEmpty
          ? _patternUrl(urlPatterns, 'detail')
          : '/g/{id}/';

      final baseUrl = (rawConfig['baseUrl'] as String?) ?? '';
      if (baseUrl.isEmpty) {
        return AdapterDetailResult(
          content: normalizedContent,
          imageUrls: fallbackImages,
        );
      }

      final detailUrl = GenericUrlBuilder(baseUrl: baseUrl)
          .buildDetailUrl(detailPattern, contentId);
      final detailHtml = await _fetchDetailHtml(
        detailUrl: detailUrl,
        baseUrl: baseUrl,
        detailPattern: detailPattern,
        contentId: contentId,
      );
      if (detailHtml.isEmpty) {
        return AdapterDetailResult(
          content: normalizedContent,
          imageUrls: fallbackImages,
        );
      }

      normalizedContent = _hydrateDetailMetadata(normalizedContent, detailHtml);

      final readerLinks = _extractReaderLinks(detailHtml);
      if (readerLinks.isEmpty) {
        return AdapterDetailResult(
          content: normalizedContent,
          imageUrls: fallbackImages,
        );
      }

      final imageUrls = <String>[];
      final imageSelector = _resolveImageSelector(rawConfig);

      for (final link in readerLinks) {
        final absUrl = link.startsWith('http') ? link : '$baseUrl$link';
        final pageResponse = await _dio.get<dynamic>(
          absUrl,
          options: Options(responseType: ResponseType.plain),
        );
        final pageHtml = pageResponse.data?.toString() ?? '';
        final imageUrl = _extractImageUrl(pageHtml, imageSelector);
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }

      if (imageUrls.isEmpty) {
        return AdapterDetailResult(
          content: normalizedContent,
          imageUrls: fallbackImages,
        );
      }

      final updated = normalizedContent.copyWith(
        imageUrls: imageUrls,
        pageCount: imageUrls.length,
      );
      return AdapterDetailResult(content: updated, imageUrls: imageUrls);
    } catch (_) {
      return AdapterDetailResult(
        content: normalizedContent,
        imageUrls: fallbackImages,
      );
    }
  }

  @override
  Future<List<Content>> fetchRelated(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchRelated(contentId, rawConfig);
  }

  @override
  Future<List<Comment>> fetchComments(
    String contentId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchComments(contentId, rawConfig);
  }

  @override
  Future<ChapterData?> fetchChapterImages(
    String chapterId,
    Map<String, dynamic> rawConfig,
  ) {
    return _delegate.fetchChapterImages(chapterId, rawConfig);
  }

  List<String> _extractReaderLinks(String html) {
    final matches = RegExp(
      r'href="((?:https?://e-hentai\.org)?/s/[^"]+)"',
      caseSensitive: false,
    ).allMatches(html);
    final seen = <String>{};
    final links = <String>[];

    for (final match in matches) {
      final link = match.group(1);
      if (link == null || link.isEmpty) continue;
      final normalized = link.startsWith('http') ? Uri.parse(link).path : link;
      if (seen.add(normalized)) {
        links.add(normalized);
      }
    }
    return links;
  }

  String _resolveImageSelector(Map<String, dynamic> rawConfig) {
    final scraper = (rawConfig['scraper'] as Map?)?.cast<String, dynamic>();
    final selectors =
        (scraper?['selectors'] as Map?)?.cast<String, dynamic>() ?? {};
    final detail = (selectors['detail'] as Map<String, dynamic>?) ?? {};
    final imageUrls = (detail['imageUrls'] as Map<String, dynamic>?) ?? {};
    return (imageUrls['imageSelector'] as String?) ?? '#img';
  }

  String? _extractImageUrl(String html, String imageSelector) {
    if (imageSelector == '#img') {
      return RegExp(r'<img[^>]*id="img"[^>]*src="([^"]+)"')
          .firstMatch(html)
          ?.group(1);
    }
    return RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(html)?.group(1);
  }

  String _patternUrl(Map<String, dynamic> patterns, String key) {
    final entry = patterns[key];
    if (entry is String) return entry;
    if (entry is Map<String, dynamic>) {
      return (entry['url'] as String?) ?? '';
    }
    return '';
  }

  Future<String> _fetchDetailHtml({
    required String detailUrl,
    required String baseUrl,
    required String detailPattern,
    required String contentId,
  }) async {
    final candidates = <String>{detailUrl};

    final withSlash = contentId.endsWith('/') ? contentId : '$contentId/';
    final withoutSlash = contentId.endsWith('/')
        ? contentId.substring(0, contentId.length - 1)
        : contentId;

    final encoded = Uri.encodeComponent(contentId);
    final encodedWithSlash = Uri.encodeComponent(
        withSlash.endsWith('/') ? withSlash : '$withSlash/');
    final encodedNoSlash = Uri.encodeComponent(withoutSlash);

    final doubleEncoded = Uri.encodeComponent(encoded);

    for (final id in <String>[
      contentId,
      withSlash,
      withoutSlash,
      encoded,
      encodedWithSlash,
      encodedNoSlash,
      doubleEncoded,
    ]) {
      if (id.isEmpty) continue;
      final candidate =
          GenericUrlBuilder(baseUrl: baseUrl).buildDetailUrl(detailPattern, id);
      candidates.add(candidate);
    }

    for (final url in candidates) {
      try {
        final response = await _dio.get<dynamic>(
          url,
          options: Options(responseType: ResponseType.plain),
        );
        final html = response.data?.toString() ?? '';
        if (html.isNotEmpty) {
          return html;
        }
      } catch (_) {
        // Try next candidate URL variant.
      }
    }

    return '';
  }

  Content _emptyContent(String id, Map<String, dynamic> rawConfig) {
    return Content(
      id: id,
      sourceId: (rawConfig['source'] as String?) ?? 'ehentai',
      title: 'Unknown',
      coverUrl: '',
      tags: const [],
      artists: const [],
      characters: const [],
      parodies: const [],
      groups: const [],
      language: (rawConfig['defaultLanguage'] as String?) ?? 'unknown',
      pageCount: 0,
      imageUrls: const [],
      uploadDate: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Content _hydrateDetailMetadata(Content content, String html) {
    final currentTitle = content.title.trim();
    final currentCover = content.coverUrl.trim();

    final title = currentTitle.isEmpty || currentTitle == 'Unknown'
        ? _extractTitle(html)
        : currentTitle;
    final coverUrl =
        currentCover.isEmpty ? _extractCoverUrl(html) : currentCover;

    var tags = content.tags;
    if (tags.isEmpty) {
      final parsedTags = _extractTags(html);
      if (parsedTags.isNotEmpty) {
        tags = parsedTags;
      }
    }

    final hydrated = content.copyWith(
      title: title.isEmpty ? content.title : title,
      coverUrl: coverUrl.isEmpty ? content.coverUrl : coverUrl,
      tags: tags,
    );

    return _normalizeEhentaiTags(hydrated);
  }

  String _extractTitle(String html) {
    final match =
        RegExp(r'<h1[^>]*id="gn"[^>]*>([\s\S]*?)</h1>').firstMatch(html);
    return _cleanHtmlText(match?.group(1) ?? '');
  }

  String _extractCoverUrl(String html) {
    final block = RegExp(
      r'<div[^>]*id="gd1"[^>]*>[\s\S]*?</div>',
      caseSensitive: false,
    ).firstMatch(html)?.group(0);

    final src = RegExp(
      r'<img[^>]*(?:data-src|src)="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(block ?? '')?.group(1);
    if (src != null && src.isNotEmpty) {
      return src.trim();
    }

    final styleUrlRaw = RegExp(r'url\(([^\)]+)\)', caseSensitive: false)
        .firstMatch(html)
        ?.group(1);

    if (styleUrlRaw == null || styleUrlRaw.trim().isEmpty) {
      return '';
    }

    return styleUrlRaw.trim().replaceAll(RegExp(r'^["]|["]$'), '');
  }

  List<Tag> _extractTags(String html) {
    final matches = RegExp(
      r'<div[^>]*class="[^"]*\bgt\b[^"]*"[^>]*title="([^"]+)"',
    ).allMatches(html);

    final tags = <Tag>[];
    for (final match in matches) {
      final name = _cleanHtmlText(match.group(1) ?? '');
      if (name.isEmpty) continue;
      tags.add(Tag(id: 0, name: name, type: TagType.tag, count: 0));
    }
    return tags;
  }

  String _cleanHtmlText(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&quot;', '"')
        .trim();
  }

  Content _normalizeEhentaiTags(Content content) {
    if (content.tags.isEmpty) return content;

    final normalizedTags = <Tag>[];
    final artists = <String>[];
    final characters = <String>[];
    final parodies = <String>[];
    final groups = <String>[];
    var language = content.language;

    for (final tag in content.tags) {
      final raw = tag.name.trim();
      if (!raw.contains(':')) {
        normalizedTags.add(tag);
        continue;
      }

      final parts = raw.split(':');
      if (parts.length < 2) {
        normalizedTags.add(tag);
        continue;
      }

      final type = parts.first.trim().toLowerCase();
      final name = parts.sublist(1).join(':').trim();
      if (name.isEmpty) {
        normalizedTags.add(tag);
        continue;
      }

      final mappedType = _mapTagType(type);
      normalizedTags.add(tag.copyWith(type: mappedType, name: name));

      switch (mappedType) {
        case TagType.artist:
          artists.add(name);
          break;
        case TagType.character:
          characters.add(name);
          break;
        case TagType.parody:
          parodies.add(name);
          break;
        case TagType.group:
          groups.add(name);
          break;
        case TagType.language:
          if (language == 'unknown' || language.isEmpty) {
            language = name;
          }
          break;
        default:
          break;
      }
    }

    return content.copyWith(
      tags: normalizedTags,
      artists: artists.isNotEmpty ? artists : content.artists,
      characters: characters.isNotEmpty ? characters : content.characters,
      parodies: parodies.isNotEmpty ? parodies : content.parodies,
      groups: groups.isNotEmpty ? groups : content.groups,
      language: language,
    );
  }

  String _mapTagType(String rawType) {
    switch (rawType) {
      case 'artist':
        return TagType.artist;
      case 'character':
        return TagType.character;
      case 'parody':
        return TagType.parody;
      case 'group':
        return TagType.group;
      case 'language':
        return TagType.language;
      case 'category':
        return TagType.category;
      default:
        return TagType.tag;
    }
  }
}
