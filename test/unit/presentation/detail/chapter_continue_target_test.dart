import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:nhasixapp/domain/entities/history.dart';
import 'package:nhasixapp/presentation/pages/detail/widgets/chapter_continue_fab.dart';

Chapter _chapter(String id, {String? externalUrl, String? title}) => Chapter(
      id: id,
      title: title ?? 'Chapter $id',
      url: '/chapter/$id',
      externalUrl: externalUrl,
    );

History _history(
  String chapterId, {
  required DateTime lastViewed,
  int lastPage = 5,
  int totalPages = 40,
}) =>
    History(
      contentId: chapterId,
      chapterId: chapterId,
      chapterTitle: 'Chapter $chapterId',
      lastViewed: lastViewed,
      lastPage: lastPage,
      totalPages: totalPages,
    );

void main() {
  test('resumes at the last page of the most recent chapter', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c1': _history('c1', lastViewed: now, lastPage: 12),
      },
      chapters: [_chapter('c1')],
    );

    expect(target, isNotNull);
    expect(target!.chapter.id, 'c1');
    expect(target.page, 12);
    expect(target.mode, ChapterContinueMode.resume);
  });

  test('finished chapter continues to the next chapter by name', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c1': _history('c1', lastViewed: now, lastPage: 20, totalPages: 20),
      },
      // Declared newest-first, exactly how most sources return them.
      chapters: [
        _chapter('c10', title: 'Chapter 10'),
        _chapter('c2b', title: 'Chapter 2.5'),
        _chapter('c2', title: 'Chapter 2'),
        _chapter('c1', title: 'Chapter 1'),
      ],
    );

    expect(target, isNotNull);
    expect(target!.chapter.id, 'c2');
    expect(target.page, 1);
    expect(target.mode, ChapterContinueMode.nextChapter);
  });

  test('finishing a mid-series chapter picks the next number, not the array',
      () {
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c2': _history('c2',
            lastViewed: DateTime(2026, 10, 21), lastPage: 9, totalPages: 9),
      },
      chapters: [
        _chapter('c3', title: 'Chapter 3'),
        _chapter('c2', title: 'Chapter 2'),
        _chapter('c1', title: 'Chapter 1'),
      ],
    );

    expect(target!.chapter.id, 'c3');
    expect(target.mode, ChapterContinueMode.nextChapter);
  });

  test('finished last chapter restarts the series at the first chapter', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c10': _history('c10', lastViewed: now, lastPage: 40, totalPages: 40),
      },
      chapters: [
        _chapter('c10', title: 'Chapter 10'),
        _chapter('c1', title: 'Chapter 1'),
        _chapter('c2', title: 'Chapter 2'),
      ],
    );

    expect(target!.chapter.id, 'c1');
    expect(target.page, 1);
    expect(target.mode, ChapterContinueMode.restart);
  });

  test('next chapter skips unreadable chapters', () {
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c1': _history('c1',
            lastViewed: DateTime(2026, 10, 21), lastPage: 20, totalPages: 20),
      },
      chapters: [
        _chapter('c1', title: 'Chapter 1'),
        _chapter('ext', title: 'Chapter 2', externalUrl: 'https://x.test'),
        _chapter('c3', title: 'Chapter 3'),
      ],
    );

    expect(target!.chapter.id, 'c3');
    expect(target.mode, ChapterContinueMode.nextChapter);
  });

  test('restart skips unreadable chapters declared earliest', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'c3': _history('c3', lastViewed: now, lastPage: 20, totalPages: 20),
      },
      chapters: [
        _chapter('c3', title: 'Chapter 3'),
        _chapter('ext', title: 'Chapter 1', externalUrl: 'https://x.test'),
        _chapter('c2', title: 'Chapter 2'),
      ],
    );

    expect(target!.chapter.id, 'c2');
    expect(target.page, 1);
    expect(target.mode, ChapterContinueMode.restart);
  });

  test('restart falls back to the finished chapter when names are unnumbered',
      () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'prologue': _history('prologue',
            lastViewed: now, lastPage: 20, totalPages: 20),
      },
      chapters: [
        _chapter('prologue', title: 'Prologue'),
        _chapter('extra', title: 'Bonus'),
      ],
    );

    expect(target!.chapter.id, 'prologue');
    expect(target.page, 1);
    expect(target.mode, ChapterContinueMode.restart);
  });

  test('chapter numbers parse numerically, not lexically', () {
    expect(chapterNumberFromName('Chapter 10'), 10);
    expect(chapterNumberFromName('Bab 2.5'), 2.5);
    expect(chapterNumberFromName('Ch. 7'), 7);
    expect(chapterNumberFromName('第12話'), 12);
    expect(chapterNumberFromName('12'), 12);
    expect(chapterNumberFromName('Prologue'), isNull);
  });

  test('most recently viewed chapter wins', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'old': _history('old', lastViewed: now.subtract(const Duration(days: 3))),
        'new': _history('new', lastViewed: now),
      },
      chapters: [_chapter('old'), _chapter('new')],
    );

    expect(target!.chapter.id, 'new');
  });

  test('external chapter is skipped in favour of a readable one', () {
    final now = DateTime(2026, 10, 21, 12);
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'ext': _history('ext', lastViewed: now),
        'c1': _history('c1',
            lastViewed: now.subtract(const Duration(hours: 2)), lastPage: 7),
      },
      chapters: [
        _chapter('ext', externalUrl: 'https://example.com/chapter'),
        _chapter('c1'),
      ],
    );

    expect(target!.chapter.id, 'c1');
    expect(target.page, 7);
  });

  test('synthesises the chapter when the loaded list does not contain it', () {
    final target = resolveChapterContinueTarget(
      chapterHistory: {
        'deep': _history('deep', lastViewed: DateTime(2026, 10, 21)),
      },
      chapters: const [],
    );

    expect(target, isNotNull);
    expect(target!.chapter.id, 'deep');
    expect(target.chapter.title, 'Chapter deep');
  });

  test('returns null without chapter history', () {
    expect(
      resolveChapterContinueTarget(chapterHistory: null, chapters: const []),
      isNull,
    );
    expect(
      resolveChapterContinueTarget(chapterHistory: const {}, chapters: const []),
      isNull,
    );
  });
}
