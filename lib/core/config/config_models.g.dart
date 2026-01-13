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
      typeMapping: (json['typeMapping'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      searchConfig: json['searchConfig'] == null
          ? null
          : SearchConfig.fromJson(json['searchConfig'] as Map<String, dynamic>),
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
      'typeMapping': instance.typeMapping,
      'searchConfig': instance.searchConfig?.toJson(),
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

TagsManifest _$TagsManifestFromJson(Map<String, dynamic> json) => TagsManifest(
      version: json['version'] as String,
      lastUpdated: json['lastUpdated'] as String?,
      sources: (json['sources'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, TagSourceConfig.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$TagsManifestToJson(TagsManifest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'lastUpdated': instance.lastUpdated,
      'sources': instance.sources.map((k, e) => MapEntry(k, e.toJson())),
    };

TagSourceConfig _$TagSourceConfigFromJson(Map<String, dynamic> json) =>
    TagSourceConfig(
      type: json['type'] as String,
      assetPath: json['assetPath'] as String?,
      format: json['format'] as String?,
      structure: (json['structure'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      migration: json['migration'] == null
          ? null
          : TagMigrationConfig.fromJson(
              json['migration'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TagSourceConfigToJson(TagSourceConfig instance) =>
    <String, dynamic>{
      'type': instance.type,
      'assetPath': instance.assetPath,
      'format': instance.format,
      'structure': instance.structure,
      'migration': instance.migration?.toJson(),
    };

TagMigrationConfig _$TagMigrationConfigFromJson(Map<String, dynamic> json) =>
    TagMigrationConfig(
      enabled: json['enabled'] as bool,
      remoteUrl: json['remoteUrl'] as String?,
      fallbackUrl: json['fallbackUrl'] as String?,
      cacheTtlSeconds: (json['cacheTtlSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TagMigrationConfigToJson(TagMigrationConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'remoteUrl': instance.remoteUrl,
      'fallbackUrl': instance.fallbackUrl,
      'cacheTtlSeconds': instance.cacheTtlSeconds,
    };

ConfigVersion _$ConfigVersionFromJson(Map<String, dynamic> json) =>
    ConfigVersion(
      version: json['version'] as String,
      minAppVersion: json['minimumAppVersion'] as String?,
      configs: (json['configs'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, ConfigManifest.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ConfigVersionToJson(ConfigVersion instance) =>
    <String, dynamic>{
      'version': instance.version,
      'minimumAppVersion': instance.minAppVersion,
      'configs': instance.configs,
    };

ConfigManifest _$ConfigManifestFromJson(Map<String, dynamic> json) =>
    ConfigManifest(
      version: json['version'] as String,
      file: json['url'] as String,
    );

Map<String, dynamic> _$ConfigManifestToJson(ConfigManifest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'url': instance.file,
    };

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
      limits: json['limits'] == null
          ? null
          : AppLimits.fromJson(json['limits'] as Map<String, dynamic>),
      durations: json['durations'] == null
          ? null
          : AppDurations.fromJson(json['durations'] as Map<String, dynamic>),
      ui: json['ui'] == null
          ? null
          : AppUiConfig.fromJson(json['ui'] as Map<String, dynamic>),
      storage: json['storage'] == null
          ? null
          : AppStorage.fromJson(json['storage'] as Map<String, dynamic>),
      reader: json['reader'] == null
          ? null
          : AppReader.fromJson(json['reader'] as Map<String, dynamic>),
      privacy: json['privacy'] == null
          ? null
          : AppPrivacy.fromJson(json['privacy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
      'limits': instance.limits?.toJson(),
      'durations': instance.durations?.toJson(),
      'ui': instance.ui?.toJson(),
      'storage': instance.storage?.toJson(),
      'reader': instance.reader?.toJson(),
      'privacy': instance.privacy?.toJson(),
    };

AppLimits _$AppLimitsFromJson(Map<String, dynamic> json) => AppLimits(
      defaultPageSize: (json['defaultPageSize'] as num?)?.toInt() ?? 20,
      maxConcurrentDownloads:
          (json['maxConcurrentDownloads'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$AppLimitsToJson(AppLimits instance) => <String, dynamic>{
      'defaultPageSize': instance.defaultPageSize,
      'maxConcurrentDownloads': instance.maxConcurrentDownloads,
    };

AppDurations _$AppDurationsFromJson(Map<String, dynamic> json) => AppDurations(
      splashDelayMs: (json['splashDelayMs'] as num?)?.toInt() ?? 2000,
      snackbarDurationMs: (json['snackbarDurationMs'] as num?)?.toInt() ?? 3000,
    );

Map<String, dynamic> _$AppDurationsToJson(AppDurations instance) =>
    <String, dynamic>{
      'splashDelayMs': instance.splashDelayMs,
      'snackbarDurationMs': instance.snackbarDurationMs,
    };

AppUiConfig _$AppUiConfigFromJson(Map<String, dynamic> json) => AppUiConfig(
      gridColumnsPortrait: (json['gridColumnsPortrait'] as num?)?.toInt() ?? 2,
      cardAspectRatio: (json['cardAspectRatio'] as num?)?.toDouble() ?? 0.7,
    );

Map<String, dynamic> _$AppUiConfigToJson(AppUiConfig instance) =>
    <String, dynamic>{
      'gridColumnsPortrait': instance.gridColumnsPortrait,
      'cardAspectRatio': instance.cardAspectRatio,
    };

AppStorage _$AppStorageFromJson(Map<String, dynamic> json) => AppStorage(
      backupFolderName: json['backupFolderName'] as String? ?? 'nhasix_backup',
    );

Map<String, dynamic> _$AppStorageToJson(AppStorage instance) =>
    <String, dynamic>{
      'backupFolderName': instance.backupFolderName,
    };

AppReader _$AppReaderFromJson(Map<String, dynamic> json) => AppReader(
      preloadNextChapter: json['preloadNextChapter'] as bool? ?? true,
    );

Map<String, dynamic> _$AppReaderToJson(AppReader instance) => <String, dynamic>{
      'preloadNextChapter': instance.preloadNextChapter,
    };

AppPrivacy _$AppPrivacyFromJson(Map<String, dynamic> json) => AppPrivacy(
      enableAnalytics: json['enableAnalytics'] as bool? ?? true,
    );

Map<String, dynamic> _$AppPrivacyToJson(AppPrivacy instance) =>
    <String, dynamic>{
      'enableAnalytics': instance.enableAnalytics,
    };

_SearchConfig _$SearchConfigFromJson(Map<String, dynamic> json) =>
    _SearchConfig(
      searchMode: $enumDecode(_$SearchModeEnumMap, json['searchMode']),
      endpoint: json['endpoint'] as String,
      sortingConfig: json['sortingConfig'] == null
          ? null
          : SortingConfig.fromJson(
              json['sortingConfig'] as Map<String, dynamic>),
      queryParam: json['queryParam'] as String?,
      filterSupport: json['filterSupport'] == null
          ? null
          : FilterSupportConfig.fromJson(
              json['filterSupport'] as Map<String, dynamic>),
      textFields: (json['textFields'] as List<dynamic>?)
          ?.map((e) => TextFieldConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      radioGroups: (json['radioGroups'] as List<dynamic>?)
          ?.map((e) => RadioGroupConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkboxGroups: (json['checkboxGroups'] as List<dynamic>?)
          ?.map((e) => CheckboxGroupConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : PaginationConfig.fromJson(
              json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchConfigToJson(_SearchConfig instance) =>
    <String, dynamic>{
      'searchMode': _$SearchModeEnumMap[instance.searchMode]!,
      'endpoint': instance.endpoint,
      'sortingConfig': instance.sortingConfig,
      'queryParam': instance.queryParam,
      'filterSupport': instance.filterSupport,
      'textFields': instance.textFields,
      'radioGroups': instance.radioGroups,
      'checkboxGroups': instance.checkboxGroups,
      'pagination': instance.pagination,
    };

const _$SearchModeEnumMap = {
  SearchMode.queryString: 'query-string',
  SearchMode.formBased: 'form-based',
};

_FilterSupportConfig _$FilterSupportConfigFromJson(Map<String, dynamic> json) =>
    _FilterSupportConfig(
      singleSelect: (json['singleSelect'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      multiSelect: (json['multiSelect'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      supportsExclude: json['supportsExclude'] as bool,
    );

Map<String, dynamic> _$FilterSupportConfigToJson(
        _FilterSupportConfig instance) =>
    <String, dynamic>{
      'singleSelect': instance.singleSelect,
      'multiSelect': instance.multiSelect,
      'supportsExclude': instance.supportsExclude,
    };

_TextFieldConfig _$TextFieldConfigFromJson(Map<String, dynamic> json) =>
    _TextFieldConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      placeholder: json['placeholder'] as String?,
      maxLength: (json['maxLength'] as num?)?.toInt(),
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TextFieldConfigToJson(_TextFieldConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'label': instance.label,
      'type': instance.type,
      'placeholder': instance.placeholder,
      'maxLength': instance.maxLength,
      'min': instance.min,
      'max': instance.max,
    };

_RadioGroupConfig _$RadioGroupConfigFromJson(Map<String, dynamic> json) =>
    _RadioGroupConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => RadioOptionConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RadioGroupConfigToJson(_RadioGroupConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'label': instance.label,
      'options': instance.options,
    };

_RadioOptionConfig _$RadioOptionConfigFromJson(Map<String, dynamic> json) =>
    _RadioOptionConfig(
      value: json['value'] as String,
      label: json['label'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$RadioOptionConfigToJson(_RadioOptionConfig instance) =>
    <String, dynamic>{
      'value': instance.value,
      'label': instance.label,
      'isDefault': instance.isDefault,
    };

_CheckboxGroupConfig _$CheckboxGroupConfigFromJson(Map<String, dynamic> json) =>
    _CheckboxGroupConfig(
      name: json['name'] as String,
      label: json['label'] as String,
      paramName: json['paramName'] as String,
      displayMode: json['displayMode'] as String? ?? 'expandable',
      columns: (json['columns'] as num?)?.toInt() ?? 3,
      loadFromTags: json['loadFromTags'] as bool? ?? false,
      tagType: json['tagType'] as String?,
    );

Map<String, dynamic> _$CheckboxGroupConfigToJson(
        _CheckboxGroupConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'label': instance.label,
      'paramName': instance.paramName,
      'displayMode': instance.displayMode,
      'columns': instance.columns,
      'loadFromTags': instance.loadFromTags,
      'tagType': instance.tagType,
    };

_SortingConfig _$SortingConfigFromJson(Map<String, dynamic> json) =>
    _SortingConfig(
      allowDynamicReSort: json['allowDynamicReSort'] as bool,
      defaultSort: json['defaultSort'] as String,
      widgetType: $enumDecode(_$SortWidgetTypeEnumMap, json['widgetType']),
      options: (json['options'] as List<dynamic>)
          .map((e) => SortOptionConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      messages:
          SortingMessages.fromJson(json['messages'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SortingConfigToJson(_SortingConfig instance) =>
    <String, dynamic>{
      'allowDynamicReSort': instance.allowDynamicReSort,
      'defaultSort': instance.defaultSort,
      'widgetType': _$SortWidgetTypeEnumMap[instance.widgetType]!,
      'options': instance.options,
      'messages': instance.messages,
    };

const _$SortWidgetTypeEnumMap = {
  SortWidgetType.dropdown: 'dropdown',
  SortWidgetType.chips: 'chips',
  SortWidgetType.readonly: 'readonly',
};

_SortOptionConfig _$SortOptionConfigFromJson(Map<String, dynamic> json) =>
    _SortOptionConfig(
      value: json['value'] as String,
      apiValue: json['apiValue'] as String,
      label: json['label'] as String,
      displayLabel: json['displayLabel'] as String,
      icon: json['icon'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$SortOptionConfigToJson(_SortOptionConfig instance) =>
    <String, dynamic>{
      'value': instance.value,
      'apiValue': instance.apiValue,
      'label': instance.label,
      'displayLabel': instance.displayLabel,
      'icon': instance.icon,
      'isDefault': instance.isDefault,
    };

_SortingMessages _$SortingMessagesFromJson(Map<String, dynamic> json) =>
    _SortingMessages(
      dropdownLabel: json['dropdownLabel'] as String?,
      noOptionsAvailable: json['noOptionsAvailable'] as String?,
      readOnlyPrefix: json['readOnlyPrefix'] as String?,
      readOnlySuffix: json['readOnlySuffix'] as String?,
      tapToModifyHint: json['tapToModifyHint'] as String?,
      returnToSearchButton: json['returnToSearchButton'] as String?,
    );

Map<String, dynamic> _$SortingMessagesToJson(_SortingMessages instance) =>
    <String, dynamic>{
      'dropdownLabel': instance.dropdownLabel,
      'noOptionsAvailable': instance.noOptionsAvailable,
      'readOnlyPrefix': instance.readOnlyPrefix,
      'readOnlySuffix': instance.readOnlySuffix,
      'tapToModifyHint': instance.tapToModifyHint,
      'returnToSearchButton': instance.returnToSearchButton,
    };

_PaginationConfig _$PaginationConfigFromJson(Map<String, dynamic> json) =>
    _PaginationConfig(
      urlPattern: json['urlPattern'] as String,
      paramName: json['paramName'] as String? ?? 'page',
    );

Map<String, dynamic> _$PaginationConfigToJson(_PaginationConfig instance) =>
    <String, dynamic>{
      'urlPattern': instance.urlPattern,
      'paramName': instance.paramName,
    };
