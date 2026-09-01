import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';

void main() {
  group('Chapter isExternal / isReadableInApp', () {
    test('internal chapter: externalUrl null, pages > 0', () {
      const chapter = Chapter(
        id: 'fb164cb9-0d50-4ffd-9763-968d7862e209',
        title: 'Ch.34',
        url: 'fb164cb9-0d50-4ffd-9763-968d7862e209',
        pages: 19,
      );
      expect(chapter.isExternal, isFalse);
      expect(chapter.isReadableInApp, isTrue);
      expect(chapter.isUnavailable, isFalse);
    });

    test('external chapter with non-empty externalUrl', () {
      const chapter = Chapter(
        id: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        title: 'Ch.1.5',
        url: 'db996812-7984-4d1d-bd8b-af76c5b083b3',
        pages: 0,
        externalUrl:
            'https://comikey.com/read/isekai-returnee-is-too-op-manga/kj2PPk/chapter-1-5/',
      );
      expect(chapter.isExternal, isTrue);
      expect(chapter.isReadableInApp, isFalse);
    });

    test('empty/whitespace externalUrl is NOT external', () {
      const chapter = Chapter(
        id: 'a',
        title: 'Ch.1',
        url: 'a',
        pages: 10,
        externalUrl: '   ',
      );
      expect(chapter.isExternal, isFalse);
      expect(chapter.isReadableInApp, isTrue);
    });

    test('externalUrl set but isUnavailable false → isReadableInApp false', () {
      const chapter = Chapter(
        id: 'b',
        title: 'Ch.1',
        url: 'b',
        pages: 0,
        externalUrl: 'https://example.com/chapter-1',
        isUnavailable: false,
      );
      expect(chapter.isExternal, isTrue);
      expect(chapter.isUnavailable, isFalse);
      expect(chapter.isReadableInApp, isFalse);
    });

    test('internal but pages == 0 → not readable in app', () {
      const chapter = Chapter(
        id: 'c',
        title: 'Ch.1',
        url: 'c',
        pages: 0,
      );
      expect(chapter.isExternal, isFalse);
      expect(chapter.isReadableInApp, isFalse);
    });

    test('isUnavailable=true internal chapter → not readable', () {
      const chapter = Chapter(
        id: 'd',
        title: 'Ch.1',
        url: 'd',
        pages: 20,
        isUnavailable: true,
      );
      expect(chapter.isExternal, isFalse);
      expect(chapter.isUnavailable, isTrue);
      expect(chapter.isReadableInApp, isFalse);
    });

    test('pages null (legacy data) with no external → readable', () {
      const chapter = Chapter(
        id: 'e',
        title: 'Ch.1',
        url: 'e',
      );
      expect(chapter.pages, isNull);
      expect(chapter.isExternal, isFalse);
      expect(chapter.isReadableInApp, isTrue);
    });
  });

  group('Chapter copyWith', () {
    test('preserves externalUrl/pages/isUnavailable when not provided', () {
      const chapter = Chapter(
        id: 'x',
        title: 'Ch.1',
        url: 'x',
        pages: 5,
        externalUrl: 'https://example.com/x',
      );
      final next = chapter.copyWith(title: 'Ch.2');
      expect(next.id, 'x');
      expect(next.title, 'Ch.2');
      expect(next.pages, 5);
      expect(next.externalUrl, 'https://example.com/x');
      expect(next.isExternal, isTrue);
    });

    test('overrides externalUrl/pages/isUnavailable when provided', () {
      const chapter = Chapter(
        id: 'x',
        title: 'Ch.1',
        url: 'x',
        pages: 0,
        externalUrl: 'https://example.com/x',
      );
      final next = chapter.copyWith(
        pages: 10,
        isUnavailable: false,
      );
      expect(next.pages, 10);
      expect(next.isUnavailable, isFalse);
      expect(next.externalUrl, 'https://example.com/x');
      expect(next.isExternal, isTrue);
    });
  });

  group('Chapter equality (Equatable)', () {
    test('two chapters with identical external fields are equal', () {
      const a = Chapter(
        id: '1',
        title: 'Ch.1',
        url: '1',
        pages: 10,
        externalUrl: 'https://example.com/1',
        isUnavailable: false,
      );
      const b = Chapter(
        id: '1',
        title: 'Ch.1',
        url: '1',
        pages: 10,
        externalUrl: 'https://example.com/1',
        isUnavailable: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different externalUrl makes chapters unequal', () {
      const a = Chapter(
        id: '1',
        title: 'Ch.1',
        url: '1',
        externalUrl: 'https://a.com',
      );
      const b = Chapter(
        id: '1',
        title: 'Ch.1',
        url: '1',
        externalUrl: 'https://b.com',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
