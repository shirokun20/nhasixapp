import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_models.freezed.dart';
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
  final SearchConfig? searchConfig;

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
    this.searchConfig,
  });

  factory SourceConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SourceConfigToJson(this);
}

// ... existing classes ...

enum SearchMode {
  @JsonValue('query-string')
  queryString,

  @JsonValue('form-based')
  formBased,
}

enum SortWidgetType {
  @JsonValue('dropdown')
  dropdown,

  @JsonValue('chips')
  chips,

  @JsonValue('readonly')
  readonly,
}

@freezed
sealed class SearchConfig with _$SearchConfig {
  const factory SearchConfig({
    required SearchMode searchMode,
    required String endpoint,
    SortingConfig? sortingConfig,
    String? queryParam,
    FilterSupportConfig? filterSupport,
    List<TextFieldConfig>? textFields,
    List<RadioGroupConfig>? radioGroups,
    List<CheckboxGroupConfig>? checkboxGroups,
    PaginationConfig? pagination,
  }) = _SearchConfig;

  factory SearchConfig.fromJson(Map<String, dynamic> json) =>
      _$SearchConfigFromJson(json);
}

@freezed
sealed class FilterSupportConfig with _$FilterSupportConfig {
  const factory FilterSupportConfig({
    required List<String> singleSelect,
    required List<String> multiSelect,
    required bool supportsExclude,
  }) = _FilterSupportConfig;

  factory FilterSupportConfig.fromJson(Map<String, dynamic> json) =>
      _$FilterSupportConfigFromJson(json);
}

@freezed
sealed class TextFieldConfig with _$TextFieldConfig {
  const factory TextFieldConfig({
    required String name,
    required String label,
    required String type,
    String? placeholder,
    int? maxLength,
    int? min,
    int? max,
  }) = _TextFieldConfig;

  factory TextFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$TextFieldConfigFromJson(json);
}

@freezed
sealed class RadioGroupConfig with _$RadioGroupConfig {
  const factory RadioGroupConfig({
    required String name,
    required String label,
    required List<RadioOptionConfig> options,
  }) = _RadioGroupConfig;

  factory RadioGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioGroupConfigFromJson(json);
}

@freezed
sealed class RadioOptionConfig with _$RadioOptionConfig {
  const factory RadioOptionConfig({
    required String value,
    required String label,
    @Default(false) bool isDefault,
  }) = _RadioOptionConfig;

  factory RadioOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioOptionConfigFromJson(json);
}

@freezed
sealed class CheckboxGroupConfig with _$CheckboxGroupConfig {
  const factory CheckboxGroupConfig({
    required String name,
    required String label,
    required String paramName,
    @Default('expandable') String displayMode,
    @Default(3) int columns,
    @Default(false) bool loadFromTags,
    String? tagType,
  }) = _CheckboxGroupConfig;

  factory CheckboxGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$CheckboxGroupConfigFromJson(json);
}

@freezed
sealed class SortingConfig with _$SortingConfig {
  const factory SortingConfig({
    required bool allowDynamicReSort,
    required String defaultSort,
    required SortWidgetType widgetType,
    required List<SortOptionConfig> options,
    required SortingMessages messages,
  }) = _SortingConfig;

  factory SortingConfig.fromJson(Map<String, dynamic> json) =>
      _$SortingConfigFromJson(json);
}

@freezed
sealed class SortOptionConfig with _$SortOptionConfig {
  const factory SortOptionConfig({
    required String value,
    required String apiValue,
    required String label,
    required String displayLabel,
    String? icon,
    @Default(false) bool isDefault,
  }) = _SortOptionConfig;

  factory SortOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SortOptionConfigFromJson(json);
}

@freezed
sealed class SortingMessages with _$SortingMessages {
  const factory SortingMessages({
    String? dropdownLabel,
    String? noOptionsAvailable,
    String? readOnlyPrefix,
    String? readOnlySuffix,
    String? tapToModifyHint,
    String? returnToSearchButton,
  }) = _SortingMessages;

  factory SortingMessages.fromJson(Map<String, dynamic> json) =>
      _$SortingMessagesFromJson(json);
}

@freezed
sealed class PaginationConfig with _$PaginationConfig {
  const factory PaginationConfig({
    required String urlPattern,
    @Default('page') String paramName,
  }) = _PaginationConfig;

  factory PaginationConfig.fromJson(Map<String, dynamic> json) =>
      _$PaginationConfigFromJson(json);
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
class FeatureFlag {
  final bool enabled;
  final bool requiresPremium;

  FeatureFlag({
    this.enabled = false,
    this.requiresPremium = false,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) =>
      _$FeatureFlagFromJson(json);
  Map<String, dynamic> toJson() => _$FeatureFlagToJson(this);
}

@JsonSerializable()
class FeatureConfig {
  final FeatureFlag? search;
  final FeatureFlag? random;
  final FeatureFlag? related;
  final FeatureFlag? download;
  final FeatureFlag? favorite;
  final FeatureFlag? chapters;
  final FeatureFlag? bookmark;
  final FeatureFlag? supportsTagExclusion;
  final FeatureFlag? supportsAdvancedSearch;
  final FeatureFlag? generatePdf;

  FeatureConfig({
    this.search,
    this.random,
    this.related,
    this.download,
    this.favorite,
    this.chapters,
    this.bookmark,
    this.supportsTagExclusion,
    this.supportsAdvancedSearch,
    this.generatePdf,
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
  final Map<String, bool>? multiSelectSupport;
  final Map<String, String>? mappings;

  TagSourceConfig({
    required this.type,
    this.assetPath,
    this.format,
    this.structure,
    this.migration,
    this.multiSelectSupport,
    this.mappings,
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
  @JsonKey(name: 'minimumAppVersion')
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
  @JsonKey(name: 'url')
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
  final Map<String, dynamic>? featureFlags;

  AppConfig({
    this.limits,
    this.durations,
    this.ui,
    this.storage,
    this.reader,
    this.privacy,
    this.featureFlags,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);
}

// Sub-models for AppConfig (Simplified for now, can be expanded)
@JsonSerializable()
class AppLimits {
  final int defaultPageSize;
  final int maxBatchSize;
  final int maxConcurrentDownloads;
  final int searchHistoryLimit;
  final int imagePreloadBuffer;

  AppLimits({
    this.defaultPageSize = 20,
    this.maxBatchSize = 1000,
    this.maxConcurrentDownloads = 3,
    this.searchHistoryLimit = 50,
    this.imagePreloadBuffer = 5,
  });

  factory AppLimits.fromJson(Map<String, dynamic> json) =>
      _$AppLimitsFromJson(json);
  Map<String, dynamic> toJson() => _$AppLimitsToJson(this);
}

@JsonSerializable()
class AppDurations {
  final int splashDelayMs;
  final int snackbarShortMs;
  final int snackbarLongMs;
  final int pageTransitionMs;
  final int searchDebounceMs;
  final int networkTimeoutMs;
  final int cacheExpirationHours;
  final int readerAutoHideDelaySeconds;
  final int progressUpdateIntervalMs;

  AppDurations({
    this.splashDelayMs = 1000,
    this.snackbarShortMs = 2000,
    this.snackbarLongMs = 4000,
    this.pageTransitionMs = 300,
    this.searchDebounceMs = 300,
    this.networkTimeoutMs = 30000,
    this.cacheExpirationHours = 24,
    this.readerAutoHideDelaySeconds = 3,
    this.progressUpdateIntervalMs = 100,
  });

  factory AppDurations.fromJson(Map<String, dynamic> json) =>
      _$AppDurationsFromJson(json);
  Map<String, dynamic> toJson() => _$AppDurationsToJson(this);
}

@JsonSerializable()
class AppUiConfig {
  final int gridColumnsPortrait;
  final int gridColumnsLandscape;
  final double minCardWidth;
  final double cardAspectRatio;
  final double cardBorderRadius;
  final double defaultPadding;
  final int titleMaxLength;

  AppUiConfig({
    this.gridColumnsPortrait = 2,
    this.gridColumnsLandscape = 3,
    this.minCardWidth = 150.0,
    this.cardAspectRatio = 0.65,
    this.cardBorderRadius = 12.0,
    this.defaultPadding = 16.0,
    this.titleMaxLength = 40,
  });

  factory AppUiConfig.fromJson(Map<String, dynamic> json) =>
      _$AppUiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AppUiConfigToJson(this);
}

@JsonSerializable()
class AppStorage {
  final String backupFolderName;
  final int maxImageSizeKb;
  final int pdfPartsSizePages;

  AppStorage({
    this.backupFolderName = 'nhasix',
    this.maxImageSizeKb = 200,
    this.pdfPartsSizePages = 100,
  });

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
