import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Types of legal content available
enum LegalContentType {
  termsAndConditions,
  privacyPolicy,
  faq,
}

/// Service to fetch legal content from local assets
class LegalContentService {
  LegalContentService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _logger = Logger();

  /// Get file name for content type
  String _getFileName(LegalContentType type) {
    switch (type) {
      case LegalContentType.termsAndConditions:
        return 'terms_and_conditions.md';
      case LegalContentType.privacyPolicy:
        return 'privacy_policy.md';
      case LegalContentType.faq:
        return 'faq.md';
    }
  }

  /// Get title for content type
  String getTitle(LegalContentType type, String locale) {
    if (locale == 'id') {
      switch (type) {
        case LegalContentType.termsAndConditions:
          return 'Syarat dan Ketentuan';
        case LegalContentType.privacyPolicy:
          return 'Kebijakan Privasi';
        case LegalContentType.faq:
          return 'FAQ';
      }
    }
    switch (type) {
      case LegalContentType.termsAndConditions:
        return 'Terms and Conditions';
      case LegalContentType.privacyPolicy:
        return 'Privacy Policy';
      case LegalContentType.faq:
        return 'FAQ';
    }
  }

  /// Fetch content from local assets
  Future<String> fetchContent(LegalContentType type, String locale) async {
    _logger.i('LegalContentService: Loading ${type.name} from local assets');
    return _loadLocalAsset(type, locale);
  }

  /// Load from local assets
  Future<String> _loadLocalAsset(LegalContentType type, String locale) async {
    final fileName = _getFileName(type);
    final assetPath = 'assets/legal/$locale/$fileName';

    try {
      return await _bundle.loadString(assetPath);
    } catch (e) {
      // If locale-specific file not found, try English
      if (locale != 'en') {
        _logger.w('LegalContentService: Fallback to English for ${type.name}');
        return await _bundle.loadString('assets/legal/en/$fileName');
      }
      rethrow;
    }
  }
}
