import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/data/datasources/remote/nhentai_scraper.dart';

class MockLogger extends Mock implements Logger {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  late NhentaiScraper scraper;
  late MockLogger mockLogger;
  late MockRemoteConfigService mockRemoteConfigService;

  setUp(() {
    mockLogger = MockLogger();
    mockRemoteConfigService = MockRemoteConfigService();
    // Return null config to use default selectors
    when(() => mockRemoteConfigService.getConfig(any())).thenReturn(null);

    scraper = NhentaiScraper(
      logger: mockLogger,
      remoteConfigService: mockRemoteConfigService,
    );
  });

  group('NhentaiScraper Comments', () {
    test('should parse comments correctly', () {
      const html = '''
      <div id="comments">
        <div class="comment" id="comment-123456">
          <div class="poster">
            <a href="/users/user1" class="username">User1</a>
            <img src="https://example.com/avatar1.jpg" class="avatar">
          </div>
          <div class="body">This is a comment.</div>
          <time datetime="2023-01-01T12:00:00+00:00"></time>
        </div>
        <div class="comment" id="comment-789012">
          <div class="poster">
            <span class="username">User2</span>
            <img class="avatar" data-src="https://example.com/avatar2.jpg">
          </div>
          <div class="body">Another comment with <b>bold</b> text.</div>
          <time datetime="2023-01-02T15:30:00+00:00"></time>
        </div>
      </div>
      ''';

      final comments = scraper.parseComments(html);

      expect(comments.length, 2);

      // Check first comment
      expect(comments[0].id, '123456');
      expect(comments[0].username, 'User1');
      expect(comments[0].body, 'This is a comment.');
      expect(comments[0].avatarUrl, 'https://example.com/avatar1.jpg');
      expect(comments[0].postDate, DateTime.parse('2023-01-01T12:00:00+00:00'));

      // Check second comment
      expect(comments[1].id, '789012');
      expect(comments[1].username, 'User2');
      expect(comments[1].body, 'Another comment with bold text.');
      expect(comments[1].avatarUrl, 'https://example.com/avatar2.jpg');
      expect(comments[1].postDate, DateTime.parse('2023-01-02T15:30:00+00:00'));
    });

    test('should return empty list when no comments container found', () {
      const html = '<div>No comments here</div>';
      final comments = scraper.parseComments(html);
      expect(comments, isEmpty);
    });

    test('should handle parsing errors gracefully', () {
      const html = '''
      <div id="comments">
        <div class="comment" id="comment-1">
          <!-- Missing fields -->
        </div>
      </div>
      ''';

      final comments = scraper.parseComments(html);
      expect(comments.length, 1);
      // Should have defaults
      expect(comments[0].username, 'Anonymous');
      expect(comments[0].body, '');
    });
  });
}
