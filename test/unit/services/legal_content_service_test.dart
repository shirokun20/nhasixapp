
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/services/legal_content_service.dart';
import 'package:flutter/services.dart';

class FakeAssetBundle extends Fake implements AssetBundle {
  final Map<String, String> assets;

  FakeAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    throw Exception('Asset not found: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LegalContentService service;

  group('LegalContentService', () {
    test('getTitle returns correct title for English locale', () {
      service = LegalContentService(bundle: FakeAssetBundle({}));
      expect(service.getTitle(LegalContentType.termsAndConditions, 'en'),
          'Terms and Conditions');
      expect(service.getTitle(LegalContentType.privacyPolicy, 'en'),
          'Privacy Policy');
      expect(service.getTitle(LegalContentType.faq, 'en'), 'FAQ');
    });

    test('getTitle returns correct title for Indonesian locale', () {
      service = LegalContentService(bundle: FakeAssetBundle({}));
      expect(service.getTitle(LegalContentType.termsAndConditions, 'id'),
          'Syarat dan Ketentuan');
      expect(service.getTitle(LegalContentType.privacyPolicy, 'id'),
          'Kebijakan Privasi');
      expect(service.getTitle(LegalContentType.faq, 'id'), 'FAQ');
    });

    test('fetchContent loads from assets', () async {
      service = LegalContentService(
        bundle: FakeAssetBundle({
          'assets/legal/en/terms_and_conditions.md': 'Terms content',
        }),
      );

      final content = await service.fetchContent(
          LegalContentType.termsAndConditions, 'en');
      expect(content, 'Terms content');
    });

    test('fetchContent falls back to English if locale asset missing', () async {
      service = LegalContentService(
        bundle: FakeAssetBundle({
          'assets/legal/en/terms_and_conditions.md': 'Terms content fallback',
        }),
      );

      final content = await service.fetchContent(
          LegalContentType.termsAndConditions, 'fr'); // Use non-existing locale
      expect(content, 'Terms content fallback');
    });
  });
}
