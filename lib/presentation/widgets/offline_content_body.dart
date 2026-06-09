import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:nhasixapp/core/routing/app_router.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/offline_content_manager.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import '../../domain/extensions/content_extensions.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../l10n/app_localizations.dart';
import '../../services/pdf_conversion_queue_manager.dart';
import '../../services/tag_blacklist_service.dart';
import '../blocs/download/download_bloc.dart';
import '../cubits/offline_search/offline_search_cubit.dart';
import '../cubits/offline_search/offline_library_models.dart';
import '../../core/config/remote_config_service.dart';
import '../cubits/settings/settings_cubit.dart';
import 'content_card_widget.dart';
import 'error_widget.dart';
import 'offline_content_shimmer.dart';
import '../mixins/offline_management_mixin.dart';
import 'permission_request_sheet.dart';
import 'progressive_image_widget.dart';

enum _LibraryOptionsSheetSection {
  sort,
  filter,
}

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
  }

  @override
  void dispose() {
    _tagBlacklistService.removeListener(_handleBlacklistChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    return BlocBuilder<OfflineSearchCubit, OfflineSearchState>(
      bloc: _offlineSearchCubit,
      builder: (context, state) {
        return Column(
          children: [
            _buildSearchBar(),
            _buildLibraryControls(state),
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
                child: _buildContent(state),
              ),
            ),
          ],
        );
      },
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

  Widget _buildLibraryControls(OfflineSearchState state) {
    return Column(
      key: const ValueKey('offline-library-controls-visible'),
      children: [
        _buildLibraryToolbar(state),
        _buildLibrarySummary(state),
      ],
    );
  }

  Widget _buildLibraryToolbar(OfflineSearchState state) {
    final sortMode = state is OfflineSearchLoaded
        ? state.sortMode
        : OfflineLibrarySortMode.date;
    final l10n = AppLocalizations.of(context)!;
    final options = state is OfflineSearchLoaded
        ? state.availableFilters
        : const <OfflineSourceFilterOption>[
            OfflineSourceFilterOption(
              id: OfflineSourceFilterOption.allId,
              kind: OfflineSourceBucketKind.all,
            ),
          ];
    final selectedFilterId =
        state is OfflineSearchLoaded ? state.selectedFilterId : null;
    final selectedOption = options.firstWhere(
      (option) =>
          option.id == (selectedFilterId ?? OfflineSourceFilterOption.allId),
      orElse: () => const OfflineSourceFilterOption(
        id: OfflineSourceFilterOption.allId,
        kind: OfflineSourceBucketKind.all,
      ),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('offline-library-options-button'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showLibraryOptionsSheet(
            options: options,
            selectedFilterId: selectedFilterId,
            sortMode: sortMode,
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_filterLabel(selectedOption)} · ${l10n.sortBy}: ${_sortLabel(sortMode)}',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySummary(OfflineSearchState state) {
    if (state is! OfflineSearchLoaded) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.displayTitle,
              style: TextStyleConst.labelLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            state.resultsSummary,
            style: TextStyleConst.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLibraryOptionsSheet({
    required List<OfflineSourceFilterOption> options,
    required String? selectedFilterId,
    required OfflineLibrarySortMode sortMode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    var selectedSection = selectedFilterId != null &&
            selectedFilterId != OfflineSourceFilterOption.allId
        ? _LibraryOptionsSheetSection.filter
        : _LibraryOptionsSheetSection.sort;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final fade = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                );
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, 0.16),
                                  end: Offset.zero,
                                ).animate(fade);

                                return ClipRect(
                                  child: SlideTransition(
                                    position: slide,
                                    child: FadeTransition(
                                      opacity: fade,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                selectedSection ==
                                        _LibraryOptionsSheetSection.sort
                                    ? l10n.sortBy
                                    : l10n.filterBy,
                                key: ValueKey(selectedSection),
                                style: TextStyleConst.titleSmall.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key:
                                const ValueKey('offline-library-options-close'),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLibrarySectionSelector(
                        selectedSection: selectedSection,
                        onChanged: (nextSection) {
                          setSheetState(() {
                            selectedSection = nextSection;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: selectedSection ==
                                  _LibraryOptionsSheetSection.sort
                              ? ListView(
                                  key: const ValueKey(
                                    'offline-library-sort-section',
                                  ),
                                  padding: EdgeInsets.zero,
                                  children: [
                                    _buildOptionTile(
                                      key: const ValueKey(
                                        'offline-sort-option-date',
                                      ),
                                      title: l10n.recent,
                                      icon: Icons.schedule_rounded,
                                      selected: sortMode ==
                                          OfflineLibrarySortMode.date,
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        _offlineSearchCubit.setSortMode(
                                          OfflineLibrarySortMode.date,
                                        );
                                      },
                                    ),
                                    _buildOptionTile(
                                      key: const ValueKey(
                                        'offline-sort-option-title',
                                      ),
                                      title: 'A-Z',
                                      icon: Icons.sort_by_alpha_rounded,
                                      selected: sortMode ==
                                          OfflineLibrarySortMode.title,
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        _offlineSearchCubit.setSortMode(
                                          OfflineLibrarySortMode.title,
                                        );
                                      },
                                    ),
                                    _buildOptionTile(
                                      key: const ValueKey(
                                        'offline-sort-option-image-count',
                                      ),
                                      title: l10n.pages,
                                      icon: Icons.auto_stories_rounded,
                                      selected: sortMode ==
                                          OfflineLibrarySortMode.imageCount,
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        _offlineSearchCubit.setSortMode(
                                          OfflineLibrarySortMode.imageCount,
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  key: const ValueKey(
                                    'offline-library-filter-section',
                                  ),
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) {
                                    return Divider(
                                      height: 1,
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.08),
                                    );
                                  },
                                  itemBuilder: (context, index) {
                                    final option = options[index];
                                    return _buildOptionTile(
                                      key: ValueKey(
                                        'offline-filter-option-${option.id}',
                                      ),
                                      title: _filterLabel(option),
                                      icon: _filterIcon(option.kind),
                                      selected: (selectedFilterId ??
                                              OfflineSourceFilterOption
                                                  .allId) ==
                                          option.id,
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        _offlineSearchCubit.filterBySource(
                                          option.kind ==
                                                  OfflineSourceBucketKind.all
                                              ? null
                                              : option.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionTile({
    required Key key,
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.75)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.28)
                    : colorScheme.outline.withValues(alpha: 0.18),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.16)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: selected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: selected
                      ? Container(
                          key: const ValueKey('offline-option-selected-dot'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          key: const ValueKey('offline-option-unselected-icon'),
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySectionSelector({
    required _LibraryOptionsSheetSection selectedSection,
    required ValueChanged<_LibraryOptionsSheetSection> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLibrarySectionButton(
              key: const ValueKey('offline-library-options-section-sort'),
              label: l10n.sortBy,
              icon: Icons.sort_rounded,
              selected: selectedSection == _LibraryOptionsSheetSection.sort,
              onTap: () => onChanged(_LibraryOptionsSheetSection.sort),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildLibrarySectionButton(
              key: const ValueKey('offline-library-options-section-filter'),
              label: l10n.filterBy,
              icon: Icons.filter_alt_rounded,
              selected: selectedSection == _LibraryOptionsSheetSection.filter,
              onTap: () => onChanged(_LibraryOptionsSheetSection.filter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySectionButton({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.32)
                  : colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.18)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyleConst.labelSmall.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: selected
                    ? Container(
                        key: const ValueKey('offline-section-selected-dot'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        key: const ValueKey('offline-section-unselected-icon'),
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(OfflineLibrarySortMode sortMode) {
    final l10n = AppLocalizations.of(context)!;
    switch (sortMode) {
      case OfflineLibrarySortMode.date:
        return l10n.recent;
      case OfflineLibrarySortMode.title:
        return 'A-Z';
      case OfflineLibrarySortMode.imageCount:
        return l10n.pages;
    }
  }

  String _filterLabel(OfflineSourceFilterOption option) {
    final l10n = AppLocalizations.of(context)!;
    switch (option.kind) {
      case OfflineSourceBucketKind.all:
        return l10n.all;
      case OfflineSourceBucketKind.local:
        return l10n.local;
      case OfflineSourceBucketKind.other:
        return l10n.other;
      case OfflineSourceBucketKind.installed:
        return option.displayName ?? option.sourceId ?? option.id;
    }
  }

  IconData _filterIcon(OfflineSourceBucketKind kind) {
    switch (kind) {
      case OfflineSourceBucketKind.all:
        return Icons.apps_rounded;
      case OfflineSourceBucketKind.local:
        return Icons.folder_rounded;
      case OfflineSourceBucketKind.other:
        return Icons.extension_rounded;
      case OfflineSourceBucketKind.installed:
        return Icons.public_rounded;
    }
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
          onRetry: () {
            if (state.query.trim().isNotEmpty) {
              _offlineSearchCubit.searchOfflineContent(state.query.trim());
              return;
            }
            _offlineSearchCubit.getAllOfflineContent();
          },
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
          Expanded(
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settingsState) {
                final localBlacklistEntries = settingsState is SettingsLoaded
                    ? settingsState.preferences.blacklistedTags
                    : const <String>[];

                // Wrap GridView with NotificationListener for infinite scroll
                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        ResponsiveGridDelegate.createStandardGridDelegate(
                      context,
                      context.read<SettingsCubit>(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.displayOrder.length +
                        (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.displayOrder.length) {
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

                      final entryKey = state.displayOrder[index];
                      final group = state.groupsByKey[entryKey];
                      if (group != null) {
                        return _buildGroupedContentCard(
                          group: group,
                          highlightQuery: state.query,
                          localBlacklistEntries: localBlacklistEntries,
                        );
                      }

                      final item = state.itemsById[entryKey];
                      if (item == null) {
                        return const SizedBox.shrink();
                      }

                      return _buildSingleContentCard(
                        item: item,
                        offlineSize: state.offlineSizes[item.stableId],
                        highlightQuery: state.query,
                        localBlacklistEntries: localBlacklistEntries,
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

  Widget _buildSingleContentCard({
    required OfflineLibraryItemData item,
    required String? offlineSize,
    required String highlightQuery,
    required List<String> localBlacklistEntries,
  }) {
    final content = item.content.copyWith(
      subTitle: _buildSingleItemSubtitle(item),
    );

    return ContentCard(
      content: content,
      onTap: () => _openReader(context, content),
      onLongPress: () => _showContentActions(
        context,
        content,
        itemData: item,
      ),
      showOfflineIndicator: true,
      isHighlighted: false,
      isBlurred: _tagBlacklistService.isContentBlacklisted(
        content,
        localEntries: localBlacklistEntries,
      ),
      offlineSize: offlineSize ??
          OfflineContentManager.formatStorageSize(item.fileSizeBytes),
      highlightQuery: highlightQuery,
      preferStaticCover: true,
    );
  }

  Widget _buildGroupedContentCard({
    required OfflineLibraryGroupData group,
    required String highlightQuery,
    required List<String> localBlacklistEntries,
  }) {
    final previewContent = group.previewContent.copyWith(
      title: group.parentTitle,
      subTitle: _buildGroupSubtitle(group),
      pageCount: group.totalImageCount,
      uploadDate: group.sortDate,
    );

    return ContentCard(
      content: previewContent,
      onTap: () => _handleGroupedCardTap(context, group),
      onLongPress: () => _showGroupedContentSheet(context, group),
      showOfflineIndicator: true,
      isHighlighted: false,
      isBlurred: _tagBlacklistService.isContentBlacklisted(
        previewContent,
        localEntries: localBlacklistEntries,
      ),
      offlineSize:
          OfflineContentManager.formatStorageSize(group.totalFileSizeBytes),
      highlightQuery: highlightQuery,
      preferStaticCover: true,
    );
  }

  Future<void> _handleGroupedCardTap(
    BuildContext context,
    OfflineLibraryGroupData group,
  ) async {
    if (group.children.length == 1) {
      await _openReader(context, group.children.first.content);
      return;
    }

    await _showGroupedContentSheet(context, group);
  }

  String _buildSingleItemSubtitle(OfflineLibraryItemData item) {
    final contentSubtitle = item.content.subTitle?.trim();
    final sourceLabel = _buildSourceLabel(
      kind: item.sourceBucketKind,
      sourceDisplayName: item.sourceDisplayName,
    );

    if (contentSubtitle != null && contentSubtitle.isNotEmpty) {
      return '$sourceLabel • $contentSubtitle';
    }

    return sourceLabel;
  }

  String _buildGroupSubtitle(OfflineLibraryGroupData group) {
    final sourceLabel = _buildSourceLabel(
      kind: group.sourceBucketKind,
      sourceDisplayName: group.sourceDisplayName,
    );
    final childLabels = group.children
        .take(2)
        .map((child) => child.childLabel.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    final remainder = group.children.length - childLabels.length;
    final childSummary = [
      ...childLabels,
      if (remainder > 0) '+$remainder',
    ].join(' • ');

    if (childSummary.isEmpty) {
      return sourceLabel;
    }

    return '$sourceLabel • $childSummary';
  }

  String _buildSourceLabel({
    required OfflineSourceBucketKind kind,
    required String sourceDisplayName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case OfflineSourceBucketKind.local:
        return l10n.local;
      case OfflineSourceBucketKind.other:
        return '${l10n.other}: $sourceDisplayName';
      case OfflineSourceBucketKind.installed:
        return sourceDisplayName;
      case OfflineSourceBucketKind.all:
        return l10n.all;
    }
  }

  Future<void> _showGroupedContentSheet(
    BuildContext context,
    OfflineLibraryGroupData group,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final sizeText =
        OfflineContentManager.formatStorageSize(group.totalFileSizeBytes);

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final parentContext = context;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProgressiveImageWidget(
                        networkUrl: group.previewContent.coverUrl,
                        contentId: group.previewContent.id,
                        isThumbnail: true,
                        width: 60,
                        height: 84,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                        preferStaticPreview: true,
                        errorWidget: Container(
                          width: 60,
                          height: 84,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
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
                            group.parentTitle,
                            style: TextStyleConst.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildSourceLabel(
                              kind: group.sourceBucketKind,
                              sourceDisplayName: group.sourceDisplayName,
                            ),
                            style: TextStyleConst.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${group.children.length} • '
                            '${l10n.pages}: ${group.totalImageCount} • $sizeText',
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
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.children.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final child = group.children[index];
                    final childSize = OfflineContentManager.formatStorageSize(
                      child.fileSizeBytes,
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.secondaryContainer,
                        foregroundColor: colorScheme.onSecondaryContainer,
                        child: Text(
                          '${index + 1}',
                          style: TextStyleConst.labelSmall.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        child.childLabel,
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${l10n.pages}: ${child.imageCount} • $childSize',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                          _showContentActions(
                            parentContext,
                            child.content,
                            itemData: child,
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _openReader(parentContext, child.content);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

  Future<void> _showContentActions(
    BuildContext context,
    Content content, {
    OfflineLibraryItemData? itemData,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final offlineManager = getIt<OfflineContentManager>();
    final l10n = AppLocalizations.of(context)!;

    final imagePaths = await offlineManager.getOfflineImageUrls(content.id);
    int totalBytes = 0;
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    final sizeText = OfflineContentManager.formatStorageSize(totalBytes);
    final resolvedPath = itemData?.resolvedPath ??
        await offlineManager.resolveOfflineStoragePath(
          contentId: content.id,
          contentPath: content.derivedContentPath,
          imageUrls: imagePaths,
        );

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        // Capture parent context safely
        final parentContext = context;

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ProgressiveImageWidget(
                        networkUrl: content.coverUrl,
                        contentId: content.id,
                        isThumbnail: true,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(4),
                        preferStaticPreview: true,
                        errorWidget: Container(
                          width: 50,
                          height: 70,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image,
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
                            content.title,
                            style: TextStyleConst.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!
                                .pagesWithSize(content.pageCount, sizeText),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
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
                            Icons.folder_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.path,
                            style: TextStyleConst.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (resolvedPath != null &&
                          resolvedPath.trim().isNotEmpty)
                        SelectableText(
                          resolvedPath,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Text(
                          l10n.unknown,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              FutureBuilder<bool>(
                future: _checkPdfExists(content.id),
                builder: (context, snapshot) {
                  final isPdf = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.remove_red_eye,
                        color:
                            isPdf ? colorScheme.tertiary : colorScheme.primary),
                    title: Text(isPdf ? '${l10n.readNow} (PDF)' : l10n.readNow),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _openReader(parentContext, content);
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  try {
                    // Check feature flag
                    final remoteConfig = getIt<RemoteConfigService>();
                    // Offline content always has sourceId
                    final isEnabled = remoteConfig.isFeatureEnabled(
                        content.sourceId, (f) => f.generatePdf);

                    if (!isEnabled) return const SizedBox.shrink();

                    return ListTile(
                      leading: Icon(Icons.picture_as_pdf,
                          color: colorScheme.tertiary),
                      title: Text(l10n.convertToPdf),
                      subtitle: Text(AppLocalizations.of(context)!
                          .nPages(content.pageCount)),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _generatePdf(parentContext, content);
                      },
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmation(parentContext, content);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Generate PDF from offline content
  Future<void> _generatePdf(BuildContext context, Content content) async {
    final l10n = AppLocalizations.of(context)!;
    final offlineManager = getIt<OfflineContentManager>();
    // Queue manager will handle conversion sequentially

    try {
      // Check permissions before starting PDF conversion
      if (!context.mounted) return;

      final hasPermissions = await showPermissionRequestSheet(
        context,
        requireStorage: true,
        requireNotification: true,
      );

      if (!context.mounted || !hasPermissions) {
        if (context.mounted && !hasPermissions) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.permissionDenied),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.convertingToPdf),
          duration: const Duration(seconds: 2),
        ),
      );

      final imagePaths = await offlineManager.getOfflineImageUrls(content.id);

      if (imagePaths.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfConversionFailedWithError(
              content.title,
              AppLocalizations.of(context)!.noImagesFound,
            )),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // Queue PDF conversion instead of converting immediately
      final queueManager = getIt<PdfConversionQueueManager>();
      await queueManager.queueConversion(
        contentId: content.id,
        title: content.title,
        imagePaths: imagePaths,
        sourceId: content.sourceId,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pdfConversionFailedWithError(
            content.title,
            e.toString(),
          )),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      BuildContext context, Content content) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final prefs = await SharedPreferences.getInstance();
    final skipConfirmation = prefs.getBool('skip_delete_confirmation') ?? false;

    if (skipConfirmation) {
      if (!context.mounted) return;
      await _deleteContent(context, content);
      return;
    }

    final dontAskAgainNotifier = ValueNotifier<bool>(false);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n
                .removeDownloadConfirmation), // Ensure this key exists or use fallback
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: dontAskAgainNotifier,
              builder: (context, dontAskAgain, child) => CheckboxListTile(
                value: dontAskAgain,
                onChanged: (value) =>
                    dontAskAgainNotifier.value = value ?? false,
                title: Text(AppLocalizations.of(context)!.dontAskAgain),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (dontAskAgainNotifier.value) {
        await prefs.setBool('skip_delete_confirmation', true);
      }
      if (!context.mounted) return;
      await _deleteContent(context, content);
    }
    dontAskAgainNotifier.dispose();
  }

  /// Delete offline content
  Future<void> _deleteContent(BuildContext context, Content content) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletingContent(content.title)),
          duration: const Duration(seconds: 1),
        ),
      );

      await context.read<OfflineSearchCubit>().deleteOfflineContent(content.id);

      // Add a small delay to ensure DB transaction is committed
      // Use getIt to access the singleton DownloadBloc, bypassing context entirely
      Future.delayed(const Duration(milliseconds: 500), () {
        getIt<DownloadBloc>().add(const DownloadRefreshEvent());
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.contentDeleted),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _openReader(BuildContext context, Content content) async {
    final offlineManager = getIt<OfflineContentManager>();
    // Try to find PDF
    try {
      final firstImagePath =
          await offlineManager.getOfflineFirstImagePath(content.id);
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        final pdfDir = Directory(p.join(contentDir, 'pdf'));

        if (await pdfDir.exists()) {
          final files = await pdfDir.list().toList();
          final pdfs = files
              .where((f) => f.path.toLowerCase().endsWith('.pdf'))
              .toList();
          if (pdfs.isNotEmpty) {
            // Found PDF!
            final pdfFile = pdfs.first;
            if (context.mounted) {
              AppRouter.goToReaderPdf(context,
                  filePath: pdfFile.path,
                  contentId: content.id,
                  title: content.title);
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for PDF: $e');
    }

    // Fallback to Image Reader
    if (context.mounted) {
      await AppRouter.goToReader(
        context,
        content.id,
        content: content,
        forceStartFromBeginning: true,
      );
    }
  }

  Future<bool> _checkPdfExists(String contentId) async {
    final offlineManager = getIt<OfflineContentManager>();
    try {
      final firstImagePath =
          await offlineManager.getOfflineFirstImagePath(contentId);
      debugPrint('First image path: $firstImagePath');
      if (firstImagePath != null) {
        final contentDir = File(firstImagePath).parent.parent.path;
        debugPrint('contentDir: $contentDir');
        final pdfDir = Directory(p.join(contentDir, 'pdf'));
        debugPrint('pdfDir: $pdfDir');
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
}
