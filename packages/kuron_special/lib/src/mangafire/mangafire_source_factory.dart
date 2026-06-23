import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:logger/logger.dart';

import 'mangafire_adapter.dart';
import 'mangafire_vrf_cache.dart';
import 'mangafire_webview_helper.dart';

class MangaFireSourceFactory implements SourceFactory {
  MangaFireSourceFactory({
    required Dio dio,
    required Logger logger,
    MangaFireVrfCache? vrfCache,
    MangaFireWebViewHelper? webViewHelper,
  })  : _dio = dio,
        _logger = logger,
        _vrfCache = vrfCache ?? MangaFireVrfCache(),
        _webViewHelper = webViewHelper ??
            MangaFireWebViewHelper(
              logger: logger,
            );

  final Dio _dio;
  final Logger _logger;
  final MangaFireVrfCache _vrfCache;
  final MangaFireWebViewHelper _webViewHelper;

  @override
  String get sourceId => 'mangafire';

  @override
  ContentSource create(Map<String, dynamic> config) {
    final baseUrl = (config['baseUrl'] as String?)?.trim().isNotEmpty == true
        ? config['baseUrl'] as String
        : 'https://mangafire.to';
    final headers =
        ((config['network'] as Map<String, dynamic>?)?['headers'] as Map?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{};

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: <String, dynamic>{
          ..._dio.options.headers,
          ...headers,
          if (!headers.containsKey('Referer')) 'Referer': '$baseUrl/',
        },
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
        responseType: ResponseType.plain,
      ),
    );
    dio.httpClientAdapter = _dio.httpClientAdapter;
    dio.interceptors.addAll(_dio.interceptors);

    final adapter = MangaFireAdapter(
      dio: dio,
      logger: _logger,
      vrfCache: _vrfCache,
      webViewHelper: _webViewHelper,
      baseUrl: baseUrl,
    );

    return GenericHttpSource(
      rawConfig: config,
      dio: dio,
      logger: _logger,
      adapterOverride: adapter,
    );
  }
}
