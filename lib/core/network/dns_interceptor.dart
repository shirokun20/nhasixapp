import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'dns_resolver.dart';

/// DNS-over-HTTPS Interceptor
/// Resolves DNS before making requests, replacing hostname with IP
/// while preserving original hostname in Host header for SNI
class DnsInterceptor extends Interceptor {
  final DnsResolver _dnsResolver;
  final Logger _logger;

  DnsInterceptor({
    required DnsResolver dnsResolver,
    required Logger logger,
  })  : _dnsResolver = dnsResolver,
        _logger = logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;
    
    // Skip DNS resolution for IP addresses
    if (_isIpAddress(uri.host)) {
      return handler.next(options);
    }

    try {
      // Resolve DNS using DoH
      _logger.d('Resolving ${uri.host} via DoH...');
      final addresses = await _dnsResolver.lookup(uri.host);

      if (addresses.isEmpty) {
        throw DioException(
          requestOptions: options,
          error: 'DNS resolution failed for ${uri.host}',
          type: DioExceptionType.unknown,
        );
      }

      // Use first resolved IP address
      final resolvedIp = addresses.first.address;
      _logger.d('Resolved ${uri.host} to $resolvedIp');

      // Replace host with IP in URL
      final resolvedUri = uri.replace(host: resolvedIp);
      
      // Update request with resolved IP
      options.path = resolvedUri.toString();
      
      // Preserve original hostname in Host header for SNI and virtual hosting
      options.headers[HttpHeaders.hostHeader] = uri.host;

      handler.next(options);
    } catch (e) {
      _logger.w('DoH resolution failed for ${uri.host}, using system DNS', error: e);
      // Fallback to default behavior (system DNS)
      handler.next(options);
    }
  }

  /// Check if string is an IP address
  bool _isIpAddress(String host) {
    try {
      InternetAddress(host);
      return true;
    } catch (_) {
      return false;
    }
  }
}
