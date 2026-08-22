import 'dart:convert';
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/adapters/generic_scraper_adapter.dart';
import 'package:kuron_generic/src/parsers/generic_html_parser.dart';
import 'package:kuron_generic/src/url_builder/generic_url_builder.dart';
import 'package:logger/logger.dart';

Future<void> main(List<String> args) async {
  final source = args[0];
  final page = args.length > 1 ? int.parse(args[1]) : 1;
  final cfg = (jsonDecode(File('../../informations/configs/$source-config.json').readAsStringSync()) as Map).cast<String, Object?>();
  final dio = Dio(BaseOptions(baseUrl: cfg['baseUrl'] as String, headers: ((cfg['network'] as Map?)?['headers'] as Map?)?.cast<String, dynamic>(), validateStatus: (s) => s != null && s < 500));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) { print('REQ: ${o.uri}'); h.next(o); }));
  final adapter = GenericScraperAdapter(dio: dio, urlBuilder: GenericUrlBuilder(baseUrl: cfg['baseUrl'] as String), parser: GenericHtmlParser(logger: Logger(level: Level.off)), logger: Logger(level: Level.off), sourceId: source);
  final r = await adapter.search(SearchFilter(query: '', page: page), cfg);
  print('p$page items=${r.items.length} hasNext=${r.hasNextPage} first=${r.items.isEmpty ? '-' : r.items.first.id}');
  if (r.items.isNotEmpty) {
    final c = r.items.first.coverUrl;
    print('first cover: ${c.isEmpty ? "EMPTY" : c.substring(0, c.length > 80 ? 80 : c.length)}');
  }
}
