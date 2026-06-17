import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart';

void main() {
  test('loadTagsFromUrl parses remote tag payload directly', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async => server.close(force: true));

    server.listen((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<List<dynamic>>[
          <dynamic>[1, 'Genre One', 'genre-one', 8, 42],
          <dynamic>[2, 'Genre Two', 'genre-two', 8, 7],
        ]))
        ..close();
    });

    final dio = Dio();
    final manager = TagDataManager(dio: dio, logger: Logger());
    final tags = await manager.loadTagsFromUrl(
      'http://127.0.0.1:${server.port}/tags.json',
    );

    expect(tags, hasLength(2));
    expect(tags.first.name, 'Genre One');
    expect(tags.first.slug, 'genre-one');
    expect(tags.first.type, 'genre');
    expect(tags.first.count, 42);
  });
}
