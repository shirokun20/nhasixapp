import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/download_status.dart';
import '../blocs/download/download_bloc.dart';
// Note: DownloadEvent is part of download_bloc.dart

/// Global widget to display active download progress at the top of the screen
class GlobalDownloadProgressWidget extends StatelessWidget {
  const GlobalDownloadProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadBlocState>(
      buildWhen: (previous, current) {
        if (previous is DownloadLoaded && current is DownloadLoaded) {
          // Rebuild if active count changes
          if (previous.activeDownloads.length != current.activeDownloads.length) return true;
          
          if (current.activeDownloads.isEmpty) return false;

          // If multiple downloads, check total stats
          if (current.activeDownloads.length > 1) {
            return previous.totalProgress != current.totalProgress ||
                   previous.totalDownloadSpeed != current.totalDownloadSpeed;
          }

          // Single download check
          final prevDownload = previous.activeDownloads.first;
          final currDownload = current.activeDownloads.first;
          return prevDownload.progress != currDownload.progress ||
                 prevDownload.state != currDownload.state ||
                 prevDownload.contentId != currDownload.contentId;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is! DownloadLoaded || state.activeDownloads.isEmpty) {
          return const SizedBox.shrink();
        }

        // Check for multiple downloads
        if (state.activeDownloads.length > 1) {
          return _buildMultipleDownloadsView(context, state);
        }

        // Single download view
        return _buildSingleDownloadView(context, state.activeDownloads.first);
      },
    );
  }

  /// Build view for multiple active downloads
  Widget _buildMultipleDownloadsView(BuildContext context, DownloadLoaded state) {
    final activeCount = state.activeDownloads.length;
    final totalProgress = state.totalProgress;
    final speed = state.formattedTotalSpeed;

    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () {
          // Navigate to downloads screen
          // context.push('/downloads');
          // For now, we can trigger an event or rely on parent navigation
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              // Summary Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.downloading,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Summary Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloading $activeCount items',
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: totalProgress,
                            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                         // Show speed and percentage
                        Text(
                          '$speed • ${(totalProgress * 100).toInt()}%',
                          style: TextStyleConst.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),

              // Action: Cancel All or Pause All could be added here, 
              // but for safety, we just show a "Go to Details" arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build view for a single active download
  Widget _buildSingleDownloadView(BuildContext context, DownloadStatus download) {
    final isPaused = download.isPaused;
    final progress = download.progress;

    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () {
            // Navigation to downloads screen could happen here if needed
            // context.push('/downloads'); 
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
                // Icon or Thumbnail
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPaused ? Icons.pause : Icons.downloading,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.title ?? 'Download',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyleConst.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (isPaused) {
                          context.read<DownloadBloc>().add(
                            DownloadResumeEvent(download.contentId),
                          );
                        } else {
                          context.read<DownloadBloc>().add(
                            DownloadPauseEvent(download.contentId),
                          );
                        }
                      },
                      tooltip: isPaused 
                          ? AppLocalizations.of(context)?.resume 
                          : AppLocalizations.of(context)?.pause,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () {
                        context.read<DownloadBloc>().add(
                          DownloadCancelEvent(download.contentId),
                        );
                      },
                      tooltip: AppLocalizations.of(context)?.cancel,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

