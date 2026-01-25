import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'crotpedia_scraper.dart';
import 'crotpedia_url_builder.dart';
import 'crotpedia_search_capabilities.dart';
import 'auth/crotpedia_auth_manager.dart';
import 'models/crotpedia_series.dart';

/// Crotpedia ContentSource implementation.
///
/// Provides content operations for Crotpedia source with optional authentication.
/// Login is required only for bookmark features.
class CrotpediaSource implements ContentSource {
  static final String sourceIdValue = SourceType.crotpedia.id;
  static const String displayNameValue = 'Crotpedia';
  static const String baseUrlValue = 'https://crotpedia.net';

  final CrotpediaScraper _scraper;
  final CrotpediaAuthManager _authManager;
  final Dio _dio;
  final Logger? _logger;
  final String _overriddenBaseUrl;
  final String _displayName;

  CrotpediaSource({
    required CrotpediaScraper scraper,
    required CrotpediaAuthManager authManager,
    required Dio dio,
    Logger? logger,
    String? baseUrl,
    String? displayName,
  })  : _scraper = scraper,
        _authManager = authManager,
        _dio = dio,
        _logger = logger,
        _overriddenBaseUrl = baseUrl ?? baseUrlValue,
        _displayName = displayName ?? displayNameValue {
    if (baseUrl != null) {
      CrotpediaUrlBuilder.setBaseUrl(baseUrl);
    }
  }

  // ============ ContentSource Interface ============

  @override
  String get id => sourceIdValue;

  @override
  String get displayName => _displayName;

  @override
  String get iconPath => 'assets/icons/crotpedia.png';

  @override
  String get baseUrl => _overriddenBaseUrl;

  @override
  bool get requiresBypass => false; // No cloudflare for now

  @override
  SearchCapabilities get searchCapabilities => crotpediaSearchCapabilities;

  @override
  String get refererHeader => baseUrlValue;

  // ============ Download & Display Customization ============

  @override
  Map<String, String> getImageDownloadHeaders({
    required String imageUrl,
    Map<String, String>? cookies,
  }) {
    final headers = {
      'Referer': baseUrlValue,
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };

    // Add authentication cookies if provided by caller
    // Caller (download_service) is responsible for fetching cookies from auth manager
    if (cookies != null && cookies.isNotEmpty) {
      final cookieString = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      headers['Cookie'] = cookieString;
    }

    return headers;
  }

  @override
  int? get brandColor => 0xFF1E88E5; // Crotpedia blue

  @override
  bool get showsPageCountInList => false; // Manga source - shows chapters

  @override
  bool get supportsAuthentication => true; // Has login feature

  @override
  bool get supportsBookmarks => true; // Has bookmark feature (requires login)


  @override
  Future<ContentListResult> getList({
    int page = 1,
    SortOption sort = SortOption.newest,
  }) async {
    try {
      final url = page == 1
          ? CrotpediaUrlBuilder.home()
          : CrotpediaUrlBuilder.page(page);

      final response = await _dio.get(
        url,
        options: Options(headers: {'Referer': '$baseUrlValue/'}),
      );
      final seriesList = _scraper.parseLatestSeries(response.data);
      final pagination = _scraper.parsePagination(response.data);

      final contents = seriesList.map(_mapSeriesToContent).toList();

      return ContentListResult(
        contents: contents,
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalCount: contents.length,
        hasNext: pagination.hasNext,
        hasPrevious: pagination.hasPrevious,
      );
    } catch (e) {
      _logger?.e('Failed to get list: $e');
      return ContentListResult(
        contents: [],
        currentPage: page,
        totalPages: 0,
        totalCount: 0,
        hasNext: false,
      );
    }
  }

  @override
  Future<ContentListResult> getPopular({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  }) async {
    try {
      final url = CrotpediaUrlBuilder.advancedSearch(
        order: 'popular',
      );

      final response = await _dio.get(
        url,
        options: Options(headers: {'Referer': '$baseUrlValue/'}),
      );
      final seriesList = _scraper.parseSearchResults(response.data);
      final pagination = _scraper.parsePagination(response.data);

      final contents = seriesList.map(_mapSeriesToContent).toList();

      return ContentListResult(
        contents: contents,
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalCount: contents.length,
        hasNext: pagination.hasNext,
        hasPrevious: pagination.hasPrevious,
      );
    } catch (e) {
      _logger?.e('Failed to get popular: $e');
      return ContentListResult(
        contents: [],
        currentPage: page,
        totalPages: 0,
        totalCount: 0,
        hasNext: false,
      );
    }
  }

  @override
  Future<ContentListResult> search(SearchFilter filter) async {
    try {
      final url = _buildSearchUrl(filter);

      final response = await _dio.get(
        url,
        options: Options(headers: {'Referer': '$baseUrlValue/'}),
      );
      final seriesList = _scraper.parseSearchResults(response.data);
      final pagination = _scraper.parsePagination(response.data);

      final contents = seriesList.map(_mapSeriesToContent).toList();

      return ContentListResult(
        contents: contents,
        currentPage: pagination.currentPage,
        totalPages: pagination.totalPages,
        totalCount: contents.length,
        hasNext: pagination.hasNext,
        hasPrevious: pagination.hasPrevious,
      );
    } catch (e) {
      _logger?.e('Failed to search: $e');
      return ContentListResult(
        contents: [],
        currentPage: filter.page,
        totalPages: 0,
        totalCount: 0,
        hasNext: false,
      );
    }
  }

  @override
  Future<Content> getDetail(String contentId) async {
    try {
      // Fetch series detail
      final seriesUrl = CrotpediaUrlBuilder.seriesDetail(contentId);
      final response = await _dio.get(
        seriesUrl,
        options: Options(headers: {'Referer': '$baseUrlValue/'}),
      );

      final seriesDetail = _scraper.parseSeriesDetail(response.data);

      // Map chapters
      final chapters = seriesDetail.chapters
          .map((c) => Chapter(
                id: c.slug,
                title: c.title,
                url: CrotpediaUrlBuilder.chapterReader(c.slug),
                uploadDate: c.publishedDate,
              ))
          .toList();

      // For Crotpedia (Manga/Manhwa), we don't load all images at once anymore.
      // We provide the chapter list, and the UI should handle fetching chapter images.

      // Map to Content entity
      return Content(
        id: contentId,
        sourceId: id,
        title: seriesDetail.title,
        coverUrl: seriesDetail.coverUrl,
        pageCount: 0, // Dynamic per chapter
        imageUrls: const [], // Empty initially
        chapters: chapters, // New field!
        tags: seriesDetail.genres.entries
            .map((e) => Tag(
                  id: e.key.hashCode,
                  name: e.value,
                  type: TagType.tag,
                  count: 0,
                  slug: e.key,
                ))
            .toList(),
        artists: seriesDetail.artist != null ? [seriesDetail.artist!] : seriesDetail.author != null ? [seriesDetail.author!] : [],
        characters: const [],
        parodies: const [],
        groups: const [],
        language: 'indonesian',
        uploadDate: DateTime.now(), // Use latest chapter date if available
        favorites: seriesDetail.favorites ?? 0,
      );
    } catch (e) {
      _logger?.e('Failed to get detail: $e');
      rethrow;
    }
  }

  @override
  Future<List<Content>> getRandom({int count = 1}) async {
    // Not implemented for Crotpedia
    return [];
  }

  @override
  Future<List<Content>> getRelated(String contentId) async {
    try {
      // Get detail to extract tags
      final content = await getDetail(contentId);

      // Search by first tag
      if (content.tags.isNotEmpty) {
        final firstTag = content.tags.first.name;
        final filter = SearchFilter(
          query: firstTag,
          page: 1,
        );

        final result = await search(filter);
        // Filter out the current content
        return result.contents.where((c) => c.id != contentId).take(5).toList();
      }

      return [];
    } catch (e) {
      _logger?.e('Failed to get related: $e');
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
    // Crotpedia images are already full URLs from eromanga.cfd
    // Just return them as-is (this method won't be used much)
    return '';
  }

  @override
  String buildThumbnailUrl({
    required String contentId,
    required String mediaId,
  }) {
    // Not used for Crotpedia
    return '';
  }

  @override
  String? parseContentIdFromUrl(String url) {
    // Extract slug from URL like https://crotpedia.net/baca/series/slug-name/
    final regex = RegExp(r'/baca/series/([^/]+)/?$');
    return regex.firstMatch(url)?.group(1);
  }

  @override
  bool isValidContentId(String contentId) {
    // Slug format validation
    return contentId.isNotEmpty && !contentId.contains('/');
  }

  // ============ Crotpedia-Specific Methods ============

  /// Get images from a specific chapter
  Future<List<String>> getChapterImages(String chapterSlug) async {
    try {
      final url = CrotpediaUrlBuilder.chapterReader(chapterSlug);
      final response = await _dio.get(
        url,
        options: Options(headers: {'Referer': '$baseUrlValue/'}),
      );
      return _scraper.parseChapterImages(response.data);
    } catch (e) {
      _logger?.e('Failed to get chapter images: $e');
      return [];
    }
  }

  /// Toggle bookmark for a series
  /// Returns new bookmark status (true=bookmarked)
  /// Requires login!
  Future<bool> toggleBookmark(String contentId, bool currentStatus) async {
    if (!isLoggedIn) {
      throw Exception('Login required for bookmarks');
    }

    return _authManager.toggleBookmark(contentId, !currentStatus);
  }

  // ============ Auth Methods (Delegated) ============

  /// Login with user-provided credentials
  Future<CrotpediaAuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    return _authManager.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  /// Try to restore session from saved credentials
  Future<bool> tryAutoLogin() => _authManager.tryAutoLogin();

  /// Check if user is logged in
  bool get isLoggedIn => _authManager.isLoggedIn;

  /// Get current auth state for UI
  CrotpediaAuthState get authState => _authManager.state;

  /// Get logged in username
  String? get username => _authManager.username;

  /// Check if credentials are saved (for "Remember Me")
  Future<bool> hasStoredCredentials() => _authManager.hasStoredCredentials();

  /// Get registration URL to open in WebView
  String get registerUrl => _authManager.registerUrl;

  /// Logout and clear stored credentials
  Future<void> logout() => _authManager.logout();

  // ============ Private Helper Methods ============

  String _buildSearchUrl(SearchFilter filter) {
    if (filter.query.isNotEmpty) {
      // Check for raw parameter format from FormBasedSearchUI
      // Format: "raw:title=val&author=val&genre[]=x&genre[]=y"
      if (filter.query.startsWith('raw:')) {
        final rawParams = filter.query.substring(4); // Remove 'raw:'
        // Construct advanced search URL with pagination support
        // Format: /advanced-search/page/N/?params (when page > 1)
        final pagePath = filter.page > 1 ? 'page/${filter.page}/' : '';
        return '$baseUrl/advanced-search/$pagePath?$rawParams';
      }

      // Check for genre navigation (legacy/direct)
      if (filter.query.startsWith('genre:')) {
        final genreSlug = filter.query.substring(6); // Remove 'genre:'
        return CrotpediaUrlBuilder.genre(genreSlug, page: filter.page);
      }

      // Check if it's a form-encoded query (contains known keys)
      // We look for 'title:', 'author:', 'artist:', 'year:', 'status:', 'type:'
      // If found, we parse it.
      if (_isFormEncoded(filter.query)) {
        final params = _parseQueryString(filter.query);
        final genres = filter.includeTags.map((tag) => tag.name).toList();

        return CrotpediaUrlBuilder.advancedSearch(
          title: params['title'] ?? '',
          author: params['author'] ?? '',
          artist: params['artist'] ?? '',
          year: params['year'] ?? '',
          status: params['status'] ?? '',
          type: params['type'] ?? '',
          order: _mapSortOption(filter.sort),
          genres: genres,
          page: filter.page,
        );
      }

      // Simple search if just query and NO tags
      if (filter.includeTags.isEmpty && filter.excludeTags.isEmpty) {
        return CrotpediaUrlBuilder.simpleSearch(filter.query,
            page: filter.page);
      }
    }

    // Default Advanced search (if tags are present but no special query parsing needed)
    // Here we treat filter.query as 'title' by default if it's just a string
    final genres = filter.includeTags.map((tag) => tag.name).toList();
    return CrotpediaUrlBuilder.advancedSearch(
      title: filter.query,
      order: _mapSortOption(filter.sort),
      genres: genres,
      page: filter.page,
    );
  }

  bool _isFormEncoded(String query) {
    return query.contains('title:') ||
        query.contains('author:') ||
        query.contains('artist:') ||
        query.contains('year:') ||
        query.contains('status:') ||
        query.contains('type:');
  }

  Map<String, String> _parseQueryString(String query) {
    final Map<String, String> params = {};
    // Split by space, validation needed for quoted strings?
    // FormBasedSearchWidget currently just appends "key:value "
    // We assume value doesn't contain space for now or implementation in widget handles it.
    // Ideally we should have better parsing but for now strict split is okay if widget respects it.
    // If widget allows spaces in value without quotes, this split is fragile.
    // BUT FormBasedSearchWidget logic was: buffer.write('$key:${controller.text} ');
    // If controller.text has spaces, e.g. "My Title", it becomes "title:My Title ".
    // Splitting by space will break "Title".
    // "title:My", "Title" -> "Title" is lost or treated as next key?

    // Better Regex approach:
    // keys are specific.
    // We can regex match `(title|author|artist|year|status|type):(.+?)(\s|$)`
    // Wait, regex lookahead is safer.

    // Let's use a simpler approach that works with the current widget implementation.
    // Widget produces: "title:val author:val "
    // If val has spaces, we need to handle it.
    // Current widget logic: `buffer.write('$key:${controller.text} ');`
    // Example: "title:My Book author:John Doe "

    // We can iterate through known keys and extract values between them.
    // But we don't know the order or which keys are present.

    // Regex strategy:
    // Match `(\w+):` to find keys.
    // The value is everything until the next key or end of string.

    final keyRegex = RegExp(r'\b(title|author|artist|year|status|type):');
    final matches = keyRegex.allMatches(query).toList();

    if (matches.isEmpty) return {};

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final key = match.group(1)!;
      final start = match.end;
      final end =
          (i + 1 < matches.length) ? matches[i + 1].start : query.length;

      var value = query.substring(start, end).trim();
      params[key] = value;
    }

    return params;
  }

  String _mapSortOption(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'update';
      case SortOption.popular:
      case SortOption.popularToday:
      case SortOption.popularWeek:
      case SortOption.popularMonth:
        return 'popular';
    }
  }

  Content _mapSeriesToContent(CrotpediaSeries series) {
    return Content(
      id: series.slug,
      sourceId: id,
      title: series.title,
      coverUrl: series.coverUrl,
      pageCount: 0, // Will be filled in detail view
      imageUrls: const [],
      tags: series.genres.entries
          .map((e) => Tag(
                id: e.key.hashCode, // Use hash for int ID
                name: e.value,
                type: TagType.tag,
                count: 0,
                slug: e.key, // Store actual slug here
              ))
          .toList(),
      artists: series.artist != null ? [series.artist!] : [],
      characters: const [],
      parodies: const [],
      groups: const [],
      language: 'indonesian',
      uploadDate: series.year != null 
          ? DateTime(series.year!, 1, 1) // Default to Jan 1st of year
          : DateTime.now(),
      favorites: series is CrotpediaSeriesDetail ? (series.favorites ?? 0) : 0,
      englishTitle: series is CrotpediaSeriesDetail ? series.alternativeTitle : null,
    );
  }
}
