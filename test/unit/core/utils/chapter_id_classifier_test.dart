import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/chapter_id_classifier.dart';

void main() {
  group('ChapterIdClassifier.isCrotpediaChapterId', () {
    test('returns false for komikcast slug without source hint', () {
      const id = 'atm-ojisan-isekai-de-mote-ki-ga-tomaranai';

      final result = ChapterIdClassifier.isCrotpediaChapterId(id);

      expect(result, isFalse);
    });

    test('returns false for komikcast slug with non-crotpedia source', () {
      const id = 'atm-ojisan-isekai-de-mote-ki-ga-tomaranai';

      final result = ChapterIdClassifier.isCrotpediaChapterId(
        id,
        sourceId: 'komikcast',
      );

      expect(result, isFalse);
    });

    test('returns true for crotpedia chapter slug with chapter marker', () {
      const id = 'my-series-chapter-12-bahasa-indonesia';

      final result = ChapterIdClassifier.isCrotpediaChapterId(
        id,
        sourceId: 'crotpedia',
      );

      expect(result, isTrue);
    });

    test('returns false for numeric ids', () {
      const id = '123456';

      final result = ChapterIdClassifier.isCrotpediaChapterId(
        id,
        sourceId: 'crotpedia',
      );

      expect(result, isFalse);
    });
  });
}
