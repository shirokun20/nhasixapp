import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/data/datasources/remote/api/nhentai_api_comments_model.dart';
import 'package:nhasixapp/data/models/comment_model.dart';

void main() {
  group('Nhentai API Comments', () {
    final sampleJson = [
      {
        'id': 4336911,
        'gallery_id': 629156,
        'poster': {
          'id': 7973848,
          'username': 'DC : Tavikopi',
          'slug': 'dc-tavikopi',
          'avatar_url': 'avatars/7973848.png?_=aa2ef1f4ce7725f4',
          'is_superuser': false,
          'is_staff': false
        },
        'post_date': 1770787656,
        'body': "Hi, I'm selling my photos/videoshoots"
      },
      {
        'id': 4336885,
        'gallery_id': 629156,
        'poster': {
          'id': 5985791,
          'username': 'Colors82',
          'slug': 'colors82',
          'avatar_url': 'avatars/5985791.png?_=1f470d138228bc28',
          'is_superuser': false,
          'is_staff': false
        },
        'post_date': 1770785895,
        'body': 'wait so is asuna a white woman?'
      }
    ];

    test('should parse NhentaiComment from JSON', () {
      final comment = NhentaiComment.fromJson(sampleJson[0]);

      expect(comment.id, 4336911);
      expect(comment.galleryId, 629156);
      expect(comment.body, "Hi, I'm selling my photos/videoshoots");
      expect(comment.postDate, 1770787656);

      expect(comment.poster.id, 7973848);
      expect(comment.poster.username, 'DC : Tavikopi');
      expect(
          comment.poster.avatarUrl, 'avatars/7973848.png?_=aa2ef1f4ce7725f4');
    });

    test('should map NhentaiComment to CommentModel correctly', () {
      final apiComment = NhentaiComment.fromJson(sampleJson[0]);
      final model = CommentModel.fromApi(apiComment);

      expect(model.id, '4336911');
      expect(model.username, 'DC : Tavikopi');
      expect(model.body, "Hi, I'm selling my photos/videoshoots");

      // Check avatar URL fix (relative path -> full url)
      expect(model.avatarUrl,
          'https://i3.nhentai.net/avatars/7973848.png?_=aa2ef1f4ce7725f4');

      // Check date conversion (Unix timestamp to DateTime)
      // 1770787656 = 2026-02-11 12:27:36 UTC
      expect(model.postDate!.year, 2026);
      expect(model.postDate!.month, 2);
      expect(model.postDate!.day, 11);
    });
  });
}
