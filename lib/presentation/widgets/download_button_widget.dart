import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/routing/app_router.dart';
import '../../domain/entities/entities.dart';
import '../blocs/download/download_bloc.dart';

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
    return BlocBuilder<DownloadBloc, DownloadBlocState>(
      builder: (context, state) {
        if (state is! DownloadLoaded) {
          return _buildButton(
            context: context,
            icon: Icons.download,
            text: 'Download',
            onPressed: null,
            color: ColorsConst.accentGreen,
          );
        }

        // Find download status for this content
        final download =
            state.downloads.where((d) => d.contentId == content.id).firstOrNull;

        if (download == null) {
          // Not downloaded, show download button with green color to match DetailScreen
          return _buildButton(
            context: context,
            icon: Icons.download,
            text: 'Download',
            onPressed: () => _startDownload(context),
            color: ColorsConst.accentGreen,
          );
        }

        // Show status based on download state
        switch (download.state) {
          case DownloadState.queued:
            return _buildButton(
              context: context,
              icon: Icons.schedule,
              text: 'Queued',
              onPressed: () => _cancelDownload(context),
              color: ColorsConst.warning,
            );

          case DownloadState.downloading:
            // If progress is 100%, show as completed even if state hasn't updated yet
            if (download.progressPercentage >= 100) {
              return _buildButton(
                context: context,
                icon: Icons.check_circle,
                text: 'Downloaded',
                onPressed: () => _openDownload(context),
                color: ColorsConst.success,
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
              text: 'Resume',
              onPressed: () => _resumeDownload(context),
              color: ColorsConst.info,
              progress: download.progressPercentage / 100,
            );

          case DownloadState.completed:
            return _buildButton(
              context: context,
              icon: Icons.check_circle,
              text: 'Downloaded',
              onPressed: () => _openDownload(context),
              color: ColorsConst.success,
            );

          case DownloadState.failed:
            return _buildButton(
              context: context,
              icon: Icons.error,
              text: 'Failed',
              onPressed: () => _retryDownload(context),
              color: ColorsConst.error,
            );

          case DownloadState.cancelled:
            return _buildButton(
              context: context,
              icon: Icons.download,
              text: 'Download',
              onPressed: () => _startDownload(context),
              color: ColorsConst.accentGreen,
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
    final buttonColor = color ?? ColorsConst.primary;

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
                  fontWeight: FontWeight.w500,
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
    final progressColor = ColorsConst.primary;
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
        content: Text('Download started: ${content.title}'),
        duration: const Duration(seconds: 2),
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
        content: Text('Opening: ${content.title}'),
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
