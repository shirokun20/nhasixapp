import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/data/repositories/translation_cache_repository_impl.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mosaic quality defaults to high', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = AiPreferencesRepositoryImpl(prefs: prefs);
    expect(await repo.getMosaicQuality(), MosaicQuality.high);
  });

  test('mosaic quality persists across reads', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = AiPreferencesRepositoryImpl(prefs: prefs);
    await repo.setMosaicQuality(MosaicQuality.low);
    expect(await repo.getMosaicQuality(), MosaicQuality.low);
    await repo.setMosaicQuality(MosaicQuality.high);
    expect(await repo.getMosaicQuality(), MosaicQuality.high);
  });
}
