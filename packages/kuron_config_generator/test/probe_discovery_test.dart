import 'package:test/test.dart';
import 'package:kuron_config_generator/src/discovery/cms_detector.dart';
import 'package:kuron_config_generator/src/discovery/api_detector.dart';
import 'package:kuron_config_generator/src/discovery/http_probe.dart';

void main() {
  group('Probe Content Type Inference', () {
    test('infers HTML from <!DOCTYPE', () {
      final result = ProbeResult(
        url: 'https://example.com/',
        statusCode: 200,
        body: '<!DOCTYPE html><html><body>Hello</body></html>',
        contentType: ProbeContentType.html,
      );
      expect(result.isSuccess, true);
      expect(result.contentType, ProbeContentType.html);
    });

    test('infers JSON from decoded body', () {
      final result = ProbeResult(
        url: 'https://api.example.com/',
        statusCode: 200,
        body: '{"id": 1, "title": "test"}',
        contentType: ProbeContentType.json,
      );
      expect(result.isSuccess, true);
      expect(result.contentType, ProbeContentType.json);
      final json = result.jsonBody;
      expect(json, isNotNull);
      expect(json['title'], 'test');
    });

    test('returns unknown for empty body', () {
      final result = ProbeResult(
        url: 'https://example.com/',
        statusCode: 200,
        body: '',
        contentType: ProbeContentType.unknown,
      );
      expect(result.contentType, ProbeContentType.unknown);
    });

    test('isBlocked for 403', () {
      final result = ProbeResult(
        url: 'https://example.com/',
        statusCode: 403,
        body: 'Blocked',
        contentType: ProbeContentType.unknown,
      );
      expect(result.isBlocked, true);
    });

    test('isBlocked for Cloudflare challenge pages with HTTP 200', () {
      final result = ProbeResult(
        url: 'https://hentairead.com/hentai/',
        statusCode: 200,
        body: '''
<!DOCTYPE html>
<html>
  <head><title>Just a moment...</title></head>
  <body>
    Performing security verification
    <script>window._cf_chl_opt = {};</script>
  </body>
</html>
''',
        contentType: ProbeContentType.html,
      );
      expect(result.isBlocked, true);
    });
  });

  group('API Detector', () {
    test('detects list from JSON array', () {
      final json = [
        {'id': 1, 'title': 'One'},
        {'id': 2, 'title': 'Two'},
      ];
      final result = inferApi('https://api.example.com/manga', json);
      expect(result.hasList, true);
      expect(result.confidence, greaterThan(0));
    });

    test('detects paginated list from data key', () {
      final json = {
        'data': [
          {'id': 1, 'title': 'One'}
        ],
        'page': 1
      };
      final result = inferApi('https://api.example.com/manga', json);
      expect(result.hasList, true);
      expect(result.listItemsPath, 'data');
    });

    test('detects detail from known manga fields', () {
      final json = {
        'id': 1,
        'title': 'Test Manga',
        'cover': 'cover.jpg',
        'description': 'A test'
      };
      final result = inferApi('https://api.example.com/manga/1', json);
      expect(result.hasDetail, true);
      expect(result.hasList, false);
    });

    test('detects results key pattern', () {
      final json = {
        'results': [
          {'id': 1}
        ],
        'total': 100
      };
      final result = inferApi('https://api.example.com/search?q=test', json);
      expect(result.hasList, true);
      expect(result.listItemsPath, 'results');
      // queryParam is derived from response body keys, not URL params
      expect(result.queryParam, isNull);
    });

    test('returns low confidence for small maps', () {
      final json = {'status': 'ok', 'message': 'hello'};
      final result = inferApi('https://api.example.com/', json);
      expect(result.confidence, lessThan(0.5));
    });
  });

  group('CMS Detector', () {
    test('detects Madara from page-item class', () {
      const html =
          '<html><body><div class="page-item">Manga</div></body></html>';
      final result = detectCms(html);
      expect(result.cmsId, 'madara');
    });

    test('falls back to custom for random HTML', () {
      const html = '<html><body><div>Hello World</div></body></html>';
      final result = detectCms(html);
      expect(result.cmsId, 'custom');
      expect(result.selectors, isNotEmpty);
    });
  });
}
