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
    required GlobalKey<NavigatorState> navigatorKey, // Keeping in constructor for compatibility but not using it as field
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

      // 1. Get Initial Cookies to sync session
      final initialCookieStr = await _getFormattedCookies(urlToLoad);
      _logger.d('Sending Initial Cookies: $initialCookieStr');

      // 2. Launch Native WebView
      // We look for success when URL matches base or dashboard, 
      // or simply wait for user to close it (implicitly valid if they think so)
      // But adding filters helps auto-close.
      final result = await KuronNative.instance.showLoginWebView(
        url: urlToLoad,
        successUrlFilters: ['crotpedia', 'doujinshi', 'hentai manga'], // Loose match for success content
        initialCookie: initialCookieStr,
      );

      if (result != null && result['success'] == true) {
        final cookies = (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        final userAgent = result['userAgent'] as String?;

        _logger.i('✅ Native WebView Selesai. Extracted ${cookies.length} cookies.');
        
        // 3. Save Cookies & UA
        if (userAgent != null) {
          _updateUserAgent(userAgent);
        }
        await _saveCookies(cookies, urlToLoad);

        // 4. Verify
        return await areCookiesValid();
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
  Future<List<io.Cookie>?> attemptLogin({
    required String email, 
    required String password
  }) async {
     _isRunning = true;
     try {
       final loginUrl = 'https://crotpedia.net/login/';
       
       // Sync cookies
       final initialCookieStr = await _getFormattedCookies(loginUrl);

       final result = await KuronNative.instance.showLoginWebView(
         url: loginUrl,
         successUrlFilters: ['/wp-admin', '/dashboard', 'crotpedia.net/'], 
         initialCookie: initialCookieStr, // Critical for user session consistency
       );

       if (result != null && result['success'] == true) {
         final cookiesStrList = (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
         final userAgent = result['userAgent'] as String?;
         
         if (userAgent != null) _updateUserAgent(userAgent);
         await _saveCookies(cookiesStrList, loginUrl);

         // Helper to return List<io.Cookie> for existing API contract
         // We parse the raw strings "key=value"
         return cookiesStrList.map((str) {
            final parts = str.split('=');
            return io.Cookie(parts[0].trim(), parts.length > 1 ? parts.sublist(1).join('=') : '');
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

  Future<void> _saveCookies(List<String> rawCookies, String url) async {
     final cookieJar = _getCookieJar();
     if (cookieJar == null || rawCookies.isEmpty) return;
     
     final uri = Uri.parse(url);
     
     // Parse "key=value" strings to Cookies
     final cookies = rawCookies.map((s) {
        final parts = s.split('=');
        final key = parts[0].trim();
        final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
        return io.Cookie(key, value)..domain = uri.host; // Basic assumption
     }).toList();

     await cookieJar.saveFromResponse(uri, cookies);
  }
  
  CookieJar? _getCookieJar() {
    final cookieManager = _httpClient.interceptors
        .whereType<CookieManager>()
        .firstOrNull;
    return cookieManager?.cookieJar;
  }

  void _updateUserAgent(String ua) {
    _httpClient.options.headers['User-Agent'] = ua;
  }

  Future<bool> areCookiesValid() async {
    final cookieJar = _getCookieJar();
    if (cookieJar == null) return false;
    
    // Check if we have cookies
    final cookies = await cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isEmpty) return false;

    try {
      final response = await _httpClient.get(
        baseUrl,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return !_isCloudflareChallenge(response.data.toString());
    } catch (e) {
      return false;
    }
  }

  bool _isCloudflareChallenge(String html) {
    final indicators = [
      'Checking your browser before accessing',
      'DDoS protection by Cloudflare',
      'cf-challenge-form',
      'challenge-platform',
      '__cf_chl_',
      'Cloudflare Ray ID',
    ];

    final lowerHtml = html.toLowerCase();
    return indicators.any((i) => lowerHtml.contains(i.toLowerCase()));
  }
  
  // Legacy getters kept for compatibility if needed
  String? get currentUserAgent => _httpClient.options.headers['User-Agent'] as String?;
}
