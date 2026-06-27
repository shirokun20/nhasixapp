import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_special/kuron_special.dart';

void main() {
  group('WebViewSessionConfig.fromJson', () {
    test('uses siteProtection autoCloseOnCookie when provided', () {
      final config = WebViewSessionConfig.fromJson({
        'network': {
          'requiresBypass': true,
          'siteProtection': {
            'autoCloseOnCookie': 'sucuri_cloudproxy_',
          },
        },
      });

      expect(config.bypassEnabled, isTrue);
      expect(config.autoCloseOnCookie, 'sucuri_cloudproxy_');
    });
  });

  group('WebViewSessionAdapter.shouldTriggerBypass', () {
    late WebViewSessionAdapter adapter;

    setUp(() {
      adapter = WebViewSessionAdapter(
        dio: Dio(),
        cookieJar: PersistCookieJar(),
        config: const WebViewSessionConfig(bypassEnabled: true),
        baseUrl: 'https://komiktap.info',
      );
    });

    test('returns true for sucuri redirect without location', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: 'https://komiktap.info'),
        statusCode: 307,
        data: '',
        headers: Headers.fromMap({
          'server': ['Sucuri/Cloudproxy'],
          'x-sucuri-id': ['18002'],
        }),
      );

      expect(adapter.shouldTriggerBypass(response), isTrue);
    });

    test('returns false for normal redirect with location', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: 'https://example.com'),
        statusCode: 307,
        data: '',
        headers: Headers.fromMap({
          'location': ['https://example.com/home'],
          'server': ['nginx'],
        }),
      );

      expect(adapter.shouldTriggerBypass(response), isFalse);
    });
  });
}
