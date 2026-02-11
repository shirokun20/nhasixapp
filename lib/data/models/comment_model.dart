import 'package:html/dom.dart' as html_dom;
import 'package:nhasixapp/domain/entities/entities.dart';
import '../datasources/remote/api/nhentai_api_comments_model.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.username,
    required super.body,
    super.avatarUrl,
    super.postDate,
  });

  factory CommentModel.fromApi(NhentaiComment apiComment) {
    var avatarUrl = apiComment.poster.avatarUrl;
    avatarUrl = !avatarUrl.startsWith('http') || avatarUrl.startsWith('https')
        ? 'https://i3.nhentai.net/$avatarUrl'
        : avatarUrl;

    return CommentModel(
      id: apiComment.id.toString(),
      username: apiComment.poster.username,
      body: apiComment.body,
      avatarUrl: avatarUrl,
      // API returns unix timestamp in seconds
      postDate: DateTime.fromMillisecondsSinceEpoch(apiComment.postDate * 1000),
    );
  }

  factory CommentModel.fromHtml(html_dom.Element element) {
    // Extract ID
    // id="comment-123456"
    final idStr = element.id;
    final id = idStr.replaceFirst('comment-', '');

    // Extract Username
    // Strategy 1: <span class="username">User</span> (Legacy)
    // Strategy 2: <div class="header">...<b><a ...>User</a></b>... (New)
    var usernameElement = element.querySelector('.username');
    if (usernameElement == null) {
      // Try finding bold tag inside header
      final headerLeft = element.querySelector('.header .left b');
      if (headerLeft != null) {
        usernameElement = headerLeft;
      }
    }
    final username = usernameElement?.text.trim() ?? 'Anonymous';

    // Extract Avatar
    // Strategy 1: <img src="url" class="avatar"> (Legacy)
    // Strategy 2: <a class="avatar"><img ...></a> (New)
    var avatarElement = element.querySelector('img.avatar');
    avatarElement ??= element.querySelector('a.avatar img');

    String? avatarUrl = avatarElement?.attributes['src'];
    // Handle data-src for lazy loading if present
    if (avatarElement?.attributes.containsKey('data-src') == true) {
      avatarUrl = avatarElement?.attributes['data-src'];
    }

    // Extract Body
    // <div class="body">...</div>
    final bodyElement = element.querySelector('.body');
    final body = bodyElement?.text.trim() ?? '';

    // Extract Date
    // <time datetime="2020-01-01T00:00:00+00:00">...</time>
    final timeElement = element.querySelector('time');
    DateTime? postDate;
    if (timeElement != null) {
      final datetimeStr = timeElement.attributes['datetime'];
      if (datetimeStr != null) {
        postDate = DateTime.tryParse(datetimeStr);
      }
    }

    return CommentModel(
      id: id,
      username: username,
      body: body,
      avatarUrl: avatarUrl,
      postDate: postDate,
    );
  }
}
