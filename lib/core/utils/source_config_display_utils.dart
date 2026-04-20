import '../config/remote_config_service.dart';

class SourceConfigDisplayInfo {
  const SourceConfigDisplayInfo({
    required this.sourceId,
    this.version,
    this.description,
  });

  final String sourceId;
  final String? version;
  final String? description;

  String get idWithVersion =>
      version == null || version!.isEmpty ? sourceId : '$sourceId • v$version';
}

SourceConfigDisplayInfo resolveSourceConfigDisplayInfo({
  required RemoteConfigService remoteConfigService,
  required String sourceId,
}) {
  final typedConfig = remoteConfigService.getConfig(sourceId);
  final rawConfig = remoteConfigService.getRawConfig(sourceId);
  final meta = (rawConfig?['meta'] as Map?)?.cast<String, dynamic>();
  final ui = (rawConfig?['ui'] as Map?)?.cast<String, dynamic>();

  return SourceConfigDisplayInfo(
    sourceId: sourceId,
    version: _normalizeDisplayValue(
          typedConfig?.version,
        ) ??
        _normalizeDisplayValue(rawConfig?['version'] as String?),
    description: _normalizeDisplayValue(
          meta?['description'] as String?,
        ) ??
        _normalizeDisplayValue(ui?['description'] as String?),
  );
}

String? _normalizeDisplayValue(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
