import 'package:equatable/equatable.dart';

/// Entity representing a user comment on a gallery
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.username,
    required this.body,
    this.avatarUrl,
    this.postDate,
  });

  /// Unique comment identifier
  final String id;

  /// Username of the commenter
  final String username;

  /// Comment content (may contain HTML)
  final String body;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// Date when the comment was posted
  final DateTime? postDate;

  @override
  List<Object?> get props => [id, username, body, avatarUrl, postDate];
}
