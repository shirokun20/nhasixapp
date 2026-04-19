import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_special/kuron_special.dart';
import 'package:logger/logger.dart';

void main() {
  final liveSmokeEnabled =
      Platform.environment['ENABLE_PHASE6_LIVE_SMOKE'] == 'true';

  group('Phase 6 live smoke', () {
    test(
      'captures real outputs for search/detail/reading/non-chapter',
      () async {
        final output = <String, dynamic>{};

        output['ehentai'] = await _probeEHentai();
        output['hentainexus'] = await _probeHentaiNexus();
        output['hitomi'] = await _probeHitomi();

        stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));

        var availableCount = 0;
        for (final entry in output.entries) {
          final data = entry.value as Map<String, dynamic>;
          final available = (data['available'] as bool?) ?? true;
          if (!available) {
            continue;
          }

          availableCount++;
          expect(data['searchCount'] as int, greaterThan(0),
              reason: '${entry.key}: search is empty');
          expect(data['coverUrl'] as String, isNotEmpty,
              reason: '${entry.key}: cover missing');
          expect(data['readingImageCount'] as int, greaterThan(0),
              reason: '${entry.key}: reading image URLs missing');
          expect(data['isNonChapter'] as bool, isTrue,
              reason: '${entry.key}: expected non-chapter mode');
        }

        expect(availableCount, greaterThan(0),
            reason: 'No Phase 6 provider returned live data');
      },
      timeout: const Timeout(Duration(minutes: 8)),
      skip: liveSmokeEnabled
          ? false
          : 'Set ENABLE_PHASE6_LIVE_SMOKE=true to run live provider smoke tests.',
    );
  });
}

Future<Map<String, dynamic>> _probeEHentai() async {
  final raw = _loadConfig('ehentai-config.json');
  final dio = _buildDio(raw);
  final jarPath = await Directory.systemTemp.createTemp('ehentai-cookies-');
  final cookieJar = PersistCookieJar(storage: FileStorage(jarPath.path));

  final source = EHentaiSourceFactory(
    dio: dio,
    cookieJar: cookieJar,
    logger: Logger(),
  ).create(raw);

  return _probeSource(source: source, query: 'english', label: 'ehentai');
}

Future<Map<String, dynamic>> _probeHentaiNexus() async {
  final raw = _loadConfig('hentainexus-config.json');
  final dio = _buildDio(raw);

  final source = HentaiNexusSourceFactory(
    dio: dio,
    logger: Logger(),
  ).create(raw);

  return _probeSource(
      source: source, query: 'female:anal', label: 'hentainexus');
}

Future<Map<String, dynamic>> _probeHitomi() async {
  final raw = _loadConfig('hitomi-config.json');
  final dio = _buildDio(raw);

  final source = HitomiSourceFactory(
    dio: dio,
    logger: Logger(),
  ).create(raw);

  return _probeSource(source: source, query: 'female:anal', label: 'hitomi');
}

Future<Map<String, dynamic>> _probeSource({
  required ContentSource source,
  required String query,
  required String label,
}) async {
  try {
    ContentListResult search;
    try {
      search = await source.search(SearchFilter(query: query, page: 1));
      if (search.contents.isEmpty) {
        search = await source.getList(page: 1);
      }
    } catch (_) {
      search = await source.getList(page: 1);
    }

    if (search.contents.isEmpty) {
      return <String, dynamic>{
        'sourceId': source.id,
        'available': false,
        'reason': '$label: no content from search/list',
        'searchCount': 0,
        'coverUrl': '',
        'readingImageCount': 0,
        'sampleImageUrl': '',
        'hasChapters': false,
        'isNonChapter': true,
      };
    }

    final item = search.contents.first;
    final detail = await source.getDetail(item.id);
    final chapterData = await source.getChapterImages(item.id);

    final hasChapters = (detail.chapters?.isNotEmpty ?? false);
    final hasCoreOutput =
        detail.coverUrl.isNotEmpty && detail.imageUrls.isNotEmpty;

    return <String, dynamic>{
      'sourceId': source.id,
      'available': hasCoreOutput,
      'reason': hasCoreOutput ? '' : '$label: incomplete cover/reading data',
      'searchCount': search.contents.length,
      'firstContentId': item.id,
      'firstTitle': item.title,
      'coverUrl': detail.coverUrl,
      'readingImageCount': detail.imageUrls.length,
      'sampleImageUrl':
          detail.imageUrls.isNotEmpty ? detail.imageUrls.first : '',
      'hasChapters': hasChapters,
      'isNonChapter': !hasChapters,
      'chapterDataReturned': chapterData != null,
    };
  } catch (e) {
    return <String, dynamic>{
      'sourceId': source.id,
      'available': false,
      'reason': '$e',
      'searchCount': 0,
      'coverUrl': '',
      'readingImageCount': 0,
      'sampleImageUrl': '',
      'hasChapters': false,
      'isNonChapter': true,
    };
  }
}

Map<String, dynamic> _loadConfig(String fileName) {
  final candidatePaths = <String>[
    'assets/configs/$fileName',
    'app/config/$fileName',
  ];

  final file = candidatePaths
      .map(File.new)
      .firstWhere((candidate) => candidate.existsSync());
  final raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

Dio _buildDio(Map<String, dynamic> rawConfig) {
  final network = (rawConfig['network'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
  final headers = (network['headers'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};

  final normalizedHeaders = <String, dynamic>{};
  headers.forEach((key, value) {
    normalizedHeaders[key] = value.toString();
  });

  return Dio(
    BaseOptions(
      headers: normalizedHeaders,
      followRedirects: true,
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}
