import 'package:kuron_generic/kuron_generic.dart';

import '../config/remote_config_service.dart';

class SourceUrlResolver {
  SourceUrlResolver._();

  static String resolveBaseUrl({
    required RemoteConfigService remoteConfigService,
    required String sourceId,
  }) {
    final rawConfig = remoteConfigService.getRawConfig(sourceId);
    if (rawConfig == null || rawConfig.isEmpty) {
      return '';
    }

    return _resolveBaseUrl(rawConfig);
  }

  static String buildContentUrl({
    required RemoteConfigService remoteConfigService,
    required String sourceId,
    required String contentId,
    bool preferChapterPattern = false,
  }) {
    final rawConfig = remoteConfigService.getRawConfig(sourceId);
    if (rawConfig == null || rawConfig.isEmpty) {
      return '';
    }

    final baseUrl = _resolveBaseUrl(rawConfig);
    if (baseUrl.isEmpty) {
      return '';
    }

    final urlBuilder = GenericUrlBuilder(baseUrl: baseUrl);
    final urlPatterns = ((rawConfig['scraper'] as Map?)?['urlPatterns'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final apiEndpoints = ((rawConfig['api'] as Map?)?['endpoints'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    if (preferChapterPattern) {
      final chapterTemplate = _patternUrl(urlPatterns['chapter']);
      if (chapterTemplate != null && chapterTemplate.isNotEmpty) {
        return urlBuilder.buildPagesUrl(chapterTemplate, contentId);
      }
    }

    final detailTemplate = _patternUrl(urlPatterns['detail']) ??
        _patternUrl(apiEndpoints['contentUrl']) ??
        _patternUrl(apiEndpoints['detail']);
    if (detailTemplate != null && detailTemplate.isNotEmpty) {
      return urlBuilder.buildDetailUrl(detailTemplate, contentId);
    }

    return '';
  }

  static String _resolveBaseUrl(Map<String, dynamic> rawConfig) {
    final api = (rawConfig['api'] as Map?)?.cast<String, dynamic>();
    final candidates = <dynamic>[
      api?['url'],
      api?['apiBase'],
      api?['baseUrl'],
      rawConfig['baseUrl'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  static String? _patternUrl(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is Map) {
      final path = value['path'];
      if (path is String && path.isNotEmpty) {
        return path;
      }
      final url = value['url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }
}
