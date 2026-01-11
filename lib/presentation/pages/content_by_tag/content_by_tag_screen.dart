import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';
import 'package:nhasixapp/presentation/widgets/sorting_widget.dart';
import 'package:nhasixapp/presentation/widgets/offline_indicator_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';

/// Screen for browsing content by specific tag
///
/// URL format: /search?q=[tag-name]
/// Simple UI: Back button + Title + Filter + Content List + Pagination
/// No database save, no highlight effects
class ContentByTagScreen extends StatefulWidget {
  const ContentByTagScreen({
    super.key,
    required this.tagQuery,
  });

  final String tagQuery;

  @override
  State<ContentByTagScreen> createState() => _ContentByTagScreenState();
}

class _ContentByTagScreenState extends State<ContentByTagScreen> {
  late final ContentBloc _contentBloc;
  SearchFilter? _currentSearchFilter;
  SortOption _currentSortOption = SortOption.newest;

  @override
  void initState() {
    super.initState();
    _contentBloc = getIt<ContentBloc>();
    _initializeContent();
  }

  /// Initialize content with tag search
  Future<void> _initializeContent() async {
    try {
      // Load saved sorting preference
      final userDataRepository = getIt<UserDataRepository>();
      _currentSortOption = await userDataRepository.getSortingPreference();

      // Create search filter for the tag
      final searchFilter = SearchFilter(
        query: widget.tagQuery,
        sortBy: _currentSortOption,
        source: SearchSource.detailScreen,
      );

      _currentSearchFilter = searchFilter;
      _contentBloc.add(ContentSearchEvent(searchFilter));

      setState(() {});
    } catch (e) {
      Logger().e('ContentByTagScreen: Error initializing content: $e');
      // Fallback to simple tag search
      final searchFilter = SearchFilter(
        query: widget.tagQuery,
        sortBy: _currentSortOption,
        source: SearchSource.detailScreen,
      );
      _currentSearchFilter = searchFilter;
      _contentBloc.add(ContentSearchEvent(searchFilter));
    }
  }

  @override
  void dispose() {
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: AppScaffoldWithOffline(
        title: widget.tagQuery.toUpperCase(),
        appBar: AppBar(
          title: Text(
            widget.tagQuery.toUpperCase(),
            style: TextStyleConst.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          // Show loading indicator when loading
          if (state is ContentLoading) {
            return Column(
              children: [
                // Offline banner
                const OfflineBanner(),
                // Loading indicator
                Expanded(
                  child: Center(
                    child: AppProgressIndicator(
                      message: state.message,
                      size: 40,
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Offline banner
              const OfflineBanner(),
              // Sorting widget - only visible when there's data
              if (_shouldShowSorting(state))
                SortingWidget(
                  currentSort: _currentSortOption,
                  onSortChanged: _onSortingChanged,
                ),

              // Content area
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: ContentListWidget(
                    onContentTap: _onContentTap,
                    enablePullToRefresh: true,
                    enableInfiniteScroll: false,
                    shouldBlurContent: _shouldBlurContent,
                  ),
                ),
              ),

              // Pagination footer
              _buildContentFooter(state),
            ],
          );
        },
      ),
    );
  }

  /// Handle content tap to navigate to detail screen
  void _onContentTap(Content content) {
    AppRouter.goToContentDetail(
      context,
      content.id,
      sourceId: content.sourceId,
    );
  }

  /// Handle sorting option change
  Future<void> _onSortingChanged(SortOption newSort) async {
    if (_currentSortOption == newSort) return;

    setState(() {
      _currentSortOption = newSort;
    });

    try {
      // Apply sorting and reload content
      if (_currentSearchFilter != null) {
        final newFilter = _currentSearchFilter!.copyWith(
          sortBy: newSort,
          page: 1, // Reset to first page when sorting changes
        );
        _currentSearchFilter = newFilter;
        _contentBloc.add(ContentSearchEvent(newFilter));
      }
    } catch (e) {
      Logger().e('ContentByTagScreen: Error changing sorting: $e');
      // Revert sort option on error
      setState(() {
        _currentSortOption = _currentSortOption;
      });
    }
  }

  /// Check if sorting should be shown
  bool _shouldShowSorting(ContentState state) {
    // Show sorting only when there's data
    if (state is ContentLoaded && state.contents.isNotEmpty) {
      return true;
    }
    // Also show when loading more or refreshing (to maintain UI consistency)
    if (state is ContentLoadingMore || state is ContentRefreshing) {
      return true;
    }
    return false;
  }

  /// Determine if content should be blurred (excluded content)
  bool _shouldBlurContent(Content content) {
    if (_currentSearchFilter == null) return false;

    final filter = _currentSearchFilter!;

    // Check excluded tags
    for (final tagFilter in filter.tags.where((t) => t.isExcluded)) {
      if (content.tags.any(
          (tag) => tag.name.toLowerCase() == tagFilter.value.toLowerCase())) {
        return true;
      }
    }

    // Check excluded groups
    for (final groupFilter in filter.groups.where((g) => g.isExcluded)) {
      if (content.groups.any(
          (group) => group.toLowerCase() == groupFilter.value.toLowerCase())) {
        return true;
      }
    }

    // Check excluded characters
    for (final charFilter in filter.characters.where((c) => c.isExcluded)) {
      if (content.characters.any(
          (char) => char.toLowerCase() == charFilter.value.toLowerCase())) {
        return true;
      }
    }

    // Check excluded parodies
    for (final parodFilter in filter.parodies.where((p) => p.isExcluded)) {
      if (content.parodies.any(
          (parod) => parod.toLowerCase() == parodFilter.value.toLowerCase())) {
        return true;
      }
    }

    // Check excluded artists
    for (final artistFilter in filter.artists.where((a) => a.isExcluded)) {
      if (content.artists.any((artist) =>
          artist.toLowerCase() == artistFilter.value.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  Widget _buildContentFooter(ContentState state) {
    if (state is! ContentLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: PaginationWidget(
        currentPage: state.currentPage,
        totalPages: state.totalPages,
        hasNext: state.hasNext,
        hasPrevious: state.hasPrevious,
        onNextPage: () {
          if (_currentSearchFilter != null) {
            final newFilter = _currentSearchFilter!.copyWith(
              page: state.currentPage + 1,
              sortBy: _currentSortOption,
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          }
        },
        onPreviousPage: () {
          if (_currentSearchFilter != null) {
            final newFilter = _currentSearchFilter!.copyWith(
              page: state.currentPage - 1,
              sortBy: _currentSortOption,
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          }
        },
        onGoToPage: (page) {
          if (_currentSearchFilter != null) {
            final newFilter = _currentSearchFilter!.copyWith(
              page: page,
              sortBy: _currentSortOption,
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          }
        },
        showProgressBar: true,
        showPercentage: true,
        showPageInput: true,
      ),
    );
  }
}
