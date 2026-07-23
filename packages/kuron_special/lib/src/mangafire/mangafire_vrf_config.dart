class MangaFireVRFConfig {
  final bool enabled;
  final String authType;
  final String captureUrl;
  final String vrfParam;
  final int ttlSeconds;
  final int cacheMaxEntries;
  final List<String> interceptEndpoints;
  final List<String> vrfFreeEndpoints;
  final int captureTimeoutMs;
  final int captureRetryDelayMs;

  const MangaFireVRFConfig({
    this.enabled = false,
    this.authType = '',
    this.captureUrl = 'https://mangafire.to/',
    this.vrfParam = 'vrf',
    this.ttlSeconds = 300,
    this.cacheMaxEntries = 20,
    this.interceptEndpoints = const [
      '/api/titles',
      '/api/chapters',
    ],
    this.vrfFreeEndpoints = const [
      '/api/filter-options',
      '/api/top-titles',
      '/api/me',
    ],
    this.captureTimeoutMs = 15000,
    this.captureRetryDelayMs = 2000,
  });

  factory MangaFireVRFConfig.fromConfigMap(Map<String, dynamic> config) {
    // Safe cast handling _Map<dynamic, dynamic> from JSON decoding
    final rawNetwork = config['network'];
    final network = (rawNetwork is Map
        ? Map<String, dynamic>.from(rawNetwork)
        : <String, dynamic>{});
    final rawAuth = network['auth'];
    final auth = (rawAuth is Map
        ? Map<String, dynamic>.from(rawAuth)
        : <String, dynamic>{});
    final enabled = auth['enabled'] == true && auth['authType'] == 'vrf';
    return MangaFireVRFConfig(
      enabled: enabled,
      authType: auth['authType'] as String? ?? '',
      captureUrl: auth['captureUrl'] as String? ?? 'https://mangafire.to/',
      vrfParam: auth['vrfParam'] as String? ?? 'vrf',
      ttlSeconds: auth['ttlSeconds'] as int? ?? 300,
      cacheMaxEntries: auth['cacheMaxEntries'] as int? ?? 20,
      captureTimeoutMs: auth['captureTimeoutMs'] as int? ?? 15000,
      captureRetryDelayMs: auth['captureRetryDelayMs'] as int? ?? 2000,
      interceptEndpoints:
          (auth['interceptEndpoints'] as List<dynamic>?)?.cast<String>() ??
              const ['/api/titles', '/api/chapters'],
    );
  }

  bool shouldIntercept(String path) {
    if (!enabled) return false;
    if (vrfFreeEndpoints.any((e) => path == e || path.startsWith('$e/'))) {
      return false;
    }
    return interceptEndpoints.any((e) => path == e || path.startsWith('$e/'));
  }
}
