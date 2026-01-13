import 'package:json_annotation/json_annotation.dart';

part 'config_models.g.dart';

@JsonSerializable(explicitToJson: true)
class RemoteConfig {
  final SourceConfig? nhentai;
  final SourceConfig? crotpedia;

  RemoteConfig({this.nhentai, this.crotpedia});

  factory RemoteConfig.fromJson(Map<String, dynamic> json) =>
      _$RemoteConfigFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SourceConfig {
  final String source;
  final String version;
  final String? lastUpdated;
  final String? baseUrl;
  final ApiConfig? api;
  final ScraperConfig? scraper;
  final NetworkConfig? network;
  final FeatureConfig? features;
  final UiConfig? ui;
  final AuthConfig? auth;
  final Map<String, String>? typeMapping; // Map type code to display name

  SourceConfig({
    required this.source,
    required this.version,
    this.lastUpdated,
    this.baseUrl,
    this.api,
    this.scraper,
    this.network,
    this.features,
    this.ui,
    this.auth,
    this.typeMapping,
  });

  factory SourceConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SourceConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ApiConfig {
  final bool enabled;
  final String? baseUrl;
  final String? apiBase;
  final int? timeout;
  final Map<String, String>? endpoints;
  final Map<String, String>? images;
  final Map<String, String>? extensionMapping;
  final List<String>? mirrors;
  final bool? useMirrors;

  ApiConfig({
    required this.enabled,
    this.baseUrl,
    this.apiBase,
    this.timeout,
    this.endpoints,
    this.images,
    this.extensionMapping,
    this.mirrors,
    this.useMirrors,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ApiConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ScraperConfig {
  final bool enabled;
  // Selectors are nested generic maps because they vary wildly by source
  final Map<String, dynamic>? selectors;
  final Map<String, String>? urlPatterns;

  ScraperConfig({
    required this.enabled,
    this.selectors,
    this.urlPatterns,
  });

  factory ScraperConfig.fromJson(Map<String, dynamic> json) =>
      _$ScraperConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ScraperConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NetworkConfig {
  final RateLimitConfig? rateLimit;
  final RetryConfig? retry;
  final CloudflareConfig? cloudflare;
  final int? timeout; // For simple network configs

  NetworkConfig({
    this.rateLimit,
    this.retry,
    this.cloudflare,
    this.timeout,
  });

  factory NetworkConfig.fromJson(Map<String, dynamic> json) =>
      _$NetworkConfigFromJson(json);
  Map<String, dynamic> toJson() => _$NetworkConfigToJson(this);
}

@JsonSerializable()
class RateLimitConfig {
  final bool enabled;
  final int requestsPerMinute;
  final int minDelayMs;
  final int? cooldownDurationMs;

  RateLimitConfig({
    this.enabled = true,
    required this.requestsPerMinute,
    required this.minDelayMs,
    this.cooldownDurationMs,
  });

  factory RateLimitConfig.fromJson(Map<String, dynamic> json) =>
      _$RateLimitConfigFromJson(json);
  Map<String, dynamic> toJson() => _$RateLimitConfigToJson(this);
}

@JsonSerializable()
class RetryConfig {
  final int maxAttempts;
  final int? delayMs;
  final bool exponentialBackoff;

  RetryConfig({
    required this.maxAttempts,
    this.delayMs,
    this.exponentialBackoff = true,
  });

  factory RetryConfig.fromJson(Map<String, dynamic> json) =>
      _$RetryConfigFromJson(json);
  Map<String, dynamic> toJson() => _$RetryConfigToJson(this);
}

@JsonSerializable()
class CloudflareConfig {
  final bool bypassEnabled;
  final bool antiDetection;

  CloudflareConfig({
    required this.bypassEnabled,
    required this.antiDetection,
  });

  factory CloudflareConfig.fromJson(Map<String, dynamic> json) =>
      _$CloudflareConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CloudflareConfigToJson(this);
}

@JsonSerializable()
class FeatureConfig {
  final bool search;
  final bool random;
  final bool related;
  final bool download;
  final bool favorite;
  final bool chapters;
  final bool bookmark;
  final bool supportsTagExclusion;
  final bool supportsAdvancedSearch;

  FeatureConfig({
    this.search = false,
    this.random = false,
    this.related = false,
    this.download = false,
    this.favorite = false,
    this.chapters = false,
    this.bookmark = false,
    this.supportsTagExclusion = false,
    this.supportsAdvancedSearch = false,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) =>
      _$FeatureConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FeatureConfigToJson(this);
}

@JsonSerializable()
class UiConfig {
  final String displayName;
  final String iconPath;
  final String themeColor;
  final String cardStyle;

  UiConfig({
    required this.displayName,
    required this.iconPath,
    required this.themeColor,
    required this.cardStyle,
  });

  factory UiConfig.fromJson(Map<String, dynamic> json) =>
      _$UiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$UiConfigToJson(this);
}

@JsonSerializable()
class AuthConfig {
  final bool enabled;
  final String? loginEndpoint;
  final String? registerEndpoint;
  final List<String>? sessionCookies;
  final int? sessionDurationSeconds;

  AuthConfig({
    required this.enabled,
    this.loginEndpoint,
    this.registerEndpoint,
    this.sessionCookies,
    this.sessionDurationSeconds,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AuthConfigToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TagsManifest {
  final String version;
  final String? lastUpdated;
  final Map<String, TagSourceConfig> sources;

  TagsManifest({
    required this.version,
    this.lastUpdated,
    required this.sources,
  });

  factory TagsManifest.fromJson(Map<String, dynamic> json) =>
      _$TagsManifestFromJson(json);
  Map<String, dynamic> toJson() => _$TagsManifestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TagSourceConfig {
  final String type;
  final String? assetPath;
  final String? format;
  final List<String>? structure;
  final TagMigrationConfig? migration;

  TagSourceConfig({
    required this.type,
    this.assetPath,
    this.format,
    this.structure,
    this.migration,
  });

  factory TagSourceConfig.fromJson(Map<String, dynamic> json) =>
      _$TagSourceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TagSourceConfigToJson(this);
}

@JsonSerializable()
class TagMigrationConfig {
  final bool enabled;
  final String? remoteUrl;
  final String? fallbackUrl;
  final int? cacheTtlSeconds;

  TagMigrationConfig({
    required this.enabled,
    this.remoteUrl,
    this.fallbackUrl,
    this.cacheTtlSeconds,
  });

  factory TagMigrationConfig.fromJson(Map<String, dynamic> json) =>
      _$TagMigrationConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TagMigrationConfigToJson(this);
}

@JsonSerializable()
class ConfigVersion {
  final String version;
  final String? minAppVersion;
  final Map<String, ConfigManifest> configs;

  ConfigVersion({
    required this.version,
    this.minAppVersion,
    required this.configs,
  });

  factory ConfigVersion.fromJson(Map<String, dynamic> json) =>
      _$ConfigVersionFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigVersionToJson(this);
}

@JsonSerializable()
class ConfigManifest {
  final String version;
  final String file;

  ConfigManifest({
    required this.version,
    required this.file,
  });

  factory ConfigManifest.fromJson(Map<String, dynamic> json) =>
      _$ConfigManifestFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigManifestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AppConfig {
  final AppLimits? limits;
  final AppDurations? durations;
  final AppUiConfig? ui;
  final AppStorage? storage;
  final AppReader? reader;
  final AppPrivacy? privacy;

  AppConfig({
    this.limits,
    this.durations,
    this.ui,
    this.storage,
    this.reader,
    this.privacy,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}

// Sub-models for AppConfig (Simplified for now, can be expanded)
@JsonSerializable()
class AppLimits {
  final int defaultPageSize;
  final int maxConcurrentDownloads;

  AppLimits({this.defaultPageSize = 20, this.maxConcurrentDownloads = 3});

  factory AppLimits.fromJson(Map<String, dynamic> json) =>
      _$AppLimitsFromJson(json);
  Map<String, dynamic> toJson() => _$AppLimitsToJson(this);
}

@JsonSerializable()
class AppDurations {
  final int splashDelayMs;
  final int snackbarDurationMs;

  AppDurations({this.splashDelayMs = 2000, this.snackbarDurationMs = 3000});

  factory AppDurations.fromJson(Map<String, dynamic> json) =>
      _$AppDurationsFromJson(json);
  Map<String, dynamic> toJson() => _$AppDurationsToJson(this);
}

@JsonSerializable()
class AppUiConfig {
  final int gridColumnsPortrait;
  final double cardAspectRatio;

  AppUiConfig({this.gridColumnsPortrait = 2, this.cardAspectRatio = 0.7});

  factory AppUiConfig.fromJson(Map<String, dynamic> json) =>
      _$AppUiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppUiConfigToJson(this);
}

@JsonSerializable()
class AppStorage {
  final String backupFolderName;

  AppStorage({this.backupFolderName = 'nhasix_backup'});

  factory AppStorage.fromJson(Map<String, dynamic> json) =>
      _$AppStorageFromJson(json);
  Map<String, dynamic> toJson() => _$AppStorageToJson(this);
}

@JsonSerializable()
class AppReader {
  final bool preloadNextChapter;

  AppReader({this.preloadNextChapter = true});

  factory AppReader.fromJson(Map<String, dynamic> json) =>
      _$AppReaderFromJson(json);
  Map<String, dynamic> toJson() => _$AppReaderToJson(this);
}

@JsonSerializable()
class AppPrivacy {
  final bool enableAnalytics;

  AppPrivacy({this.enableAnalytics = true});

  factory AppPrivacy.fromJson(Map<String, dynamic> json) =>
      _$AppPrivacyFromJson(json);
  Map<String, dynamic> toJson() => _$AppPrivacyToJson(this);
}
