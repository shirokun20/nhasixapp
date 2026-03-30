import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/workers/download_lifecycle_mixin.dart';
import '../blocs/download/download_bloc.dart';

/// Monitors app lifecycle and interacts with DownloadBloc to handle
/// background downloads.
class LifecycleWatcher extends StatefulWidget {
  final Widget child;

  const LifecycleWatcher({
    required this.child,
    super.key,
  });

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver, DownloadLifecycleMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    // Get current download state
    final downloadState = context.read<DownloadBloc>().state;

    if (downloadState is DownloadLoaded) {
      // Map to ActiveDownloadInfo
      final activeDownloads = downloadState.activeDownloads.map((download) {
        return ActiveDownloadInfo(
          contentId: download.contentId,
          isInProgress: true, // Only active ones are here
          currentProgress: download.progressPercentage,
          totalImages: download.totalPages,
          // Other fields omitted, will rely on saved resume state
        );
      }).toList();

      handleLifecycleChange(state, activeDownloads);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
