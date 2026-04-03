import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:kuron_special/kuron_special.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage(this._sessionJson);

  final String _sessionJson;

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _sessionJson;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return;
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return;
  }
}

class _MutableFakeSecureStorage extends FlutterSecureStorage {
  _MutableFakeSecureStorage(this._store);

  final Map<String, String> _store;

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
      return;
    }

    _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('ApiAuthConfig.fromSourceConfig', () {
    test('parses auth config from source json', () {
      final rawConfig = <String, dynamic>{
        'baseUrl': 'https://nhentai.net',
        'api': {
          'apiBase': 'https://nhentai.net/api/v2',
        },
        'auth': {
          'enabled': true,
          'authorizationScheme': 'User',
          'powAction': 'login',
          'endpoints': {
            'pow': '/api/v2/pow',
            'captcha': '/api/v2/captcha',
            'login': '/api/v2/auth/login',
            'favorites': '/api/v2/favorites',
          },
          'fields': {
            'username': 'username',
            'password': 'password',
            'captchaResponse': 'captcha_response',
            'powChallenge': 'pow_challenge',
            'powNonce': 'pow_nonce',
            'powAction': 'pow_action',
          },
        },
      };

      final config = ApiAuthConfig.fromSourceConfig(rawConfig);

      expect(config.apiBase, 'https://nhentai.net/api/v2');
      expect(config.loginEndpoint, '/api/v2/auth/login');
      expect(config.powEndpoint, '/api/v2/pow');
      expect(config.captchaEndpoint, '/api/v2/captcha');
      expect(config.favoritesEndpoint, '/api/v2/favorites');
      expect(config.powAction, 'login');
      expect(config.captchaField, 'captcha_response');
      expect(config.challengeField, 'pow_challenge');
      expect(config.nonceField, 'pow_nonce');
      expect(config.actionField, 'pow_action');
    });
  });

  group('ConfigDrivenApiAuthClient.solvePowNonce', () {
    test('returns nonce for challenge+nonce formula', () {
      const config = ApiAuthConfig(
        apiBase: 'https://example.com',
        authorizationScheme: 'User',
        loginEndpoint: '/auth/login',
        usernameField: 'username',
        passwordField: 'password',
        captchaField: 'captcha_response',
        challengeField: 'pow_challenge',
        nonceField: 'pow_nonce',
        actionField: 'pow_action',
        accessTokenField: 'access_token',
        refreshTokenField: 'refresh_token',
        expiresInField: 'expires_in',
        tokenTypeField: 'token_type',
      );

      final client = ConfigDrivenApiAuthClient(
        dio: Dio(),
        config: config,
        logger: Logger(),
      );

      final nonce = client.solvePowNonce(
        challenge: 'abc123',
        difficulty: 8,
        maxIterations: 500000,
      );

      expect(nonce, '188');
    });
  });

  group('ConfigDrivenApiAuthClient.logout', () {
    test('sends refresh token in logout body when available', () async {
      final capturedRequests = <Map<String, dynamic>>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequests.add(<String, dynamic>{
              'path': options.path,
              'data': options.data,
            });
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: const {'success': true},
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final secureStorage = _FakeSecureStorage(
        '{"accessToken":"access-token","refreshToken":"refresh-token"}',
      );

      const config = ApiAuthConfig(
        apiBase: 'https://example.com',
        authorizationScheme: 'User',
        loginEndpoint: '/auth/login',
        usernameField: 'username',
        passwordField: 'password',
        captchaField: 'captcha_response',
        challengeField: 'pow_challenge',
        nonceField: 'pow_nonce',
        actionField: 'pow_action',
        accessTokenField: 'access_token',
        refreshTokenField: 'refresh_token',
        expiresInField: 'expires_in',
        tokenTypeField: 'token_type',
        logoutEndpoint: '/auth/logout',
      );

      final client = ConfigDrivenApiAuthClient(
        dio: dio,
        config: config,
        logger: Logger(),
        secureStorage: secureStorage,
      );

      await client.logout(clearStorage: false);

      expect(capturedRequests, hasLength(1));
      expect(
          capturedRequests.single['path'], 'https://example.com/auth/logout');
      expect(
        capturedRequests.single['data'],
        <String, dynamic>{'refresh_token': 'refresh-token'},
      );
    });

    test('clears in-memory authorization header on logout', () async {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'User stale-token';

      const config = ApiAuthConfig(
        apiBase: 'https://example.com',
        authorizationScheme: 'User',
        loginEndpoint: '/auth/login',
        usernameField: 'username',
        passwordField: 'password',
        captchaField: 'captcha_response',
        challengeField: 'pow_challenge',
        nonceField: 'pow_nonce',
        actionField: 'pow_action',
        accessTokenField: 'access_token',
        refreshTokenField: 'refresh_token',
        expiresInField: 'expires_in',
        tokenTypeField: 'token_type',
      );

      final client = ConfigDrivenApiAuthClient(
        dio: dio,
        config: config,
        logger: Logger(),
      );

      await client.logout(clearStorage: false);

      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ConfigDrivenApiAuthClient.attachSessionHeaderFromStorage', () {
    test('removes stale authorization header when no session exists', () async {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'User stale-token';

      final secureStorage = _MutableFakeSecureStorage(<String, String>{});

      const config = ApiAuthConfig(
        apiBase: 'https://example.com',
        authorizationScheme: 'User',
        loginEndpoint: '/auth/login',
        usernameField: 'username',
        passwordField: 'password',
        captchaField: 'captcha_response',
        challengeField: 'pow_challenge',
        nonceField: 'pow_nonce',
        actionField: 'pow_action',
        accessTokenField: 'access_token',
        refreshTokenField: 'refresh_token',
        expiresInField: 'expires_in',
        tokenTypeField: 'token_type',
      );

      final client = ConfigDrivenApiAuthClient(
        dio: dio,
        config: config,
        logger: Logger(),
        secureStorage: secureStorage,
      );

      await client.attachSessionHeaderFromStorage();

      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
