import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'komiktap_source.dart';
import 'komiktap_scraper.dart';

/// Factory class for creating KomiktapSource instances with optional config.
class KomiktapFactory {
  /// Create a ready-to-use KomiktapSource with default configuration
  static KomiktapSource create({
    Dio? dio,
    Logger? logger,
    String? baseUrl,
    String? displayName,
    Map<String, dynamic>? customSelectors,
  }) {
    final scraper = KomiktapScraper(
      customSelectors: customSelectors,
    );

    final httpClient = dio ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
          maxRedirects: 3,
        ));

    return KomiktapSource(
      scraper: scraper,
      dio: httpClient,
      logger: logger,
      baseUrl: baseUrl,
      displayName: displayName,
    );
  }

  /// Create a KomiktapSource from remote config JSON
  /// 
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "baseUrl": "https://komiktap.info",
  ///   "displayName": "KomikTap",
  ///   "selectors": {
  ///     "home": { ... },
  ///     "search": { ... }
  ///   }
  /// }
  /// ```
  static KomiktapSource createFromConfig({
    required Map<String, dynamic> config,
    Dio? dio,
    Logger? logger,
  }) {
    final baseUrl = config['baseUrl'] as String?;
    final displayName = config['displayName'] as String?;
    final selectors = config['selectors'] as Map<String, dynamic>?;

    return create(
      dio: dio,
      logger: logger,
      baseUrl: baseUrl,
      displayName: displayName,
      customSelectors: selectors,
    );
  }
}
