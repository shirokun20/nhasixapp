import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';
import '../../services/download_service.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      color: colorScheme.surface,
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
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          download.statusText,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: _getStatusColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context),
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
                            colorScheme.onSurface.withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getProgressColor(context)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(download.progressPercentage > 100) ? '100' : download.progressPercentage}%',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    _buildVerifiedPagesText(download),
                    const SizedBox(width: 16),
                  ],

                  if (download.fileSize > 0) ...[
                    Icon(
                      Icons.storage_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      download.formattedFileSize,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  if (download.speed > 0) ...[
                    Icon(
                      Icons.speed_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      download.formattedSpeed,
                      style: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // More actions button
                  IconButton(
                    onPressed: () => _showMoreActions(context),
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          download.error!,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: colorScheme.error,
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${_formatDuration(download.estimatedTimeRemaining!)}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    Color color;
    String action;

    switch (download.state) {
      case DownloadState.queued:
        icon = Icons.schedule;
        color = colorScheme.onSurface.withValues(alpha: 0.6);
        action = 'start';
        break;
      case DownloadState.downloading:
        // If progress is 100%, show as completed even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          icon = Icons.check_circle;
          color = colorScheme.tertiary;
          action = 'details';
        } else {
          icon = Icons.pause;
          color = colorScheme.primary;
          action = 'pause';
        }
        break;
      case DownloadState.paused:
        icon = Icons.play_arrow;
        color = colorScheme.primary;
        action = 'start';
        break;
      case DownloadState.completed:
        icon = Icons.check_circle;
        color = colorScheme.tertiary;
        action = 'details';
        break;
      case DownloadState.failed:
        icon = Icons.refresh;
        color = colorScheme.error;
        action = 'retry';
        break;
      case DownloadState.cancelled:
        icon = Icons.refresh;
        color = colorScheme.onSurface.withValues(alpha: 0.6);
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
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
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
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Download Actions',
              style: TextStyleConst.titleMedium.copyWith(
                color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? colorScheme.error : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyleConst.bodyMedium.copyWith(
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onAction?.call(action);
      },
    );
  }

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (download.state) {
      case DownloadState.queued:
        return colorScheme.onSurface.withValues(alpha: 0.6);
      case DownloadState.downloading:
        // If progress is 100%, show success color even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          return colorScheme.tertiary;
        }
        return colorScheme.primary;
      case DownloadState.paused:
        return colorScheme.secondary;
      case DownloadState.completed:
        return colorScheme.tertiary;
      case DownloadState.failed:
        return colorScheme.error;
      case DownloadState.cancelled:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  Color _getProgressColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (download.state) {
      case DownloadState.downloading:
        // If progress is 100%, show success color even if state hasn't updated yet
        if (download.progressPercentage >= 100) {
          return colorScheme.tertiary;
        }
        return colorScheme.primary;
      case DownloadState.paused:
        return colorScheme.secondary;
      case DownloadState.completed:
        return colorScheme.tertiary;
      case DownloadState.failed:
        return colorScheme.error;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.3);
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

  String _buildPagesText(DownloadStatus download) {
    if (download.isRangeDownload) {
      // For range downloads, show: "X/Y (Pages A-B of C)"
      return '${download.downloadedPages}/${download.pagesToDownload} (Pages ${download.startPage}-${download.endPage} of ${download.totalPages})';
    } else {
      // For full downloads, show: "X/Y"
      return '${download.downloadedPages}/${download.totalPages}';
    }
  }

  /// Build verified pages text using actual file count
  Widget _buildVerifiedPagesText(DownloadStatus download) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _verifyDownloadStatus(download.contentId),
      builder: (context, snapshot) {
        final colorScheme = Theme.of(context).colorScheme;
        
        if (!snapshot.hasData) {
          return Text(
            _buildPagesText(download),
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          );
        }

        final data = snapshot.data!;
        final actualCount = data['actualCount'] as int;
        final expectedCount = data['expectedCount'] as int?;
        final isRangeDownload = data['isRangeDownload'] as bool;

        // If expectedCount is null or 0, fall back to database values
        if (expectedCount == null || expectedCount == 0) {
          return Text(
            _buildPagesText(download),
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          );
        }

        String text;
        if (isRangeDownload) {
          final rangeStart = data['rangeStart'] as int?;
          final rangeEnd = data['rangeEnd'] as int?;
          final totalPages = data['totalPages'] as int?;
          text = '$actualCount/$expectedCount (Pages $rangeStart-$rangeEnd of $totalPages)';
        } else {
          text = '$actualCount/$expectedCount';
        }

        return Text(
          text,
          style: TextStyleConst.bodySmall.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }

  /// Verify download status by checking actual files
  Future<Map<String, dynamic>> _verifyDownloadStatus(String contentId) async {
    try {
      final downloadService = GetIt.instance<DownloadService>();
      return await downloadService.verifyDownloadStatus(contentId);
    } catch (e) {
      // Return null expectedCount to trigger fallback to database values
      return {
        'actualCount': 0,
        'expectedCount': null, // This will trigger fallback in _buildVerifiedPagesText
        'isRangeDownload': false,
      };
    }
  }
}
