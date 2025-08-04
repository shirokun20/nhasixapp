import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Singleton HTTP client manager to ensure proper lifecycle management
/// and prevent disposal issues across the application
class HttpClientManager {
  static HttpClientManager? _instance;
  static Dio? _httpClient;
  static Logger? _logger;

  HttpClientManager._internal();

  /// Get the singleton instance
  static HttpClientManager get instance {
    _instance ??= HttpClientManager._internal();
    return _instance!;
  }

  /// Initialize the HTTP client with proper configuration
  static Dio initializeHttpClient({Logger? logger}) {
    _logger = logger ?? Logger();

    if (_httpClient != null) {
      _logger
          ?.d('HTTP client already initialized, returning existing instance');
      return _httpClient!;
    }

    _logger?.i('Initializing HTTP client singleton...');

    _httpClient = Dio();

    // Configure default options
    _httpClient!.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };

    // Set default timeouts
    _httpClient!.options.connectTimeout = const Duration(seconds: 30);
    _httpClient!.options.receiveTimeout = const Duration(seconds: 30);
    _httpClient!.options.sendTimeout = const Duration(seconds: 30);
    _httpClient!.options.followRedirects = true;
    _httpClient!.options.maxRedirects = 5;
    _httpClient!.options.responseType = ResponseType.plain;

    // Add logging interceptor
    _httpClient!.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => _logger?.d(obj),
      ),
    );

    // Add error handling interceptor
    _httpClient!.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logger?.e('HTTP Error: ${error.message}');
          handler.next(error);
        },
        onRequest: (options, handler) {
          _logger?.d('HTTP Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger?.d(
              'HTTP Response: ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
      ),
    );

    _logger?.i('HTTP client singleton initialized successfully');
    return _httpClient!;
  }

  /// Get the HTTP client instance
  /// Throws an exception if not initialized
  static Dio get httpClient {
    if (_httpClient == null) {
      throw StateError(
        'HTTP client not initialized. Call HttpClientManager.initializeHttpClient() first.',
      );
    }
    return _httpClient!;
  }

  /// Check if HTTP client is initialized
  static bool get isInitialized => _httpClient != null;

  /// Update HTTP client configuration
  static void updateConfiguration({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, dynamic>? headers,
  }) {
    if (_httpClient == null) {
      _logger?.w('Cannot update configuration: HTTP client not initialized');
      return;
    }

    _logger?.d('Updating HTTP client configuration...');

    if (connectTimeout != null) {
      _httpClient!.options.connectTimeout = connectTimeout;
    }
    if (receiveTimeout != null) {
      _httpClient!.options.receiveTimeout = receiveTimeout;
    }
    if (sendTimeout != null) {
      _httpClient!.options.sendTimeout = sendTimeout;
    }
    if (headers != null) {
      _httpClient!.options.headers.addAll(headers);
    }

    _logger?.d('HTTP client configuration updated');
  }

  /// Add an interceptor to the HTTP client
  static void addInterceptor(Interceptor interceptor) {
    if (_httpClient == null) {
      _logger?.w('Cannot add interceptor: HTTP client not initialized');
      return;
    }

    _httpClient!.interceptors.add(interceptor);
    _logger?.d('Interceptor added to HTTP client');
  }

  /// Remove an interceptor from the HTTP client
  static void removeInterceptor(Interceptor interceptor) {
    if (_httpClient == null) {
      _logger?.w('Cannot remove interceptor: HTTP client not initialized');
      return;
    }

    _httpClient!.interceptors.remove(interceptor);
    _logger?.d('Interceptor removed from HTTP client');
  }

  /// Clear all interceptors except the default ones
  static void clearInterceptors() {
    if (_httpClient == null) {
      _logger?.w('Cannot clear interceptors: HTTP client not initialized');
      return;
    }

    _httpClient!.interceptors.clear();
    _logger?.d('All interceptors cleared from HTTP client');
  }

  /// Get HTTP client statistics
  static Map<String, dynamic> getStatistics() {
    if (_httpClient == null) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'interceptors_count': _httpClient!.interceptors.length,
      'connect_timeout': _httpClient!.options.connectTimeout?.inMilliseconds,
      'receive_timeout': _httpClient!.options.receiveTimeout?.inMilliseconds,
      'send_timeout': _httpClient!.options.sendTimeout?.inMilliseconds,
      'base_url': _httpClient!.options.baseUrl,
      'headers_count': _httpClient!.options.headers.length,
    };
  }

  /// Reset the HTTP client (for testing purposes only)
  /// WARNING: This should only be used in tests
  static void resetForTesting() {
    _logger?.w(
        'Resetting HTTP client for testing - this should only be used in tests!');
    _httpClient?.close(force: true);
    _httpClient = null;
    _instance = null;
  }
}
