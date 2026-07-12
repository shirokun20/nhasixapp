import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';

class SchaleClearanceService {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const _storageKey = 'schale_clearance_token';

  // Turnstile sitekey extracted from niyaniya.moe bundle
  static const _turnstileSiteKey = '0x4AAAAAAA1gtfQl-5lpZVcM';

  String? _cachedToken;

  SchaleClearanceService({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
  })  : _secureStorage = secureStorage,
        _logger = logger;

  Future<void> init() async {
    try {
      final stored = await _secureStorage.read(key: _storageKey);
      if (stored != null && stored.isNotEmpty) _cachedToken = stored;
    } catch (_) {}
  }

  String? get cached => _cachedToken;

  Future<String?> acquire() async {
    if (_cachedToken != null) return _cachedToken;

    _logger.i('schale: acquiring clearance via captcha webview');
    final captchaResult = await KuronNative.instance.showCaptchaWebView(
      provider: 'turnstile',
      siteKey: _turnstileSiteKey,
      baseUrl: 'https://niyaniya.moe/',
    );
    final crt = captchaResult?['token'] as String?;
    if (crt != null && crt.isNotEmpty) {
      _logger.i('schale: acquired clearance token');
      await setToken(crt);
      return crt;
    }

    _logger.w('schale: captcha clearance failed');
    return null;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _storageKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _storageKey);
  }

  Interceptor createInterceptor() => _SchaleInterceptor(service: this);
}

class _SchaleInterceptor extends Interceptor {
  final SchaleClearanceService _service;
  _SchaleInterceptor({required SchaleClearanceService service}) : _service = service;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final url = options.uri.toString();
    if (!(options.method == 'POST' && url.contains('/books/detail/')) &&
        !url.contains('/books/data/')) {
      return handler.next(options);
    }
    var crt = _service._cachedToken;
    crt ??= await _service.acquire();
    if (crt != null) options.queryParameters['crt'] = crt;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 403 &&
        (err.requestOptions.uri.toString().contains('/books/detail/') ||
         err.requestOptions.uri.toString().contains('/books/data/'))) {
      await _service._secureStorage.delete(key: SchaleClearanceService._storageKey);
      _service._cachedToken = null;
    }
    handler.next(err);
  }
}
