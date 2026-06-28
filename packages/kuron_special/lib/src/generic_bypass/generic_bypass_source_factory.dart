import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../webview_session/webview_session_adapter.dart';

/// Reusable factory for any source that needs Cloudflare bypass via
/// [WebViewSessionAdapter]. Wraps Dio with an interceptor that delegates
/// GET requests through `requestWithBypass`.
///
/// Register one instance per source ID, passing a pre-configured
/// [WebViewSessionAdapter] with isolated cookie storage.
class GenericBypassSourceFactory implements SourceFactory {
  final String _sourceId;
  final Dio _dio;
  final WebViewSessionAdapter _sessionAdapter;
  final Logger _logger;

  GenericBypassSourceFactory({
    required String sourceId,
    required Dio dio,
    required WebViewSessionAdapter sessionAdapter,
    required Logger logger,
  })  : _sourceId = sourceId,
        _dio = dio,
        _sessionAdapter = sessionAdapter,
        _logger = logger;

  @override
  String get sourceId => _sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) {
    // NativeAdapter improves TLS fingerprint to avoid CF detection
    try {
      _dio.httpClientAdapter = NativeAdapter(
        createCupertinoConfiguration: () =>
            URLSessionConfiguration.ephemeralSessionConfiguration(),
      );
    } catch (e) {
      _logger.w('$_sourceId: Failed to attach NativeAdapter: $e');
    }

    final interceptingDio = _BypassDioInterceptor(
      baseDio: _dio,
      sessionAdapter: _sessionAdapter,
    );

    return GenericHttpSource(
      rawConfig: config,
      dio: interceptingDio,
      logger: _logger,
    );
  }
}

/// Dio wrapper that routes GET through [WebViewSessionAdapter.requestWithBypass]
/// so Cloudflare 403 triggers native WebView bypass.
class _BypassDioInterceptor with DioMixin implements Dio {
  final Dio _baseDio;
  final WebViewSessionAdapter _sessionAdapter;

  _BypassDioInterceptor({
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
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final uri = Uri.parse(path).replace(queryParameters: queryParameters);
      path = uri.toString();
    }

    // Force 4xx to throw so WebViewSessionAdapter can detect CF 403
    // Redirects (3xx) remain non-throwing.
    final passthroughOptions = (options ?? Options()).copyWith(
      validateStatus: (status) => status != null && status < 400,
    );

    return _sessionAdapter.requestWithBypass<T>(
      path,
      options: passthroughOptions,
    );
  }

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
