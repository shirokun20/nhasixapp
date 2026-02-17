import 'package:test/test.dart';
import 'package:kuron_komiktap/src/komiktap_scraper.dart';

void main() {
  group('KomiktapScraper', () {
    late KomiktapScraper scraper;

    setUp(() {
      scraper = KomiktapScraper();
    });

    test('parseSeriesDetail extracts metadata correctly', () {
      const htmlContent = r'''
<article id="post-162771" class="post-162771 hentry" itemscope="itemscope"
    itemtype="http://schema.org/CreativeWorkSeries">
    <div class="seriestucon">
        <div class="seriestuheader">
            <h1 class="entry-title" itemprop="name">Adabana Boku No Onee-chan after (MTL)</h1>
            <div class="seriestualt"> 徒花 + 僕のお姉ちゃん-after-</div>
        </div>
        <div class="seriestucontent">
            <div class="seriestucontl">
                <div class="thumb" itemprop="image" itemscope="" itemtype="https://schema.org/ImageObject"> <img
                        width="700" height="991" src="https://komiktap.info/wp-content/uploads/2026/01/cover.jpg-1.webp"
                        class="attachment- size- wp-post-image" alt="Adabana Boku No Onee-chan after (MTL)"
                        title="Adabana Boku No Onee-chan after (MTL)" itemprop="image" decoding="async"
                        fetchpriority="high"></div>
                <div data-id="162771" class="bookmark"><i class="far fa-bookmark" aria-hidden="true"></i> Bookmark</div>
                <div class="bmc">Followed by 21 people</div>
                <div class="rating bixbox">
                    <div class="rating-prc" itemscope="itemscope" itemprop="aggregateRating"
                        itemtype="//schema.org/AggregateRating">
                        <meta itemprop="worstRating" content="1">
                        <meta itemprop="bestRating" content="10">
                        <meta itemprop="ratingCount" content="10">
                        <div class="rtp">
                            <div class="rtb"><span style="width:80%"></span></div>
                        </div>
                        <div class="num" itemprop="ratingValue" content="8">8</div>
                    </div>
                </div>
            </div>
            <div class="seriestucontentr">
                <div class="seriestuhead">
                    <div class="entry-content entry-content-single" itemprop="description"></div>
                    <div class="lastend" style="display: none;">
                        <div class="inepcx"> <a href="#/"> <span>First:</span> <span class="epcur epcurfirst">Chapter
                                    ?</span> </a></div>
                        <div class="inepcx"> <a
                                href="https://komiktap.info/adabana-boku-no-onee-chan-after-mtl-chapter-2/">
                                <span>Latest:</span> <span class="epcur epcurlast">Chapter 2</span> </a></div>
                    </div>
                </div>
                <div class="seriestucont">
                    <div class="seriestucontr">
                        <table class="infotable">
                            <tbody>
                                <tr>
                                    <td>Status</td>
                                    <td>Ongoing</td>
                                </tr>
                                <tr>
                                    <td>Type</td>
                                    <td>Manga</td>
                                </tr>
                                <tr>
                                    <td>Released</td>
                                    <td>2025</td>
                                </tr>
                                <tr>
                                    <td>Author</td>
                                    <td>Tirotata</td>
                                </tr>
                                <tr>
                                    <td>Posted By</td>
                                    <td> <span itemprop="author" itemscope="" itemtype="https://schema.org/Person"
                                            class="author vcard"> <i itemprop="name">Ophisz</i> </span></td>
                                </tr>
                                <tr>
                                    <td>Posted On</td>
                                    <td> <time itemprop="datePublished" datetime="2026-01-23T11:03:29+08:00">Januari 23,
                                            2026</time></td>
                                </tr>
                                <tr>
                                    <td>Updated On</td>
                                    <td> <time itemprop="dateModified" datetime="2026-01-23T11:06:17+08:00">Januari 23,
                                            2026</time></td>
                                </tr>
                            </tbody>
                        </table>
                        <div class="seriestugenre"><a href="https://komiktap.info/genres/anal/" rel="tag">Anal</a> <a
                                href="https://komiktap.info/genres/sister/" rel="tag">Sister</a> <a
                                href="https://komiktap.info/genres/story-arc/" rel="tag">Story Arc</a></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</article>
      ''';

      final detail = scraper.parseSeriesDetail(htmlContent, 'test-slug');

      expect(detail.title, equals('Adabana Boku No Onee-chan after (MTL)'));
      expect(detail.favorites, equals(21));

      // Check author extraction
      expect(detail.author, equals('Tirotata'));

      // Check date extraction (Updated On preference)
      // 2026-01-23T11:06:17+08:00
      expect(detail.lastUpdate, isNotNull);
      expect(detail.lastUpdate!.year, equals(2026));
      expect(detail.lastUpdate!.month, equals(1));
      expect(detail.lastUpdate!.day, equals(23));

      // Check other metadata
      expect(detail.status, equals('Ongoing'));
      expect(detail.type, equals('Manga'));
    });
  });
}
