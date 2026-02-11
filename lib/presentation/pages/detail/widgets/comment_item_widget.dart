import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentItemWidget extends StatelessWidget {
  final Comment comment;

  const CommentItemWidget({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  image: comment.avatarUrl != null &&
                          comment.avatarUrl!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(comment.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                    ? Icon(Icons.person, size: 20, color: theme.hintColor)
                    : null,
              ),
              const SizedBox(width: 12),

              // Username and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (comment.postDate != null)
                      Text(
                        dateFormat.format(comment.postDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment Body (Markdown)
          MarkdownWidget(
            data: comment.body,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            config: MarkdownConfig(
              configs: [
                PConfig(
                  textStyle: theme.textTheme.bodyMedium!,
                ),
                LinkConfig(
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  onTap: (url) {
                    // TODO: Handle link tap securely
                  },
                ),
                BlockquoteConfig(
                  sideColor: theme.colorScheme.primary,
                  // backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                CodeConfig(
                  style: TextStyle(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
