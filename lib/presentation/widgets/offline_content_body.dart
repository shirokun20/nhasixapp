import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/constants/design_tokens.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/mixins/offline_management_mixin.dart';
import 'package:nhasixapp/presentation/models/content_group.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import '../../services/tag_blacklist_service.dart';
import '../blocs/download/download_bloc.dart';
import '../../core/config/remote_config_service.dart';
import '../cubits/settings/settings_cubit.dart';
import 'content_group_card_widget.dart';
import 'error_widget.dart';
import 'offline_content_shimmer.dart';

/// Reusable widget that displays offline content with search and filtering
/// Used by OfflineContentScreen and OfflineMode in MainScreen
class OfflineContentBody extends StatefulWidget {
  const OfflineContentBody({super.key});

  @override
  State<OfflineContentBody> createState() => _OfflineContentBodyState();
}

class _OfflineContentBodyState extends State<OfflineContentBody>
    with OfflineManagementMixin<OfflineContentBody> {
  late OfflineSearchCubit _offlineSearchCubit;
  late final TagBlacklistService _tagBlacklistService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isFabVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _offlineSearchCubit = context.read<OfflineSearchCubit>();
    _tagBlacklistService = getIt<TagBlacklistService>()
      ..addListener(_handleBlacklistChanged);

    // Ensure content is loaded if not already
    if (_offlineSearchCubit.state is OfflineSearchInitial) {
      _offlineSearchCubit.getAllOfflineContent();
    }

    unawaited(_tagBlacklistService.syncAllAvailableSources());

    // The _scrollController listener has been moved to NotificationListener
    // to handle hide-on-scroll and show-on-idle logic.
  }

  Future<void> _openSeriesDetail(ContentGroup contentGroup) async {
    final changed =
        await AppRouter.goToOfflineSeriesDetail(context, contentGroup);
    if (changed == true && mounted) {
      await _offlineSearchCubit.forceRefresh();
    }
  }

  @override
  void dispose() {
    _tagBlacklistService.removeListener(_handleBlacklistChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _isFabVisible.dispose();
    super.dispose();
  }

  void _handleBlacklistChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsCubit>().state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: BlocListener<DownloadBloc, DownloadBlocState>(
              listenWhen: (previous, current) {
                // Only trigger if completed downloads count changes (success or delete)
                // This filters out frequent progress updates
                if (previous is DownloadLoaded && current is DownloadLoaded) {
                  return previous.completedDownloads.length !=
                      current.completedDownloads.length;
                }
                return true;
              },
              listener: (context, downloadState) {
                // Auto-refresh when a download completes
                if (downloadState is DownloadLoaded) {
                  if (_searchController.text.isEmpty) {
                    _offlineSearchCubit.getAllOfflineContent();
                  }
                }
              },
              child: BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
                bloc: _offlineSearchCubit,
                builder: (context, state) => _buildContent(state),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isFabVisible,
        builder: (context, isVisible, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            offset: isVisible ? Offset.zero : const Offset(0, 2),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              scale: isVisible ? 1.0 : 0.8,
              child: child,
            ),
          );
        },
        child: _buildFloatingSortButton(),
      ),
    );
  }

  void _showSortFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For floating effect
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort Options',
                    style: TextStyleConst.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildSortTab(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortTab(ScrollController scrollController) {
    return BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
      bloc: _offlineSearchCubit,
      builder: (context, state) {
        String currentOrderBy = 'created_at';
        bool currentDescending = true;
        if (state is OfflineSearchLoaded) {
          currentOrderBy = state.orderBy;
          currentDescending = state.descending;
        }

        Widget buildSortTile(
            String title, String orderBy, bool descending, IconData icon) {
          final isSelected =
              currentOrderBy == orderBy && currentDescending == descending;
          final colorScheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Material(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                onTap: () {
                  _offlineSearchCubit.changeSorting(
                      orderBy: orderBy, descending: descending);
                  context.pop();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                    border: Border.all(
                      color:
                          isSelected ? colorScheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            size: 20,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: colorScheme.primary)
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            buildSortTile('A - Z', 'title', false, Icons.sort_by_alpha_rounded),
            buildSortTile('Z - A', 'title', true, Icons.sort_by_alpha_rounded),
            buildSortTile(
                'New to Old', 'created_at', true, Icons.new_releases_rounded),
            buildSortTile(
                'Old to New', 'created_at', false, Icons.history_rounded),
            buildSortTile('Pages (Ascending)', 'total_pages', false,
                Icons.format_list_numbered_rounded),
            buildSortTile('Pages (Descending)', 'total_pages', true,
                Icons.format_list_numbered_rtl_rounded),
          ],
        );
      },
    );
  }

  Widget _buildFloatingSortButton() {
    return FloatingActionButton.extended(
      onPressed: _showSortFilterModal,
      icon: const Icon(Icons.sort),
      label: Text(
        'Sort',
        style: TextStyleConst.buttonMedium,
      ),
      elevation: DesignTokens.elevationLg,
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)!.searchOfflineContentHint,
                    hintStyle: TextStyleConst.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _offlineSearchCubit.getAllOfflineContent();
                            },
                            icon: Icon(
                              Icons.clear,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (text) {
                    // Reactive UI handled by ValueListenableBuilder
                  },
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      _offlineSearchCubit.searchOfflineContent(query.trim());
                    } else {
                      _offlineSearchCubit.getAllOfflineContent();
                    }
                  },
                );
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
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.search,
              style: TextStyleConst.buttonMedium.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
      bloc: _offlineSearchCubit,
      builder: (context, state) {
        String? selectedSourceId;
        if (state is OfflineSearchLoaded) {
          selectedSourceId = state.selectedSourceId;
        } else {
          selectedSourceId = getIt<SharedPreferences>()
              .getString('offline_selected_source_filter');
        }

        final remoteConfig = getIt<RemoteConfigService>();
        final sourceConfigs = remoteConfig.getAllSourceConfigs();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                context,
                label: AppLocalizations.of(context)?.all ?? 'All',
                isSelected: selectedSourceId == null,
                onSelected: (selected) {
                  if (selected) _offlineSearchCubit.filterBySource(null);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Local',
                isSelected: selectedSourceId == 'local',
                onSelected: (selected) {
                  if (selected) _offlineSearchCubit.filterBySource('local');
                },
              ),
              ...sourceConfigs.map((config) {
                final sourceId = config.source;
                final displayName = config.ui?.displayName ?? sourceId;
                final themeColor = config.ui?.activeColor;

                Color? chipColor;
                if (themeColor != null) {
                  try {
                    chipColor =
                        Color(int.parse(themeColor.replaceFirst('#', '0xFF')));
                  } catch (e) {
                    // Fallback if color parsing fails
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildFilterChip(
                    context,
                    label: displayName,
                    isSelected: selectedSourceId == sourceId,
                    onSelected: (selected) {
                      if (selected) {
                        _offlineSearchCubit.filterBySource(sourceId);
                      }
                    },
                    color: chipColor?.withValues(alpha: 0.2),
                    selectedColor: chipColor,
                    textColor:
                        (selectedSourceId == sourceId && chipColor != null)
                            ? Colors.white
                            : null,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    Color? color,
    Color? selectedColor,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = selectedColor ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(!isSelected),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        splashColor: baseColor.withValues(alpha: 0.2),
        highlightColor: baseColor.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: DesignTokens.durationPageTurn,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? baseColor.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: isSelected
                  ? baseColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle_rounded, size: 16, color: baseColor),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? baseColor : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(OfflineSearchState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state is OfflineSearchLoading) {
      return const OfflineContentGridShimmer();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.query.isEmpty
                    ? AppLocalizations.of(context)!.noOfflineContent
                    : AppLocalizations.of(context)!
                        .noResultsFoundFor(state.query),
                textAlign: TextAlign.center,
                style: TextStyleConst.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              if (state.query.isEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Explicit Import Action for Empty State
                    await importFromBackup(context);
                  },
                  icon: const Icon(Icons.restore_page),
                  label: Text(AppLocalizations.of(context)!.importFromBackup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
              if (state.query.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noResultsFound,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              if (state.query.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.howToGetStarted,
                            style: TextStyleConst.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipRow(colorScheme, '1. Browse comics you like'),
                      const SizedBox(height: 8),
                      _buildTipRow(colorScheme, '2. Tap the download button'),
                      const SizedBox(height: 8),
                      _buildTipRow(colorScheme,
                          '3. Access them here anytime, even offline!'),
                    ],
                  ),
                ),
              if (state.query.isEmpty) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/downloads'),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(AppLocalizations.of(context)!
                      .browseDownloads), // Hardcoded to avoid key guessing
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (state is OfflineSearchLoaded) {
      return Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
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
          Expanded(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                // Wrap GridView with NotificationListener for infinite scroll
                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    // Hide FAB when scrolling, show when idle
                    if (scrollInfo is ScrollUpdateNotification) {
                      if (_isFabVisible.value) _isFabVisible.value = false;
                    } else if (scrollInfo is ScrollEndNotification) {
                      if (!_isFabVisible.value) _isFabVisible.value = true;
                    }

                    // Trigger load more when user scrolls to 80% of content
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                      if (state.hasMore && !state.isLoadingMore) {
                        _offlineSearchCubit.loadMoreContent();
                      }
                    }
                    return false;
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: state.isListMode
                        ? const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 120, // Height for list mode items
                          )
                        : ResponsiveGridDelegate.createStandardGridDelegate(
                            context,
                            context.read<SettingsCubit>(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                    // Add 1 for loading indicator if loading more
                    itemCount:
                        state.results.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at bottom if loading more
                      if (index == state.results.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.loadingMore,
                                  style: TextStyleConst.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final contentGroup = _dedupedGroup(state.results[index]);
                      return ContentGroupCardWidget(
                        key: ValueKey(
                            '${contentGroup.representativeContent.sourceId}_${contentGroup.baseTitle}'),
                        contentGroup: contentGroup,
                        isListMode: state.isListMode,
                        onTap: () => _openSeriesDetail(contentGroup),
                        onLongPress: () {
                          _showGroupContentActions(context, contentGroup);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return const OfflineContentGridShimmer();
  }

  ContentGroup _dedupedGroup(ContentGroup group) {
    final items = group.uniqueItems;
    return ContentGroup(
      baseTitle: group.baseTitle,
      items: items,
      totalSize: items.fold(
        0,
        (sum, item) => sum + group.sizeForContent(item.id),
      ),
      itemSizes: group.itemSizes,
      readProgress: group.readProgress,
      isRead: group.isRead,
      isReading: group.isReading,
    );
  }

  Widget _buildTipRow(ColorScheme colorScheme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showGroupContentActions(
      BuildContext context, ContentGroup group) async {
    final colorScheme = Theme.of(context).colorScheme;
    final offlineManager = getIt<OfflineContentManager>();

    final representative = group.representativeContent;

    final chapterPaths = <({String title, String path})>[];
    for (final item in group.uniqueItems) {
      try {
        final firstImage = await offlineManager.getOfflineFirstImagePath(
          item.id,
        );
        if (firstImage != null) {
          chapterPaths
              .add((title: item.title, path: File(firstImage).parent.path));
        }
      } catch (_) {
        // Best effort only. Missing paths should not block the info sheet.
      }
    }

    if (!context.mounted) return;

    final parentContext = context;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (bottomSheetContext) {
        final sizeText =
            OfflineContentManager.formatStorageSize(group.totalSize);
        final chapterLabel =
            '${group.chapterCount} Chapter${group.chapterCount > 1 ? 's' : ''} tersedia';

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.library_books_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.baseTitle,
                            style: TextStyleConst.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chapterLabel,
                            style: TextStyleConst.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoPill(
                        context,
                        icon: Icons.auto_stories_rounded,
                        label: 'Chapters',
                        value: '${group.chapterCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoPill(
                        context,
                        icon: Icons.storage_rounded,
                        label: 'Storage',
                        value: sizeText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoPill(
                        context,
                        icon: Icons.public_rounded,
                        label: 'Source',
                        value: representative.sourceId.toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (chapterPaths.isNotEmpty) ...[
                ListTile(
                  leading: Icon(Icons.folder_copy_rounded,
                      color: colorScheme.secondary),
                  title: Text(
                    'Chapter paths',
                    style: TextStyleConst.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${chapterPaths.length} lokasi tersimpan',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_all_rounded),
                    tooltip: 'Copy all paths',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: chapterPaths
                              .map((entry) => entry.path)
                              .join('\n'),
                        ),
                      );
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(content: Text('Paths copied')),
                      );
                    },
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: chapterPaths.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = chapterPaths[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              '${index + 1}',
                              style: TextStyleConst.labelSmall.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleConst.labelMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            entry.path,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleConst.labelSmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Copy path',
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: entry.path));
                                  ScaffoldMessenger.of(parentContext)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text('Path copied')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 18),
                                tooltip: 'Open in explorer',
                                onPressed: () => OpenFile.open(entry.path),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Text(
                    'Path chapter belum tersedia.',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleConst.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyleConst.labelMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
