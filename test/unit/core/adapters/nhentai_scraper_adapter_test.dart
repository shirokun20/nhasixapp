import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/adapters/nhentai_scraper_adapter_impl.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart' as app_filter;
import 'package:kuron_core/kuron_core.dart' as core;
// Mockito not needed as we use manual mock below

// Since Mockito is not in dev_dependencies, we create a manual mock
class MockRemoteDataSource implements RemoteDataSource {
  app_filter.SearchFilter? capturedFilter;

  @override
  Future<Map<String, dynamic>> searchContentWithPaginationViaApi(
      app_filter.SearchFilter filter) async {
    capturedFilter = filter;
    return {
      'contents': <dynamic>[],
      'pagination': {'totalPages': 1, 'hasNext': false, 'hasPrevious': false},
      'totalData': 0,
    };
  }

  // Stubs for other members to satisfy interface (ignoring unused ones for this test)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NhentaiScraperAdapterImpl', () {
    test('should correctly map excluded tags and filter types', () async {
      // Arrange
      final mockRemoteDataSource = MockRemoteDataSource();
      final adapter = NhentaiScraperAdapterImpl(mockRemoteDataSource);

      const coreFilter = core.SearchFilter(
        query: 'test query',
        page: 1,
        sort: core.SortOption.popular,
        includeTags: [
          core.FilterItem(id: 1, name: 'tag1', type: 'tag', isExcluded: false),
          core.FilterItem(
              id: 2, name: 'artist1', type: 'artist', isExcluded: false),
          core.FilterItem(
              id: 3, name: 'char1', type: 'character', isExcluded: false),
        ],
        excludeTags: [
          core.FilterItem(id: 4, name: 'tag2', type: 'tag', isExcluded: true),
          core.FilterItem(
              id: 5, name: 'group1', type: 'group', isExcluded: true),
        ],
      );

      // Act
      await adapter.search(coreFilter);

      // Assert
      final captured = mockRemoteDataSource.capturedFilter;
      expect(captured, isNotNull);

      // Check Tags (Included)
      expect(captured!.tags.any((t) => t.value == 'tag1' && !t.isExcluded),
          isTrue);

      // Check Tags (Excluded)
      expect(
          captured.tags.any((t) => t.value == 'tag2' && t.isExcluded), isTrue);

      // Check Artists
      expect(captured.artists.length, 1);
      expect(captured.artists.first.value, 'artist1');
      expect(captured.artists.first.isExcluded, isFalse);

      // Check Characters
      expect(captured.characters.length, 1);
      expect(captured.characters.first.value, 'char1');

      // Check Groups (Excluded)
      expect(captured.groups.length, 1);
      expect(captured.groups.first.value, 'group1');
      expect(captured.groups.first.isExcluded, isTrue);

      // Verify no mixed types in tags
      expect(captured.tags.length, 2); // tag1 and tag2 only
    });
  });
}
