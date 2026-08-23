import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';

Future<void> main() async {
  final config = (jsonDecode(File(
          '../../informations/configs/sektedoujin-config.json')
      .readAsStringSync()) as Map)
      .cast<String, dynamic>();
  final baseUrl = config['baseUrl'] as String;
  final adapter = GenericScraperAdapter(
    dio: Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    )),
    urlBuilder: GenericUrlBuilder(baseUrl: baseUrl),
    parser: GenericHtmlParser(logger: Logger(level: Level.off)),
    logger: Logger(level: Level.info),
    sourceId: 'sektedoujin',
  );

  for (final page in [1, 2]) {
    final result = await adapter.search(
      SearchFilter(
        query: '',
        page: page,
        includeTags: [FilterItem(id: 0, name: 'ecchi', type: 'genre')],
      ),
      config,
    );
    print('genre ecchi p$page: ${result.items.length} items');
  }
}
