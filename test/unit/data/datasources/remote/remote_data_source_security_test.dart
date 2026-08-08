import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/data/datasources/remote/anti_detection.dart';
import 'package:nhasixapp/data/datasources/remote/cloudflare_bypass_no_webview.dart';
import 'package:nhasixapp/data/datasources/remote/exceptions.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/request_rate_manager.dart';

/// Security tests for the task-3 hardening in RemoteDataSource:
/// - fetchHtml absolute-URL host allowlist (D1, task 3.1)
/// - redirect allowlist in _getPageHtml (D2, task 3.3)
void main() {
  late HttpServer server;
  late RemoteConfigService config;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    baseUrl = 'http://127.0.0.1:${server.port}';
    server.listen((request) {
      if (request.uri.path == '/redirect-foreign') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set('location', 'http://127.0.0.1:9/evil')
          ..close();
        return;
      }
      if (request.uri.path == '/redirect-self') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set('location', '$baseUrl/final')
          ..close();
        return;
      }
      if (request.uri.path == '/final') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<div class="gallery">ok</div>')
          ..close();
        return;
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('<div class="gallery">home</div>')
        ..close();
    });

    config = RemoteConfigService(dio: Dio(), logger: Logger());
    config.registerSourceConfig('nhentai', {
      'source': 'nhentai',
      'version': '1.0.0',
      'baseUrl': baseUrl,
      'network': {
        'rateLimit': {
          'enabled': false,
          'requestsPerMinute': 1000,
          'minDelayMs': 0,
        },
      },
    });
  });

  RemoteDataSource buildDataSource() {
    return RemoteDataSource(
      httpClient: Dio(),
      scraper: NhentaiScraper(remoteConfigService: config),
      cloudflareBypass: CloudflareBypassNoWebView(httpClient: Dio()),
      antiDetection: AntiDetection(),
      rateManager: RequestRateManager(remoteConfigService: config),
      remoteConfigService: config,
    );
  }

  group('fetchHtml absolute-URL host allowlist (D1)', () {
    test('relative path fetches fine', () async {
      final html = await buildDataSource().fetchHtml('/index.html');
      expect(html, contains('home'));
    });

    test('foreign absolute URL rejected before any request', () async {
      await expectLater(
        buildDataSource().fetchHtml('http://evil.com/page'),
        throwsA(isA<StateError>()),
      );
    });

    test('protocol-relative URL rejected (SSRF via //host)', () async {
      await expectLater(
        buildDataSource().fetchHtml('//evil.com/page'),
        throwsA(isA<StateError>()),
      );
    });

    test('plain path with scheme-less relative is accepted', () async {
      // `page` is neither absolute nor starts with '/', so it is rejected as
      // an invalid path rather than silently fetched relative.
      await expectLater(
        buildDataSource().fetchHtml('page'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('_getPageHtml redirect allowlist (D2)', () {
    test('foreign-host redirect is rejected (NetworkException)', () async {
      await expectLater(
        buildDataSource().fetchHtml('/redirect-foreign'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('same-host redirect is followed', () async {
      final html = await buildDataSource().fetchHtml('/redirect-self');
      expect(html, contains('ok'));
    });
  });
}
