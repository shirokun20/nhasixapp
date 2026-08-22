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
  final cfg = (jsonDecode(File('../../informations/configs/$source-config.json').readAsStringSync()) as Map).cast<String, Object?>();
  final dio = Dio(BaseOptions(baseUrl: cfg['baseUrl'] as String, headers: ((cfg['network'] as Map?)?['headers'] as Map?)?.cast<String, dynamic>(), validateStatus: (s) => s != null && s < 500));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) { print('REQ: ${o.uri}'); h.next(o); }));
  final adapter = GenericScraperAdapter(dio: dio, urlBuilder: GenericUrlBuilder(baseUrl: cfg['baseUrl'] as String), parser: GenericHtmlParser(logger: Logger(level: Level.off)), logger: Logger(level: Level.off), sourceId: source);
  final r = await adapter.search(const SearchFilter(query: '', page: 1, includeTags: [FilterItem(id: 0, name: 'action', type: 'tag')]), cfg);
  print('tag=action items=${r.items.length} first=${r.items.isEmpty ? "-" : r.items.first.id}');
}
