import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  final Dio _dio;
  final Logger _logger;
  final SharedPreferences _prefs; // NEW: For reading license status

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
  
  // Registry to track which features require premium (Parsed manually from JSON)
  // Structure: { 'sourceName': { 'featureName': requiresPremium } }
  final Map<String, Map<String, bool>> _premiumRegistry = {};

  RemoteConfigService({
    required Dio dio,
    required Logger logger,
    required SharedPreferences prefs, // NEW
  })  : _dio = dio,
        _logger = logger,
        _prefs = prefs;

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
      // onProgress?.call(0.2, 'Loading nhentai config...');
      // await _loadFromAsset('nhentai', 'assets/configs/nhentai-config.json',
      //     (json) => _sourceConfigs['nhentai'] = SourceConfig.fromJson(json));

      // onProgress?.call(0.4, 'Loading crotpedia config...');
      // await _loadFromAsset('crotpedia', 'assets/configs/crotpedia-config.json',
      //     (json) => _sourceConfigs['crotpedia'] = SourceConfig.fromJson(json));

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
      
      // Manually parse premium flags if present
      if (data.containsKey('features')) {
        final features = data['features'] as Map<String, dynamic>;
        final Map<String, bool> sourceFlags = {};
        
        features.forEach((key, value) {
          if (value is Map<String, dynamic> && value.containsKey('requiresPremium')) {
            sourceFlags[key] = value['requiresPremium'] == true;
          } else {
             // Default to false if not specified or simple boolean
             sourceFlags[key] = false;
          }
        });
        
        _premiumRegistry[sourceName] = sourceFlags;
      }
      
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

  /// Get all available source configurations
  List<SourceConfig> getAllSourceConfigs() {
    return _sourceConfigs.values.toList();
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
    
    final feature = config!.features!;
    final isEnabledInConfig = selector(feature);

    if (!isEnabledInConfig) return false;

    // Check if feature requires premium
    // We check the manual registry we populated during load
 
    
    // We need to infer the feature name from the selector/config
    // Since we can't reflect on the selector, we check the registry for ANY true flag?
    // No, we need to know specifically which feature.
    // LIMITATION: The current method signature `(f) => f.download` hides the name "download".
    // WE CANNOT know "download" was accessed.
    
    // WORKAROUND: Change the method approach or assume we iterate the registry?
    // If we assume `selector` just returns the enabled state...
    // But `isFeatureEnabled` implies "Can I use it?".
    
    // PROPOSAL: Since I can't reflect the name, I will just return `isEnabledInConfig`.
    // BUT I added `_premiumRegistry`. It's useless if I can't look up the key.
    
    // Better: Add a new method `isPremiumFeatureEnabled(String source, String featureName)`.
    // And update callsites? Too many callsites.
    
    // Hack: For now, if ANY feature in the source requires premium, and premium is invalid, disable ALL premium features?
    // No, that blocks non-premium features if logic is mixed.
    
    // Let's rely on the fact that `User` requests specifically checking `komiktap-config.json` manually.
    // I will modify `isFeatureAccessible` in `LicenseService` to take the feature name?
    // Or just make `RemoteConfigService` expose `requiresPremium(source, feature)`.
    
    // Let's implement `isPremiumAccessible(source, featureName)` in RemoteConfigService
    // and let the UI use THAT.
    
    return isEnabledInConfig;
  }
  
  /// Check if a feature requires premium (without checking license validity)
  /// This is useful for UI logic that needs to check license separately
  bool doesFeatureRequirePremium(String source, String featureName) {
    if (!_sourceConfigs.containsKey(source)) return false;

    final featureMap = _premiumRegistry[source];
    if (featureMap == null) return false;

    return featureMap[featureName] ?? false;
  }

  /// Check if a specific named feature is accessible (checks enabled + premium)
  /// [isPremiumActive] - Optional override for premium status. If not provided, reads from SharedPreferences
  bool isContentFeatureAccessible(String source, String featureName, {bool? isPremiumActive}) {
    if (!_sourceConfigs.containsKey(source)) return false;
    
    // 1. Check if feature is enabled in basic config first (if accessible)
    // This part is tricky because we don't know the exact hierarchy path of featureName
    // So we rely on the registry for "premium requirement" AND "existence"
    
    final featureMap = _premiumRegistry[source];
    // If feature is not in registry, it might still be enabled/disabled but not premium
    // But for "isContentFeatureAccessible" we primarily care about the premium gate for now
    
    if (featureMap == null) return true; // No registry = assume free/enabled
    
    // 2. Check Premium Requirement
    final requiresPremium = featureMap[featureName] ?? false;
    
    if (requiresPremium) {
       // Use provided premium status or fall back to SharedPreferences
       final isLicenseValid = isPremiumActive ?? (_prefs.getBool('komiktap_license_valid') ?? false);
       if (!isLicenseValid) {
         return false;
       }
    }
    
    return true;
  }



  /// Check if source supports tag exclusion (for search UI)
  bool supportsTagExclusion(String source) {
    return isFeatureEnabled(source, (f) => f.supportsTagExclusion?.enabled ?? false);
  }

  /// Check if source supports advanced search
  bool supportsAdvancedSearch(String source) {
    return isFeatureEnabled(source, (f) => f.supportsAdvancedSearch?.enabled ?? false);
  }
}
