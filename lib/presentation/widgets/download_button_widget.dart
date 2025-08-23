import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
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
          );
        }

        // Find download status for this content
        final download =
            state.downloads.where((d) => d.contentId == content.id).firstOrNull;

        if (download == null) {
          // Not downloaded, show download button
          return _buildButton(
            context: context,
            icon: Icons.download,
            text: 'Download',
            onPressed: () => _startDownload(context),
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
    final isEnabled = onPressed != null;

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
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(text, style: TextStyleConst.labelLarge),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    return SizedBox(
      height: size == DownloadButtonSize.large ? 48 : 40,
      child: Stack(
        children: [
          // Progress background
          Positioned.fill(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ColorsConst.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorsConst.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Button
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.pause, size: 18),
            label: showText
                ? Text('${download.progressPercentage.toInt()}%')
                : const SizedBox.shrink(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsConst.primary,
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
    // TODO: Navigate to reader or show downloaded content
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${content.title}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // TODO: Navigate to reader
          },
        ),
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
