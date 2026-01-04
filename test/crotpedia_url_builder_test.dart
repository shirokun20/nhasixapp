import 'package:test/test.dart';
import 'package:kuron_crotpedia/src/crotpedia_url_builder.dart';

void main() {
  group('CrotpediaUrlBuilder', () {
    group('Browse URLs', () {
      test('home() returns base URL', () {
        expect(CrotpediaUrlBuilder.home(), equals('https://crotpedia.net'));
      });

      test('page() builds correct pagination URL', () {
        expect(
          CrotpediaUrlBuilder.page(2),
          equals('https://crotpedia.net/page/2/'),
        );
      });

      test('doujinList() returns doujin list URL', () {
        expect(
          CrotpediaUrlBuilder.doujinList(),
          equals('https://crotpedia.net/doujin-list/'),
        );
      });

      test('seriesDetail() builds correct series URL', () {
        expect(
          CrotpediaUrlBuilder.seriesDetail('test-series'),
          equals('https://crotpedia.net/baca/series/test-series/'),
        );
      });

      test('chapterReader() builds correct chapter URL', () {
        expect(
          CrotpediaUrlBuilder.chapterReader('test-chapter-1'),
          equals('https://crotpedia.net/baca/test-chapter-1/'),
        );
      });

      test('genre() builds correct genre URL', () {
        expect(
          CrotpediaUrlBuilder.genre('action'),
          equals('https://crotpedia.net/baca/genre/action/'),
        );
      });
    });

    group('Search URLs', () {
      test('simpleSearch() encodes query properly', () {
        final url = CrotpediaUrlBuilder.simpleSearch('Blue Archive');
        expect(url, contains('/?s='));
        expect(url, contains('Blue'));
        expect(url, contains('Archive'));
      });

      test('simpleSearch() handles special characters', () {
        final url = CrotpediaUrlBuilder.simpleSearch('test & query');
        expect(url, contains('test'));
        expect(url, contains('query'));
      });

      test('advancedSearch() with all parameters', () {
        final url = CrotpediaUrlBuilder.advancedSearch(
          title: 'neko',
          author: 'test author',
          artist: 'test artist',
          year: '2024',
          status: 'completed',
          type: 'Doujinshi',
          order: 'popular',
          genres: ['action', 'romance'],
        );

        expect(url, contains('title=neko'));
        expect(url, contains('author=test'));
        expect(url, contains('artist=test'));
        expect(url, contains('yearx=2024'));
        expect(url, contains('status=completed'));
        expect(url, contains('type=Doujinshi'));
        expect(url, contains('order=popular'));
        expect(url, contains('genre[]=action'));
        expect(url, contains('genre[]=romance'));
      });

      test('advancedSearch() includes all params even when empty', () {
        final url = CrotpediaUrlBuilder.advancedSearch();

        expect(url, contains('title='));
        expect(url, contains('author='));
        expect(url, contains('artist='));
        expect(url, contains('yearx='));
        expect(url, contains('status='));
        expect(url, contains('type='));
        expect(url, contains('order='));
      });

      test('advancedSearch() handles multiple genres', () {
        final url = CrotpediaUrlBuilder.advancedSearch(
          genres: ['action', 'romance', 'comedy'],
        );

        expect(url, contains('genre[]=action'));
        expect(url, contains('genre[]=romance'));
        expect(url, contains('genre[]=comedy'));
      });

      test('advancedSearch() encodes special characters', () {
        final url = CrotpediaUrlBuilder.advancedSearch(
          title: 'test & title',
          author: 'name with spaces',
        );

        expect(url, contains('title='));
        expect(url, contains('author='));
        // Should be URL encoded
        expect(url.contains('&'), isTrue);
      });
    });

    group('Auth URLs', () {
      test('login() returns login URL', () {
        expect(
          CrotpediaUrlBuilder.login(),
          equals('https://crotpedia.net/login/'),
        );
      });

      test('register() returns register URL', () {
        expect(
          CrotpediaUrlBuilder.register(),
          equals('https://crotpedia.net/register/'),
        );
      });

      test('bookmark() returns bookmark URL', () {
        expect(
          CrotpediaUrlBuilder.bookmark(),
          equals('https://crotpedia.net/bookmark/'),
        );
      });
    });

    group('API URLs', () {
      test('apiPosts() with defaults', () {
        final url = CrotpediaUrlBuilder.apiPosts();
        expect(url, contains('/wp-json/wp/v2/posts'));
        expect(url, contains('page=1'));
        expect(url, contains('per_page=10'));
      });

      test('apiPosts() with custom parameters', () {
        final url = CrotpediaUrlBuilder.apiPosts(page: 3, perPage: 25);
        expect(url, contains('page=3'));
        expect(url, contains('per_page=25'));
      });

      test('apiPost() builds correct single post URL', () {
        final url = CrotpediaUrlBuilder.apiPost(12345);
        expect(
          url,
          equals('https://crotpedia.net/wp-json/wp/v2/posts/12345'),
        );
      });
    });
  });
}
