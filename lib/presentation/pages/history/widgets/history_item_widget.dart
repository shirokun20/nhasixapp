import 'package:flutter/material.dart';

import '../../../../core/constants/text_style_const.dart';
import '../../../../domain/entities/entities.dart';
import '../../../widgets/progressive_image_widget.dart';

/// Widget for displaying individual history item
class HistoryItemWidget extends StatelessWidget {
  const HistoryItemWidget({
    super.key,
    required this.history,
    required this.onTap,
    this.onRemove,
    this.showRemoveButton = true,
  });

  final History history;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(context),
              
              const SizedBox(width: 16),
              
              // Content info
              Expanded(
                child: _buildContentInfo(context),
              ),
              
              // Actions
              if (showRemoveButton && onRemove != null)
                _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 120,
        child: history.coverUrl != null
            ? ProgressiveImageWidget(
                networkUrl: history.coverUrl!,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildContentInfo(BuildContext context) {
    final progressPercentage = history.totalPages > 0 
        ? (history.lastPage / history.totalPages).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          history.title ?? 'Unknown Title',
          style: TextStyleConst.contentTitle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Progress info
        Row(
          children: [
            Icon(
              Icons.menu_book,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${history.lastPage}/${history.totalPages} pages',
              style: TextStyleConst.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (history.isCompleted) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              history.isCompleted 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            minHeight: 4,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Last viewed
        Text(
          _formatLastViewed(history.lastViewed),
          style: TextStyleConst.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        
        // Time spent (if available)
        if (history.timeSpent.inMinutes > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimeSpent(history.timeSpent),
                style: TextStyleConst.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Continue reading button
        IconButton(
          onPressed: onTap,
          icon: Icon(
            history.isCompleted ? Icons.replay : Icons.play_arrow,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: history.isCompleted ? 'Read Again' : 'Continue Reading',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Remove button
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Remove from History',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    );
  }

  String _formatLastViewed(DateTime lastViewed) {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inDays > 0) {
      return 'Last read ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return 'Last read ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last read ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Last read just now';
    }
  }

  String _formatTimeSpent(Duration timeSpent) {
    if (timeSpent.inHours > 0) {
      return '${timeSpent.inHours}h ${timeSpent.inMinutes % 60}m reading time';
    } else if (timeSpent.inMinutes > 0) {
      return '${timeSpent.inMinutes}m reading time';
    } else {
      return 'Less than 1 minute';
    }
  }
}
