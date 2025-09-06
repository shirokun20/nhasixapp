import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/responsive_grid_delegate.dart';
import '../../cubits/offline_search/offline_search_cubit.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../widgets/content_card_widget.dart';
import '../../widgets/progress_indicator_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/app_scaffold_with_offline.dart';

/// Screen for browsing offline/downloaded content
class OfflineContentScreen extends StatefulWidget {
  const OfflineContentScreen({super.key});

  @override
  State<OfflineContentScreen> createState() => _OfflineContentScreenState();
}

class _OfflineContentScreenState extends State<OfflineContentScreen> {
  late OfflineSearchCubit _offlineSearchCubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _offlineSearchCubit = getIt<OfflineSearchCubit>();

    // Load all offline content initially
    _offlineSearchCubit.getAllOfflineContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocProvider<OfflineSearchCubit>(
      create: (context) => _offlineSearchCubit,
      child: AppScaffoldWithOffline(
        title: AppLocalizations.of(context)!.offlineContentTitle,
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
                builder: (context, state) => _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
      ),
      title: Row(
        children: [
          Icon(
            Icons.offline_bolt,
            color: Theme.of(context).colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline Content',
            style: TextStyleConst.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        // Storage info
        BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
          builder: (context, state) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _offlineSearchCubit.getOfflineStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stats['totalContent']} items',
                            style: TextStyleConst.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            stats['formattedSize'],
                            style: TextStyleConst.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyleConst.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchOfflineContentHint,
                hintStyle: TextStyleConst.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _offlineSearchCubit.getAllOfflineContent();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.trim().isEmpty) {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _offlineSearchCubit.searchOfflineContent(value.trim());
                } else {
                  _offlineSearchCubit.getAllOfflineContent();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _offlineSearchCubit.searchOfflineContent(query);
              } else {
                _offlineSearchCubit.getAllOfflineContent();
              }
              _searchFocusNode.unfocus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Search',
              style: TextStyleConst.buttonMedium.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OfflineSearchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (state is OfflineSearchLoading) {
      return const Center(
        child: AppProgressIndicator(
          message: 'Loading offline content...',
        ),
      );
    }

    if (state is OfflineSearchError) {
      return Center(
        child: AppErrorWidget(
          title: AppLocalizations.of(context)!.offlineContentError,
          message: state.message,
          onRetry: () => _offlineSearchCubit.getAllOfflineContent(),
        ),
      );
    }

    if (state is OfflineSearchEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              state.emptyMessage,
              style: TextStyleConst.bodyLarge.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/downloads'),
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context)!.goToDownloads),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (state is OfflineSearchLoaded) {
      return Column(
        children: [
          // Results header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  state.displayTitle,
                  style: TextStyleConst.headingSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  state.resultsSummary,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Content grid
          Expanded(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: ResponsiveGridDelegate.createStandardGridDelegate(
                    context,
                    context.read<SettingsCubit>(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final content = state.results[index];
                    Logger().i(content);
                    return ContentCard(
                      content: content,
                      onTap: () => context.push('/reader/${content.id}'),
                  showOfflineIndicator: true,
                );
              },
                );
              },
            ),
          ),
        ],
      );
    }

    // Initial state
    return const Center(
      child: AppProgressIndicator(
        message: 'Loading offline content...',
      ),
    );
  }
}
