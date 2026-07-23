import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_cache.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_config.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_interceptor.dart';
import 'package:kuron_special/src/mangafire/mangafire_vrf_capture_service.dart';
import 'package:logger/logger.dart';

void main() {
  group('MangaFireVRFInterceptor', () {
    late MangaFireVRFConfig config;
    late MangaFireVRFCache cache;
    late MockCaptureService captureService;
    late MangaFireVRFInterceptor interceptor;
    late Dio dio;
    late DioAdapter adapter;

    setUp(() {
      config = MangaFireVRFConfig(
        enabled: true,
        vrfParam: 'vrf',
        interceptEndpoints: ['/api/titles', '/api/chapters'],
        vrfFreeEndpoints: ['/api/filter-options', '/api/top-titles'],
        ttlSeconds: 300,
      );
      cache = MangaFireVRFCache(maxEntries: 10, ttlSeconds: 300);
      captureService = MockCaptureService();
      dio = Dio(BaseOptions(baseUrl: 'https://mangafire.to'));
      interceptor = MangaFireVRFInterceptor(
        config: config,
        cache: cache,
        captureService: captureService,
        logger: Logger(printer: SimplePrinter(colors: false, printTime: false)),
      );
      dio.interceptors.add(interceptor);
      adapter = DioAdapter(dio: dio);
    });

    test('uses cached URL directly', () async {
      cache.set(
        '/api/titles',
        'https://mangafire.to/api/titles?page=1&hot=1&vrf=cached_vrf',
      );

      adapter.onGet(
        'https://mangafire.to/api/titles?page=1&hot=1&vrf=cached_vrf',
        (server) => server.reply(200, {'items': []}),
      );

      await dio.get('/api/titles', queryParameters: {'page': '1'});
      expect(captureService.captureCallCount, equals(0));
    });

    test('triggers capture on cache miss, then uses result', () async {
      captureService.onCapture = (path, params) {
        captureService.captureCallCount++;
        cache.set(
          path,
          'https://mangafire.to/api/titles?page=1&vrf=captured_vrf',
        );
      };

      adapter.onGet(
        'https://mangafire.to/api/titles?page=1&vrf=captured_vrf',
        (server) => server.reply(200, {'items': []}),
      );

      await dio.get('/api/titles', queryParameters: {'page': '1'});
      expect(captureService.captureCallCount, equals(1));
    });

    test('passes through for filter-options', () async {
      adapter.onGet(
        '/api/filter-options',
        (server) => server.reply(200, {'data': {}}),
      );

      final resp = await dio.get('/api/filter-options');
      expect(resp.requestOptions.uri.queryParameters, isNot(contains('vrf')));
      expect(captureService.captureCallCount, equals(0));
    });
  });
}

class MockCaptureService implements MangaFireVRFCaptureService {
  int captureCallCount = 0;
  void Function(String path, Map<String, dynamic>? params)? onCapture;

  @override
  Future<void> captureForPath(String path,
      {Map<String, dynamic>? requestParams}) async {
    onCapture?.call(path, requestParams);
  }

  @override
  Future<void> warmup() async {}
}
