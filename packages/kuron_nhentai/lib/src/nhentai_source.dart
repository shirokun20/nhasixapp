import 'package:kuron_core/kuron_core.dart';
import 'nhentai_search_capabilities.dart';
import 'nhentai_url_builder.dart';

/// nhentai ContentSource implementation.
///
/// This class provides all content operations for nhentai source.
/// The actual scraping logic is delegated to an external scraper
/// that will be injected from the main app.
class NhentaiSource implements ContentSource {
  /// Creates a new NhentaiSource.
  ///
  /// [scraper] - The scraper implementation for making HTTP requests
  /// This allows the main app to inject its existing scraper with
  /// all the cloudflare bypass logic.
  NhentaiSource({
    required NhentaiScraperAdapter scraper,
  }) : _scraper = scraper;

  final NhentaiScraperAdapter _scraper;

  @override
  String get id => 'nhentai';

  @override
  String get displayName => 'nhentai';

  @override
  String get iconPath => 'assets/icons/nhentai.png';

  @override
  String get baseUrl => NhentaiUrlBuilder.baseUrl;

  @override
  bool get requiresBypass => true;

  @override
  SearchCapabilities get searchCapabilities => nhentaiSearchCapabilities;

  @override
  String get refererHeader => NhentaiUrlBuilder.refererHeader;

  @override
  Future<ContentListResult> search(SearchFilter filter) async {
    return _scraper.search(filter);
  }

  @override
  Future<Content> getDetail(String contentId) async {
    return _scraper.getDetail(contentId);
  }

  @override
  Future<ContentListResult> getList({
    int page = 1,
    SortOption sort = SortOption.newest,
  }) async {
    return _scraper.getList(page: page, sort: sort);
  }

  @override
  Future<ContentListResult> getPopular({
    PopularTimeframe timeframe = PopularTimeframe.allTime,
    int page = 1,
  }) async {
    return _scraper.getPopular(timeframe: timeframe, page: page);
  }

  @override
  Future<List<Content>> getRandom({int count = 1}) async {
    return _scraper.getRandom(count: count);
  }

  @override
  Future<List<Content>> getRelated(String contentId) async {
    return _scraper.getRelated(contentId);
  }

  @override
  String buildImageUrl({
    required String contentId,
    required String mediaId,
    required int page,
    required String extension,
    bool thumbnail = false,
  }) {
    if (thumbnail) {
      return NhentaiUrlBuilder.buildPageThumbnailUrl(
        mediaId: mediaId,
        page: page,
        extension: extension,
      );
    }
    return NhentaiUrlBuilder.buildImageUrl(
      mediaId: mediaId,
      page: page,
      extension: extension,
    );
  }

  @override
  String buildThumbnailUrl({
    required String contentId,
    required String mediaId,
  }) {
    return NhentaiUrlBuilder.buildThumbnailUrl(mediaId: mediaId);
  }

  @override
  String? parseContentIdFromUrl(String url) {
    return NhentaiUrlBuilder.parseContentIdFromUrl(url);
  }

  @override
  bool isValidContentId(String contentId) {
    return NhentaiUrlBuilder.isValidContentId(contentId);
  }
}

/// Adapter interface for nhentai scraper.
///
/// This allows the main app to inject its existing scraper implementation
/// that has all the cloudflare bypass and rate limiting logic.
abstract class NhentaiScraperAdapter {
  Future<ContentListResult> search(SearchFilter filter);
  Future<Content> getDetail(String contentId);
  Future<ContentListResult> getList({int page = 1, SortOption sort});
  Future<ContentListResult> getPopular({PopularTimeframe timeframe, int page});
  Future<List<Content>> getRandom({int count = 1});
  Future<List<Content>> getRelated(String contentId);
}
