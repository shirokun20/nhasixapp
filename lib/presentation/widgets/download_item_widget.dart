import 'package:flutter/material.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';

/// Widget for displaying individual download item with progress and actions
class DownloadItemWidget extends StatelessWidget {
  const DownloadItemWidget({
    super.key,
    required this.download,
    this.onTap,
    this.onAction,
  });

  final DownloadStatus download;
  final VoidCallback? onTap;
  final Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorsConst.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Content ${download.contentId}',
                          style: TextStyleConst.titleMedium.copyWith(
                            color: ColorsConst.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          download.statusText,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              if (download.totalPages > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: download.progress,
                        backgroundColor:
                            ColorsConst.onSurface.withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getProgressColor()),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${download.progressPercentage}%',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Details row
              Row(
                children: [
                  if (download.totalPages > 0) ...[
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: ColorsConst.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${download.downloadedPages}/${download.totalPages}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  if (download.fileSize > 0) ...[
                    Icon(
                      Icons.storage_outlined,
                      size: 16,
                      color: ColorsConst.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      download.formattedFileSize,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  if (download.speed > 0) ...[
                    Icon(
                      Icons.speed_outlined,
                      size: 16,
                      color: ColorsConst.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      download.formattedSpeed,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // More actions button
                  IconButton(
                    onPressed: () => _showMoreActions(context),
                    icon: Icon(
                      Icons.more_vert,
                      color: ColorsConst.onSurface.withValues(alpha: 0.6),
                    ),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),

              // Error message if failed
              if (download.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsConst.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ColorsConst.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: ColorsConst.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          download.error!,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: ColorsConst.error,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ETA if downloading
              if (download.isInProgress &&
                  download.estimatedTimeRemaining != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: ColorsConst.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${_formatDuration(download.estimatedTimeRemaining!)}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    IconData icon;
    Color color;
    String action;

    switch (download.state) {
      case DownloadState.queued:
        icon = Icons.schedule;
        color = ColorsConst.onSurface.withValues(alpha: 0.6);
        action = 'start';
        break;
      case DownloadState.downloading:
        // If progress is 100%, show as completed even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          icon = Icons.check_circle;
          color = ColorsConst.success;
          action = 'details';
        } else {
          icon = Icons.pause;
          color = ColorsConst.primary;
          action = 'pause';
        }
        break;
      case DownloadState.paused:
        icon = Icons.play_arrow;
        color = ColorsConst.primary;
        action = 'start';
        break;
      case DownloadState.completed:
        icon = Icons.check_circle;
        color = ColorsConst.success;
        action = 'details';
        break;
      case DownloadState.failed:
        icon = Icons.refresh;
        color = ColorsConst.error;
        action = 'retry';
        break;
      case DownloadState.cancelled:
        icon = Icons.refresh;
        color = ColorsConst.onSurface.withValues(alpha: 0.6);
        action = 'retry';
        break;
    }

    return IconButton(
      onPressed: () => onAction?.call(action),
      icon: Icon(icon, color: color),
      iconSize: 24,
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsConst.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsConst.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Download Actions',
              style: TextStyleConst.titleMedium.copyWith(
                color: ColorsConst.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            if (download.canPause)
              _buildActionTile(
                context,
                icon: Icons.pause,
                title: 'Pause',
                action: 'pause',
              ),

            if (download.canResume)
              _buildActionTile(
                context,
                icon: Icons.play_arrow,
                title: 'Resume',
                action: 'start',
              ),

            if (download.canCancel)
              _buildActionTile(
                context,
                icon: Icons.cancel,
                title: 'Cancel',
                action: 'cancel',
                isDestructive: true,
              ),

            if (download.canRetry)
              _buildActionTile(
                context,
                icon: Icons.refresh,
                title: 'Retry',
                action: 'retry',
              ),

            // Add PDF conversion option for completed downloads
            // This allows users to convert downloaded images to PDF
            if (download.state == DownloadState.completed)
              _buildActionTile(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Convert to PDF',
                action: 'convert_pdf',
              ),

            _buildActionTile(
              context,
              icon: Icons.info_outline,
              title: 'Details',
              action: 'details',
            ),

            _buildActionTile(
              context,
              icon: Icons.delete_outline,
              title: 'Remove',
              action: 'remove',
              isDestructive: true,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String action,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? ColorsConst.error : ColorsConst.onSurface,
      ),
      title: Text(
        title,
        style: TextStyleConst.bodyMedium.copyWith(
          color: isDestructive ? ColorsConst.error : ColorsConst.onSurface,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onAction?.call(action);
      },
    );
  }

  Color _getStatusColor() {
    switch (download.state) {
      case DownloadState.queued:
        return ColorsConst.onSurface.withValues(alpha: 0.6);
      case DownloadState.downloading:
        // If progress is 100%, show success color even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          return ColorsConst.success;
        }
        return ColorsConst.primary;
      case DownloadState.paused:
        return ColorsConst.warning;
      case DownloadState.completed:
        return ColorsConst.success;
      case DownloadState.failed:
        return ColorsConst.error;
      case DownloadState.cancelled:
        return ColorsConst.onSurface.withValues(alpha: 0.6);
    }
  }

  Color _getProgressColor() {
    switch (download.state) {
      case DownloadState.downloading:
        // If progress is 100%, show success color even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          return ColorsConst.success;
        }
        return ColorsConst.primary;
      case DownloadState.paused:
        return ColorsConst.warning;
      case DownloadState.completed:
        return ColorsConst.success;
      case DownloadState.failed:
        return ColorsConst.error;
      default:
        return ColorsConst.onSurface.withValues(alpha: 0.3);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
