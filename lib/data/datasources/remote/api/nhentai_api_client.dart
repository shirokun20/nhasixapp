/// nhentai API Client
///
/// Dedicated client for interacting with nhentai JSON API.
/// Handles all API requests with proper error handling and rate limiting.
library;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../../core/config/api_config.dart';
import '../anti_detection.dart';
import '../request_rate_manager.dart';
import 'nhentai_api_models.dart';

/// Exception thrown when nhentai API request fails
class NhentaiApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NhentaiApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NhentaiApiException: $message (status: $statusCode)';

  /// Check if this is a rate limit error
  bool get isRateLimited => statusCode == 429;

  /// Check if this is a not found error
  bool get isNotFound => statusCode == 404;

  /// Check if this is a server error
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if this error should trigger a retry
  bool get shouldRetry => isServerError || isRateLimited;
}

/// nhentai API Client
///
/// Provides methods to interact with nhentai's JSON API endpoints.
/// Includes automatic retry logic and rate limiting.
class NhentaiApiClient {
  final Dio _dio;
  final Logger _logger = Logger();
  final RequestRateManager _rateManager;
  final AntiDetection _antiDetection;

  /// Create a new NhentaiApiClient
  ///
  /// [dio] - Optional custom Dio instance (useful for testing)
  NhentaiApiClient({Dio? dio})
      : _dio = dio ?? _createDefaultDio(),
        _rateManager = RequestRateManager(),
        _antiDetection = AntiDetection();

  /// Create default Dio instance with proper configuration
  static Dio _createDefaultDio() {
    final antiDetection = AntiDetection();
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(milliseconds: ApiConfig.apiTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.apiTimeout),
      headers: antiDetection.getRandomHeaders(),
    ));

    // Add logging interceptor in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (object) => Logger().d(object.toString()),
    ));

    return dio;
  }

  /// Wait for rate limiting before making request
  Future<void> _waitForRateLimit() async {
    if (!_rateManager.canMakeRequest()) {
      final delay = _rateManager.calculateDelay();
      _logger.d('Rate limiting: waiting ${delay.inMilliseconds}ms');
      await Future.delayed(delay);
    }
    await _antiDetection.applyRandomDelay();
  }

  /// Get gallery detail by ID
  ///
  /// [id] - Gallery ID (numeric string)
  /// Returns [NhentaiGalleryResponse] with full gallery details
  Future<NhentaiGalleryResponse> getGallery(String id) async {
    final url = ApiConfig.getGalleryEndpoint(id);
    _logger.d('NhentaiApiClient: Fetching gallery $id');

    try {
      await _waitForRateLimit();
      final response = await _makeRequest(url);

      final gallery = NhentaiGalleryResponse.fromJson(response.data);
      _logger.i('NhentaiApiClient: Successfully fetched gallery $id');
      return gallery;
    } catch (e) {
      _logger.e('NhentaiApiClient: Failed to fetch gallery $id', error: e);
      rethrow;
    }
  }

  /// Get all galleries (homepage content)
  ///
  /// [page] - Page number (1-indexed)
  /// Returns [NhentaiListResponse] with list of galleries
  Future<NhentaiListResponse> getAllGalleries({int page = 1}) async {
    final url = ApiConfig.getAllGalleriesEndpoint(page: page);
    _logger.d('NhentaiApiClient: Fetching all galleries page $page');

    try {
      await _waitForRateLimit();
      final response = await _makeRequest(url);

      final listResponse = NhentaiListResponse.fromJson(response.data);
      _logger.i(
          'NhentaiApiClient: Fetched ${listResponse.result.length} galleries from page $page');
      return listResponse;
    } catch (e) {
      _logger.e('NhentaiApiClient: Failed to fetch galleries page $page',
          error: e);
      rethrow;
    }
  }

  /// Search galleries
  ///
  /// [query] - Search query (supports nhentai search syntax)
  /// [sort] - Sort option: 'date', 'popular', 'popular-week', 'popular-today'
  /// [page] - Page number (1-indexed)
  /// Returns [NhentaiListResponse] with search results
  Future<NhentaiListResponse> search(
    String query, {
    String sort = 'date',
    int page = 1,
  }) async {
    final mappedSort = ApiConfig.mapSortOption(sort);
    final url = ApiConfig.getSearchEndpoint(
      query: query,
      sort: mappedSort,
      page: page,
    );
    _logger.d(
        'NhentaiApiClient: Searching "$query" (sort: $mappedSort, page: $page)');

    try {
      await _waitForRateLimit();
      final response = await _makeRequest(url);

      final listResponse = NhentaiListResponse.fromJson(response.data);
      _logger.i(
          'NhentaiApiClient: Search returned ${listResponse.result.length} results');
      return listResponse;
    } catch (e) {
      _logger.e('NhentaiApiClient: Search failed for "$query"', error: e);
      rethrow;
    }
  }

  /// Get related galleries
  ///
  /// [id] - Gallery ID to find related content for
  /// Returns [NhentaiRelatedResponse] with related galleries
  Future<NhentaiRelatedResponse> getRelated(String id) async {
    final url = ApiConfig.getRelatedEndpoint(id);
    _logger.d('NhentaiApiClient: Fetching related for gallery $id');

    try {
      await _waitForRateLimit();
      final response = await _makeRequest(url);

      final relatedResponse = NhentaiRelatedResponse.fromJson(response.data);
      _logger.i(
          'NhentaiApiClient: Found ${relatedResponse.result.length} related galleries');
      return relatedResponse;
    } catch (e) {
      _logger.e('NhentaiApiClient: Failed to fetch related for $id', error: e);
      rethrow;
    }
  }

  /// Get popular galleries
  ///
  /// [period] - Time period: 'all', 'week', 'today'
  /// [page] - Page number (1-indexed)
  /// Returns [NhentaiListResponse] with popular galleries
  Future<NhentaiListResponse> getPopular({
    String period = 'all',
    int page = 1,
  }) async {
    // Popular is just a search with empty query and sort option
    final sort = switch (period.toLowerCase()) {
      'week' => 'popular-week',
      'today' => 'popular-today',
      _ => 'popular',
    };

    return search('', sort: sort, page: page);
  }

  /// Make HTTP request with retry logic
  Future<Response> _makeRequest(String url) async {
    int attempts = 0;
    NhentaiApiException? lastException;

    while (attempts < ApiConfig.maxRetryAttempts) {
      attempts++;

      try {
        // Refresh headers to avoid detection
        _dio.options.headers = _antiDetection.getRandomHeaders();

        final response = await _dio.get(url);

        if (response.statusCode == 200 && response.data != null) {
          _rateManager.recordRequest();
          return response;
        }

        throw NhentaiApiException(
          'Unexpected response',
          statusCode: response.statusCode,
        );
      } on DioException catch (e) {
        lastException = _handleDioException(e, url);

        if (!lastException.shouldRetry ||
            attempts >= ApiConfig.maxRetryAttempts) {
          throw lastException;
        }

        // Trigger cooldown if rate limited
        if (lastException.isRateLimited) {
          _rateManager.triggerCooldown();
        }

        _logger.w(
            'NhentaiApiClient: Retry attempt $attempts/${ApiConfig.maxRetryAttempts} for $url');
        await Future.delayed(
            Duration(milliseconds: ApiConfig.retryDelayMs * attempts));
      }
    }

    throw lastException ??
        const NhentaiApiException('Max retry attempts exceeded');
  }

  /// Handle Dio exceptions and convert to NhentaiApiException
  NhentaiApiException _handleDioException(DioException e, String url) {
    final statusCode = e.response?.statusCode;

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        NhentaiApiException(
          'Request timeout',
          statusCode: statusCode,
          originalError: e,
        ),
      DioExceptionType.badResponse => NhentaiApiException(
          _getErrorMessage(statusCode),
          statusCode: statusCode,
          originalError: e,
        ),
      DioExceptionType.cancel => NhentaiApiException(
          'Request cancelled',
          statusCode: statusCode,
          originalError: e,
        ),
      _ => NhentaiApiException(
          'Network error: ${e.message}',
          statusCode: statusCode,
          originalError: e,
        ),
    };
  }

  /// Get user-friendly error message based on status code
  String _getErrorMessage(int? statusCode) {
    return switch (statusCode) {
      400 => 'Bad request',
      403 => 'Access forbidden (possible Cloudflare block)',
      404 => 'Content not found',
      429 => 'Rate limited - please wait',
      500 => 'Server error',
      502 => 'Bad gateway',
      503 => 'Service unavailable',
      _ => 'HTTP error $statusCode',
    };
  }

  /// Check if API is reachable
  Future<bool> checkHealth() async {
    try {
      await _waitForRateLimit();
      final response = await _dio.get(
        ApiConfig.getAllGalleriesEndpoint(page: 1),
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.w('NhentaiApiClient: Health check failed', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _rateManager.dispose();
    _antiDetection.dispose();
  }
}
