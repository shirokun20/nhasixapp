import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dns_models.dart';
import 'dns_settings_service.dart';

class DnsResolver {
  late final Dio _dio;
  final DnsSettingsService _settingsService;
  final Logger _logger;

  final Map<String, _CachedDnsResult> _cache = {};

  static const Duration cacheTtl = Duration(minutes: 5);

  DnsResolver({
    required DnsSettingsService settingsService,
    required Logger logger,
  })  : _settingsService = settingsService,
        _logger = logger {
    // This breaks the circular dependency with HttpClientManager
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
    ));
  }

  Future<List<InternetAddress>> lookup(String host) async {
    final settings = _settingsService.currentSettings;

    if (!settings.enabled || settings.provider == DnsProvider.system) {
      return _systemLookup(host);
    }

    final cached = _cache[host];
    if (cached != null && !cached.isExpired) {
      _logger.d('DNS cache hit for $host');
      return cached.addresses;
    }

    try {
      final addresses = await _performDohLookup(host, settings);

      _cache[host] = _CachedDnsResult(addresses);
      _logger.d('DNS resolved $host to ${addresses.length} addresses via DoH');

      return addresses;
    } catch (e) {
      _logger.w('DoH lookup failed for $host, falling back to system DNS',
          error: e);

      return _systemLookup(host);
    }
  }

  Future<List<InternetAddress>> _performDohLookup(
    String host,
    DnsSettings settings,
  ) async {
    final dohUrl = settings.effectiveDohUrl;

    if (dohUrl.isEmpty) {
      throw Exception('DoH URL not configured');
    }

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

    final data = response.data as Map<String, dynamic>;
    final answers = data['Answer'] as List?;

    if (answers == null || answers.isEmpty) {
      throw Exception('No DNS answers received for $host');
    }

    // Extract A records (type 1)
    final addresses =
        answers.where((answer) => answer['type'] == 1).map((answer) {
      final ip = answer['data'] as String;
      return InternetAddress(ip);
    }).toList();

    if (addresses.isEmpty) {
      throw Exception('No A records found for $host');
    }

    return addresses;
  }

  Future<List<InternetAddress>> _systemLookup(String host) async {
    try {
      return await InternetAddress.lookup(host);
    } catch (e) {
      _logger.e('System DNS lookup failed for $host', error: e);
      rethrow;
    }
  }

  void clearCache() {
    _cache.clear();
    _logger.i('DNS cache cleared');
  }

  void clearCacheFor(String host) {
    _cache.remove(host);
    _logger.d('DNS cache cleared for $host');
  }

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

class _CachedDnsResult {
  final List<InternetAddress> addresses;
  final DateTime timestamp;

  _CachedDnsResult(this.addresses) : timestamp = DateTime.now();

  bool get isExpired {
    final age = DateTime.now().difference(timestamp);
    return age > DnsResolver.cacheTtl;
  }
}
