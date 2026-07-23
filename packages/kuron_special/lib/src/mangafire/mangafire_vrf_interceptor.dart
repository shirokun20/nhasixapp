import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'mangafire_vrf_config.dart';
import 'mangafire_vrf_cache.dart';
import 'mangafire_vrf_capture_service.dart';

class MangaFireVRFInterceptor extends Interceptor {
  final MangaFireVRFConfig _config;
  final MangaFireVRFCache _cache;
  final MangaFireVRFCaptureService _captureService;
  final Logger _logger;
  final String _logTag;
  final Set<String> _retrying = {};
  final Dio _retryDio = Dio();

  MangaFireVRFInterceptor({
    required MangaFireVRFConfig config,
    required MangaFireVRFCache cache,
    required MangaFireVRFCaptureService captureService,
    required Logger logger,
    String sourceId = 'mangafire',
  })  : _config = config,
        _cache = cache,
        _captureService = captureService,
        _logger = logger,
        _logTag = sourceId;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.uri.path;
    if (!_config.shouldIntercept(path)) return handler.next(options);

    final cached = _cache.getEntry(path);
    if (cached != null) {
      final cachedUri = Uri.tryParse(cached);
      final reqPage = options.uri.queryParameters['page'];
      final cachedPage = cachedUri?.queryParameters['page'];
      final reqLang = options.uri.queryParameters['language'];
      final cachedLang = cachedUri?.queryParameters['language'];
      if (cachedPage != reqPage || cachedLang != reqLang) {
        _cache.invalidate(path);
      } else {
        options.extra.putIfAbsent('vrf_original_uri', () => options.uri);
        options.path = cached;
        options.queryParameters.clear();
        options.extra['vrf_cached'] = true;
        return handler.next(options);
      }
    }

    final requestParams =
        Map<String, dynamic>.from(options.uri.queryParameters);
    await _captureService.captureForPath(path, requestParams: requestParams);
    final after = _cache.getEntry(path);
    if (after != null) {
      options.extra.putIfAbsent('vrf_original_uri', () => options.uri);
      options.path = after;
      options.queryParameters.clear();
      options.extra['vrf_cached'] = true;
      return handler.next(options);
    }

    _logger.w('$_logTag: no VRF for $path, proceeding raw');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final data = err.response?.data;
    final msg = (data is Map) ? data['message']?.toString() ?? '' : '';
    final isInvalid =
        err.response?.statusCode == 403 && msg.toLowerCase() == 'invalid token';
    if (!isInvalid) {
      handler.next(err);
      return;
    }

    final path = options.uri.path;
    if (_retrying.contains(path)) {
      handler.next(err);
      return;
    }

    _logger.i('$_logTag: 403 for $path, recapturing');
    _cache.invalidate(path);
    _retrying.add(path);
    final originalUri =
        options.extra['vrf_original_uri'] as Uri? ?? options.uri;
    final requestParams =
        Map<String, dynamic>.from(originalUri.queryParameters);
    await _captureService.captureForPath(path, requestParams: requestParams);
    final vrfUrl = _cache.getEntry(path);
    if (vrfUrl != null) {
      final retry = options.copyWith();
      retry.path = vrfUrl;
      retry.queryParameters.clear();
      try {
        final resp = await _retryDio.fetch(retry);
        _retrying.remove(path);
        return handler.resolve(resp);
      } catch (_) {}
    }

    _retrying.remove(path);
    handler.next(err);
  }
}
