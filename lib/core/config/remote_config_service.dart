import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  final Dio _dio;
  final Logger _logger;

  // GitHub Raw URLs for tags (large files, downloaded on demand)
  static const String _tagsBaseUrl =
      'https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs/tags';
  static const String _nhentaiTagsUrl = '$_tagsBaseUrl/tags_nhentai.json';
  static const String _crotpediaTagsUrl = '$_tagsBaseUrl/tags_crotpedia.json';

  // Asset path for tags config (manifest)
  static const String _tagsAssetPath = 'assets/configs/tags-config.json';

  // Cache keys for downloaded tags
  static const String _nhentaiTagsCacheKey = 'tags_cache_nhentai';
  static const String _crotpediaTagsCacheKey = 'tags_cache_crotpedia';

  // In-memory Configs
  AppConfig? _appConfig;
  TagsManifest? _tagsManifest;
  final Map<String, SourceConfig> _sourceConfigs = {};

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
    _logger.i('Initializing Config from Assets (Stable Mode)...');

    try {
      // SIMPLIFIED: Just load from assets directly, skip remote download
      // This is more stable and faster for production use
      onProgress?.call(0.2, 'Loading nhentai config...');
      await _loadFromAsset('nhentai', 'assets/configs/nhentai-config.json',
          (json) => _sourceConfigs['nhentai'] = SourceConfig.fromJson(json));

      onProgress?.call(0.4, 'Loading crotpedia config...');
      await _loadFromAsset('crotpedia', 'assets/configs/crotpedia-config.json',
          (json) => _sourceConfigs['crotpedia'] = SourceConfig.fromJson(json));

      onProgress?.call(0.6, 'Loading komiktap config...');
      await _loadFromAsset('komiktap', 'assets/configs/komiktap-config.json',
          (json) => _sourceConfigs['komiktap'] = SourceConfig.fromJson(json));

      onProgress?.call(0.8, 'Loading app config...');
      await _loadFromAsset('app', 'assets/configs/app-config.json',
          (json) => _appConfig = AppConfig.fromJson(json));

      onProgress?.call(0.9, 'Loading tags config...');
      await _loadFromAsset('tags', _tagsAssetPath,
          (json) => _tagsManifest = TagsManifest.fromJson(json));

      onProgress?.call(1.0, 'All configs loaded successfully');

      _logger.i('✅ Successfully loaded all configs from assets');
    } catch (e) {
      _logger.e('Failed to load configs from assets', error: e);
      if (isFirstRun) {
        rethrow;
      }
    }
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
      rethrow;
    }
  }

  /// Download tags for a specific source from GitHub
  /// Large files (tags_nhentai.json, tags_crotpedia.json) saved to reduce APK size
  Future<void> downloadTagsForSource(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') {
      _logger.w('Tags download not supported for source: $source');
      return;
    }

    final url = source == 'nhentai' ? _nhentaiTagsUrl : _crotpediaTagsUrl;
    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;

    try {
      _logger.i('Downloading tags for $source from: $url');

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final String jsonString;
        if (response.data is String) {
          jsonString = response.data as String;
        } else {
          jsonString = jsonEncode(response.data);
        }

        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonString);
        await prefs.setInt(
            '${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);

        _logger.i('✅ Successfully downloaded and cached tags for $source');
      } else {
        _logger
            .w('Failed to download tags for $source: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error downloading tags for $source', error: e);
    }
  }

  /// Get cached tags for a source
  Future<List<Map<String, dynamic>>?> getCachedTags(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') {
      return null;
    }

    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);

      if (jsonString != null) {
        final List<dynamic> data = jsonDecode(jsonString);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _logger.w('Failed to load cached tags for $source', error: e);
    }

    return null;
  }

  /// Check if tags are cached for a source
  Future<bool> hasTagsCache(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') {
      return false;
    }

    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;

    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(cacheKey);
  }

  /// Get cache age in days
  Future<int?> getTagsCacheAge(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') {
      return null;
    }

    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;

    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${cacheKey}_timestamp');

      if (timestamp != null) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheDate);
        return age.inDays;
      }
    } catch (e) {
      _logger.w('Failed to get cache age for $source', error: e);
    }

    return null;
  }

  // Getters
  SourceConfig? getConfig(String source) {
    return _sourceConfigs[source];
  }

  AppConfig? get appConfig => _appConfig;
  TagsManifest? get tagsManifest => _tagsManifest;

  // Existing helpers
  Future<bool> hasValidCache(String source) async {
    // Since we always load from assets now, just check if config is loaded
    return _sourceConfigs.containsKey(source);
  }

  Future<DateTime?> getLastSyncTime() async {
    // Return current time since we load from assets
    return DateTime.now();
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
