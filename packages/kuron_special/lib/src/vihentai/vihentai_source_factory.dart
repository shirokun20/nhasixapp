/// ViHentai source factory — creates [GenericHttpSource] with ViHentaiAdapter.
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../webview_session/webview_session_adapter.dart';
import 'vihentai_adapter.dart';

class ViHentaiSourceFactory implements SourceFactory {
  final Dio _dio;
  final WebViewSessionAdapter _sessionAdapter;
  final Logger _logger;
  final PersistCookieJar _cookieJar;

  ViHentaiSourceFactory({
    required Dio dio,
    required WebViewSessionAdapter sessionAdapter,
    required Logger logger,
    required PersistCookieJar cookieJar,
  })  : _dio = dio,
        _sessionAdapter = sessionAdapter,
        _logger = logger,
        _cookieJar = cookieJar;

  @override
  String get sourceId => 'vihentai';

  @override
  ContentSource create(Map<String, dynamic> config) {
    // Per-source Dio with CookieManager sharing cf_vihentai jar with
    // WebViewSessionAdapter. Both cookies (cf_clearance from bypass,
    // laravel_session from solve) go to the same jar.
    final vihentaiDio = Dio(_dio.options);
    try {
      vihentaiDio.httpClientAdapter = NativeAdapter(
        createCupertinoConfiguration: () =>
            URLSessionConfiguration.ephemeralSessionConfiguration(),
      );
    } catch (e) {
      _logger.w('vihentai: Failed to attach NativeAdapter: $e');
    }

    // Use the SAME PersistCookieJar instance as WebViewSessionAdapter.
    // One jar, one memory cache — CF clearance + laravel_session coexist.
    vihentaiDio.interceptors.add(CookieManager(_cookieJar));

    // Copy global interceptors (logging, etc.)
    for (final interceptor in _dio.interceptors) {
      try { vihentaiDio.interceptors.add(interceptor); } catch (_) {}
    }

    // Bypass interceptor — routes GET through WebViewSessionAdapter for CF
    final bypassDio = _BypassDioInterceptor(
      baseDio: vihentaiDio,
      sessionAdapter: _sessionAdapter,
    );

    final urlBuilder = GenericUrlBuilder(
      baseUrl: config['baseUrl'] as String? ?? '',
    );
    final parser = GenericHtmlParser(logger: _logger);
    final scraperAdapter = GenericScraperAdapter(
      dio: bypassDio,
      urlBuilder: urlBuilder,
      parser: parser,
      logger: _logger,
      sourceId: 'vihentai',
    );

    final vihentaiAdapter = ViHentaiAdapter(
      dio: bypassDio,
      delegate: scraperAdapter,
      logger: _logger,
      sourceId: 'vihentai',
      cookieJar: _cookieJar,
    );

    return GenericHttpSource(
      rawConfig: config,
      dio: bypassDio,
      logger: _logger,
      adapterOverride: vihentaiAdapter,
    );
  }
}

/// Dio interceptor that routes GET through WebViewSessionAdapter bypass.
class _BypassDioInterceptor with DioMixin implements Dio {
  final Dio _baseDio;
  final WebViewSessionAdapter _sessionAdapter;

  _BypassDioInterceptor({
    required Dio baseDio,
    required WebViewSessionAdapter sessionAdapter,
  })  : _baseDio = baseDio,
        _sessionAdapter = sessionAdapter {
    options = baseDio.options;
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
    final passthroughOptions = (options ?? Options()).copyWith(
      validateStatus: (status) => status != null && status < 400,
    );
    // Forward session cookie from shared options.headers so that
    // WebViewSessionAdapter sends laravel_session alongside cf_clearance.
    if (this.options.headers.containsKey('Cookie')) {
      passthroughOptions.headers ??= <String, dynamic>{};
      passthroughOptions.headers!['Cookie'] = this.options.headers['Cookie'];
    }
    return _sessionAdapter.requestWithBypass<T>(
      path,
      options: passthroughOptions,
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
    return _baseDio.post<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
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
    return _baseDio.request<T>(url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
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
    return _baseDio.put<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }

  @override
  Future<Response<T>> head<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _baseDio.head<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken);
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _baseDio.delete<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken);
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
    return _baseDio.patch<T>(path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress);
  }
}
