import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';
import 'package:test/test.dart';

void main() {
  group('GenericUrlBuilder.buildSearchUrl', () {
    const builder = GenericUrlBuilder(baseUrl: 'https://nhentai.net');

    test('removes empty sort query parameter', () {
      const filter = SearchFilter(
        query: 'language:"english"',
        page: 1,
      );

      final url = builder.buildSearchUrl(
        '/api/v2/search?query={query}&sort={sort}&page={page}',
        filter,
      );

      expect(
        url,
        'https://nhentai.net/api/v2/search?query=language%3A%22english%22&page=1',
      );
    });

    test('keeps sort query parameter when provided', () {
      const filter = SearchFilter(
        query: 'language:"english"',
        page: 1,
      );

      final url = builder.buildSearchUrl(
        '/api/v2/search?query={query}&sort={sort}&page={page}',
        filter,
        sortValue: 'date',
      );

      expect(
        url,
        'https://nhentai.net/api/v2/search?query=language%3A%22english%22&sort=date&page=1',
      );
    });

    test('removes empty query parameter when query is blank', () {
      const filter = SearchFilter(query: '', page: 2);

      final url = builder.buildSearchUrl(
        '/api/v2/search?query={query}&sort={sort}&page={page}',
        filter,
      );

      expect(url, 'https://nhentai.net/api/v2/search?page=2');
    });
  });
}
