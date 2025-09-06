import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../domain/entities/entities.dart';
import '../blocs/download/download_bloc.dart';
import 'download_range_selector.dart';

/// Widget untuk tombol download dengan status dan progress
class DownloadButtonWidget extends StatelessWidget {
  const DownloadButtonWidget({
    super.key,
    required this.content,
    this.showProgress = true,
    this.showText = true,
    this.size = DownloadButtonSize.medium,
  });

  final Content content;
  final bool showProgress;
  final bool showText;
  final DownloadButtonSize size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocBuilder<DownloadBloc, DownloadBlocState>(
      builder: (context, state) {
        if (state is! DownloadLoaded) {
          return _buildButton(
            context: context,
            icon: Icons.download,
            text: AppLocalizations.of(context)!.download,
            onPressed: null,
            color: colorScheme.tertiary,
          );
        }

        // Find download status for this content
        final download =
            state.downloads.where((d) => d.contentId == content.id).firstOrNull;

        if (download == null) {
          // Not downloaded, show download options with dropdown
          return _buildDownloadOptionsButton(context);
        }

        // Show status based on download state
        switch (download.state) {
          case DownloadState.queued:
            return _buildButton(
              context: context,
              icon: Icons.schedule,
              text: AppLocalizations.of(context)!.queued,
              onPressed: () => _cancelDownload(context),
              color: colorScheme.secondary,
            );

          case DownloadState.downloading:
            // If progress is 100%, show as completed even if state hasn't updated yet
            if (download.progressPercentage >= 100) {
              return _buildButton(
                context: context,
                icon: Icons.check_circle,
                text: AppLocalizations.of(context)!.downloaded,
                onPressed: () => _openDownload(context),
                color: colorScheme.tertiary,
              );
            }
            return _buildProgressButton(
              context: context,
              download: download,
              onPressed: () => _pauseDownload(context),
            );

          case DownloadState.paused:
            return _buildButton(
              context: context,
              icon: Icons.play_arrow,
              text: AppLocalizations.of(context)!.resume,
              onPressed: () => _resumeDownload(context),
              color: colorScheme.primary,
              progress: download.progressPercentage / 100,
            );

          case DownloadState.completed:
            return _buildButton(
              context: context,
              icon: Icons.check_circle,
              text: AppLocalizations.of(context)!.downloaded,
              onPressed: () => _openDownload(context),
              color: colorScheme.tertiary,
            );

          case DownloadState.failed:
            return _buildButton(
              context: context,
              icon: Icons.error,
              text: AppLocalizations.of(context)!.failed,
              onPressed: () => _retryDownload(context),
              color: colorScheme.error,
            );

          case DownloadState.cancelled:
            return _buildButton(
              context: context,
              icon: Icons.download,
              text: AppLocalizations.of(context)!.download,
              onPressed: () => _startDownload(context),
              color: colorScheme.tertiary,
            );
        }
      },
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    Color? color,
    double? progress,
  }) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;

    switch (size) {
      case DownloadButtonSize.small:
        return _buildSmallButton(
          context: context,
          icon: icon,
          text: text,
          onPressed: onPressed,
          color: buttonColor,
          progress: progress,
        );

      case DownloadButtonSize.medium:
        return _buildMediumButton(
          context: context,
          icon: icon,
          text: text,
          onPressed: onPressed,
          color: buttonColor,
          progress: progress,
        );

      case DownloadButtonSize.large:
        return _buildLargeButton(
          context: context,
          icon: icon,
          text: text,
          onPressed: onPressed,
          color: buttonColor,
          progress: progress,
        );
    }
  }

  Widget _buildSmallButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required Color color,
    double? progress,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          if (progress != null)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: color.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            color: color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required Color color,
    double? progress,
  }) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          if (progress != null)
            Positioned.fill(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.3)),
              ),
            ),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: showText ? Text(text) : const SizedBox.shrink(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: showText ? 16 : 12,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required Color color,
    double? progress,
  }) {
    // For download state, use outlined style to match DetailScreen design
    final isDownloadButton = icon == Icons.download;
    
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Stack(
        children: [
          if (progress != null)
            Positioned.fill(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.3)),
              ),
            ),
          if (isDownloadButton)
            // Use outlined style for download button to match DetailScreen
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                text,
                style: TextStyleConst.buttonMedium.copyWith(
                  color: color,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(
                  color: color,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            // Use elevated style for other states
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(text, style: TextStyleConst.labelLarge),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressButton({
    required BuildContext context,
    required DownloadStatus download,
    required VoidCallback onPressed,
  }) {
    final progress = download.progressPercentage / 100;
    final isLarge = size == DownloadButtonSize.large;
    final buttonHeight = isLarge ? 48.0 : 40.0;
    
    // Use more vibrant colors for better visibility
    final progressColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = progressColor.withValues(alpha: 0.15);
    final progressValueColor = progressColor.withValues(alpha: 0.8);

    return SizedBox(
      height: buttonHeight,
      child: Stack(
        children: [
          // Enhanced progress background with rounded corners
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
                color: backgroundColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
                  minHeight: buttonHeight,
                ),
              ),
            ),
          ),
          // Enhanced button with better styling
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
              border: Border.all(
                color: progressColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(
                Icons.pause, 
                size: isLarge ? 20 : 18,
                color: Colors.white,
              ),
              label: showText
                  ? Text(
                      '${download.progressPercentage.toInt()}%',
                      style: TextStyleConst.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: isLarge ? 16 : 14,
                      ),
                    )
                  : const SizedBox.shrink(),
              style: ElevatedButton.styleFrom(
                backgroundColor: progressColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: progressColor.withValues(alpha: 0.3),
                padding: EdgeInsets.symmetric(
                  horizontal: showText ? (isLarge ? 24 : 16) : (isLarge ? 16 : 12),
                  vertical: isLarge ? 12 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startDownload(BuildContext context) {
    context.read<DownloadBloc>().add(DownloadQueueEvent(content: content));
    context.read<DownloadBloc>().add(DownloadStartEvent(content.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.downloadStarted(content.title)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDownloadOptionsButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'download_all') {
          _startDownload(context);
        } else if (value == 'download_range') {
          _showRangeSelector(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'download_all',
          child: Row(
            children: [
              Icon(Icons.download, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.downloadAll),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'download_range',
          child: Row(
            children: [
              Icon(Icons.folder_open, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.downloadRange),
            ],
          ),
        ),
      ],
      child: _buildButton(
        context: context,
        icon: Icons.download,
        text: AppLocalizations.of(context)!.download,
        onPressed: null, // Handled by PopupMenuButton
        color: colorScheme.tertiary,
      ),
    );
  }

  void _showRangeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DownloadRangeSelector(
        totalPages: content.pageCount,
        contentTitle: content.title,
        onRangeSelected: (startPage, endPage) {
          _startRangeDownload(context, startPage, endPage);
        },
      ),
    );
  }

  void _startRangeDownload(BuildContext context, int startPage, int endPage) {
    context.read<DownloadBloc>().add(DownloadRangeEvent(
      content: content,
      startPage: startPage,
      endPage: endPage,
    ));
    context.read<DownloadBloc>().add(DownloadStartEvent(content.id));

    final pageText = startPage == endPage 
        ? AppLocalizations.of(context)!.pageText(startPage)
        : AppLocalizations.of(context)!.pagesText(startPage, endPage);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.rangeDownloadStarted(content.title, pageText)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _pauseDownload(BuildContext context) {
    context.read<DownloadBloc>().add(DownloadPauseEvent(content.id));
  }

  void _resumeDownload(BuildContext context) {
    context.read<DownloadBloc>().add(DownloadStartEvent(content.id));
  }

  void _cancelDownload(BuildContext context) {
    context.read<DownloadBloc>().add(DownloadCancelEvent(content.id));
  }

  void _retryDownload(BuildContext context) {
    context.read<DownloadBloc>().add(DownloadRetryEvent(content.id));
  }

  void _openDownload(BuildContext context) {
    // Navigate to reader screen with the downloaded content
    AppRouter.goToReader(context, content.id);
    
    // Show confirmation that content is being opened
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.opening(content.title)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Size options for download button
enum DownloadButtonSize {
  small,
  medium,
  large,
}
