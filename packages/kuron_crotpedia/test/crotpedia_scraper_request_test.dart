import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_crotpedia/src/crotpedia_scraper.dart';

void main() {
  group('CrotpediaScraper - Request List', () {
    late CrotpediaScraper scraper;
    late String requestListHtml;

    setUpAll(() async {
      scraper = CrotpediaScraper(customSelectors: {});
      
      // Load the actual HTML file (from main project root)
      final htmlFile = File(
        '../../informations/documentation/crotpedia/html/html_halaman_list_request_page_with_pagination.html',
      );
      requestListHtml = await htmlFile.readAsString();
    });

    test('should parse request list with genres', () {
      final results = scraper.parseRequestList(requestListHtml);

      // Should have 10 items on the page
      expect(results.length, greaterThan(0));
      
      // Check first item
      final firstItem = results.first;
      expect(firstItem.title, isNotEmpty);
      expect(firstItem.title, contains('Shibotte Shiborare'));
      
      // Verify genres are parsed
      expect(firstItem.genres, isNotEmpty);
      print('First item genres: ${firstItem.genres}');
      
      // Should have multiple genres
      expect(firstItem.genres.length, greaterThan(5));
      
      // Check that genres contain expected values
      expect(firstItem.genres.values, contains('Ahegao'));
      expect(firstItem.genres.values, contains('Big Breast'));
      expect(firstItem.genres.values, contains('Vanilla'));
      
      // Print all parsed items for debugging
      for (var i = 0; i < results.length && i < 3; i++) {
        print('\nItem $i:');
        print('  Title: ${results[i].title}');
        print('  Genres: ${results[i].genres}');
      }
    });
    
    test('should parse all items on the page', () {
      final results = scraper.parseRequestList(requestListHtml);
      
      // Based on the HTML, there should be 10 items
      expect(results.length, equals(10));
      
      // Verify each item has genres
      for (var item in results) {
        expect(item.title, isNotEmpty, reason: 'Title should not be empty');
        expect(item.genres, isNotEmpty, reason: 'Genres should be parsed for ${item.title}');
      }
    });
  });
}
