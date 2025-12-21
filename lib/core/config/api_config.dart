/// API Configuration
///
/// Centralized configuration for API endpoints and settings.
library;

/// Configuration class for nhentai API
class ApiConfig {
  ApiConfig._();

  // ============ nhentai API ============

  /// Base URL for nhentai API
  static const String nhentaiApiBase = 'https://nhentai.net/api';

  /// nhentai website base URL (for fallback scraping)
  static const String nhentaiWebBase = 'https://nhentai.net';

  /// API request timeout in milliseconds
  static const int apiTimeout = 30000;

  /// Enable automatic fallback to HTML scraper if API fails
  static const bool enableApiFallback = true;

  /// Maximum retry attempts for API requests
  static const int maxRetryAttempts = 3;

  /// Delay between retries in milliseconds
  static const int retryDelayMs = 1000;

  // ============ Rate Limiting ============

  /// Minimum delay between API requests in milliseconds
  static const int minRequestDelayMs = 200;

  /// Maximum requests per minute
  static const int maxRequestsPerMinute = 60;

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
