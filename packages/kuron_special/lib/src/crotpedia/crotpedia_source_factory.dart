import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:logger/logger.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:kuron_core/kuron_core.dart';
import '../webview_session/webview_session_adapter.dart';

/// Factory to construct a Crotpedia generic source with a fully wired
/// WebViewSessionAdapter for Cloudflare bypass and auto-login capabilities.
/// Factory to construct a Crotpedia generic source with a fully wired
/// WebViewSessionAdapter for Cloudflare bypass and auto-login capabilities.
class CrotpediaSourceFactory implements SourceFactory {
  final Dio _dio;
  final PersistCookieJar _cookieJar;
  final Logger _logger;

  CrotpediaSourceFactory({
    required Dio dio,
    required PersistCookieJar cookieJar,
    required Logger logger,
  })  : _dio = dio,
        _cookieJar = cookieJar,
        _logger = logger;

  @override
  String get sourceId => 'crotpedia';

  @override
  ContentSource create(Map<String, dynamic> config) {
    // 1. Attach NativeAdapter to handle Cloudflare TLS fingerprinting
    try {
      _dio.httpClientAdapter = NativeAdapter(
        createCupertinoConfiguration: () =>
            URLSessionConfiguration.ephemeralSessionConfiguration(),
      );
    } catch (e) {
      _logger.w('Failed to attach NativeAdapter for Crotpedia: $e');
    }

    final baseUrl = config['baseUrl'] as String? ?? 'https://crotpedia.net';

    // 2. Build the WebViewSessionAdapter
    final sessionConfig = WebViewSessionConfig.fromJson(config);
    final sessionAdapter = WebViewSessionAdapter(
      dio: _dio,
      cookieJar: _cookieJar,
      config: sessionConfig,
      baseUrl: baseUrl,
      logger: _logger,
    );

    /// 3. Create a custom GenericRestAdapter subclass (or just override request method)
    /// We intercept `request` calls at the GenericAdapter level so that it
    /// automatically uses `sessionAdapter.requestWithBypass` instead of `dio.get`.
    final interceptingDio = _CrotpediaDioInterceptor(
      baseDio: _dio,
      sessionAdapter: sessionAdapter,
    );

    // 4. Return the configured GenericHttpSource
    return GenericHttpSource(
      rawConfig: config,
      dio: interceptingDio,
      logger: _logger,
    );
  }
}

/// A wrapper around Dio that delegates GET requests to WebViewSessionAdapter's
/// `requestWithBypass` method. This allows `GenericScraperAdapter` to
/// seamlessly benefit from Cloudflare bypass and Auth without modifying its code.
class _CrotpediaDioInterceptor with DioMixin implements Dio {
  final Dio _baseDio;
  final WebViewSessionAdapter _sessionAdapter;

  _CrotpediaDioInterceptor({
    required Dio baseDio,
    required WebViewSessionAdapter sessionAdapter,
  })  : _baseDio = baseDio,
        _sessionAdapter = sessionAdapter {
    options = baseDio.options;
    interceptors.addAll(baseDio.interceptors);
    httpClientAdapter = baseDio.httpClientAdapter;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    // We delegate GET to the session adapter to handle 403 bypass
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri.parse(path).replace(queryParameters: queryParameters);
      path = uri.toString();
    }

    // As `requestWithBypass` natively returns `Response<T>`, this works cleanly
    return _sessionAdapter.requestWithBypass<T>(path, options: options);
  }

  // Delegate other core requests back to baseDio
  @override
  Future<Response<T>> request<T>(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _baseDio.request<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _baseDio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _baseDio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _baseDio.head<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _baseDio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) {
    return _baseDio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
