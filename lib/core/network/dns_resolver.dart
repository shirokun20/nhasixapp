import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dns_models.dart';
import 'dns_settings_service.dart';

/// DNS resolver with DNS-over-HTTPS support
class DnsResolver {
  late final Dio _dio;
  final DnsSettingsService _settingsService;
  final Logger _logger;

  /// Cache for DNS lookups with TTL
  final Map<String, _CachedDnsResult> _cache = {};

  /// Cache TTL duration
  static const Duration cacheTtl = Duration(minutes: 5);

  DnsResolver({
    required DnsSettingsService settingsService,
    required Logger logger,
  })  : _settingsService = settingsService,
        _logger = logger {
    // Create a standalone Dio instance for DoH requests
    // This breaks the circular dependency with HttpClientManager
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
    ));
  }

  /// Lookup DNS A records for hostname
  /// Returns list of IP addresses
  Future<List<InternetAddress>> lookup(String host) async {
    final settings = _settingsService.currentSettings;

    // Use system DNS if DoH is disabled or provider is system
    if (!settings.enabled || settings.provider == DnsProvider.system) {
      return _systemLookup(host);
    }

    // Check cache first
    final cached = _cache[host];
    if (cached != null && !cached.isExpired) {
      _logger.d('DNS cache hit for $host');
      return cached.addresses;
    }

    try {
      // Perform DoH lookup
      final addresses = await _performDohLookup(host, settings);
      
      // Cache result
      _cache[host] = _CachedDnsResult(addresses);
      _logger.d('DNS resolved $host to ${addresses.length} addresses via DoH');
      
      return addresses;
    } catch (e) {
      _logger.w('DoH lookup failed for $host, falling back to system DNS', error: e);
      
      // Fallback to system DNS on error
      return _systemLookup(host);
    }
  }

  /// Perform DNS-over-HTTPS lookup
  Future<List<InternetAddress>> _performDohLookup(
    String host,
    DnsSettings settings,
  ) async {
    final dohUrl = settings.effectiveDohUrl;

    if (dohUrl.isEmpty) {
      throw Exception('DoH URL not configured');
    }

    // Make DoH request (DNS JSON API format)
    final response = await _dio.get(
      dohUrl,
      queryParameters: {
        'name': host,
        'type': 'A', // IPv4 only for now
      },
      options: Options(
        headers: {'Accept': 'application/dns-json'},
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    // Parse response
    final data = response.data as Map<String, dynamic>;
    final answers = data['Answer'] as List?;

    if (answers == null || answers.isEmpty) {
      throw Exception('No DNS answers received for $host');
    }

    // Extract A records (type 1)
    final addresses = answers
        .where((answer) => answer['type'] == 1)
        .map((answer) {
          final ip = answer['data'] as String;
          return InternetAddress(ip);
        })
        .toList();

    if (addresses.isEmpty) {
      throw Exception('No A records found for $host');
    }

    return addresses;
  }

  /// System DNS lookup (fallback)
  Future<List<InternetAddress>> _systemLookup(String host) async {
    try {
      return await InternetAddress.lookup(host);
    } catch (e) {
      _logger.e('System DNS lookup failed for $host', error: e);
      rethrow;
    }
  }

  /// Clear DNS cache
  void clearCache() {
    _cache.clear();
    _logger.i('DNS cache cleared');
  }

  /// Clear cache entry for specific host
  void clearCacheFor(String host) {
    _cache.remove(host);
    _logger.d('DNS cache cleared for $host');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final total = _cache.length;
    final expired = _cache.values.where((entry) => entry.isExpired).length;
    final fresh = total - expired;

    return {
      'total_entries': total,
      'fresh_entries': fresh,
      'expired_entries': expired,
    };
  }
}

/// Cached DNS result with TTL
class _CachedDnsResult {
  final List<InternetAddress> addresses;
  final DateTime timestamp;

  _CachedDnsResult(this.addresses) : timestamp = DateTime.now();

  /// Check if cache entry is expired
  bool get isExpired {
    final age = DateTime.now().difference(timestamp);
    return age > DnsResolver.cacheTtl;
  }
}
