import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart';

import 'package:nhasixapp/presentation/utils/search_filter_presenter.dart';

void main() {
  group('SearchFilterPresenter', () {
    test('buildHelpfulMessage returns different messages based on hasFilters',
        () {
      const emptyFilter = SearchFilter();
      final messageEmpty =
          SearchFilterPresenter.buildHelpfulMessage(emptyFilter);
      expect(messageEmpty, 'Try searching with different keywords.');

      const activeFilter = SearchFilter(query: 'test');
      final messageActive =
          SearchFilterPresenter.buildHelpfulMessage(activeFilter);
      expect(
          messageActive, 'Try adjusting your search filters or search terms.');
    });

    test('buildFilterSummary formats correctly for empty filter', () {
      const filter = SearchFilter();
      final summary = SearchFilterPresenter.buildFilterSummary(filter);
      expect(summary, '');
    });

    test('buildFilterSummary formats correctly for query only', () {
      const filter = SearchFilter(query: 'naruto');
      final summary = SearchFilterPresenter.buildFilterSummary(filter);
      expect(summary, 'Query: "naruto"');
    });

    test('buildFilterSummary formats correctly for includes and excludes', () {
      const filter = SearchFilter(
        query: 'test',
        tags: [
          FilterItem(value: 'action', isExcluded: false),
          FilterItem(value: 'romance', isExcluded: true),
        ],
        language: 'english',
      );
      final summary = SearchFilterPresenter.buildFilterSummary(filter);
      expect(summary,
          'Query: "test" • Tags: action • Exclude Tags: romance • Language: english');
    });

    test('buildFilterSummary formats all filter types', () {
      const filter = SearchFilter(
        groups: [FilterItem(value: 'groupA', isExcluded: false)],
        characters: [FilterItem(value: 'charB', isExcluded: true)],
        parodies: [FilterItem(value: 'parodyC', isExcluded: false)],
        artists: [FilterItem(value: 'artistD', isExcluded: true)],
        category: 'manga',
      );

      final summary = SearchFilterPresenter.buildFilterSummary(filter);
      expect(summary.contains('Groups: groupA'), isTrue);
      expect(summary.contains('Exclude Characters: charB'), isTrue);
      expect(summary.contains('Parodies: parodyC'), isTrue);
      expect(summary.contains('Exclude Artists: artistD'), isTrue);
      expect(summary.contains('Category: manga'), isTrue);
    });
  });
}
