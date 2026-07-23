import 'dart:async';

import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

import 'mangafire_vrf_config.dart';
import 'mangafire_vrf_cache.dart';
import 'mangafire_vrf_capture_service.dart';
import 'mangafire_vrf_interceptor.dart';

class MangaFireSourceFactory implements SourceFactory {
  final Dio _dio;
  final Logger _logger;
  final String _sourceId;

  MangaFireSourceFactory({
    required Dio dio,
    required Logger logger,
    String sourceId = 'mangafire',
  })  : _dio = dio,
        _logger = logger,
        _sourceId = sourceId;

  @override
  String get sourceId => _sourceId;

  @override
  ContentSource create(Map<String, dynamic> config) {
    final vrfConfig = MangaFireVRFConfig.fromConfigMap(config);

    if (!vrfConfig.enabled) {
      _logger.i('$_sourceId: VRF not enabled in config, using generic source');
      return GenericHttpSource(rawConfig: config, dio: _dio, logger: _logger);
    }

    final vrfCache = MangaFireVRFCache(
      maxEntries: vrfConfig.cacheMaxEntries,
      ttlSeconds: vrfConfig.ttlSeconds,
    );

    final vrfService = MangaFireVRFCaptureService(
      config: vrfConfig,
      cache: vrfCache,
      logger: _logger,
      sourceId: _sourceId,
    );

    final interceptor = MangaFireVRFInterceptor(
      config: vrfConfig,
      cache: vrfCache,
      captureService: vrfService,
      logger: _logger,
      sourceId: _sourceId,
    );

    // Clone Dio. VRF interceptor must be FIRST so its onError handles
    // 403 before HttpClientManager's onError swallows it.
    final mangafireDio = Dio(_dio.options);
    mangafireDio.interceptors.add(interceptor);
    for (final existing in _dio.interceptors) {
      try {
        mangafireDio.interceptors.add(existing);
      } catch (_) {}
    }

    // Proactive warmup
    unawaited(vrfService.warmup());

    return GenericHttpSource(
        rawConfig: config, dio: mangafireDio, logger: _logger);
  }
}
