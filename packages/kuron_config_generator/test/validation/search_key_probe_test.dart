import 'package:kuron_config_generator/src/validation/negative_probes.dart'
    show FindingSeverity;
import 'package:kuron_config_generator/src/validation/search_key_probe.dart';
import 'package:test/test.dart';

void main() {
  group('verifySearchKey', () {
    test('all titles contain query → verified, no finding', () {
      final r = verifySearchKey(
          query: 'naruto',
          titles: ['Naruto Side A', 'Naruto Gaiden', 'Boruto: Naruto Next']);
      expect(r.verified, isTrue);
      expect(r.matchRatio, closeTo(1.0, 0.01));
      expect(r.finding, isNull);
    });

    test('zero matches → blocking finding (silent fail trap)', () {
      final r = verifySearchKey(
          query: 'keywrong', titles: ['Recent 1', 'Recent 2', 'Recent 3']);
      expect(r.verified, isFalse);
      expect(r.matchRatio, 0);
      expect(r.finding, isNotNull);
      expect(r.finding!.isBlocking, isTrue);
      expect(r.finding!.probe, 'search-key');
      expect(r.finding!.message, contains('unfiltered recents'));
    });

    test('fuzzy partial match (≥1 word of multi-word query) counts', () {
      final r = verifySearchKey(
        query: 'one piece',
        titles: ['One Piece 101', 'Piece of Cake', 'Unrelated Title'],
      );
      // 'piece' matches 2/3 ('One Piece 101' via both words, 'Piece of
      // Cake' via 'piece'; 'Unrelated' matches neither) → ratio ≥ 0.5.
      expect(r.verified, isTrue);
      expect(r.matchRatio, closeTo(2 / 3, 0.01));
    });

    test('below half match → warning finding, still verified', () {
      final r = verifySearchKey(
        query: 'gintama',
        titles: ['Gintama 1', 'Other A', 'Other B', 'Other C'],
      );
      expect(r.verified, isTrue); // warning not blocking
      expect(r.finding, isNotNull);
      expect(r.finding!.isBlocking, isFalse);
      expect(r.finding!.message, contains('fuzzy'));
    });

    test('empty query or titles → unverified, no finding', () {
      expect(verifySearchKey(query: '', titles: ['a']).verified, isFalse);
      expect(
        verifySearchKey(query: 'x', titles: []).finding,
        isNull,
      );
    });
  });

  group('CmsConfidence', () {
    test('ratio ≥ 0.6 → confident, no needsReview finding', () {
      final c = CmsConfidence(cmsId: 'madara', hits: 3, totalHints: 4);
      expect(c.ratio, closeTo(0.75, 0.01));
      expect(c.confident, isTrue);
      expect(c.needsReviewFinding, isNull);
      expect(c.toString(), contains('75%'));
      expect(c.toString(), isNot(contains('needsReview')));
    });

    test('ratio < 0.6 → needsReview info finding', () {
      final c = CmsConfidence(cmsId: 'custom', hits: 1, totalHints: 4);
      expect(c.confident, isFalse);
      final f = c.needsReviewFinding;
      expect(f, isNotNull);
      expect(f!.severity, FindingSeverity.info);
      expect(f.message, contains('25%'));
      expect(f.suggestion, contains('review'));
    });

    test('zero hints → ratio 0, not confident', () {
      final c = const CmsConfidence(cmsId: 'x', hits: 0, totalHints: 0);
      expect(c.ratio, 0);
      expect(c.confident, isFalse);
    });
  });
}
