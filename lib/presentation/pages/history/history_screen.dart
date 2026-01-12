import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/shimmer_loading_widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/analytics_service.dart';
import '../../cubits/history/history_cubit.dart';
import '../../cubits/history/history_cubit_factory.dart';
import '../../cubits/history/history_state.dart';
import '../../widgets/widgets.dart';
import '../history/widgets/history_item_widget.dart';
import '../history/widgets/history_empty_widget.dart';
import '../history/widgets/history_cleanup_info_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

/// Screen for displaying reading history with auto-cleanup features
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryCubit _historyCubit;
  late final ScrollController _scrollController;
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = getIt<AnalyticsService>();
    _historyCubit = HistoryCubitFactory.create();
    _scrollController = ScrollController();

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Track screen view
    _trackScreenView();

    // Load initial history
    _historyCubit.loadHistory();
  }

  Future<void> _trackScreenView() async {
    await _analyticsService.trackScreenView(
      'history',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottomReached && _historyCubit.canLoadMore) {
      _historyCubit.loadMoreHistory();
    }
  }

  bool get _isBottomReached {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>.value(
      value: _historyCubit,
      child: AppScaffoldWithOffline(
        title: AppLocalizations.of(context)!.readingHistory,
        appBar: _buildAppBar(context),
        drawer: AppMainDrawerWidget(context: context),
        body: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            // LayoutBuilder is already handled by AppScaffoldWithOffline
            return RefreshIndicator(
              onRefresh: () => _historyCubit.refreshHistory(),
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.readingHistory),
      actions: [
        // Cleanup info button
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showCleanupInfo(context),
          tooltip: AppLocalizations.of(context)?.cleanupInfo ?? 'Cleanup Info',
        ),
        // Clear all button
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.clearAllHistory),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'manual_cleanup',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services, size: 20),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.manualCleanup),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cleanup_settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.cleanupSettings),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, HistoryState state) {
    if (state is HistoryLoading) {
      return const ListShimmer(itemCount: 8);
    }

    if (state is HistoryClearing) {
      return Center(
        child: AppProgressIndicator(
            message: AppLocalizations.of(context)?.clearingHistory ??
                'Clearing history...'),
      );
    }

    if (state is HistoryError) {
      return AppErrorWidget(
        title: AppLocalizations.of(context)!.errorLoadingHistory,
        message: state.message,
        onRetry: state.canRetry ? () => _historyCubit.loadHistory() : null,
        icon: Icons.history,
      );
    }

    if (state is HistoryEmpty) {
      return Center(child: const HistoryEmptyWidget());
    }

    if (state is HistoryLoaded) {
      return _buildHistoryList(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildHistoryList(BuildContext context, HistoryLoaded state) {
    return Column(
      children: [
        // History count info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            '${state.history.length} items in history',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
            textAlign: TextAlign.center,
          ),
        ),

        // History list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.history.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator for pagination
              if (index >= state.history.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ListShimmer(itemCount: 2),
                );
              }

              final historyItem = state.history[index];
              return HistoryItemWidget(
                history: historyItem,
                onTap: () => _navigateToContent(context, historyItem),
                onRemove: () =>
                    _removeHistoryItem(context, historyItem.contentId),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog(context);
        break;
      case 'manual_cleanup':
        _performManualCleanup(context);
        break;
      case 'cleanup_settings':
        _navigateToCleanupSettings(context);
        break;
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllHistory),
        content: Text(
          AppLocalizations.of(context)!.areYouSureClearHistory,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _historyCubit.clearHistory();
            },
            child: Text(AppLocalizations.of(context)!.clearAll),
          ),
        ],
      ),
    );
  }

  void _performManualCleanup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.manualCleanup),
        content: Text(
          AppLocalizations.of(context)!.manualCleanupConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _historyCubit.performManualCleanup();
            },
            child: Text(AppLocalizations.of(context)!.cleanup),
          ),
        ],
      ),
    );
  }

  void _removeHistoryItem(BuildContext context, String contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFromHistory),
        content: Text(AppLocalizations.of(context)!.removeFromHistoryQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _historyCubit.removeHistoryItem(contentId);
            },
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }

  void _showCleanupInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HistoryCleanupInfoWidget(
        historyCubit: _historyCubit,
      ),
    );
  }

  void _navigateToContent(BuildContext context, dynamic historyItem) {
    // Navigate to content detail/reader with sourceId to ensure correct source is used
    // This fixes the issue where clicking Crotpedia items caused errors due to missing source context
    context.push(
      '/content/${historyItem.contentId}?sourceId=${historyItem.sourceId}',
    );
  }

  void _navigateToCleanupSettings(BuildContext context) {
    // Navigate to cleanup settings
    // This would typically open a settings page or dialog
    context.push('/settings');
  }
}
