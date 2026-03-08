import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:kuron_native/kuron_native.dart';

/// Configuration for the WebView session (parsed from JSON)
class WebViewSessionConfig {
  final bool bypassEnabled;
  final bool authEnabled;
  final String loginUrl;
  final String registerUrl;
  final String bookmarkVerifyUrl;
  final String nonceRegex;
  final String loginSuccessFilter;

  const WebViewSessionConfig({
    this.bypassEnabled = false,
    this.authEnabled = false,
    this.loginUrl = '',
    this.registerUrl = '',
    this.bookmarkVerifyUrl = '',
    this.nonceRegex = '',
    this.loginSuccessFilter = '',
  });

  factory WebViewSessionConfig.fromJson(Map<String, dynamic> json) {
    final network = json['network'] as Map<String, dynamic>? ?? {};
    final cf = network['cloudflare'] as Map<String, dynamic>? ?? {};
    final auth = json['auth'] as Map<String, dynamic>? ?? {};

    return WebViewSessionConfig(
      bypassEnabled: cf['bypassEnabled'] == true,
      authEnabled: auth['enabled'] == true,
      loginUrl: (auth['loginUrl'] as String?) ?? '',
      registerUrl: (auth['registerUrl'] as String?) ?? '',
      bookmarkVerifyUrl: (auth['bookmarkUrl'] as String?) ?? '',
      nonceRegex: (auth['nonceRegex'] as String?) ?? '',
      loginSuccessFilter: (auth['loginSuccessFilter'] as String?) ?? '',
    );
  }
}

/// Result of an authentication attempt
class WebViewAuthResult {
  final bool success;
  final String? errorMessage;
  final String? username;

  const WebViewAuthResult._({
    required this.success,
    this.errorMessage,
    this.username,
  });

  factory WebViewAuthResult.success(String username) => WebViewAuthResult._(
        success: true,
        username: username,
      );

  factory WebViewAuthResult.failure(String message) => WebViewAuthResult._(
        success: false,
        errorMessage: message,
      );
}

/// State of authentication
enum WebViewAuthState {
  notLoggedIn,
  loggingIn,
  loggedIn,
  error,
}

/// An adapter that orchestrates Cloudflare bypass and authentication
/// through a shared Dio instance and CookieJar.
class WebViewSessionAdapter {
  final Dio _dio;
  final PersistCookieJar _cookieJar;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;
  final WebViewSessionConfig _config;
  final String _baseUrl;

  WebViewAuthState _authState = WebViewAuthState.notLoggedIn;
  String? _username;
  String? _email;
  bool _isBypassing = false;

  // Secure storage keys
  static const _keyPrefix = 'kuron_special_auth_';
  String get _keyEmail => '$_keyPrefix${_baseUrl.hashCode}_email';
  String get _keyPassword => '$_keyPrefix${_baseUrl.hashCode}_password';

  WebViewSessionAdapter({
    required Dio dio,
    required PersistCookieJar cookieJar,
    required WebViewSessionConfig config,
    required String baseUrl,
    FlutterSecureStorage? secureStorage,
    Logger? logger,
  })  : _dio = dio,
        _cookieJar = cookieJar,
        _config = config,
        _baseUrl = baseUrl,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger() {
    // Attach CookieManager to Dio
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // ============ Getters ============

  WebViewAuthState get authState => _authState;
  bool get isLoggedIn => _authState == WebViewAuthState.loggedIn;
  String? get username => _username;
  String? get email => _email;
  String get registerUrl => _config.registerUrl;

  Future<Map<String, String>> getCookiesForDomain(String url) async {
    try {
      final uri = Uri.parse(url.isEmpty ? _baseUrl : url);
      final cookies = await _cookieJar.loadForRequest(uri);

      if (cookies.isEmpty) return {};

      return Map.fromEntries(
        cookies.map((cookie) => MapEntry(cookie.name, cookie.value)),
      );
    } catch (e) {
      _logger.e('Failed to get cookies: $e');
      return {};
    }
  }

  // ============ Cloudflare Bypass ============

  /// Returns true if the HTML response looks like a Cloudflare challenge.
  bool isCloudflareChallenge(String html) {
    final indicators = [
      'Checking your browser',
      'cf-challenge-form',
      'challenge-platform',
      '__cf_chl_',
      'cf-mitigated',
      'Ray ID:',
      '<title>Just a moment...</title>',
      '<title>Attention Required! | Cloudflare</title>',
      '<div id="cf-please-wait">',
    ];

    final lowerHtml = html.toLowerCase();
    return indicators
        .any((indicator) => lowerHtml.contains(indicator.toLowerCase()));
  }

  /// Execute a GET request, automatically handling Cloudflare bypass if encountered.
  Future<Response<T>> requestWithBypass<T>(
    String url, {
    Options? options,
  }) async {
    try {
      // 1. First attempt
      options ??= Options();
      options.headers ??= {};

      // Sync stored dynamically captured UserAgent from previous bypass if available
      final storedUa = _dio.options.headers['User-Agent'] as String?;
      if (storedUa != null) {
        options.headers ??= {};
        options.headers?['User-Agent'] = storedUa;
      }

      return await _dio.get<T>(url, options: options);
    } on DioException catch (e) {
      // 2. Detect 403 Challenge
      final isCloudflare = e.response?.statusCode == 403 &&
          (e.response?.headers.value('cf-mitigated') != null ||
              (e.response?.data is String &&
                  isCloudflareChallenge(e.response!.data as String)));

      if (!isCloudflare || !_config.bypassEnabled) {
        rethrow;
      }

      _logger.w('🔒 Cloudflare 403 challenge detected for: $url');

      // Prevent concurrent bypass loops
      if (_isBypassing) {
        _logger.w('Already bypassing, waiting and retrying...');
        await Future.delayed(const Duration(seconds: 5));
        return await _dio.get<T>(url, options: options);
      }

      // 3. Launch UI Bypass and use verified response directly.
      final bypassResponse = await _attemptNativeBypassAndVerify<T>(
        targetUrl: url,
        options: options,
      );
      if (bypassResponse == null) {
        _logger.e('❌ Cloudflare bypass failed completely.');
        rethrow;
      }

      _logger.i('✅ Cloudflare bypassed. Using verified response.');
      return bypassResponse;
    }
  }

  Future<Response<T>?> _attemptNativeBypassAndVerify<T>({
    required String targetUrl,
    Options? options,
  }) async {
    _isBypassing = true;
    try {
      _logger.i('🚀 Launching Native WebView for CF Bypass...');

      // 1. Clear old cookies to ensure fresh start
      final uri = Uri.parse(targetUrl);
      await _cookieJar.delete(uri);

      // 2. Launch Native WebView
      // Note: we let Native WebView use default System UA.
      final result = await KuronNative.instance.showLoginWebView(
        url: targetUrl,
        successUrlFilters: [],
        initialCookie: null,
        userAgent: null,
        autoCloseOnCookie: 'cf_clearance',
        clearCookies: true,
      );

      if (result != null && result['success'] == true) {
        final cookiesRaw =
            (result['cookies'] as List<dynamic>?)?.cast<String>() ?? [];
        final userAgent = result['userAgent'] as String?;

        if (userAgent != null && userAgent.isNotEmpty) {
          _dio.options.headers['User-Agent'] = userAgent;
          _logger.i('🔄 Synced User-Agent: $userAgent');
        }

        if (cookiesRaw.isNotEmpty) {
          await _saveRawCookies(cookiesRaw, targetUrl);
        }

        // 3. Verify and return success response to caller.
        return await _verifyBypass<T>(targetUrl, options: options);
      }
      return null;
    } catch (e) {
      _logger.e('Native Bypass Error: $e');
      return null;
    } finally {
      _isBypassing = false;
    }
  }

  Future<Response<T>?> _verifyBypass<T>(
    String url, {
    Options? options,
  }) async {
    for (int i = 0; i < 3; i++) {
      try {
        final response = await _dio.get<T>(
          url,
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != null && response.statusCode! >= 400) {
          _logger.w(
            'Bypass verify attempt ${i + 1} got status ${response.statusCode}',
          );
          continue;
        }

        // Status < 400 means bypass worked — return immediately.
        // Don't re-check isCloudflareChallenge here because normal pages
        // can contain CF-related strings (Ray ID in footer, challenge-platform
        // in Turnstile scripts) causing false positives.
        return response;
      } catch (e) {
        _logger.w('Verify attempt ${i + 1} failed: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Future<void> _saveRawCookies(List<String> rawCookies, String urlStr) async {
    final uri = Uri.parse(urlStr);

    // Create new cookies ensuring path=/ and domain matches
    final cookiesToSave = rawCookies.map((s) {
      final parts = s.split('=');
      final key = parts[0].trim();
      final value = parts.length > 1 ? parts.sublist(1).join('=') : '';
      return Cookie(key, value)
        ..domain = uri.host
        ..path = '/';
    }).toList();

    await _cookieJar.saveFromResponse(uri, cookiesToSave);
    _logger.d('Saved ${cookiesToSave.length} cookies to jar for ${uri.host}');
  }

  // ============ Authentication Focus ============

  /// Login programmatically by fetching nonce and POSTing credentials
  Future<WebViewAuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (!_config.authEnabled || _config.loginUrl.isEmpty) {
      return WebViewAuthResult.failure('Authentication is not configured.');
    }

    _authState = WebViewAuthState.loggingIn;

    try {
      // 1. Getting Nonce
      final loginPageRes = await requestWithBypass<String>(_config.loginUrl);
      final nonceMatch =
          RegExp(_config.nonceRegex).firstMatch(loginPageRes.data ?? '');
      final nonce = nonceMatch?.group(1) ?? '';

      if (nonce.isEmpty) {
        _authState = WebViewAuthState.error;
        return WebViewAuthResult.failure('Failed to extract login nonce.');
      }

      // 2. Submit Logic
      final postRes = await _dio.post(_config.loginUrl,
          data: {
            'koi_user_login': email,
            'koi_user_pass': password,
            'koi_login_nonce': nonce,
          },
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false,
            validateStatus: (s) => s != null && s < 500,
          ));

      // Check failure signs from form HTML response
      final postHtml = postRes.data.toString();
      if (postHtml.contains('Incorrect password') ||
          postHtml.contains('password you entered is incorrect')) {
        _authState = WebViewAuthState.error;
        return WebViewAuthResult.failure('Invalid email or password.');
      }

      // 3. Verify
      final verified = await _verifyLoginSession();
      if (verified) {
        _authState = WebViewAuthState.loggedIn;
        _email = email;
        _username = email.split('@').first;

        if (rememberMe) {
          await _secureStorage.write(key: _keyEmail, value: email);
          await _secureStorage.write(key: _keyPassword, value: password);
        }
        return WebViewAuthResult.success(_username!);
      }

      _authState = WebViewAuthState.error;
      return WebViewAuthResult.failure('Login verification failed.');
    } catch (e) {
      _authState = WebViewAuthState.error;
      return WebViewAuthResult.failure('Login failed: $e');
    }
  }

  /// Used to check if we have a valid login session (usually by accessing bookmark endpoint)
  Future<bool> _verifyLoginSession() async {
    if (_config.bookmarkVerifyUrl.isEmpty) return false;

    try {
      final res = await _dio.get(_config.bookmarkVerifyUrl,
          options: Options(followRedirects: false));
      // Accessing bookmark should return 200. If we get 302, it redirects to login=unauthenticated
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    if (!_config.authEnabled) return false;

    try {
      if (await _verifyLoginSession()) {
        _email = await _secureStorage.read(key: _keyEmail);
        _username = _email?.split('@').first;
        _authState = WebViewAuthState.loggedIn;
        return true;
      }

      final savedEmail = await _secureStorage.read(key: _keyEmail);
      final savedPassword = await _secureStorage.read(key: _keyPassword);

      if (savedEmail != null && savedPassword != null) {
        final result = await login(
            email: savedEmail, password: savedPassword, rememberMe: true);
        return result.success;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set session from external WebView login (e.g. native browser login flow).
  /// [username] is the detected username from cookies.
  /// [rawCookies] is a list of "key=value" strings from the WebView.
  Future<void> setExternalLogin({
    required String username,
    required List<String> rawCookies,
  }) async {
    if (rawCookies.isNotEmpty) {
      await _saveRawCookies(rawCookies, _baseUrl);
    }

    _authState = WebViewAuthState.loggedIn;
    _username = username;
    _email = '$username@external';

    // Save identity so tryAutoLogin can restore state
    await _secureStorage.write(key: _keyEmail, value: _email!);
    // No password for external sessions
  }

  Future<void> logout() async {
    await _cookieJar.deleteAll();
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyPassword);

    _authState = WebViewAuthState.notLoggedIn;
    _email = null;
    _username = null;
  }
}
