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
    // Fix avatar URL if it's relative or missing protocol
    // API often returns something like "/avatars/..." or "//i.nhentai.net/..."
    if (avatarUrl.startsWith('//')) {
      avatarUrl = 'https:$avatarUrl';
    } else if (avatarUrl.startsWith('/')) {
      // Default to i3 for avatars if relative path
      avatarUrl = 'https://i3.nhentai.net$avatarUrl';
    } else if (!avatarUrl.startsWith('http')) {
      // Handle paths like "avatars/..."
      avatarUrl = 'https://i3.nhentai.net/$avatarUrl';
    }

    return CommentModel(
      id: apiComment.id.toString(),
      username: apiComment.poster.username,
      body: apiComment.body,
      avatarUrl: avatarUrl,
      // API returns unix timestamp in seconds
      postDate: DateTime.fromMillisecondsSinceEpoch(apiComment.postDate * 1000),
    );
  }
}
