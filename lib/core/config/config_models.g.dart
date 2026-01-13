// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteConfig _$RemoteConfigFromJson(Map<String, dynamic> json) => RemoteConfig(
      nhentai: json['nhentai'] == null
          ? null
          : SourceConfig.fromJson(json['nhentai'] as Map<String, dynamic>),
      crotpedia: json['crotpedia'] == null
          ? null
          : SourceConfig.fromJson(json['crotpedia'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RemoteConfigToJson(RemoteConfig instance) =>
    <String, dynamic>{
      'nhentai': instance.nhentai?.toJson(),
      'crotpedia': instance.crotpedia?.toJson(),
    };

SourceConfig _$SourceConfigFromJson(Map<String, dynamic> json) => SourceConfig(
      source: json['source'] as String,
      version: json['version'] as String,
      lastUpdated: json['lastUpdated'] as String?,
      baseUrl: json['baseUrl'] as String?,
      api: json['api'] == null
          ? null
          : ApiConfig.fromJson(json['api'] as Map<String, dynamic>),
      scraper: json['scraper'] == null
          ? null
          : ScraperConfig.fromJson(json['scraper'] as Map<String, dynamic>),
      network: json['network'] == null
          ? null
          : NetworkConfig.fromJson(json['network'] as Map<String, dynamic>),
      features: json['features'] == null
          ? null
          : FeatureConfig.fromJson(json['features'] as Map<String, dynamic>),
      ui: json['ui'] == null
          ? null
          : UiConfig.fromJson(json['ui'] as Map<String, dynamic>),
      auth: json['auth'] == null
          ? null
          : AuthConfig.fromJson(json['auth'] as Map<String, dynamic>),
      tags: json['tags'] == null
          ? null
          : TagConfig.fromJson(json['tags'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SourceConfigToJson(SourceConfig instance) =>
    <String, dynamic>{
      'source': instance.source,
      'version': instance.version,
      'lastUpdated': instance.lastUpdated,
      'baseUrl': instance.baseUrl,
      'api': instance.api?.toJson(),
      'scraper': instance.scraper?.toJson(),
      'network': instance.network?.toJson(),
      'features': instance.features?.toJson(),
      'ui': instance.ui?.toJson(),
      'auth': instance.auth?.toJson(),
      'tags': instance.tags?.toJson(),
    };

ApiConfig _$ApiConfigFromJson(Map<String, dynamic> json) => ApiConfig(
      enabled: json['enabled'] as bool,
      baseUrl: json['baseUrl'] as String?,
      apiBase: json['apiBase'] as String?,
      timeout: (json['timeout'] as num?)?.toInt(),
      endpoints: (json['endpoints'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      images: (json['images'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      extensionMapping:
          (json['extensionMapping'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      mirrors:
          (json['mirrors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      useMirrors: json['useMirrors'] as bool?,
    );

Map<String, dynamic> _$ApiConfigToJson(ApiConfig instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'baseUrl': instance.baseUrl,
      'apiBase': instance.apiBase,
      'timeout': instance.timeout,
      'endpoints': instance.endpoints,
      'images': instance.images,
      'extensionMapping': instance.extensionMapping,
      'mirrors': instance.mirrors,
      'useMirrors': instance.useMirrors,
    };

ScraperConfig _$ScraperConfigFromJson(Map<String, dynamic> json) =>
    ScraperConfig(
      enabled: json['enabled'] as bool,
      selectors: json['selectors'] as Map<String, dynamic>?,
      urlPatterns: (json['urlPatterns'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$ScraperConfigToJson(ScraperConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'selectors': instance.selectors,
      'urlPatterns': instance.urlPatterns,
    };

NetworkConfig _$NetworkConfigFromJson(Map<String, dynamic> json) =>
    NetworkConfig(
      rateLimit: json['rateLimit'] == null
          ? null
          : RateLimitConfig.fromJson(json['rateLimit'] as Map<String, dynamic>),
      retry: json['retry'] == null
          ? null
          : RetryConfig.fromJson(json['retry'] as Map<String, dynamic>),
      cloudflare: json['cloudflare'] == null
          ? null
          : CloudflareConfig.fromJson(
              json['cloudflare'] as Map<String, dynamic>),
      timeout: (json['timeout'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NetworkConfigToJson(NetworkConfig instance) =>
    <String, dynamic>{
      'rateLimit': instance.rateLimit?.toJson(),
      'retry': instance.retry?.toJson(),
      'cloudflare': instance.cloudflare?.toJson(),
      'timeout': instance.timeout,
    };

RateLimitConfig _$RateLimitConfigFromJson(Map<String, dynamic> json) =>
    RateLimitConfig(
      enabled: json['enabled'] as bool? ?? true,
      requestsPerMinute: (json['requestsPerMinute'] as num).toInt(),
      minDelayMs: (json['minDelayMs'] as num).toInt(),
      cooldownDurationMs: (json['cooldownDurationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RateLimitConfigToJson(RateLimitConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'requestsPerMinute': instance.requestsPerMinute,
      'minDelayMs': instance.minDelayMs,
      'cooldownDurationMs': instance.cooldownDurationMs,
    };

RetryConfig _$RetryConfigFromJson(Map<String, dynamic> json) => RetryConfig(
      maxAttempts: (json['maxAttempts'] as num).toInt(),
      delayMs: (json['delayMs'] as num?)?.toInt(),
      exponentialBackoff: json['exponentialBackoff'] as bool? ?? true,
    );

Map<String, dynamic> _$RetryConfigToJson(RetryConfig instance) =>
    <String, dynamic>{
      'maxAttempts': instance.maxAttempts,
      'delayMs': instance.delayMs,
      'exponentialBackoff': instance.exponentialBackoff,
    };

CloudflareConfig _$CloudflareConfigFromJson(Map<String, dynamic> json) =>
    CloudflareConfig(
      bypassEnabled: json['bypassEnabled'] as bool,
      antiDetection: json['antiDetection'] as bool,
    );

Map<String, dynamic> _$CloudflareConfigToJson(CloudflareConfig instance) =>
    <String, dynamic>{
      'bypassEnabled': instance.bypassEnabled,
      'antiDetection': instance.antiDetection,
    };

FeatureConfig _$FeatureConfigFromJson(Map<String, dynamic> json) =>
    FeatureConfig(
      search: json['search'] as bool? ?? false,
      random: json['random'] as bool? ?? false,
      related: json['related'] as bool? ?? false,
      download: json['download'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
      chapters: json['chapters'] as bool? ?? false,
      bookmark: json['bookmark'] as bool? ?? false,
      supportsTagExclusion: json['supportsTagExclusion'] as bool? ?? false,
      supportsAdvancedSearch: json['supportsAdvancedSearch'] as bool? ?? false,
    );

Map<String, dynamic> _$FeatureConfigToJson(FeatureConfig instance) =>
    <String, dynamic>{
      'search': instance.search,
      'random': instance.random,
      'related': instance.related,
      'download': instance.download,
      'favorite': instance.favorite,
      'chapters': instance.chapters,
      'bookmark': instance.bookmark,
      'supportsTagExclusion': instance.supportsTagExclusion,
      'supportsAdvancedSearch': instance.supportsAdvancedSearch,
    };

UiConfig _$UiConfigFromJson(Map<String, dynamic> json) => UiConfig(
      displayName: json['displayName'] as String,
      iconPath: json['iconPath'] as String,
      themeColor: json['themeColor'] as String,
      cardStyle: json['cardStyle'] as String,
    );

Map<String, dynamic> _$UiConfigToJson(UiConfig instance) => <String, dynamic>{
      'displayName': instance.displayName,
      'iconPath': instance.iconPath,
      'themeColor': instance.themeColor,
      'cardStyle': instance.cardStyle,
    };

AuthConfig _$AuthConfigFromJson(Map<String, dynamic> json) => AuthConfig(
      enabled: json['enabled'] as bool,
      loginEndpoint: json['loginEndpoint'] as String?,
      registerEndpoint: json['registerEndpoint'] as String?,
      sessionCookies: (json['sessionCookies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sessionDurationSeconds: (json['sessionDurationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AuthConfigToJson(AuthConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'loginEndpoint': instance.loginEndpoint,
      'registerEndpoint': instance.registerEndpoint,
      'sessionCookies': instance.sessionCookies,
      'sessionDurationSeconds': instance.sessionDurationSeconds,
    };

TagConfig _$TagConfigFromJson(Map<String, dynamic> json) => TagConfig(
      enabled: json['enabled'] as bool,
      version: json['version'] as String?,
      endpoint: json['endpoint'] as String?,
      updateIntervalHours: (json['updateIntervalHours'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TagConfigToJson(TagConfig instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'version': instance.version,
      'endpoint': instance.endpoint,
      'updateIntervalHours': instance.updateIntervalHours,
    };
