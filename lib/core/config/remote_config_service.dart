import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  final Dio _dio;
  final Logger _logger;

  // CDN URLs
  static const String _baseUrl =
      'https://cdn.jsdelivr.net/gh/shirokun20/nhasixapp@configs/configs';
  static const String _nhentaiConfigUrl = '$_baseUrl/nhentai-config.json';
  static const String _crotpediaConfigUrl = '$_baseUrl/crotpedia-config.json';

  // Asset Fallbacks
  static const String _nhentaiAssetPath = 'assets/configs/nhentai-config.json';
  static const String _crotpediaAssetPath =
      'assets/configs/crotpedia-config.json';

  // Config Cache Keys
  static const String _nhentaiCacheKey = 'config_cache_nhentai';
  static const String _crotpediaCacheKey = 'config_cache_crotpedia';
  static const String _lastCheckedKey = 'config_last_checked';

  // In-memory Configs
  SourceConfig? _nhentaiConfig;
  SourceConfig? _crotpediaConfig;

  RemoteConfigService({
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  /// Initialize with Smart Sync logic
  /// [isFirstRun] - If true, throws exception on failure (Strict Mode)
  Future<void> smartInitialize({bool isFirstRun = false}) async {
    _logger
        .i('Initializing Remote Config (Smart Mode, FirstRun: $isFirstRun)...');

    await Future.wait([
      _smartSyncSource(
        'nhentai',
        _nhentaiConfigUrl,
        _nhentaiAssetPath,
        _nhentaiCacheKey,
        (json) => _nhentaiConfig = SourceConfig.fromJson(json),
        isFirstRun,
      ),
      _smartSyncSource(
        'crotpedia',
        _crotpediaConfigUrl,
        _crotpediaAssetPath,
        _crotpediaCacheKey,
        (json) => _crotpediaConfig = SourceConfig.fromJson(json),
        isFirstRun,
      ),
    ]);
  }

  /// Check if we have a valid cache for a source
  Future<bool> hasValidCache(String source) async {
    final prefs = await SharedPreferences.getInstance();
    final key = source == 'nhentai' ? _nhentaiCacheKey : _crotpediaCacheKey;
    return prefs.containsKey(key);
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastCheckedKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> _smartSyncSource(
    String sourceName,
    String remoteUrl,
    String assetPath,
    String cacheKey,
    Function(Map<String, dynamic>) updateConfig,
    bool isFirstRun,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final hasCache = prefs.containsKey(cacheKey);

    // 1. Strict Mode (First Run) - MUST download
    if (isFirstRun && !hasCache) {
      _logger.i('First run for $sourceName: Enforcing remote fetch');
      await _fetchAndCache(
          sourceName, remoteUrl, cacheKey, updateConfig, prefs);
      return;
    }

    // 2. Normal Mode - Try Remote (Smart Update), Fallback to Cache/Asset
    try {
      if (hasCache) {
        // Load current cache first so app has data immediately/fallback
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          final currentData = jsonDecode(cachedJson) as Map<String, dynamic>;
          updateConfig(currentData);

          // If we have data, we can try to update in background or wait
          // For now, checks version
          await _tryUpdateRemote(sourceName, remoteUrl,
              currentData['version'] as String?, cacheKey, updateConfig, prefs);
        }
      } else {
        // No cache, but not strict? (Rare case, maybe manual retry or cleared cache)
        // Try remote, if fail use asset
        await _fetchAndCache(
            sourceName, remoteUrl, cacheKey, updateConfig, prefs);
      }
    } catch (e) {
      if (isFirstRun) {
        _logger.e('Strict initialization failed for $sourceName', error: e);
        rethrow; // Block app start if strict
      }

      _logger.w('Remote sync failed for $sourceName, using fallback: $e');
      // Ensure we have SOMETHING loaded (Cache already loaded above, or Asset)
      if (getConfig(sourceName) == null) {
        await _loadFromAsset(sourceName, assetPath, updateConfig);
      }
    }
  }

  Future<void> _tryUpdateRemote(
    String sourceName,
    String remoteUrl,
    String? currentVersion,
    String cacheKey,
    Function(Map<String, dynamic>) updateConfig,
    SharedPreferences prefs,
  ) async {
    try {
      _logger.d('Checking updates for $sourceName (Current: $currentVersion)');
      final response = await _dio.get(
        remoteUrl,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final newData = response.data as Map<String, dynamic>;
        final newVersion = newData['version'] as String?;

        if (newVersion != currentVersion) {
          _logger.i(
              '🚀 Update found for $sourceName: $currentVersion -> $newVersion');
          updateConfig(newData);
          await prefs.setString(cacheKey, jsonEncode(newData));
          await prefs.setInt(
              _lastCheckedKey, DateTime.now().millisecondsSinceEpoch);
        } else {
          _logger.d('✅ $sourceName is up to date ($currentVersion)');
          // Still update timestamp to show we checked
          await prefs.setInt(
              _lastCheckedKey, DateTime.now().millisecondsSinceEpoch);
        }
      }
    } catch (e) {
      // Silent fail on update check, keep using cache
      _logger.w('Failed to check validation for $sourceName: $e');
    }
  }

  Future<void> _fetchAndCache(
    String sourceName,
    String remoteUrl,
    String cacheKey,
    Function(Map<String, dynamic>) updateConfig,
    SharedPreferences prefs,
  ) async {
    _logger.d('Fetching fresh config for $sourceName');
    final response = await _dio.get(
      remoteUrl,
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout:
            const Duration(seconds: 10), // Longer timeout for fresh fetch
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      updateConfig(data);
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setInt(
          _lastCheckedKey, DateTime.now().millisecondsSinceEpoch);
      _logger.i('✅ Successfully fetched initial $sourceName config');
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Invalid status code: ${response.statusCode}',
      );
    }
  }

  Future<void> _loadFromAsset(
    String sourceName,
    String assetPath,
    Function(Map<String, dynamic>) updateConfig,
  ) async {
    _logger.d('Loading fallback asset for $sourceName');
    final assetString = await rootBundle.loadString(assetPath);
    final data = jsonDecode(assetString) as Map<String, dynamic>;
    updateConfig(data);
  }

  SourceConfig? getConfig(String source) {
    if (source == 'nhentai') return _nhentaiConfig;
    if (source == 'crotpedia') return _crotpediaConfig;
    return null;
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
