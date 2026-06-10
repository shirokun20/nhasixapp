import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/services/pdf_conversion_queue_manager.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/cubits/offline_search/offline_search_cubit.dart';
import 'package:nhasixapp/presentation/mixins/offline_management_mixin.dart';
import 'package:nhasixapp/presentation/models/content_group.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../services/tag_blacklist_service.dart';
import '../blocs/download/download_bloc.dart';
import '../../core/config/remote_config_service.dart';
import '../cubits/settings/settings_cubit.dart';
import '../pages/offline/offline_series_detail_screen.dart';
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
    // Assuming OfflineSearchCubit is provided in the context or via GetIt
    // For safety, we use GetIt here as it's a singleton
    _offlineSearchCubit = getIt<OfflineSearchCubit>();
    _tagBlacklistService = getIt<TagBlacklistService>()
      ..addListener(_handleBlacklistChanged);

    // Ensure content is loaded if not already
    if (_offlineSearchCubit.state is OfflineSearchInitial) {
      _offlineSearchCubit.getAllOfflineContent();
    } else {
      // Check for stale data (e.g. downloaded while on another screen)
      // If the count differs from DownloadBloc, refresh it
      try {
        final downloadState = context.read<DownloadBloc>().state;
        if (downloadState is DownloadLoaded &&
            _offlineSearchCubit.state is OfflineSearchLoaded) {
          final offlineCount =
              (_offlineSearchCubit.state as OfflineSearchLoaded).results.length;
          final downloadCount = downloadState.completedDownloads.length;
          if (offlineCount != downloadCount) {
            _offlineSearchCubit.getAllOfflineContent();
          }
        }
      } catch (e) {
        debugPrint('Error syncing offline state with downloads: $e');
      }
    }

    unawaited(_tagBlacklistService.syncAllAvailableSources());

    // The _scrollController listener has been moved to NotificationListener
    // to handle hide-on-scroll and show-on-idle logic.
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
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _offlineSearchCubit.changeSorting(
                      orderBy: orderBy, descending: descending);
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
      elevation: 4,
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
                borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(12),
        splashColor: baseColor.withValues(alpha: 0.2),
        highlightColor: baseColor.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? baseColor.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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

                      final contentGroup = state.results[index];
                      return ContentGroupCardWidget(
                        key: ValueKey(
                            '${contentGroup.representativeContent.sourceId}_${contentGroup.baseTitle}'),
                        contentGroup: contentGroup,
                        isListMode: state.isListMode,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfflineSeriesDetailScreen(
                                contentGroup: contentGroup,
                              ),
                            ),
                          );
                        },
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
    final l10n = AppLocalizations.of(context)!;

    final representative = group.representativeContent;
    final isSingle = group.items.length == 1;

    // Get content path if possible
    String? contentPath;
    try {
      final firstImage =
          await offlineManager.getOfflineFirstImagePath(representative.id);
      if (firstImage != null) {
        contentPath = File(firstImage).parent.path;
        if (!isSingle) {
          // If it's a group, maybe use the parent directory of the chapter
          contentPath = File(contentPath).parent.path;
        }
      }
    } catch (e) {
      debugPrint('Error getting content path: $e');
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
                      width: 48,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          representative.sourceId == 'nhentai' ? 'NH' : 'CP',
                          style: TextStyleConst.labelLarge.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSingle
                                ? AppLocalizations.of(context)!.pagesWithSize(
                                    representative.pageCount, sizeText)
                                : '${group.items.length} Chapters • $sizeText',
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
              const Divider(),
              if (contentPath != null) ...[
                ListTile(
                  leading: Icon(Icons.folder_open_rounded,
                      color: colorScheme.secondary),
                  title: Text(
                    contentPath,
                    style: TextStyleConst.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy path',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: contentPath!));
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                                content: Text('Path copied to clipboard')),
                          );
                          Navigator.pop(bottomSheetContext);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 20),
                        tooltip: 'Open in explorer',
                        onPressed: () {
                          OpenFile.open(contentPath);
                          Navigator.pop(bottomSheetContext);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
              ],
              if (isSingle) ...[
                FutureBuilder<bool>(
                  future: _checkPdfExists(representative.id),
                  builder: (context, snapshot) {
                    final isPdf = snapshot.data ?? false;
                    return ListTile(
                      leading: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.remove_red_eye,
                          color: isPdf
                              ? colorScheme.tertiary
                              : colorScheme.primary),
                      title:
                          Text(isPdf ? '${l10n.readNow} (PDF)' : l10n.readNow),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _openReader(parentContext, representative);
                      },
                    );
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
                  title: Text(l10n.convertToPdf),
                  subtitle: Text(AppLocalizations.of(context)!
                      .nPages(representative.pageCount)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _generatePdf(parentContext, representative);
                  },
                ),
              ] else ...[
                ListTile(
                  leading:
                      Icon(Icons.remove_red_eye, color: colorScheme.primary),
                  title: Text(l10n.readFirstChapter),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Open the oldest chapter in the group
                    final oldest = List<Content>.from(group.items)
                      ..sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
                    if (oldest.isNotEmpty) {
                      _openReader(parentContext, oldest.first);
                    }
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.picture_as_pdf, color: colorScheme.tertiary),
                  title: Text(l10n.convertAllToPdf),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    for (final item in group.items) {
                      _generatePdf(parentContext, item, showSnackbar: false);
                    }
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Queued ${group.items.length} chapters for PDF conversion')),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  isSingle
                      ? l10n.delete
                      : l10n.deleteSeriesWithCount(group.items.length),
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showGroupDeleteConfirmation(parentContext, group);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkPdfExists(String contentId) async {
    final offlineManager = getIt<OfflineContentManager>();
    try {
      final firstImagePath =
          await offlineManager.getOfflineFirstImagePath(contentId);
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        final pdfDir = Directory(p.join(contentDir, 'pdf'));
        if (await pdfDir.exists()) {
          final files = await pdfDir.list().toList();
          return files.any((f) => f.path.toLowerCase().endsWith('.pdf'));
        }
      }
    } catch (e) {
      debugPrint('Error checking PDF existence: $e');
    }
    return false;
  }

  void _openReader(BuildContext context, Content content) async {
    final offlineManager = getIt<OfflineContentManager>();
    try {
      final firstImagePath =
          await offlineManager.getOfflineFirstImagePath(content.id);
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        final pdfDir = Directory(p.join(contentDir, 'pdf'));
        if (await pdfDir.exists()) {
          final files = await pdfDir.list().toList();
          final pdfFile = files
              .where((f) => f.path.toLowerCase().endsWith('.pdf'))
              .firstOrNull;

          if (pdfFile != null && context.mounted) {
            AppRouter.goToReaderPdf(
              context,
              filePath: pdfFile.path,
              contentId: content.id,
              title: content.title,
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for PDF in _openReader: $e');
    }

    if (context.mounted) {
      await AppRouter.goToReader(
        context,
        content.id,
        content: content,
      );
    }
  }

  Future<void> _generatePdf(BuildContext context, Content content,
      {bool showSnackbar = true}) async {
    final offlineManager = getIt<OfflineContentManager>();
    final queueManager = getIt<PdfConversionQueueManager>();

    try {
      final imagePaths = await offlineManager.getOfflineImageUrls(content.id);
      if (imagePaths.isEmpty) return;

      await queueManager.queueConversion(
        contentId: content.id,
        title: content.title,
        imagePaths: imagePaths,
        sourceId: content.sourceId,
      );

      if (showSnackbar && context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.convertingToPdf)),
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
  }

  void _showGroupDeleteConfirmation(BuildContext context, ContentGroup group) {
    final l10n = AppLocalizations.of(context)!;
    final isSingle = group.items.length == 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(isSingle
            ? l10n.removeDownloadConfirmation
            : l10n.deleteSeriesConfirmation(
                group.items.length, group.baseTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteContentGroup(context, group);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContentGroup(
      BuildContext context, ContentGroup group) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<OfflineSearchCubit>();
    try {
      for (final item in group.items) {
        await cubit.deleteOfflineContent(item.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contentDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    }
  }
}
