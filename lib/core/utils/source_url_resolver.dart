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
        apiEndpoints['contentUrl'] as String? ??
        apiEndpoints['detail'] as String?;
    if (detailTemplate != null && detailTemplate.isNotEmpty) {
      return urlBuilder.buildDetailUrl(detailTemplate, contentId);
    }

    return '';
  }

  static String _resolveBaseUrl(Map<String, dynamic> rawConfig) {
    return ((rawConfig['api'] as Map?)?['baseUrl'] as String?) ??
        (rawConfig['baseUrl'] as String?) ??
        '';
  }

  static String? _patternUrl(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is Map) {
      return value['url'] as String?;
    }
    return null;
  }
}
