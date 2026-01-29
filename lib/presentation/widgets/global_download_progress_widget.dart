import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../blocs/download/download_bloc.dart';
// Note: DownloadEvent and DownloadState are part of download_bloc.dart, so they are available via that import.

/// Global widget to display active download progress at the top of the screen
class GlobalDownloadProgressWidget extends StatelessWidget {
  const GlobalDownloadProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadBlocState>(
      buildWhen: (previous, current) {
        // Rebuild only if active downloads change or their state changes significantly
        // We might need to optimize this if progress updates are too frequent
        // But for a banner, 60fps might be fine or we can throttle in Bloc.
        if (previous is DownloadLoaded && current is DownloadLoaded) {
          if (previous.activeDownloads.isEmpty && current.activeDownloads.isNotEmpty) return true;
          if (previous.activeDownloads.isNotEmpty && current.activeDownloads.isEmpty) return true;
          if (previous.activeDownloads.isNotEmpty && current.activeDownloads.isNotEmpty) {
             final prevDownload = previous.activeDownloads.first;
             final currDownload = current.activeDownloads.first;
             // Rebuild on progress, title, or status change
             return prevDownload.progress != currDownload.progress ||
                    prevDownload.state != currDownload.state ||
                    prevDownload.contentId != currDownload.contentId;
          }
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is! DownloadLoaded || state.activeDownloads.isEmpty) {
          return const SizedBox.shrink();
        }

        final download = state.activeDownloads.first;
        final isPaused = download.isPaused; // property of DownloadStatus entity
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
      },
    );
  }
}

