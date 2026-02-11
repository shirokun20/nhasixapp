import 'package:html/dom.dart' as html_dom;
import 'package:nhasixapp/domain/entities/entities.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.username,
    required super.body,
    super.avatarUrl,
    super.postDate,
  });

  factory CommentModel.fromHtml(html_dom.Element element) {
    // Extract ID
    // id="comment-123456"
    final idStr = element.id;
    final id = idStr.replaceFirst('comment-', '');

    // Extract Username
    // <div class="poster">...<span class="username">User</span>...</div>
    // Note: Structure might vary, sometimes inside anchor
    final usernameElement = element.querySelector('.username');
    final username = usernameElement?.text.trim() ?? 'Anonymous';

    // Extract Avatar
    // <img src="url" class="avatar">
    final avatarElement = element.querySelector('img.avatar');
    String? avatarUrl = avatarElement?.attributes['src'];
    // Handle data-src for lazy loading if present
    if (avatarElement?.attributes.containsKey('data-src') == true) {
      avatarUrl = avatarElement?.attributes['data-src'];
    }

    // Extract Body
    // <div class="body">...</div>
    final bodyElement = element.querySelector('.body');
    // We keep inner HTML to preserve formatting if needed, or text for simple display
    // Let's keep text for now but maybe clean up whitespace
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
