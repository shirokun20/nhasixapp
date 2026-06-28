import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:kuron_special/kuron_special.dart';

class _FakeKuronNative extends KuronNative {
  Map<String, dynamic>? result;
  String? lastAutoCloseOnCookie;
  List<String>? lastCaptureRequestPatterns;
  List<String>? lastAllowRequestPatterns;
  bool? lastClearCookies;

  @override
  Future<Map<String, dynamic>?> showLoginWebView({
    required String url,
    List<String>? successUrlFilters,
    String? initialCookie,
    String? userAgent,
    String? autoCloseOnCookie,
    String? ssoRedirectUrl,
    List<String>? domImageSelectors,
    List<String>? domImageAttributes,
    List<String>? domLinkSelectors,
    List<String>? captureRequestPatterns,
    List<String>? allowRequestPatterns,
    String? pageFinishedScript,
    bool blockNetworkImages = false,
    bool enableAdBlock = false,
    bool clearCookies = false,
  }) async {
    lastAutoCloseOnCookie = autoCloseOnCookie;
    lastCaptureRequestPatterns = captureRequestPatterns;
    lastAllowRequestPatterns = allowRequestPatterns;
    lastClearCookies = clearCookies;
    return result;
  }
}

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

  group('WebViewSessionAdapter bypass options', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('kuron_special_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<File> writeCapturedHtml(String html) async {
      final file = File('${tempDir.path}/captured.html');
      await file.writeAsString(jsonEncode(html));
      return file;
    }

    Dio buildChallengeDio({
      required int Function() callCount,
      String verifyBody = 'verified',
    }) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (callCount() == 1) {
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 403,
                  data: 'challenge',
                  headers: Headers.fromMap({
                    'cf-mitigated': ['challenge'],
                  }),
                ),
              );
              return;
            }

            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: verifyBody,
              ),
            );
          },
        ),
      );
      return dio;
    }

    test('generic adapter ignores captured html and re-verifies with Dio',
        () async {
      var calls = 0;
      final native = _FakeKuronNative();
      final htmlFile = await writeCapturedHtml('<html>captured</html>');
      native.result = {
        'success': true,
        'pageHtml': htmlFile.path,
        'cookies': <String>[],
        'userAgent': 'ua',
      };

      final dio = buildChallengeDio(callCount: () => ++calls);
      final adapter = WebViewSessionAdapter(
        dio: dio,
        cookieJar: PersistCookieJar(),
        config: const WebViewSessionConfig(
          bypassEnabled: true,
          autoCloseOnCookie: 'cf_clearance',
        ),
        baseUrl: 'https://example.com',
        native: native,
      );

      final response =
          await adapter.requestWithBypass<String>('https://example.com/list');

      expect(response.data, 'verified');
      expect(calls, 2);
      expect(native.lastAutoCloseOnCookie, 'cf_clearance');
      expect(native.lastCaptureRequestPatterns, isNull);
      expect(native.lastAllowRequestPatterns, isNull);
      expect(native.lastClearCookies, isTrue);
    });

    test('hentairead adapter uses captured html for non-reader pages',
        () async {
      var calls = 0;
      final native = _FakeKuronNative();
      final htmlFile = await writeCapturedHtml('<html>captured</html>');
      native.result = {
        'success': true,
        'pageHtml': htmlFile.path,
        'cookies': <String>[],
        'userAgent': 'ua',
      };

      final dio = buildChallengeDio(callCount: () => ++calls);
      final adapter = WebViewSessionAdapter(
        dio: dio,
        cookieJar: PersistCookieJar(),
        config: const WebViewSessionConfig(bypassEnabled: true),
        baseUrl: 'https://hentairead.com',
        native: native,
        bypassOptionsBuilder: HentaiReadSourceFactory.buildBypassOptions,
      );

      final response = await adapter
          .requestWithBypass<String>('https://hentairead.com/hentai/');

      expect(response.data, '<html>captured</html>');
      expect(calls, 1);
      expect(native.lastCaptureRequestPatterns, isNull);
      expect(native.lastAllowRequestPatterns, isNull);
    });

    test('hentairead reader bypass uses captured html and keeps auto-close',
        () async {
      var calls = 0;
      final native = _FakeKuronNative();
      final htmlFile = await writeCapturedHtml('<html>reader</html>');
      native.result = {
        'success': true,
        'pageHtml': htmlFile.path,
        'cookies': <String>[],
        'userAgent': 'ua',
      };

      final dio = buildChallengeDio(callCount: () => ++calls);
      final adapter = WebViewSessionAdapter(
        dio: dio,
        cookieJar: PersistCookieJar(),
        config: const WebViewSessionConfig(
          bypassEnabled: true,
          autoCloseOnCookie: 'cf_clearance',
        ),
        baseUrl: 'https://hentairead.com',
        native: native,
        bypassOptionsBuilder: HentaiReadSourceFactory.buildBypassOptions,
      );

      final response = await adapter.requestWithBypass<String>(
        'https://hentairead.com/hentai/sample/english/p/1/',
      );

      expect(response.data, '<html>reader</html>');
      expect(calls, 0);
      expect(native.lastAutoCloseOnCookie, 'cf_clearance');
      expect(native.lastCaptureRequestPatterns, const ['henread.xyz/']);
      expect(native.lastAllowRequestPatterns, contains('hentairead.com'));
    });

    test('hentairead reader bypass prefers captured image urls when present',
        () async {
      var calls = 0;
      final native = _FakeKuronNative();
      native.result = {
        'success': true,
        'capturedImageUrls': <String>[
          'https://henread.xyz/294075/87911/hr_0001.jpg',
          'https://henread.xyz/294075/87911/hr_0002.jpg',
        ],
        'cookies': <String>[],
        'userAgent': 'ua',
      };

      final dio = buildChallengeDio(callCount: () => ++calls);
      final adapter = WebViewSessionAdapter(
        dio: dio,
        cookieJar: PersistCookieJar(),
        config: const WebViewSessionConfig(
          bypassEnabled: true,
          autoCloseOnCookie: 'cf_clearance',
        ),
        baseUrl: 'https://hentairead.com',
        native: native,
        bypassOptionsBuilder: HentaiReadSourceFactory.buildBypassOptions,
      );

      final response = await adapter.requestWithBypass<String>(
        'https://hentairead.com/hentai/sample/english/p/1/',
      );

      expect(
        response.data,
        '{"images":["https://henread.xyz/294075/87911/hr_0001.jpg","https://henread.xyz/294075/87911/hr_0002.jpg"]}',
      );
      expect(calls, 0);
    });
  });
}
