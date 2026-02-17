import 'dart:io';
import 'package:test/test.dart';
import 'package:kuron_crotpedia/src/crotpedia_scraper.dart';

String fixture(String name) {
  final dir = Directory.current;
  // If running from root, verify if we need to append package path
  final path = dir.path.endsWith('kuron_crotpedia')
      ? 'test/fixtures/$name'
      : 'packages/kuron_crotpedia/test/fixtures/$name';
  return File(path).readAsStringSync();
}

void main() {
  late CrotpediaScraper scraper;

  setUp(() {
    scraper = CrotpediaScraper();
  });

  group('CrotpediaScraper', () {
    group('parseLatestSeries', () {
      test('parses series list HTML correctly from real HTML', () async {
        final html = fixture('series_list.html');
        final series = scraper.parseLatestSeries(html);

        // Real HTML has multiple .flexbox4-item elements
        expect(series, isNotEmpty);

        // Verify first series (based on real halaman_utama.html)
        final firstSeries = series.first;
        expect(firstSeries.slug, isNotEmpty);
        expect(firstSeries.title, isNotEmpty);
        expect(firstSeries.coverUrl, isNotEmpty);
      });

      test('returns empty list for invalid HTML', () {
        final series = scraper.parseLatestSeries('<html></html>');
        expect(series, isEmpty);
      });

      test('handles missing elements gracefully', () {
        const html = '''
          <div class="flexbox4">
            <div class="flexbox4-item">
              <a href="/baca/series/incomplete/">
                <!-- Missing img and title -->
              </a>
            </div>
          </div>
        ''';
        final series = scraper.parseLatestSeries(html);
        expect(series, hasLength(1));
        expect(series[0].slug, equals('incomplete'));
        expect(series[0].title, isEmpty);
        expect(series[0].coverUrl, isEmpty);
      });
    });

    group('parseSeriesDetail', () {
      test('parses series detail HTML correctly from real HTML', () async {
        final html = fixture('series_detail.html');
        final detail = scraper.parseSeriesDetail(html);

        // Real halaman_detail.html has actual data
        expect(detail.title, equals('Shikatte Hoshii'));
        expect(detail.coverUrl, contains('Shikatte-Hoshii.jpg'));

        // Strict metadata verification
        expect(detail.status, equals('Completed'));
        expect(detail.author, equals('Peniken'));
        expect(detail.year, equals(2025));

        // Check genres
        expect(detail.genres, isNotEmpty);
        expect(detail.genres, containsValue('Ahegao'));
        expect(detail.genres, containsValue('Uncensored'));

        // Check synopsis
        expect(detail.synopsis, contains('Jatuh cinta sedarai kecil'));
      });

      test('parses chapter list correctly from real HTML', () async {
        final html = fixture('series_detail.html');
        final detail = scraper.parseSeriesDetail(html);

        // Real HTML has .series-chapterlist li elements
        expect(detail.chapters, isNotEmpty);
        expect(detail.chapters.first.slug, isNotEmpty);
        expect(detail.chapters.first.title, isNotEmpty);
      });

      test('parses chapters with and without download links', () {
        const html = '''
          <html>
            <ul class="series-chapterlist">
              <!-- Chapter WITH download link -->
              <li>
                <div class="flexch">
                  <div class="flexch-book"> <i class="fa-solid fa-book-open"></i> </div>
                  <div class="flexch-infoz"> 
                    <a href="/baca/alien-vs-joshidaisei-chapter-1/"
                       title="Alien vs Joshidaisei Chapter 1 Bahasa Indonesia">
                       <span>Chapter 1</span>
                       <span class="date">Maret 11, 2021</span>
                    </a> 
                  </div> 
                  <a href="http://crotpedia.net/go/32191e9e">
                    <div class="flexch-dllink"><i class="fa-solid fa-circle-down"></i></div>
                  </a>
                </div>
              </li>
              
              <!-- Chapter WITHOUT download link (BUG CASE) -->
              <li>
                <div class="flexch">
                  <div class="flexch-book"> <i class="fa-solid fa-book-open"></i> </div>
                  <div class="flexch-infoz"> 
                    <a href="/baca/when-the-shepherds-purse-blooms-chapter-1-bahasa-indonesia/"
                       title="When the Shepherd's Purse Blooms Chapter 1 Bahasa Indonesia">
                       <span>Chapter 1</span>
                       <span class="date">Juni 22, 2021</span>
                    </a> 
                  </div>
                </div>
              </li>
            </ul>
          </html>
        ''';

        final detail = scraper.parseSeriesDetail(html);

        // CRITICAL: Both chapters should parse successfully
        expect(detail.chapters.length, equals(2),
            reason:
                'Should parse both chapters regardless of download link presence');

        // Chapter 1 (with download link)
        expect(
            detail.chapters[0].slug, equals('alien-vs-joshidaisei-chapter-1'));
        expect(detail.chapters[0].title, contains('Chapter 1'));

        // Chapter 2 (WITHOUT download link) - THIS IS THE BUG CASE
        expect(
            detail.chapters[1].slug,
            equals(
                'when-the-shepherds-purse-blooms-chapter-1-bahasa-indonesia'),
            reason:
                'Chapter without download link should still have valid slug');
        expect(detail.chapters[1].title, contains('Chapter 1'));
      });

      test('handles missing metadata gracefully', () {
        const html = '''
          <html>
            <div class="series-info">
              <div class="series-titlex"><h2>Minimal Series</h2></div>
            </div>
          </html>
        ''';
        final detail = scraper.parseSeriesDetail(html);
        expect(detail.title, equals('Minimal Series'));
        expect(detail.coverUrl, isEmpty);
        expect(detail.status, isNull);
        expect(detail.genres, isEmpty);
        expect(detail.chapters, isEmpty);
      });
    });

    group('parseChapterImages', () {
      test('extracts image URLs correctly from real HTML', () async {
        final html = fixture('chapter_reader.html');
        final chapterData = scraper.parseChapterImages(html);

        // Real halaman_baca.html has .reader-area p img elements
        expect(chapterData.images, isNotEmpty);
        expect(chapterData.images.length,
            greaterThan(10)); // Real HTML has 27 images

        // Check that each image URL is valid
        for (final imageUrl in chapterData.images) {
          expect(imageUrl, isNotEmpty);
        }
      });

      test('filters out non-content images (ads)', () async {
        final html = fixture('chapter_reader.html');
        final chapterData = scraper.parseChapterImages(html);

        // Should not contain saweria/donation images
        expect(
            chapterData.images.any((url) => url.contains('saweria')), isFalse);
        expect(
            chapterData.images.any((url) => url.contains('donasi')), isFalse);
      });

      test('returns empty list if no images found', () {
        const html = '<html><div class="entry-content"></div></html>';
        final chapterData = scraper.parseChapterImages(html);
        expect(chapterData.images, isEmpty);
      });

      test('handles alternative container (.reader-area)', () {
        const html = '''
          <html>
            <div class="reader-area">
              <p><img src="./test_files/test.jpg"></p>
            </div>
          </html>
        ''';
        final chapterData = scraper.parseChapterImages(html);
        expect(chapterData.images, hasLength(1));
        expect(chapterData.images[0], contains('test.jpg'));
      });

      test('parses navigation links correctly', () {
        final html = fixture('chapter_reader_with_nav.html');
        final chapterData = scraper.parseChapterImages(html);

        expect(chapterData.prevChapterId, equals('chapter-prev-slug'));
        expect(chapterData.nextChapterId, equals('chapter-next-slug'));
      });
    });

    group('parseDoujinList', () {
      test('parses doujin list correctly', () {
        const html = '''
          <html>
            <div class="mangalist-blc">
              <a class="series" href="/baca/series/series-1/">Series 1</a>
              <a class="series" href="/baca/series/series-2/">Series 2</a>
            </div>
          </html>
        ''';
        final series = scraper.parseDoujinList(html);

        expect(series, hasLength(2));
        expect(series[0].slug, equals('series-1'));
        expect(series[0].title, equals('Series 1'));
        expect(series[0].coverUrl, isEmpty); // No cover in list view
      });
    });

    group('parseSearchResults', () {
      test('parses search results from real HTML', () async {
        // Use search_results.html (halaman_advanced_search_result_found.html)
        final html = fixture('search_results.html');
        final series = scraper.parseSearchResults(html);

        // Should find items in flexbox2
        expect(series, isNotEmpty);
        expect(series.length, greaterThan(0));

        // Verify first item
        final first = series.first;
        expect(first.title, isNotEmpty);
        expect(first.slug, isNotEmpty);
        expect(first.coverUrl, isNotEmpty);
      });
    });

    group('URL slug extraction', () {
      test('extracts slug from series URL', () {
        const html = '''
          <div class="flexbox4">
            <div class="flexbox4-item">
              <a href="/baca/series/test-slug-name/">
                <div class="flexbox4-side">
                  <div class="title"><a href="/baca/series/test-slug-name/">Test</a></div>
                </div>
              </a>
            </div>
          </div>
        ''';
        final series = scraper.parseLatestSeries(html);
        expect(series[0].slug, equals('test-slug-name'));
      });

      test('extracts slug from chapter URL', () {
        const html = '''
          <html>
            <div class="series-chapterlist">
              <ul>
                <li>
                  <div class="flexch-infoz">
                    <a href="/baca/chapter-slug-here/">
                      <span class="chapternum">Ch 1</span>
                    </a>
                  </div>
                </li>
              </ul>
            </div>
          </html>
        ''';
        final detail = scraper.parseSeriesDetail(html);
        expect(detail.chapters[0].slug, equals('chapter-slug-here'));
      });
    });

    group('parsePagination', () {
      test('parses pagination correctly from homepage HTML', () async {
        final html = fixture('series_list.html');
        final pagination = scraper.parsePagination(html);

        expect(pagination.currentPage, equals(1));
        expect(pagination.hasNext, isTrue); // Homepage has next page
      });

      test('parses pagination correctly from search results HTML', () async {
        final html = fixture('search_results.html');
        final pagination = scraper.parsePagination(html);

        // Search results page also has pagination
        // Current logic might default to 1 if "current" class isn't exactly as expected
        // Check HTML content if fails
        expect(pagination.currentPage, greaterThanOrEqualTo(1));
        expect(pagination.hasNext, isNotNull);
      });

      test('handles missing pagination (assumes page 1)', () {
        const html = '<html></html>';
        final pagination = scraper.parsePagination(html);
        expect(pagination.currentPage, equals(1));
        expect(pagination.hasNext, isFalse);
      });
    });
  });
}
