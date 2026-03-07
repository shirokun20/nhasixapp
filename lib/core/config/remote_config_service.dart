import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for loading, caching and refreshing source configs.
///
/// ### Storage layers (highest priority first)
/// 1. **AppDocDir/configs/** — Downloaded/cached configs (writable, override bundled)
/// 2. **assets/configs/** — Bundled defaults (read-only, always present)
/// 3. **Hardcoded defaults** — Last-resort constants
///
/// ### Manifest-driven sync
/// On [smartInitialize] the service:
/// 1. Downloads `manifest.json` from [_manifestUrl] (5 s timeout).
/// 2. For each source in the manifest: compares manifest version vs cached
///    version in SharedPreferences. If different, downloads new config.
/// 3. Falls back to bundled asset if download fails.
///
/// Config is intentionally **not time-expiring** — invalidation is purely
/// version-driven (bumping version in manifest triggers re-download).
class RemoteConfigService {
  final Dio _dio;
  final Logger _logger;

  // ── CDN / remote URLs ───────────────────────────────────────────────────────

  /// CDN base URL for the config repo. All relative `url` fields in the
  /// manifest are resolved against this.
  static const String _cdnBase =
      'https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/master/app';

  static const String _manifestUrl = '$_cdnBase/manifest.json';

  // Legacy tags URLs (kept for backward compatibility)
  static const String _tagsBaseUrl =
      'https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/configs/configs/tags';
  static const String _nhentaiTagsUrl = '$_tagsBaseUrl/tags_nhentai.json';
  static const String _crotpediaTagsUrl = '$_tagsBaseUrl/tags_crotpedia.json';

  // ── Asset paths ──────────────────────────────────────────────────────────────

  static const String _assetConfigBase = 'assets/configs';
  static const String _tagsAssetPath = '$_assetConfigBase/tags-config.json';

  /// Bundled asset path for each **bundled** source.
  ///
  /// Only `nhentai` is bundled into the APK as a permanent default — it is
  /// always available without network. Other sources load via CDN/remote.
  static const Map<String, String> _bundledAssetPaths = {
    'nhentai': '$_assetConfigBase/nhentai-config.json',
    'app': '$_assetConfigBase/app-config.json',
    'tags': _tagsAssetPath,
  };

  /// Source IDs that are bundled into the APK and always available.
  static const Set<String> _bundledSourceIds = {'nhentai'};

  // ── SharedPreferences keys ───────────────────────────────────────────────────

  static const String _prefManifestVersion = 'config_manifest_version';
  static const String _prefLastSyncMs = 'config_last_sync_timestamp';

  /// Cached version for a specific source: "config_version_{sourceId}"
  static String _prefSourceVersion(String sourceId) =>
      'config_version_$sourceId';

  // Legacy tag cache keys
  static const String _nhentaiTagsCacheKey = 'tags_cache_nhentai';
  static const String _crotpediaTagsCacheKey = 'tags_cache_crotpedia';

  // ── In-memory state ──────────────────────────────────────────────────────────

  AppConfig? _appConfig;
  TagsManifest? _tagsManifest;
  SourceManifest? _manifest;
  final Map<String, SourceConfig> _sourceConfigs = {};
  final Map<String, Map<String, dynamic>> _rawSourceConfigs = {};

  // ── Constructor ──────────────────────────────────────────────────────────────

  RemoteConfigService({required Dio dio, required Logger logger})
      : _dio = dio,
        _logger = logger;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialise config using the Smart Sync strategy.
  ///
  /// [isFirstRun] — when true, a critical failure rethrows the exception.
  /// [onProgress] — optional 0.0–1.0 progress callback.
  Future<void> smartInitialize({
    bool isFirstRun = false,
    void Function(double progress, String message)? onProgress,
  }) async {
    _logger.i('RemoteConfigService: starting smartInitialize…');

    try {
      final configDir = await _getConfigDirectory();
      onProgress?.call(0.05, 'Checking remote manifest…');

      // Preload guaranteed bundled defaults first so critical sources like
      // nhentai are always available, even if manifest/installable parsing fails.
      await _loadSourceFromBundledFallback('nhentai');
      await _loadSourceFromBundledFallback('app');

      // Step 1 — try to download and apply the remote manifest
      SourceManifest? manifest;
      try {
        manifest = await _downloadManifest(configDir);
        _manifest = manifest;
        _logger.i(
            'Manifest fetched: ${manifest.installableSources.length} installable sources');
      } catch (e) {
        _logger.w('Manifest download failed, using bundled configs', error: e);
      }

      final double progressPerSource = manifest != null ? 0.7 / 2 : 0.7 / 2;

      double progress = 0.1;

      if (manifest != null) {
        // Step 2 — do NOT auto-sync installable sources here.
        // Installable sources are only downloaded when user explicitly clicks
        // "Install" in Settings. This allows the app to load faster and respects
        // user choice about which providers to activate.

        // Step 3 — sync app config
        if (manifest.appConfig != null) {
          onProgress?.call(progress, 'Loading app config…');
          await _syncAppConfig(manifest.appConfig!, configDir);
          progress += progressPerSource;
        }

        // Safety net: bundled sources must always be available even when
        // manifest intentionally lists only installable providers.
        for (final bundledId in _bundledSourceIds) {
          if (!_rawSourceConfigs.containsKey(bundledId)) {
            _logger.w(
              'Bundled source "$bundledId" not present after manifest sync; loading asset fallback',
            );
            await _loadSourceFromBundledFallback(bundledId);
          }
        }

        // Ensure app config exists as fallback if manifest omits appConfig.
        if (_appConfig == null && !_rawSourceConfigs.containsKey('app')) {
          _logger.w(
            'App config missing after manifest sync; loading bundled app config',
          );
          await _loadSourceFromBundledFallback('app');
        }
      } else {
        // Fallback: load only bundled configs (nhentai + app).
        // Installable sources require the manifest to know which ones are
        // installed; without it we cannot safely load them.
        for (final sourceId in ['nhentai', 'app']) {
          onProgress?.call(progress, 'Loading $sourceId config…');
          await _loadSourceFromBundledFallback(sourceId);
          progress += progressPerSource;
        }
      }

      // Tags manifest is always loaded from asset (it's metadata, not config)
      onProgress?.call(0.85, 'Loading tags config…');
      await _loadTagsManifest();

      // Attempt a background self-refresh for every source that carries a
      // configUrl field but wasn't covered by the CDN manifest (or the
      // manifest didn't update it). This keeps installable/dev configs fresh
      // without requiring a full manifest bump.
      onProgress?.call(0.92, 'Checking source self-updates…');
      await _selfRefreshAllFromConfigUrl(manifest);

      // Persist sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _prefLastSyncMs, DateTime.now().millisecondsSinceEpoch);

      onProgress?.call(1.0, 'Config ready');
      _logger.i(
          '✅ RemoteConfigService ready — ${_sourceConfigs.length} sources loaded');
    } catch (e) {
      _logger.e('RemoteConfigService initialisation failed', error: e);
      if (isFirstRun) rethrow;
    }
  }

  // Getters ──────────────────────────────────────────────────────────────────

  SourceConfig? getConfig(String source) => _sourceConfigs[source];

  List<SourceConfig> getAllSourceConfigs() =>
      _sourceConfigs.values.where((c) => c.enabled).toList();

  /// All source configs including disabled ones (used by admin UI).
  List<SourceConfig> getAllSourceConfigsRaw() => _sourceConfigs.values.toList();

  AppConfig? get appConfig => _appConfig;
  TagsManifest? get tagsManifest => _tagsManifest;
  SourceManifest? get manifest => _manifest;

  Map<String, dynamic>? getRawConfig(String source) =>
      _rawSourceConfigs[source];

  /// Ensures `manifest.json` is available in memory.
  ///
  /// If the manifest has not been loaded yet, this attempts a fresh download.
  /// Returns `null` when loading fails.
  Future<SourceManifest?> ensureManifestLoaded() async {
    if (_manifest != null) return _manifest;

    try {
      final configDir = await _getConfigDirectory();
      _manifest = await _downloadManifest(configDir);
      return _manifest;
    } catch (e) {
      _logger.w('Failed to ensure manifest is loaded', error: e);
      return null;
    }
  }

  /// Manually register a source config (used for testing/generic sources)
  void registerSourceConfig(String sourceId, Map<String, dynamic> rawConfig) {
    try {
      _rawSourceConfigs[sourceId] = rawConfig;
      _sourceConfigs[sourceId] = SourceConfig.fromJson(rawConfig);
      _logger.d('Manually registered config for $sourceId');
    } catch (e) {
      _logger.e('Failed to register config for $sourceId', error: e);
      rethrow;
    }
  }

  RateLimitConfig getRateLimitConfig(String source) =>
      getConfig(source)?.network?.rateLimit ??
      RateLimitConfig(requestsPerMinute: 30, minDelayMs: 1500);

  bool isFeatureEnabled(String source, bool Function(FeatureConfig) selector) {
    final config = getConfig(source);
    if (config?.features == null) {
      final raw = _rawSourceConfigs[source];
      if (raw != null && raw['features'] != null) {
        try {
          final featureConfig =
              FeatureConfig.fromJson(raw['features'] as Map<String, dynamic>);
          return selector(featureConfig);
        } catch (_) {}
      }
      return false;
    }
    return selector(config!.features!);
  }

  /// Returns `true` when [featureName] is enabled and **not** under maintenance.
  bool isFeatureAvailable(String source, String featureName) {
    final features = getConfig(source)?.features;
    if (features == null) return false;
    final maintenance = features.maintenanceFeatures?[featureName];
    if (maintenance?.active == true) return false;
    return switch (featureName) {
      'comments' => features.comments,
      'related' => features.related,
      'download' => features.download,
      'favorite' => features.favorite,
      'chapters' => features.chapters,
      'bookmark' => features.bookmark,
      'search' => features.search,
      'generatePdf' => features.generatePdf,
      'offlineMode' => features.offlineMode,
      _ => false,
    };
  }

  /// Returns the [MaintenanceInfo] for [featureName] if it is currently under
  /// maintenance, otherwise `null`.
  MaintenanceInfo? getFeatureMaintenance(String source, String featureName) {
    final info = getConfig(source)?.features?.maintenanceFeatures?[featureName];
    return (info?.active == true) ? info : null;
  }

  bool supportsTagExclusion(String source) =>
      isFeatureEnabled(source, (f) => f.supportsTagExclusion);

  bool supportsAdvancedSearch(String source) =>
      isFeatureEnabled(source, (f) => f.supportsAdvancedSearch);

  Future<bool> hasValidCache(String source) async =>
      _sourceConfigs.containsKey(source);

  /// Attempts to refresh a source config from its own embedded `configUrl`
  /// field (self-describing CDN reference).
  ///
  /// This is called by `GenericHttpSource` during initialization so each
  /// source can describe its own update endpoint, independent of the CDN
  /// manifest. The config is refreshed only if the remote version string
  /// differs from the currently loaded one.
  ///
  /// Returns `true` if the config was refreshed, `false` otherwise.
  Future<bool> refreshSourceFromConfigUrl(String sourceId) async {
    final raw = _rawSourceConfigs[sourceId];
    final dynamic rawConfigUrl = raw?['configUrl'];
    final configUrl = rawConfigUrl is String ? rawConfigUrl : null;
    if (configUrl == null || configUrl.isEmpty) {
      _logger.d('$sourceId: no configUrl field — skipping self-refresh');
      return false;
    }

    _logger.i('$sourceId: attempting self-refresh from $configUrl');
    try {
      final response = await _dio.get<String>(
        configUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          responseType: ResponseType.plain,
        ),
      );

      final rawJson = response.data;
      if (rawJson == null) return false;

      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final remoteVersion = decoded['version'] as String?;
      final localVersion = raw?['version'] as String?;

      if (remoteVersion == localVersion) {
        _logger.d(
            '$sourceId: configUrl version $remoteVersion == local — no update');
        return false;
      }

      // Persist to AppDocDir so it survives app restarts.
      final configDir = await _getConfigDirectory();
      final cachedFile = File(p.join(configDir.path, '$sourceId-config.json'));
      await cachedFile.writeAsString(rawJson);

      // Also update the version pref so manifest sync skips re-download.
      if (remoteVersion != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefSourceVersion(sourceId), remoteVersion);
      }

      _rawSourceConfigs[sourceId] = decoded;
      _sourceConfigs[sourceId] = SourceConfig.fromJson(decoded);

      _logger.i(
          '✅ $sourceId refreshed via configUrl: $localVersion → $remoteVersion');
      return true;
    } catch (e) {
      _logger.w('$sourceId: configUrl refresh failed — keeping existing config',
          error: e);
      return false;
    }
  }

  /// Downloads a source config from an explicit URL and applies it instantly.
  ///
  /// This is intended for developer/admin flows (for example from Settings)
  /// when testing a raw GitHub URL before the config is published to CDN.
  ///
  /// The downloaded JSON is validated and then:
  /// - saved into `AppDocDir/configs/{sourceId}-config.json`
  /// - loaded into in-memory maps (`_rawSourceConfigs`, `_sourceConfigs`)
  /// - version is persisted to SharedPreferences when available
  Future<SourceConfig> downloadAndApplySourceConfig({
    required String sourceId,
    required String url,
  }) async {
    _logger
        .i('Downloading source config for $sourceId from explicit URL: $url');

    final response = await _dio.get<String>(
      url,
      options: Options(
        receiveTimeout: const Duration(seconds: 12),
        responseType: ResponseType.plain,
      ),
    );

    final rawJson = response.data;
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw const FormatException('Downloaded config is empty');
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

    final declaredSource = decoded['source'] as String?;
    if (declaredSource == null || declaredSource.isEmpty) {
      throw const FormatException('Config is missing required "source" field');
    }
    if (declaredSource != sourceId) {
      throw FormatException(
        'Source mismatch: expected "$sourceId" but got "$declaredSource"',
      );
    }

    final parsed = SourceConfig.fromJson(decoded);

    final configDir = await _getConfigDirectory();
    final cachedFile = File(p.join(configDir.path, '$sourceId-config.json'));
    await cachedFile.writeAsString(rawJson);

    final version = decoded['version'] as String?;
    if (version != null && version.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefSourceVersion(sourceId), version);
    }

    _rawSourceConfigs[sourceId] = decoded;
    _sourceConfigs[sourceId] = parsed;

    _logger.i(
        '✅ Applied source config from URL for $sourceId (v${version ?? 'unknown'})');
    return parsed;
  }

  /// Downloads and applies source config using manifest entry (URL + version).
  ///
  /// Caller only needs to provide `sourceId`; this method resolves source URL
  /// from `manifest.json`, downloads it, caches it, and updates in-memory maps.
  Future<SourceConfig?> downloadAndApplySourceConfigFromManifest({
    required String sourceId,
  }) async {
    final manifest = await ensureManifestLoaded();
    if (manifest == null) {
      throw StateError('manifest.json is not available');
    }

    SourceManifestEntry? targetEntry;
    for (final entry in manifest.installableSources) {
      if (entry.id == sourceId) {
        targetEntry = entry;
        break;
      }
    }

    if (targetEntry == null) {
      throw StateError('Source "$sourceId" not found in manifest.json');
    }

    final resolvedUrl = _resolveUrl(targetEntry.url);
    final response = await _dio.get<String>(
      '$resolvedUrl?v=${targetEntry.version}',
      options: Options(
        receiveTimeout: const Duration(seconds: 12),
        responseType: ResponseType.plain,
      ),
    );

    final rawJson = response.data;
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw const FormatException(
          'Downloaded config from manifest URL is empty');
    }

    if (targetEntry.checksum != null && targetEntry.checksum!.isNotEmpty) {
      _validateChecksum(rawJson, targetEntry.checksum!, sourceId);
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final declaredSource = decoded['source'] as String?;
    if (declaredSource == null || declaredSource.isEmpty) {
      throw const FormatException('Config is missing required "source" field');
    }
    if (declaredSource != sourceId) {
      throw FormatException(
        'Source mismatch: expected "$sourceId" but got "$declaredSource"',
      );
    }

    SourceConfig? parsed;
    try {
      parsed = SourceConfig.fromJson(decoded);
    } catch (e, stackTrace) {
      _logger.w(
        'Typed SourceConfig parse failed for $sourceId; raw config kept for runtime adapter compatibility',
        error: e,
        stackTrace: stackTrace,
      );
    }

    final configDir = await _getConfigDirectory();
    final cachedFile = File(p.join(configDir.path, '$sourceId-config.json'));
    await cachedFile.writeAsString(rawJson);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSourceVersion(sourceId), targetEntry.version);

    _rawSourceConfigs[sourceId] = decoded;
    if (parsed != null) {
      _sourceConfigs[sourceId] = parsed;
    }

    _logger.i(
      '✅ Applied source config from manifest for $sourceId (v${targetEntry.version})',
    );
    return parsed;
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefLastSyncMs);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ─── Tags (legacy) ──────────────────────────────────────────────────────────

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
        final String jsonString = response.data is String
            ? response.data as String
            : jsonEncode(response.data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonString);
        await prefs.setInt(
            '${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
        _logger.i('✅ Tags downloaded and cached for $source');
      }
    } catch (e) {
      _logger.e('Error downloading tags for $source', error: e);
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedTags(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') return null;
    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      _logger.w('Failed to load cached tags for $source', error: e);
    }
    return null;
  }

  Future<bool> hasTagsCache(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') return false;
    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(cacheKey);
  }

  Future<int?> getTagsCacheAge(String source) async {
    if (source != 'nhentai' && source != 'crotpedia') return null;
    final cacheKey =
        source == 'nhentai' ? _nhentaiTagsCacheKey : _crotpediaTagsCacheKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('${cacheKey}_timestamp');
      if (ts != null) {
        return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts))
            .inDays;
      }
    } catch (e) {
      _logger.w('Failed to get cache age for $source', error: e);
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns (or creates) the writable config directory in AppDocDir.
  Future<Directory> _getConfigDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final configDir = Directory(p.join(docDir.path, 'configs'));
    if (!configDir.existsSync()) {
      await configDir.create(recursive: true);
    }
    return configDir;
  }

  /// Download and parse `manifest.json` from CDN. Saves to [configDir].
  Future<SourceManifest> _downloadManifest(Directory configDir) async {
    final response = await _dio.get<String>(
      _manifestUrl,
      options: Options(
        receiveTimeout: const Duration(seconds: 5),
        responseType: ResponseType.plain,
      ),
    );

    final rawJson = response.data!;
    final manifestFile = File(p.join(configDir.path, 'manifest.json'));
    await manifestFile.writeAsString(rawJson);

    final manifest =
        SourceManifest.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefManifestVersion, manifest.schemaVersion.toString());

    return manifest;
  }

  /// Sync app-config.json from CDN.
  Future<void> _syncAppConfig(
      SourceManifestAppEntry entry, Directory configDir) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_prefSourceVersion('app'));
    final cachedFile = File(p.join(configDir.path, 'app-config.json'));

    if (cachedVersion == entry.version && cachedFile.existsSync()) {
      _logger.d('Using cached app config v${entry.version}');
      final raw = jsonDecode(await cachedFile.readAsString());
      _appConfig = AppConfig.fromJson(raw as Map<String, dynamic>);
      return;
    }

    final configUrl = _resolveUrl(entry.url);
    try {
      final response = await _dio.get<String>(
        '$configUrl?v=${entry.version}',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          responseType: ResponseType.plain,
        ),
      );
      final rawJson = response.data!;
      await cachedFile.writeAsString(rawJson);
      await prefs.setString(_prefSourceVersion('app'), entry.version);
      _appConfig =
          AppConfig.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (e) {
      _logger.w('App config download failed, using bundled', error: e);
      await _loadSourceFromBundledFallback('app');
    }
  }

  /// Load a config from bundled assets (last resort).
  Future<void> _loadSourceFromBundledFallback(String sourceId) async {
    final assetPath = _bundledAssetPaths[sourceId];
    if (assetPath == null) {
      _logger.w('No bundled asset for source: $sourceId');
      return;
    }
    try {
      final assetString = await rootBundle.loadString(assetPath);
      final raw = jsonDecode(assetString) as Map<String, dynamic>;
      _rawSourceConfigs[sourceId] = raw;
      if (sourceId == 'app') {
        _appConfig = AppConfig.fromJson(raw);
      } else if (sourceId != 'tags') {
        try {
          _sourceConfigs[sourceId] = SourceConfig.fromJson(raw);
        } catch (e) {
          _logger.w(
            'Typed SourceConfig parse failed for bundled source $sourceId; raw config kept',
            error: e,
          );
        }
      }
      _logger.d('Loaded bundled config for $sourceId');
    } catch (e) {
      _logger.w('Bundled asset load failed for $sourceId', error: e);
    }
  }

  Future<void> _loadTagsManifest() async {
    try {
      final assetString = await rootBundle.loadString(_tagsAssetPath);
      _tagsManifest = TagsManifest.fromJson(
          jsonDecode(assetString) as Map<String, dynamic>);
    } catch (e) {
      _logger.w('Tags manifest load failed', error: e);
    }
  }

  /// Resolve a relative config URL against the CDN base.
  String _resolveUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) return relativeUrl;
    return '$_cdnBase/$relativeUrl';
  }

  /// Validate SHA-256 checksum of [content].
  void _validateChecksum(String content, String expected, String sourceId) {
    final actual = 'sha256:${sha256.convert(utf8.encode(content)).toString()}';
    if (actual != expected) {
      _logger.w(
          'Checksum mismatch for $sourceId: expected $expected, got $actual');
      // Non-fatal: log and continue — config may still be valid.
    }
  }

  /// For each loaded source that has a `configUrl` field and whose version
  /// was NOT already refreshed by the manifest during this init cycle, try a
  /// lightweight self-refresh.
  ///
  /// Sources that WERE handled by the manifest are skipped — the manifest
  /// sync is authoritative and already fetched the latest version.
  Future<void> _selfRefreshAllFromConfigUrl(SourceManifest? manifest) async {
    // Build a set of source IDs whose versions were handled by the manifest.
    final manifestIds =
        manifest?.installableSources.map((e) => e.id).toSet() ?? {};

    final futures = _rawSourceConfigs.keys
        .where((id) => !manifestIds.contains(id))
        .where((id) {
          final dynamic configUrl = _rawSourceConfigs[id]?['configUrl'];
          return configUrl is String && configUrl.isNotEmpty;
        })
        .map((id) => refreshSourceFromConfigUrl(id))
        .toList();

    if (futures.isEmpty) return;
    await Future.wait(futures, eagerError: false);
  }
}
