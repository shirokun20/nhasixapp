import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'dns_resolver.dart';

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

  /// Initialize the HTTP client with proper configuration.
  ///
  /// When [dnsResolver] is provided, all connections bypass system DNS via
  /// DNS-over-HTTPS. The technique used is **socket-level DNS bypass**:
  /// the raw TCP socket connects to the resolved IP, while Dart's HttpClient
  /// handles TLS with the original hostname as SNI — exactly like
  /// `curl --resolve hostname:443:ip`. HTTPS certificate validation stays
  /// fully correct with zero extra code needed.
  static Dio initializeHttpClient({
    Logger? logger,
    DnsResolver? dnsResolver,
  }) {
    _logger = logger ?? Logger();

    if (_httpClient != null) {
      _logger
          ?.d('HTTP client already initialized, returning existing instance');
      return _httpClient!;
    }

    _logger?.i('Initializing HTTP client singleton...');

    _httpClient = Dio();

    // Socket-level DNS bypass via connectionFactory.
    // Dart's HttpClient accepts a raw Socket from connectionFactory and then
    // wraps it with TLS using the *original URI hostname* for SNI — so cert
    // validation is automatic and correct, just like `curl --resolve`.
    // No URL rewriting, no custom cert callbacks needed.
    if (dnsResolver != null) {
      _httpClient!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.connectionFactory =
              (Uri uri, String? proxyHost, int? proxyPort) async {
            try {
              // Skip DoH for addresses that are already IPs
              if (_isIpAddress(uri.host)) {
                return Socket.startConnect(uri.host, uri.port);
              }
              final addresses = await dnsResolver.lookup(uri.host);
              if (addresses.isEmpty) throw Exception('No DoH addresses');
              _logger?.d(
                  'DoH: ${uri.host} → ${addresses.first.address} (SNI kept)');
              // Connect socket to resolved IP; HttpClient wraps with TLS
              // using uri.host as SNI automatically.
              return Socket.startConnect(addresses.first, uri.port);
            } catch (e) {
              _logger?.e('DoH failed for ${uri.host}: $e');
              // No system DNS fallback — propagate so the caller sees the real
              // failure instead of silently connecting via censored system DNS.
              rethrow;
            }
          };
          return client;
        },
      );
    }

    // Configure default options with Chrome Android fingerprint.
    // Only include headers that are correct across all request types.
    // Navigation-specific headers (Sec-Fetch-Mode: navigate, Upgrade-Insecure-Requests,
    // Cache-Control: max-age=0) are NOT set here — they cause Cloudflare WAF to block
    // POST/API requests since POST + navigate is a contradictory bot signal.
    // Those headers should be set per-request in GET-navigation-only contexts.
    _httpClient!.options.headers = {
      // Core identity headers — valid for all request types
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      // Chrome client hints — always sent by Chrome 89+, valid for all types
      'Sec-Ch-Ua':
          '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'Sec-Ch-Ua-Mobile': '?1',
      'Sec-Ch-Ua-Platform': '"Android"',
      // Accept-Language is safe to send on all requests
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
    };

    // Set default timeouts
    _httpClient!.options.connectTimeout = AppDurations.networkTimeout;
    _httpClient!.options.receiveTimeout = AppDurations.networkTimeout;
    _httpClient!.options.sendTimeout = AppDurations.networkTimeout;
    _httpClient!.options.followRedirects = true;
    _httpClient!.options.maxRedirects = 5;
    _httpClient!.options.responseType = ResponseType.plain;

    if (dnsResolver != null) {
      _logger?.i('DoH enabled via socket-level connectionFactory');
    }

    // Add logging interceptor
    _httpClient!.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        // logPrint: (obj) => _logger?.d(obj),
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

  /// Check if [host] is already a numeric IP address.
  /// Connections to IPs skip DoH lookup (no DNS needed).
  static bool _isIpAddress(String host) {
    try {
      InternetAddress(host, type: InternetAddressType.IPv4);
      return true;
    } catch (_) {}
    try {
      InternetAddress(host, type: InternetAddressType.IPv6);
      return true;
    } catch (_) {
      return false;
    }
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
