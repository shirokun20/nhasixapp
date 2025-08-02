
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';
import 'dart:math';

import '../../models/content_model.dart';
import '../../models/tag_model.dart';
import '../../../domain/entities/search_filter.dart';
import 'nhentai_scraper.dart';
import 'anti_detection.dart';
import 'exceptions.dart';

/// Remote data source for web scraping nhentai.net
class RemoteDataSource {
  RemoteDataSource({
    required this.httpClient,
    required this.scraper,
    required this.cloudflareBypass,
    required this.antiDetection,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final Dio httpClient;
  final NhentaiScraper scraper;
  final CloudflareBypassNoWebView cloudflareBypass;
  final AntiDetection antiDetection;
  final Logger _logger;

  static const String baseUrl = 'https://nhentai.net';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  /// Initialize the remote data source
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing RemoteDataSource...');

      // Configure HTTP client
      _configureHttpClient();

      // Initialize anti-detection measures
      await antiDetection.initialize();

      // Attempt Cloudflare bypass
      final bypassSuccess = await cloudflareBypass.attemptBypass();
      if (!bypassSuccess) {
        _logger.w('Cloudflare bypass failed, some requests may fail');
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize RemoteDataSource',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get content list from homepage or specific page
  Future<List<ContentModel>> getContentList({int page = 1}) async {
    try {
      _logger.i('Fetching content list for page $page');

      final url = page == 1 ? baseUrl : '$baseUrl/?page=$page';
      final html = await _getPageHtml(url);

      final contents = scraper.parseContentList(html);
      _logger
          .i('Successfully parsed ${contents.length} contents from page $page');

      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to get content list for page $page',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get detailed content information
  Future<ContentModel> getContentDetail(String contentId) async {
    try {
      _logger.i('Fetching content detail for ID: $contentId');

      final url = '$baseUrl/g/$contentId/';
      final html = await _getPageHtml(url);

      final content = scraper.parseContentDetail(html, contentId);
      _logger.i('Successfully parsed content detail for ID: $contentId');

      return content;
    } catch (e, stackTrace) {
      _logger.e('Failed to get content detail for ID: $contentId',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Search content with filters
  Future<List<ContentModel>> searchContent(SearchFilter filter) async {
    try {
      _logger.i('Searching content with filter: ${filter.toQueryString()}');

      final url = _buildSearchUrl(filter);
      final html = await _getPageHtml(url);

      final contents = scraper.parseSearchResults(html);
      _logger.i('Successfully found ${contents.length} search results');

      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to search content', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get random content
  Future<ContentModel> getRandomContent() async {
    try {
      _logger.i('Fetching random content');

      final url = '$baseUrl/random/';
      final html = await _getPageHtml(url);

      // Extract content ID from the redirected URL or page content
      final contentId = scraper.extractContentIdFromPage(html);
      if (contentId == null) {
        throw Exception('Failed to extract content ID from random page');
      }

      return await getContentDetail(contentId);
    } catch (e, stackTrace) {
      _logger.e('Failed to get random content',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get popular content
  Future<List<ContentModel>> getPopularContent({
    String period = 'all', // all, week, today
    int page = 1,
  }) async {
    try {
      _logger.i('Fetching popular content for period: $period, page: $page');

      final url = '$baseUrl/search/?q=&sort=popular-$period&page=$page';
      final html = await _getPageHtml(url);

      final contents = scraper.parseContentList(html);
      _logger.i('Successfully parsed ${contents.length} popular contents');

      return contents;
    } catch (e, stackTrace) {
      _logger.e('Failed to get popular content',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all available tags
  Future<List<TagModel>> getAllTags() async {
    try {
      _logger.i('Fetching all tags');

      final url = '$baseUrl/tags/';
      final html = await _getPageHtml(url);

      final tags = scraper.parseTagsPage(html);
      _logger.i('Successfully parsed ${tags.length} tags');

      return tags;
    } catch (e, stackTrace) {
      _logger.e('Failed to get all tags', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get tags by type (artist, character, etc.)
  Future<List<TagModel>> getTagsByType(String type) async {
    try {
      _logger.i('Fetching tags for type: $type');

      final url = '$baseUrl/${type}s/'; // artists/, characters/, etc.
      final html = await _getPageHtml(url);

      final tags = scraper.parseTagsPage(html, type: type);
      _logger.i('Successfully parsed ${tags.length} $type tags');

      return tags;
    } catch (e, stackTrace) {
      _logger.e('Failed to get tags for type: $type',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if Cloudflare bypass is needed
  Future<bool> checkCloudflareStatus() async {
      _logger.i('Checking Cloudflare status... from $baseUrl');
    try {
      final response = await httpClient.get(
        baseUrl
      );

      _logger.i('Cloudflare status: ${response.statusCode}');

      return !cloudflareBypass.isCloudflareChallenge(response.data) || response.statusCode == 200;
    } catch (e, stackTrace) {
      _logger.w('Failed to check Cloudflare status: $e, and $stackTrace');
      return false;
    }
  }

  /// Attempt to bypass Cloudflare protection
  Future<bool> bypassCloudflare() async {
    try {
      _logger.i('Attempting Cloudflare bypass...');
      return await cloudflareBypass.attemptBypass();
    } catch (e, stackTrace) {
      _logger.e('Cloudflare bypass failed', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get HTML content from URL with retry logic
  Future<String> _getPageHtml(String url) async {
    RemoteDataSourceException? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _logger.d('Fetching HTML from: $url (attempt $attempt/$maxRetries)');

        // Check if we should throttle requests
        if (antiDetection.shouldThrottleRequests()) {
          throw const RateLimitException('Request rate limit exceeded');
        }

        // Apply anti-detection measures
        await antiDetection.applyRandomDelay();
        final headers = antiDetection.getRandomHeaders();

        _logger.i("headers: $headers");

        final response = await httpClient.get(
          url,
          options: Options(
            headers: headers,
            sendTimeout: requestTimeout,
            receiveTimeout: requestTimeout,
            followRedirects: true,
            maxRedirects: 5,
            responseType: ResponseType.plain,
          ),
        );

        if (response.statusCode == 200) {
          final html = response.data as String;

          // Check if Cloudflare challenge is present
          if (cloudflareBypass.isCloudflareChallenge(html)) {
            _logger.w('Cloudflare challenge detected, attempting bypass...');
            final bypassSuccess = await cloudflareBypass.attemptBypass();
            if (!bypassSuccess) {
              throw const CloudflareException(
                  'Failed to bypass Cloudflare protection');
            }
            // Retry the request after bypass
            continue;
          }

          return html;
        } else if (response.statusCode == 404) {
          throw ContentNotFoundException(
              'Content not found: $url', response.statusCode.toString());
        } else if (response.statusCode == 429) {
          throw RateLimitException(
              'Rate limit exceeded: $url', response.statusCode.toString());
        } else if (response.statusCode! >= 500) {
          throw ServerException('Server error: ${response.statusCode}',
              response.statusCode.toString());
        } else {
          throw NetworkException(
              'HTTP ${response.statusCode}: ${response.statusMessage}',
              response.statusCode.toString());
        }
      } on DioException catch (e, stackTrace) {
        lastException = _handleDioException(e, url);
        _logger.w('Attempt $attempt failed: $lastException, $stackTrace');

        if (attempt < maxRetries && _shouldRetry(lastException)) {
          // Exponential backoff with jitter
          final delay = Duration(
            milliseconds:
                (1000 * pow(2, attempt - 1)).toInt() + Random().nextInt(1000),
          );
          _logger.d('Waiting ${delay.inMilliseconds}ms before retry...');
          await Future.delayed(delay);
        } else {
          break;
        }
      } catch (e) {
        lastException = ParseException('Unexpected error: $e');
        _logger.w('Attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          final delay = Duration(
            milliseconds:
                (1000 * pow(2, attempt - 1)).toInt() + Random().nextInt(1000),
          );
          _logger.d('Waiting ${delay.inMilliseconds}ms before retry...');
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ??
        NetworkException('Failed to fetch HTML after $maxRetries attempts');
  }

  /// Handle Dio exceptions and convert to appropriate exception types
  RemoteDataSourceException _handleDioException(DioException e, String url) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timeout for: $url', e.type.toString());

      case DioExceptionType.connectionError:
        return NetworkException(
            'Connection error for: $url', e.type.toString());

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return ContentNotFoundException(
              'Content not found: $url', statusCode.toString());
        } else if (statusCode == 429) {
          return RateLimitException(
              'Rate limit exceeded: $url', statusCode.toString());
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
              'Server error $statusCode for: $url', statusCode.toString());
        } else {
          return NetworkException(
              'Bad response for: $url', statusCode.toString());
        }

      case DioExceptionType.cancel:
        return NetworkException(
            'Request cancelled for: $url', e.type.toString());

      case DioExceptionType.unknown:
      default:
        return NetworkException(
            'Unknown error for: $url - ${e.message}', e.type.toString());
    }
  }

  /// Check if exception should trigger a retry
  bool _shouldRetry(RemoteDataSourceException exception) {
    return exception is NetworkException ||
        exception is TimeoutException ||
        exception is ServerException ||
        exception is CloudflareException;
  }

  /// Configure HTTP client with default settings
  void _configureHttpClient() {
    httpClient.options.baseUrl = baseUrl;
    httpClient.options.connectTimeout = requestTimeout;
    httpClient.options.receiveTimeout = requestTimeout;
    httpClient.options.sendTimeout = requestTimeout;
    httpClient.options.followRedirects = true;
    httpClient.options.maxRedirects = 5;
    httpClient.options.responseType = ResponseType.plain;

    // Add interceptors for logging and error handling
    httpClient.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => _logger.d(obj),
      ),
    );

    httpClient.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logger.e('HTTP Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// Build search URL from filter
  String _buildSearchUrl(SearchFilter filter) {
    final buffer = StringBuffer('$baseUrl/search/?');

    // Query parameter
    if (filter.query != null && filter.query!.isNotEmpty) {
      buffer.write('q=${Uri.encodeComponent(filter.query!)}');
    } else {
      buffer.write('q=');
    }

    // Sort parameter
    buffer.write('&sort=${filter.sortBy.apiValue}');

    // Page parameter
    if (filter.page > 1) {
      buffer.write('&page=${filter.page}');
    }

    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _logger.i('Disposing RemoteDataSource...');
    // httpClient.close();
    // antiDetection.dispose();
  }
}
