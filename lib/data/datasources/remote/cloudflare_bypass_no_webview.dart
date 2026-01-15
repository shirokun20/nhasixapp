import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

/// Cloudflare bypass implementation without using WebView
class CloudflareBypassNoWebView {
  CloudflareBypassNoWebView({
    required this.httpClient,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final Dio httpClient;
  final Logger _logger;

  static const String baseUrl = 'https://nhentai.net';
  static const Duration maxWaitDuration = Duration(seconds: 5);
  static const Duration retryInterval = Duration(seconds: 3);

  /// Attempt to bypass Cloudflare protection without WebView
  Future<bool> attemptBypass() async {
    // Only Android platform is supported
    if (kIsWeb || Platform.isIOS || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _logger.e('CloudflareBypass only supported on Android platform');
      throw UnsupportedError('Kuron is only supported on Android devices. Current platform: ${Platform.operatingSystem}');
    }

    _logger.i('Starting Cloudflare bypass without WebView...');

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < maxWaitDuration) {
      try {
        final response = await httpClient.get(
          baseUrl,
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (!isCloudflareChallenge(response.data)) {
          _logger.i('Cloudflare bypass successful without WebView');
          _extractCookiesFromResponse(response);
          return true;
        } else {
          _logger.w(
              'Cloudflare challenge detected, retrying in ${retryInterval.inSeconds} seconds...');
          await Future.delayed(retryInterval);
        }
      } catch (e) {
        _logger.w('Error during bypass attempt: $e');
        await Future.delayed(retryInterval);
      }
    }

    _logger.w('Cloudflare bypass without WebView failed after timeout');
    return false;
  }

  /// Check if HTML contains Cloudflare challenge
  bool isCloudflareChallenge(String html) {
    final cloudflareIndicators = [
      'Checking your browser before accessing',
      'DDoS protection by Cloudflare',
      'cf-browser-verification',
      'cf-challenge-form',
      'cf-error-details',
      'cloudflare-static',
      'ray-id',
      '__cf_chl_jschl_tk__',
    ];

    final lowerHtml = html.toLowerCase();

    return cloudflareIndicators
        .any((indicator) => lowerHtml.contains(indicator.toLowerCase()));
  }

  /// Extract cookies from response headers and add to HTTP client
  void _extractCookiesFromResponse(Response response) {
    try {
      final setCookieHeaders = response.headers.map['set-cookie'];
      if (setCookieHeaders == null || setCookieHeaders.isEmpty) {
        _logger.w('No set-cookie headers found in response');
        return;
      }

      final cookies = <String>[];
      for (final header in setCookieHeaders) {
        final cookie = header.split(';')[0].trim(); // name=value only
        cookies.add(cookie);
      }

      final cookieHeader = cookies.join('; ');
      httpClient.options.headers['cookie'] = cookieHeader;
      _logger.i('Extracted cookies and added to HTTP client: $cookieHeader');
    } catch (e) {
      _logger.w('Failed to extract cookies from response: $e');
    }
  }

  /// Clear stored cookies
  void clearCookies() {
    try {
      httpClient.options.headers.remove('cookie');
      _logger.i('Cleared Cloudflare cookies');
    } catch (e) {
      _logger.w('Failed to clear cookies: $e');
    }
  }
}
