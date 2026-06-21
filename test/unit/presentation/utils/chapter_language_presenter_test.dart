import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/presentation/utils/chapter_language_presenter.dart';

void main() {
  Chapter chapter(String id, String? language) => Chapter(
        id: id,
        title: id,
        url: '/$id',
        language: language,
      );

  String label(String key) => key.toUpperCase();

  test('normalizes aliases, regional codes, and unknown fallback', () {
    final model = ChapterLanguagePresenter.build(
      [
        chapter('en', 'english'),
        chapter('en-us', 'en-US'),
        chapter('id', 'indonesian'),
        chapter('unknown', ''),
      ],
      labelForKey: label,
    );

    expect(model.lanes.map((lane) => lane.key), ['en', 'id', 'unknown']);
    expect(model.lanes.first.chapters.map((chapter) => chapter.id), [
      'en',
      'en-us',
    ]);
  });

  test('orders unknown last', () {
    final model = ChapterLanguagePresenter.build(
      [
        chapter('unknown', null),
        chapter('ja', 'ja'),
        chapter('en', 'en'),
      ],
      labelForKey: label,
    );

    expect(model.lanes.map((lane) => lane.key), ['en', 'ja', 'unknown']);
  });

  test('keeps selected lane after paginated append', () {
    final firstPage = ChapterLanguagePresenter.build(
      [chapter('en-1', 'en'), chapter('id-1', 'id')],
      selectedKey: 'id',
      labelForKey: label,
    );

    final appended = ChapterLanguagePresenter.build(
      [
        chapter('en-1', 'en'),
        chapter('id-1', 'id'),
        chapter('id-2', 'id'),
      ],
      selectedKey: firstPage.selectedKey,
      labelForKey: label,
    );

    expect(appended.selectedKey, 'id');
    expect(appended.selectedChapters.map((chapter) => chapter.id), [
      'id-1',
      'id-2',
    ]);
  });

  test('falls back when selected lane disappears', () {
    final model = ChapterLanguagePresenter.build(
      [chapter('en-1', 'en')],
      selectedKey: 'id',
      labelForKey: label,
    );

    expect(model.selectedKey, isNull);
    expect(model.selectedChapters.single.id, 'en-1');
  });
}
