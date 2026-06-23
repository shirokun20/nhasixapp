import 'dart:convert';

import 'package:kuron_native/kuron_native.dart';
import 'package:logger/logger.dart';

class MangaFireWebViewHelper {
  MangaFireWebViewHelper({
    required Logger logger,
    KuronNative? native,
  })  : _logger = logger,
        _native = native ?? KuronNative.instance;

  final Logger _logger;
  final KuronNative _native;

  Future<String?> captureSearchRequestUrl({
    required String baseUrl,
    required String query,
  }) async {
    final escapedQuery = jsonEncode(query);
    final injectedScript = '''
      (function() {
        const applyQuery = () => {
          const input = document.querySelector('.search-inner input[name="keyword"]');
          if (!input) {
            return false;
          }
          input.value = $escapedQuery;
          input.dispatchEvent(new Event('input', { bubbles: true }));
          input.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true, key: 'a' }));
          return true;
        };
        if (!applyQuery()) {
          let attempts = 0;
          const timer = setInterval(() => {
            attempts += 1;
            if (applyQuery() || attempts > 20) {
              clearInterval(timer);
            }
          }, 400);
        }
      })();
    ''';

    return _captureRequestUrl(
      url: '$baseUrl/home',
      capturePatterns: const ['/ajax/manga/search'],
      allowPatterns: const ['mfcdn.nl', 'jquery', '.js', '.css'],
      pageFinishedScript: injectedScript,
    );
  }

  Future<String?> captureReaderRequestUrl({
    required String readerUrl,
  }) {
    return _captureRequestUrl(
      url: readerUrl,
      capturePatterns: const ['/ajax/read/chapter/', '/ajax/read/volume/'],
      allowPatterns: const ['mfcdn.nl', 'jquery', '.js', '.css', '/ajax/read/'],
    );
  }

  Future<String?> _captureRequestUrl({
    required String url,
    required List<String> capturePatterns,
    required List<String> allowPatterns,
    String? pageFinishedScript,
  }) async {
    final result = await _native.showLoginWebView(
      url: url,
      successUrlFilters: const <String>[],
      captureRequestPatterns: capturePatterns,
      allowRequestPatterns: allowPatterns,
      pageFinishedScript: pageFinishedScript,
      blockNetworkImages: true,
      clearCookies: false,
    );

    final captured = result?['capturedRequestUrl'] as String?;
    if (captured == null || captured.isEmpty) {
      _logger.w('MangaFire WebView capture failed for $url');
      return null;
    }
    return captured;
  }
}
