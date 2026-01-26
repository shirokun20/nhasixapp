import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../crotpedia_url_builder.dart';
import 'crotpedia_cookie_store.dart';

/// Authentication state for UI
enum CrotpediaAuthState {
  notLoggedIn,
  loggingIn,
  loggedIn,
  error,
}

/// Auth result for login attempts
class CrotpediaAuthResult {
  final bool success;
  final String? errorMessage;
  final String? username;

  const CrotpediaAuthResult({
    required this.success,
    this.errorMessage,
    this.username,
  });

  factory CrotpediaAuthResult.success(String username) => CrotpediaAuthResult(
        success: true,
        username: username,
      );

  factory CrotpediaAuthResult.failure(String message) => CrotpediaAuthResult(
        success: false,
        errorMessage: message,
      );
}

/// Authentication manager for Crotpedia.
///
/// NO hardcoded credentials - user must provide their own.
/// Uses FlutterSecureStorage for credential encryption.
class CrotpediaAuthManager {
  final Dio _dio;
  final CrotpediaCookieStore _cookieStore;
  final FlutterSecureStorage _secureStorage;
  final PersistCookieJar _cookieJar;

  CrotpediaAuthState _state = CrotpediaAuthState.notLoggedIn;
  String? _username;
  String? _email;

  // Secure storage keys
  static const _keyEmail = 'crotpedia_email';
  static const _keyPassword = 'crotpedia_password';
  static const _keyUsername = 'crotpedia_username';
  static const _keyLoginTime = 'crotpedia_login_time';

  CrotpediaAuthManager({
    required Dio dio,
    required CrotpediaCookieStore cookieStore,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio,
        _cookieStore = cookieStore,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cookieJar = PersistCookieJar(storage: cookieStore) {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // ============ Getters ============

  CrotpediaAuthState get state => _state;
  bool get isLoggedIn => _state == CrotpediaAuthState.loggedIn;
  String? get username => _username;
  String? get email => _email;

  /// Get cookies for specific domain as Map for MethodChannel
  /// Used to pass authentication cookies to native download layer
  Future<Map<String, String>> getCookiesForDomain(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);

      final cookies = await _cookieJar.loadForRequest(uri);

      if (cookies.isEmpty) {
        return {};
      }

      final cookieMap = Map.fromEntries(
          cookies.map((cookie) => MapEntry(cookie.name, cookie.value)));

      return cookieMap;
    } catch (e) {
      // Log error but don't throw - return empty map to allow graceful fallback
      return {};
    }
  }

  // ============ Login Flow (User Provides Credentials) ============

  /// Login with user-provided credentials
  /// Called when user submits login form
  Future<CrotpediaAuthResult> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _state = CrotpediaAuthState.loggingIn;

    try {
      // Step 1: GET login page to extract nonce
      final loginPageResponse = await _dio.get(
        CrotpediaUrlBuilder.login(),
        options: Options(
            headers: _buildEnhancedHeaders(CrotpediaUrlBuilder.login())),
      );

      final nonce = _extractNonce(loginPageResponse.data);
      if (nonce.isEmpty) {
        _state = CrotpediaAuthState.error;
        return CrotpediaAuthResult.failure('Gagal mendapatkan token login');
      }

      // Step 2: POST login with user credentials
      final loginUrl = CrotpediaUrlBuilder.login();
      final response = await _dio.post(
        loginUrl,
        data: {
          'koi_user_login': email,
          'koi_user_pass': password,
          'koi_login_nonce': nonce,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status! < 400 || status == 302,
          headers: _buildEnhancedHeaders(loginUrl),
        ),
      );

      // Step 3: Check if login successful
      if (response.statusCode == 302 || response.statusCode == 200) {
        // Check for specific error message in response body
        final responseBody = response.data.toString();
        if (responseBody.contains('Incorrect password') ||
            responseBody.contains('class="alert"')) {
          _state = CrotpediaAuthState.error;
          return CrotpediaAuthResult.failure('Email atau password salah');
        }

        // Verify by checking if we can access a protected page
        final verified = await _verifyLogin();

        if (verified) {
          _state = CrotpediaAuthState.loggedIn;
          _email = email;
          _username = email.split('@').first;

          // Save credentials securely if rememberMe is true
          if (rememberMe) {
            await _saveCredentials(email, password);
          }

          return CrotpediaAuthResult.success(_username!);
        }
      }

      // Login failed
      _state = CrotpediaAuthState.error;
      return CrotpediaAuthResult.failure('Email atau password salah');
    } catch (e) {
      _state = CrotpediaAuthState.error;
      return CrotpediaAuthResult.failure('Gagal login: ${e.toString()}');
    }
  }

  /// Verify login by checking bookmark page (requires auth)
  Future<bool> _verifyLogin() async {
    try {
      final bookmarkUrl = CrotpediaUrlBuilder.bookmark();
      final response = await _dio.get(
        bookmarkUrl,
        options: Options(
          followRedirects: false,
          headers: _buildEnhancedHeaders(bookmarkUrl),
        ),
      );
      // If redirected to login, not authenticated
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============ Auto-Login (Restore Session) ============

  /// Try to restore session from saved credentials
  /// Called on app startup
  Future<bool> tryAutoLogin() async {
    try {
      // First check if cookies are still valid
      final sessionValid = await _isSessionValid();
      if (sessionValid) {
        _state = CrotpediaAuthState.loggedIn;
        _username = await _secureStorage.read(key: _keyUsername);
        _email = await _secureStorage.read(key: _keyEmail);
        return true;
      }

      // Try to login with saved credentials
      final savedEmail = await _secureStorage.read(key: _keyEmail);
      final savedPassword = await _secureStorage.read(key: _keyPassword);

      if (savedEmail != null && savedPassword != null) {
        final result = await login(
          email: savedEmail,
          password: savedPassword,
          rememberMe: true,
        );
        return result.success;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if current session cookies are still valid
  Future<bool> _isSessionValid() async {
    final cookies = await _cookieJar.loadForRequest(
      Uri.parse(CrotpediaUrlBuilder.home()),
    );
    if (cookies.isEmpty) return false;
    return await _verifyLogin();
  }

  // ============ Bookmark Interaction ============

  Future<bool> toggleBookmark(String postId, bool setActive) async {
    try {
      const ajaxUrl = 'https://crotpedia.net/wp-admin/admin-ajax.php';
      final response = await _dio.post(
        ajaxUrl,
        data: FormData.fromMap({
          'action': 'favorites_favorite',
          'postid': postId,
          'siteid': '1',
          'status': setActive ? 'active' : 'inactive',
        }),
        options: Options(headers: _buildEnhancedHeaders(ajaxUrl)),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ Logout ============

  /// Logout and clear all stored data
  Future<void> logout() async {
    await _cookieJar.deleteAll();
    await _cookieStore.clearLoginState();
    await _clearCredentials();

    _state = CrotpediaAuthState.notLoggedIn;
    _username = null;
    _email = null;
  }

  // ============ Secure Storage ============

  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _keyEmail, value: email);
    await _secureStorage.write(key: _keyPassword, value: password);
    await _secureStorage.write(
        key: _keyUsername, value: email.split('@').first);
    await _secureStorage.write(
        key: _keyLoginTime, value: DateTime.now().toIso8601String());
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: _keyEmail);
    await _secureStorage.delete(key: _keyPassword);
    await _secureStorage.delete(key: _keyUsername);
    await _secureStorage.delete(key: _keyLoginTime);
  }

  /// Check if credentials are saved
  Future<bool> hasStoredCredentials() async {
    final email = await _secureStorage.read(key: _keyEmail);
    return email != null && email.isNotEmpty;
  }

  // ============ Registration (Open WebView) ============

  /// Get registration URL to open in WebView/browser
  String get registerUrl => CrotpediaUrlBuilder.register();

  // ============ Private Methods ============

  String _extractNonce(String html) {
    final regex = RegExp(r'name="koi_login_nonce"\s+value="([^"]+)"');
    return regex.firstMatch(html)?.group(1) ?? '';
  }

  /// Build enhanced headers to bypass Cloudflare bot detection
  Map<String, String> _buildEnhancedHeaders(String url) {
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Referer': '${CrotpediaUrlBuilder.baseUrl}/',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-Fetch-User': '?1',
      'sec-ch-ua':
          '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
      'sec-ch-ua-mobile': '?1',
      'sec-ch-ua-platform': '"Android"',
      'Cache-Control': 'max-age=0',
    };
  }
}
