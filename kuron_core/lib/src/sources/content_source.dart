import '../entities/content.dart';
import '../entities/content_list_result.dart';
import '../entities/search_filter.dart';
import '../value_objects/sort_option.dart';
import '../value_objects/popular_timeframe.dart';
import 'search_capabilities.dart';

/// Abstract interface for content sources.
///
/// Each content source (nhentai, crotpedia, etc.) must implement this interface
/// to provide content fetching capabilities.
abstract class ContentSource {
  /// Unique identifier for this source (e.g., 'nhentai', 'crotpedia')
  String get id;

  /// Display name shown in UI (e.g., 'nhentai', 'Crotpedia')
  String get displayName;

  /// Asset path to source icon
  String get iconPath;

  /// Base URL for this source
  String get baseUrl;

  /// Whether this source requires cloudflare bypass
  bool get requiresBypass;

  /// Search capabilities supported by this source
  SearchCapabilities get searchCapabilities;

  /// Search content with the given filter
  Future<ContentListResult> search(SearchFilter filter);

  /// Get content detail by ID
  Future<Content> getDetail(String contentId);

  /// Get paginated list of content
  Future<ContentListResult> getList({
    int page = 1,
    SortOption sort = SortOption.newest,
  });

  /// Get popular content
  Future<ContentListResult> getPopular({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  });

  /// Get random content
  Future<List<Content>> getRandom({int count = 1});

  /// Get related content for a specific content ID
  Future<List<Content>> getRelated(String contentId);

  /// Build full image URL for this source
  String buildImageUrl({
    required String contentId,
    required String mediaId,
    required int page,
    required String extension,
    bool thumbnail = false,
  });

  /// Build thumbnail URL for this source
  String buildThumbnailUrl({
    required String contentId,
    required String mediaId,
  });

  /// Parse content ID from a URL string
  String? parseContentIdFromUrl(String url);

  /// Validate content ID format for this source
  bool isValidContentId(String contentId);

  /// Get referer header value for requests
  String get refererHeader;

  // ============ NEW: Download & Display Customization ============

  /// Get HTTP headers required for downloading images from this source.
  ///
  /// This method returns all necessary headers (Referer, User-Agent, cookies, etc.)
  /// needed to successfully download images. Each source may have different
  /// requirements.
  ///
  /// Example:
  /// ```dart
  /// // nhentai
  /// {'Referer': 'https://nhentai.net/', 'User-Agent': 'Mozilla/5.0...'}
  ///
  /// // crotpedia with auth
  /// {'Referer': 'https://crotpedia.com/', 'Cookie': 'session=...'}
  /// ```
  Map<String, String> getImageDownloadHeaders({
    required String imageUrl,
    Map<String, String>? cookies,
  });

  /// Brand color for this source, used in UI decorations.
  ///
  /// This color is used for:
  /// - Download item progress bars
  /// - Source badges
  /// - Accent colors in source-specific screens
  ///
  /// Default returns null, which means use app's default theme color.
  int? get brandColor => null;

  /// Whether this source displays page counts in list/grid views.
  ///
  /// - nhentai: true (shows "123 pages")
  /// - manga sources (crotpedia, komiktap): false (shows chapters instead)
  bool get showsPageCountInList => true;

  /// Whether this source supports user authentication.
  ///
  /// If true, the app will show login/logout menu items for this source.
  bool get supportsAuthentication => false;

  /// Whether this source supports bookmarking/favoriting content.
  ///
  /// If true, bookmark buttons will be shown in detail screens.
  bool get supportsBookmarks => false;
}
