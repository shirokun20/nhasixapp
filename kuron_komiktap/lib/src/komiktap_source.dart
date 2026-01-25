import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'komiktap_scraper.dart';
import 'komiktap_url_builder.dart';
import 'komiktap_search_capabilities.dart';
import 'models/komiktap_models.dart';

/// KomikTap ContentSource implementation.
///
/// Provides content operations for KomikTap manga source.
/// No authentication required - all features are public.
class KomiktapSource implements ContentSource {
  static const String sourceIdValue = 'komiktap';
  static const String displayNameValue = 'KomikTap';
  static const String baseUrlValue = 'https://komiktap.info';

  final KomiktapScraper _scraper;
  final Dio _dio;
  final Logger? _logger;
  final String _overriddenBaseUrl;
  final String _displayName;

  KomiktapSource({
    required KomiktapScraper scraper,
    required Dio dio,
    Logger? logger,
    String? baseUrl,
    String? displayName,
  })  : _scraper = scraper,
        _dio = dio,
        _logger = logger,
        _overriddenBaseUrl = baseUrl ?? baseUrlValue,
        _displayName = displayName ?? displayNameValue;

  // ============ ContentSource Interface ============

  @override
  String get id => sourceIdValue;

  @override
  String get displayName => _displayName;

  @override
  String get iconPath => 'assets/icons/komiktap.png';

  @override
  String get baseUrl => _overriddenBaseUrl;

  @override
  bool get requiresBypass => false; // No cloudflare bypass needed

  @override
  SearchCapabilities get searchCapabilities => komiktapSearchCapabilities;

  @override
  String get refererHeader => baseUrlValue;

  // ============ Download & Display Customization ============

  @override
  Map<String, String> getImageDownloadHeaders({
    required String imageUrl,
    Map<String, String>? cookies,
  }) {
    return {
      'Referer': baseUrl,
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };
  }

  @override
  int? get brandColor => 0xFF4CAF50; // Green for KomikTap

  @override
  bool get showsPageCountInList => false; // Manga source - shows chapters

  @override
  bool get supportsAuthentication => false; // No login required

  @override
  bool get supportsBookmarks => false; // No bookmark feature


  @override
  Future<ContentListResult> getList({
    int page = 1,
    SortOption sort = SortOption.newest,
  }) async {
    try {
      final url = KomiktapUrlBuilder.buildHomeUrl(page: page);

      _logger?.d('Fetching list from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Referer': '$baseUrlValue/',
            'User-Agent': 'Mozilla/5.0 (compatible; KuronApp/1.0)',
          },
        ),
      );

      final metadataList = _scraper.parseLatestSeries(response.data);
      final pagination = _scraper.parsePagination(response.data);

      // Convert KomiktapSeriesMetadata to Content
      final contents = metadataList.map<Content>(_convertToContent).toList();

      _logger?.i('Parsed ${contents.length} series, page ${pagination.currentPage}/${pagination.totalPages}');

      return ContentListResult(
        contents: contents,
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalCount: contents.length,
        hasNext: pagination.hasNext,
        hasPrevious: pagination.hasPrevious,
      );
    } catch (e, stack) {
      _logger?.e('Failed to get list', error: e, stackTrace: stack);
      return ContentListResult(
        contents: [],
        currentPage: page,
        totalPages: 0,
        totalCount: 0,
        hasNext: false,
        hasPrevious: false,
      );
    }
  }

  @override
  Future<ContentListResult> getPopular({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  }) async {
    // KomikTap doesn't have explicit popular sorting
    // Fallback to latest updates
    _logger?.w('getPopular not supported, falling back to latest updates');
    return getList(page: page);
  }

  @override
  Future<ContentListResult> search(SearchFilter filter) async {
    try {
      final url = KomiktapUrlBuilder.buildSearchUrl(
        filter.query,
        page: filter.page,
      );

      _logger?.d('Searching with query: ${filter.query}, page: ${filter.page}');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Referer': '$baseUrlValue/',
            'User-Agent': 'Mozilla/5.0 (compatible; KuronApp/1.0)',
          },
        ),
      );

      final metadataList = _scraper.parseSearchResults(response.data);
      final pagination = _scraper.parsePagination(response.data);

      // Convert ContentMetadata to Content
      final contents = metadataList.map<Content>(_convertToContent).toList();

      _logger?.i('Search found ${contents.length} results');

      return ContentListResult(
        contents: contents,
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalCount: contents.length,
        hasNext: pagination.hasNext,
        hasPrevious: pagination.hasPrevious,
      );
    } catch (e, stack) {
      _logger?.e('Failed to search', error: e, stackTrace: stack);
      return ContentListResult(
        contents: [],
        currentPage: filter.page,
        totalPages: 0,
        totalCount: 0,
        hasNext: false,
        hasPrevious: false,
      );
    }
  }

  @override
  Future<Content> getDetail(String contentId) async {
    try {
      final url = KomiktapUrlBuilder.buildSeriesDetailUrl(contentId);

      _logger?.d('Fetching detail for: $contentId');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Referer': '$baseUrlValue/',
            'User-Agent': 'Mozilla/5.0 (compatible; KuronApp/1.0)',
          },
        ),
      );

      final detail = _scraper.parseSeriesDetail(response.data, contentId);

      _logger?.i('Parsed detail for "${detail.title}" with ${detail.chapters?.length ?? 0} chapters');

      // Convert ContentDetail to Content
      return _convertDetailToContent(detail);
    } catch (e, stack) {
      _logger?.e('Failed to get content detail', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<List<Content>> getRandom({int count = 1}) async {
    // KomikTap doesn't have random feature
    // Return latest updates instead
    _logger?.w('getRandom not supported, falling back to latest');
    final result = await getList(page: 1);
    return result.contents.take(count).toList();
  }

  @override
  Future<List<Content>> getRelated(String contentId) async {
    try {
      // Get detail to extract genres
      final detail = await getDetail(contentId);
      
      // If has tags, search by first tag
      if (detail.tags.isNotEmpty) {
        final firstTag = detail.tags.first;
        final genreSlug = firstTag.slug ?? firstTag.name.toLowerCase().replaceAll(' ', '-');
        
        final url = KomiktapUrlBuilder.buildGenreUrl(genreSlug);
        
        final response = await _dio.get(
          url,
          options: Options(
            headers: {
              'Referer': '$baseUrlValue/',
              'User-Agent': 'Mozilla/5.0 (compatible; KuronApp/1.0)',
            },
          ),
        );
        
        final metadataList = _scraper.parseSearchResults(response.data);
        
        // Convert and filter out the current content, take top 10
        return metadataList
            .where((item) => item.id != contentId)
            .take(10)
            .map(_convertToContent)
            .toList().cast<Content>();
      }
      
      return [];
    } catch (e, stack) {
      _logger?.e('Failed to get related', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  String buildImageUrl({
    required String contentId,
    required String mediaId,
    required int page,
    required String extension,
    bool thumbnail = false,
  }) {
    // KomikTap images are full URLs, not constructed
    // This method is legacy from nhentai API
    return '';
  }

  @override
  String buildThumbnailUrl({
    required String contentId,
    required String mediaId,
  }) {
    // Not used for KomikTap
    return '';
  }

  @override
  String? parseContentIdFromUrl(String url) {
    return KomiktapUrlBuilder.extractSlugFromUrl(url);
  }

  @override
  bool isValidContentId(String contentId) {
    // Slug format validation: alphanumeric and hyphens
    return contentId.isNotEmpty && 
           RegExp(r'^[a-z0-9-]+$').hasMatch(contentId);
  }

  // ============ Helper Methods ============

  /// Get images from a specific chapter
  Future<List<String>> getChapterImages(String chapterSlug) async {
    try {
      final url = KomiktapUrlBuilder.buildChapterUrlFromSlug(chapterSlug);

      _logger?.d('Fetching chapter pages: $chapterSlug');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Referer': '$baseUrlValue/',
            'User-Agent': 'Mozilla/5.0 (compatible; KuronApp/1.0)',
          },
        ),
      );

      final images = _scraper.parseChapterImages(response.data);

      _logger?.i('Found ${images.length} images in chapter');

      return images;
    } catch (e, stack) {
      _logger?.e('Failed to get chapter pages', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Build chapter URL (for external opening)
  String buildChapterUrl(String chapterSlug) {
    return KomiktapUrlBuilder.buildChapterUrlFromSlug(chapterSlug);
  }

  /// Build series detail URL (for external opening)
  String buildSeriesUrl(String seriesSlug) {
    return KomiktapUrlBuilder.buildSeriesDetailUrl(seriesSlug);
  }

  // ============ Private Converters ============

  /// Convert KomiktapSeriesMetadata to Content (for list views)
  Content _convertToContent(KomiktapSeriesMetadata metadata) {
    return Content(
      id: metadata.id,
      sourceId: id,
      title: metadata.title,
      coverUrl: metadata.coverImageUrl,
      pageCount: 0, // Unknown until chapter detail
      imageUrls: const [], // Empty for series
      chapters: const [], // Will be loaded in detail
      tags: metadata.tags.map((tag) => Tag(
        id: tag.hashCode,
        name: tag,
        type: TagType.tag,
        count: 0,
        slug: tag.toLowerCase().replaceAll(' ', '-'),
      )).toList(),
      artists: [],
      characters: [],
      parodies: [],
      groups: [],
      language: 'indonesian',
      uploadDate: metadata.lastUpdate ?? DateTime.now(),
      favorites: 0,
      englishTitle: metadata.subtitle,
    );
  }

  /// Convert KomiktapSeriesDetail to Content (for detail view)
  Content _convertDetailToContent(KomiktapSeriesDetail detail) {
    // Map chapters
    final chapters = (detail.chapters ?? [])
        .map((c) => Chapter(
              id: c.id,
              title: c.title,
              url: KomiktapUrlBuilder.buildChapterUrlFromSlug(c.id),
              uploadDate: c.publishDate,
            ))
        .toList();

    return Content(
      id: detail.id,
      sourceId: id,
      title: detail.title,
      coverUrl: detail.coverImageUrl,
      pageCount: 0, // Dynamic per chapter
      imageUrls: const [], // Empty initially
      chapters: chapters,
      tags: detail.tags.map((tag) => Tag(
        id: tag.hashCode,
        name: tag,
        type: TagType.tag,
        count: 0,
        slug: tag.toLowerCase().replaceAll(' ', '-'),
      )).toList(),
      artists: detail.author != null ? [detail.author!] : [],
      characters: [],
      parodies: [],
      groups: [],
      language: 'indonesian',
      uploadDate: detail.lastUpdate ?? DateTime.now(),
      favorites: 0,
      englishTitle: detail.alternativeTitle,
    );
  }
}
