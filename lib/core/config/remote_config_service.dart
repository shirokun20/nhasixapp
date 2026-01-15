import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/constants/app_constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Add this import

class RemoteConfigService {
  final Dio _dio;
  final Logger _logger;

  // CDN URLs
  static String get _baseUrl => kDebugMode
      ? 'https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs'
      : 'https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@configs/configs';
  static String get _versionUrl => '$_baseUrl/version.json';
  static const String _tagsAssetPath = 'assets/configs/tags-config.json';

  // Config Cache Keys
  static const String _versionCacheKey = 'config_version_manifest';
  static const String _appConfigCacheKey = 'config_cache_app';
  static const String _tagsCacheKey = 'config_cache_tags';
  static const String _nhentaiCacheKey = 'config_cache_nhentai';
  static const String _crotpediaCacheKey = 'config_cache_crotpedia';
  static const String _lastCheckedKey = 'config_last_checked';

  // In-memory Configs
  ConfigVersion? _versionManifest;
  AppConfig? _appConfig;
  TagsManifest? _tagsManifest;
  SourceConfig? _nhentaiConfig;
  SourceConfig? _crotpediaConfig;

  RemoteConfigService({
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  /// Initialize with Smart Sync logic (Master Manifest Pattern)
  /// [isFirstRun] - If true, throws exception on critical failure
  /// [onProgress] - Optional callback for progress tracking (0.0 to 1.0)
  Future<void> smartInitialize({
    bool isFirstRun = false,
    void Function(double progress, String message)? onProgress,
  }) async {
    _logger.i('Initializing Remote Config (Smart Mode)...');
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Fetch Master Manifest (version.json)
      onProgress?.call(0.1, 'Checking version manifest...');
      await _syncManifest(prefs, isFirstRun);

      // 2. Sync Configs based on Manifest
      // We have 4 configs to sync. Let's distribute the remaining 90% progress
      // 0.1 -> 0.325 -> 0.55 -> 0.775 -> 1.0
      
      double currentProgress = 0.1;
      final step = 0.9 / 4;

      // Nhentai Config
      onProgress?.call(currentProgress, 'Syncing nhentai config...');
      await _syncConfig(
        'nhentai',
        'nhentai-config.json',
        _nhentaiCacheKey,
        (json) => _nhentaiConfig = SourceConfig.fromJson(json),
        prefs,
      );
      currentProgress += step;
      onProgress?.call(currentProgress, 'Synced nhentai config');

      // Crotpedia Config
      onProgress?.call(currentProgress, 'Syncing crotpedia config...');
      await _syncConfig(
        'crotpedia',
        'crotpedia-config.json',
        _crotpediaCacheKey,
        (json) => _crotpediaConfig = SourceConfig.fromJson(json),
        prefs,
      );
      currentProgress += step;
      onProgress?.call(currentProgress, 'Synced crotpedia config');

      // App Config
      onProgress?.call(currentProgress, 'Syncing app config...');
      await _syncConfig(
        'app',
        'app-config.json',
        _appConfigCacheKey,
        (json) => _appConfig = AppConfig.fromJson(json),
        prefs,
      );
      currentProgress += step;
      onProgress?.call(currentProgress, 'Synced app config');

      // Tags Config
      onProgress?.call(currentProgress, 'Syncing tags config...');
      await _syncConfig(
        'tags',
        'tags-config.json',
        _tagsCacheKey,
        (json) => _tagsManifest = TagsManifest.fromJson(json),
        prefs,
      );
      currentProgress += step;
      onProgress?.call(1.0, 'All configs synced');

      // 3. Check Minimum App Version (Forced Update)
      _checkMinAppVersion();
    } catch (e) {
      _logger.e('Remote Config Initialization Failed', error: e);
      // Fallback to local assets if everything fails and we have no cache
      if (_nhentaiConfig == null) await _loadAllFallbacks();
      if (isFirstRun && _nhentaiConfig == null) rethrow;
    }
  }

  Future<void> _syncManifest(
      SharedPreferences prefs, bool mustFetchRemote) async {
    try {
      // Try fetch remote manifest
      final response = await _dio.get(
        _versionUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: constants.AppDurations.networkTimeout,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data;
        if (response.data is String) {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } else {
          data = response.data as Map<String, dynamic>;
        }

        _versionManifest = ConfigVersion.fromJson(data);
        await prefs.setString(_versionCacheKey, jsonEncode(data));
        _logger.i('✅ Master Manifest synced: v${_versionManifest?.version}');
        return;
      }
    } catch (e) {
      _logger.w('Failed to fetch remote manifest: $e');
      if (mustFetchRemote) rethrow;
    }

    // Load cached manifest if remote failed
    if (prefs.containsKey(_versionCacheKey)) {
      final json = jsonDecode(prefs.getString(_versionCacheKey)!);
      _versionManifest = ConfigVersion.fromJson(json);
      _logger.i('Loaded cached manifest: v${_versionManifest?.version}');
    } else {
      // Load asset manifest as last resort
      // final json = jsonDecode(await rootBundle.loadString('assets/configs/version.json'));
      // _versionManifest = ConfigVersion.fromJson(json);
      _logger.w('No manifest available. Will force load individual configs.');
    }
  }

  Future<void> _syncConfig<T>(
    String configName,
    String fileName,
    String cacheKey,
    Function(Map<String, dynamic>) updateConfig,
    SharedPreferences prefs,
  ) async {
    final cachedJson = prefs.getString(cacheKey);
    // Load cache first (Optimistic UI)
    if (cachedJson != null) {
      try {
        final data = jsonDecode(cachedJson);
        updateConfig(data);
        // Assuming all configs have a 'version' field.
        // AppConfig doesn't have it directly in root in my model yet,
        // but SourceConfig does.
        // For AppConfig we might rely on Manifest versioning mapping.
        // Let's rely on Manifest comparison.
      } catch (e) {
        _logger.w('Failed to load cache for $configName', error: e);
      }
    }

    // Check if we need to update based on Manifest
    final remoteVersion = _versionManifest?.configs[configName]?.version;
    // We strictly need to know the LOCAL version of the config file itself to compare.
    // But since we have the Master Manifest, we can optimize:
    // If we have a cached manifest, we can compare remoteManifest vs cachedManifest.
    // Simplified Logic: Always try fetch if manifest says new version OR if we have no config.

    // If _versionManifest is null (offline & no cache), use fallback asset
    if (_versionManifest == null && _nhentaiConfig == null) {
      // Simulate asset load delay
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadFromAsset(
          configName, 'assets/configs/$fileName', updateConfig);
      return;
    }

    if (remoteVersion != null) {
      // Compare with stored version. Ideally we store {configName}_version in prefs
      // But for now, let's just fetch if we have a valid remote manifest.
      // Optimization: store 'last_synced_version_$configName'
      final lastSyncedVersion = prefs.getString('${cacheKey}_version');

      if (lastSyncedVersion != remoteVersion) {
        _logger.i('Updating $configName: $lastSyncedVersion -> $remoteVersion');
        await _fetchAndCache('$_baseUrl/$fileName', cacheKey, updateConfig,
            prefs, remoteVersion);
      } else {
        // Simulate "Checking..." delay even if up to date
        await Future.delayed(const Duration(milliseconds: 150));
        _logger.d('$configName is up to date ($remoteVersion)');
      }
    } else {
       // Simulate check delay when remote version isn't available
       await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAndCache(
    String url,
    String cacheKey,
    Function(Map<String, dynamic>) updateConfig,
    SharedPreferences prefs,
    String version,
  ) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle both Map and String responses
        final Map<String, dynamic> data;
        if (response.data is String) {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } else {
          data = response.data as Map<String, dynamic>;
        }

        updateConfig(data);
        await prefs.setString(cacheKey, jsonEncode(data));
        await prefs.setString('${cacheKey}_version', version);
        await prefs.setInt(
            _lastCheckedKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      _logger.w('Failed to fetch $url', error: e);
    }
  }

  Future<void> _loadAllFallbacks() async {
    await _loadFromAsset('nhentai', 'assets/configs/nhentai-config.json',
        (json) => _nhentaiConfig = SourceConfig.fromJson(json));
    await _loadFromAsset('crotpedia', 'assets/configs/crotpedia-config.json',
        (json) => _crotpediaConfig = SourceConfig.fromJson(json));
    await _loadFromAsset('app', 'assets/configs/app-config.json',
        (json) => _appConfig = AppConfig.fromJson(json));
    await _loadFromAsset('tags', _tagsAssetPath,
        (json) => _tagsManifest = TagsManifest.fromJson(json));
  }

  Future<void> _loadFromAsset(
    String sourceName,
    String assetPath,
    Function(Map<String, dynamic>) updateConfig,
  ) async {
    try {
      final assetString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(assetString) as Map<String, dynamic>;
      updateConfig(data);
    } catch (e) {
      _logger.w('Asset load failed for $sourceName', error: e);
    }
  }

  // Helper to check app version
  void _checkMinAppVersion() {
    final minVersion = _versionManifest?.minAppVersion;
    if (minVersion != null) {
      _logger.i('Min App Version required: $minVersion');
      // Logic to block app would go here
    }
  }

  // Getters
  SourceConfig? getConfig(String source) {
    if (source == 'nhentai') return _nhentaiConfig;
    if (source == 'crotpedia') return _crotpediaConfig;
    return null;
  }

  AppConfig? get appConfig => _appConfig;
  TagsManifest? get tagsManifest => _tagsManifest;

  // Existing helpers
  Future<bool> hasValidCache(String source) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(
        source == 'nhentai' ? _nhentaiCacheKey : _crotpediaCacheKey);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastCheckedKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  /// Get rate limit configuration for a specific source
  RateLimitConfig getRateLimitConfig(String source) {
    return getConfig(source)?.network?.rateLimit ??
        RateLimitConfig(requestsPerMinute: 30, minDelayMs: 1500);
  }

  /// Check if a specific feature is enabled for a specific source
  /// Usage: isFeatureEnabled('nhentai', (f) => f.download)
  bool isFeatureEnabled(String source, bool Function(FeatureConfig) selector) {
    // Default to true if config is missing to avoid breaking app,
    // or false if strict. Given this is remote config, false is safer fallthrough?
    // But if config fails to load, we have assets.
    // So if config is null here, something is really wrong.
    final config = getConfig(source);
    if (config?.features == null) return false;
    return selector(config!.features!);
  }

  /// Check if source supports tag exclusion (for search UI)
  bool supportsTagExclusion(String source) {
    return isFeatureEnabled(source, (f) => f.supportsTagExclusion);
  }

  /// Check if source supports advanced search
  bool supportsAdvancedSearch(String source) {
    return isFeatureEnabled(source, (f) => f.supportsAdvancedSearch);
  }
}
