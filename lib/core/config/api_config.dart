import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/config/config_models.dart' as models;
 
/// Configuration class for nhentai API
class ApiConfig {
  ApiConfig._();
 
  static models.SourceConfig? get _nhentaiConfig =>
      getIt<RemoteConfigService>().getConfig('nhentai');
 
  // ============ nhentai API ============

  /// Base URL for nhentai API
  static String get nhentaiApiBase => _nhentaiConfig?.api?.apiBase ?? 'https://nhentai.net/api';
 
  /// nhentai website base URL (for fallback scraping)
  static String get nhentaiWebBase => _nhentaiConfig?.baseUrl ?? 'https://nhentai.net';
 
  /// API request timeout in milliseconds
  static int get apiTimeout => _nhentaiConfig?.api?.timeout ?? 30000;
 
  /// Enable automatic fallback to HTML scraper if API fails
  static bool get enableApiFallback => _nhentaiConfig?.features?.related?.enabled ?? true;
 
  /// Maximum retry attempts for API requests
  static int get maxRetryAttempts => _nhentaiConfig?.network?.retry?.maxAttempts ?? 3;
 
  /// Delay between retries in milliseconds
  static int get retryDelayMs => _nhentaiConfig?.network?.retry?.delayMs ?? 1000;

  // ============ Rate Limiting ============
 
  /// Minimum delay between API requests in milliseconds
  static int get minRequestDelayMs => _nhentaiConfig?.network?.rateLimit?.minDelayMs ?? 200;
 
  /// Maximum requests per minute
  static int get maxRequestsPerMinute => _nhentaiConfig?.network?.rateLimit?.requestsPerMinute ?? 60;

  // ============ Endpoints ============

  /// Get gallery detail endpoint
  static String getGalleryEndpoint(String id) => '$nhentaiApiBase/gallery/$id';

  /// Get all galleries endpoint (homepage)
  static String getAllGalleriesEndpoint({int page = 1}) =>
      '$nhentaiApiBase/galleries/all?page=$page';

  /// Search galleries endpoint
  static String getSearchEndpoint({
    required String query,
    String sort = 'date',
    int page = 1,
  }) {
    final encodedQuery = Uri.encodeComponent(query);
    return '$nhentaiApiBase/galleries/search?query=$encodedQuery&sort=$sort&page=$page';
  }

  /// Get related galleries endpoint
  static String getRelatedEndpoint(String id) =>
      '$nhentaiApiBase/gallery/$id/related';

  // ============ Sort Options ============

  /// Valid sort options for search
  static const List<String> validSortOptions = [
    'date', // Newest first (default)
    'popular', // Most popular all time
    'popular-week', // Popular this week
    'popular-today', // Popular today
  ];

  /// Map SortOption enum to API sort parameter
  static String mapSortOption(String sortOption) {
    return switch (sortOption.toLowerCase()) {
      'newest' || 'date' => 'date',
      'popular' || 'popular_all' => 'popular',
      'popularweek' || 'popular_week' || 'popular-week' => 'popular-week',
      'populartoday' || 'popular_today' || 'popular-today' => 'popular-today',
      _ => 'date',
    };
  }
}
