library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_generic/src/generic_http_source.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

const _baseUrl = 'https://manhwaread.com';
const _detailUrl = '$_baseUrl/manhwa/random-picked/';

const _detailHtml = '''
<html>
  <head>
    <link rel="canonical" href="/manhwa/random-picked/">
    <meta property="og:url" content="/manhwa/random-picked/">
  </head>
  <body>
    <h1 class="clipboard-copy">Random Picked</h1>
  </body>
</html>
''';

Map<String, dynamic> _buildConfig({
  String baseUrl = _baseUrl,
  String randomUrl = '/manhwa/random-picked/',
  bool includeContentIdPattern = true,
}) {
  return {
    'source': 'manhwaread',
    'baseUrl': baseUrl,
    if (includeContentIdPattern) 'contentIdPattern': '/manhwa/([^/]+)',
    'network': {
      'headers': {
        'Referer': '$baseUrl/',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    },
    'scraper': {
      'enabled': true,
      'randomUrl': randomUrl,
      'urlPatterns': {
        'detail': '/manhwa/{id}/',
      },
      'selectors': {
        'detail': {
          'fields': {
            'title': {
              'selector': 'h1.clipboard-copy',
            },
          },
        },
      },
    },
  };
}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late GenericHttpSource source;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    source = GenericHttpSource(
      rawConfig: _buildConfig(),
      dio: dio,
      logger: Logger(level: Level.off),
    );
  });

  test('falls back to scraper randomUrl and extracts the slug from detail url',
      () async {
    dioAdapter.onGet(
      _detailUrl,
      (server) => server.reply(
        200,
        _detailHtml,
        headers: {
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        },
      ),
    );

    final results = await source.getRandom();

    expect(results, hasLength(1));
    expect(results.single.id, 'random-picked');
    expect(results.single.title, 'Random Picked');
  });

  test(
      'extracts random slug from canonical html when redirect metadata is absent',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });

    final baseUrl = 'http://${server.address.host}:${server.port}';
    final liveDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    final liveSource = GenericHttpSource(
      rawConfig: _buildConfig(
        baseUrl: baseUrl,
        randomUrl: '/?random_manga=1',
        includeContentIdPattern: false,
      ),
      dio: liveDio,
      logger: Logger(level: Level.off),
    );

    server.listen((request) async {
      if (request.uri.queryParameters['random_manga'] == '1') {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(_detailHtml);
        await request.response.close();
        return;
      }

      if (request.uri.path == '/manhwa/random-picked/') {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(_detailHtml);
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });

    final results = await liveSource.getRandom();

    expect(results, hasLength(1));
    expect(results.single.id, 'random-picked');
    expect(results.single.title, 'Random Picked');
  });

  test(
      'extracts random slug from redirect target when contentIdPattern is missing',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });

    final baseUrl = 'http://${server.address.host}:${server.port}';
    final redirectDetailUrl = '$baseUrl/manhwa/random-picked/';

    server.listen((request) async {
      if (request.uri.queryParameters['random_manga'] == '1') {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set('location', '/manhwa/random-picked/');
        await request.response.close();
        return;
      }

      if (request.uri.path == '/manhwa/random-picked/') {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.html;
        request.response.write(_detailHtml);
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });

    final liveDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    final liveSource = GenericHttpSource(
      rawConfig: _buildConfig(
        baseUrl: baseUrl,
        randomUrl: '/?random_manga=1',
        includeContentIdPattern: false,
      ),
      dio: liveDio,
      logger: Logger(level: Level.off),
    );

    final results = await liveSource.getRandom();

    expect(results, hasLength(1));
    expect(results.single.id, 'random-picked');
    expect(results.single.title, 'Random Picked');
    expect(
      liveSource.parseContentIdFromUrl(redirectDetailUrl),
      'random-picked',
    );
  });
}
