import 'dart:async';
import 'dart:io' as io;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';

/// Cloudflare bypass menggunakan Native WebView (KuronNative)
///
/// Menampilkan WebView native activity agar user bisa menyelesaikan Cloudflare challenge atau Login.
/// Cookies akan disinkronisasi antara Dart (Dio) dan Native.
class CrotpediaCloudflareBypass {
  CrotpediaCloudflareBypass({
    required Dio httpClient,
    required GlobalKey<NavigatorState>
        navigatorKey, // Keeping in constructor for compatibility but not using it as field
    Logger? logger,
  })  : _httpClient = httpClient,
        _logger = logger ?? Logger();

  final Dio _httpClient;
  final Logger _logger;

  // ignore: unused_field
  bool _isRunning = false;

  static const String baseUrl = 'https://crotpedia.net';

  /// Attempt bypass menggunakan Native WebView
  Future<bool> attemptBypass({String? targetUrl}) async {
    _isRunning = true;
    try {
      final urlToLoad = targetUrl ?? baseUrl;
      _logger.i('🚀 Memulai Cloudflare bypass Native untuk: $urlToLoad');

      // 1. Clear cookies to ensure fresh start
      await _clearCookies(urlToLoad);

      // 2. Launch Native WebView
      // User instruction: context/UA must MATCH EXACTLY.
      // We let Native WebView use its default System UA, and we sync it back to Dio.
      final result = await KuronNative.instance.showLoginWebView(
        url: urlToLoad,
        successUrlFilters: [],
        initialCookie: null, // Force clean start
        userAgent: null, // Let WebView decide (System Default)
        autoCloseOnCookie: 'cf_clearance', // Auto-close when bypass succeeds
        clearCookies: true, // ✅ FORCE CLEAR COOKIES to avoid stale cf_clearance
      );

      if (result != null && result['success'] == true) {
        final cookies =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        final userAgent = result['userAgent'] as String?;

        _logger.i(
            '✅ Native WebView Selesai. Extracted ${cookies.length} cookies.');
        if (cookies.isNotEmpty) {
          _logger.d('Cookies: ${cookies.join('; ')}');
        }

        // 3. Sync UserAgent & Cookies (CRITICAL: Must match exactly)
        if (userAgent != null) {
          _logger.i('🔄 Syncing User-Agent: $userAgent');
          _updateUserAgent(userAgent);
        } else {
          _logger.w('⚠️ No User-Agent returned from Native!');
        }
        await _saveCookies(cookies, urlToLoad);

        // 4. Verify with Retry (3 attempts)
        for (int i = 0; i < 3; i++) {
          _logger.i('⏳ Verification attempt ${i + 1}/3...');
          if (await areCookiesValid()) {
            return true;
          }
          await Future.delayed(const Duration(seconds: 1));
        }

        _logger.e('❌ Verification failed after 3 attempts.');
        return false;
      }

      return false;
    } catch (e, stack) {
      _logger.e('Native Bypass Error: $e', error: e, stackTrace: stack);
      return false;
    } finally {
      _isRunning = false;
    }
  }

  /// Attempt Login via Native WebView
  ///
  /// Ignores email/password for auto-fill as we use manual native login now.
  /// User manual login is more reliable for Cloudflare sites.
  Future<List<io.Cookie>?> attemptLogin(
      {required String email, required String password}) async {
    _isRunning = true;
    try {
      const loginUrl = 'https://crotpedia.net/login/';

      // Sync cookies
      final initialCookieStr = await _getFormattedCookies(loginUrl);

      final result = await KuronNative.instance.showLoginWebView(
        url: loginUrl,
        // We only auto-close if we detect a dashboard redirect.
        // 'crotpedia.net/' is too risky if it matches the login page itself.
        successUrlFilters: ['/wp-admin', '/dashboard'],
        initialCookie:
            initialCookieStr, // Critical for user session consistency
      );

      if (result != null && result['success'] == true) {
        final cookiesStrList =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        final userAgent = result['userAgent'] as String?;

        if (userAgent != null) _updateUserAgent(userAgent);
        await _saveCookies(cookiesStrList, loginUrl);

        // Helper to return List<io.Cookie> for existing API contract
        // We parse the raw strings "key=value"
        return cookiesStrList.map((str) {
          final parts = str.split('=');
          return io.Cookie(parts[0].trim(),
              parts.length > 1 ? parts.sublist(1).join('=') : '');
        }).toList();
      }

      return null;
    } catch (e) {
      _logger.e('Native Login Failed: $e');
      return null;
    } finally {
      _isRunning = false;
    }
  }

  // --- Helpers ---

  Future<String?> _getFormattedCookies(String url) async {
    try {
      final cookieJar = _getCookieJar();
      if (cookieJar != null) {
        final cookies = await cookieJar.loadForRequest(Uri.parse(url));
        if (cookies.isNotEmpty) {
          return cookies.map((c) => '${c.name}=${c.value}').join('; ');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearCookies(String url) async {
    try {
      final cookieJar = _getCookieJar();
      if (cookieJar != null) {
        await cookieJar.delete(Uri.parse(url));
      }
    } catch (_) {}
  }

  Future<void> _saveCookies(List<String> rawCookies, String url) async {
    final cookieJar = _getCookieJar();
    if (cookieJar == null || rawCookies.isEmpty) return;

    final uri = Uri.parse(url);

    // 1. Clear existing cookies for this domain to prevent conflicts
    try {
      await cookieJar.delete(uri);
    } catch (_) {}

    // 2. Parse "key=value" strings to Cookies
    final cookies = rawCookies.map((s) {
      final parts = s.split('=');
      final key = parts[0].trim();
      final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
      // Explicitly set domain and path to ensure wide coverage for the site
      return io.Cookie(key, value)
        ..domain = uri.host
        ..path = '/';
    }).toList();

    _logger.d('Saving ${cookies.length} cookies for ${uri.host} (Path: /)');

    await cookieJar.saveFromResponse(uri, cookies);
  }

  CookieJar? _getCookieJar() {
    final cookieManager =
        _httpClient.interceptors.whereType<CookieManager>().firstOrNull;
    return cookieManager?.cookieJar;
  }

  void _updateUserAgent(String ua) {
    _httpClient.options.headers['User-Agent'] = ua;
  }

  Future<bool> areCookiesValid() async {
    final cookieJar = _getCookieJar();
    if (cookieJar == null) {
      _logger.w('⚠️ CookieJar is null');
      return false;
    }

    // Check if we have cookies
    final cookies = await cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isEmpty) {
      _logger.w('⚠️ No cookies found in CookieJar for $baseUrl');
      return false;
    }

    _logger.d(
        '🔍 Verifying with ${cookies.length} cookies: ${cookies.map((c) => "${c.name}=${c.value}").join('; ')}');

    try {
      final response = await _httpClient.get(
        baseUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Log response headers/status for debugging
      _logger.d(
          'Verification Response: ${response.statusCode} - Headers: ${response.headers.map}');

      final isChallenge = _isCloudflareChallenge(response.data.toString());
      if (isChallenge) {
        _logger.w(
            '⚠️ Verification failed: Response still looks like Cloudflare challenge.');
      } else {
        _logger.i('✅ Verification success: Cookies are valid.');
      }
      return !isChallenge;
    } catch (e) {
      _logger.e('Verification request failed: $e');
      return false;
    }
  }

  bool _isCloudflareChallenge(String html) {
    // Specific title/text usually found in the challenge page
    final indicators = [
      'Checking your browser before accessing',
      'cf-challenge-form',
      // 'challenge-platform' and '__cf_chl_' often appear in script tags of valid pages
      '<title>Just a moment...</title>',
      '<title>Attention Required! | Cloudflare</title>',
      '<div id="cf-please-wait">',
    ];

    final lowerHtml = html.toLowerCase();
    return indicators.any((i) => lowerHtml.contains(i.toLowerCase()));
  }

  // Legacy getters kept for compatibility if needed
  String? get currentUserAgent =>
      _httpClient.options.headers['User-Agent'] as String?;
}
