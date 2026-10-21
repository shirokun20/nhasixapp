import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhasixapp/data/repositories/glossary_repository_impl.dart';
import 'package:nhasixapp/domain/entities/glossary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GlossaryRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = GlossaryRepositoryImpl(prefs: prefs);
  });

  test('caps glossary at 500 entries on save', () async {
    for (int i = 0; i < 505; i++) {
      await repo.save(GlossaryEntry(
        id: 'entry_$i',
        sourceText: 'source_$i',
        translatedText: 'target_$i',
        contentId: 'content_1',
        pageIndex: 0,
        timestamp: i,
      ));
    }

    final all = await repo.getAll();
    expect(all.length, 500);
    // Entry 504 should be present at index 0 (newest)
    expect(all.first.id, 'entry_504');
  });
}
