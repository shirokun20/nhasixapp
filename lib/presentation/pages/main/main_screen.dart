import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_main_header_widget.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';
import 'package:nhasixapp/presentation/widgets/sorting_widget.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final HomeBloc _homeBloc;
  late final ContentBloc _contentBloc;
  late final SearchBloc _searchBloc;

  bool _isShowingSearchResults = false;
  SearchFilter? _currentSearchFilter;
  SortOption _currentSortOption = SortOption.newest;

  @override
  void initState() {
    super.initState();
    // Initialize HomeBloc for screen-level state management
    _homeBloc = getIt<HomeBloc>()..add(HomeStartedEvent());

    // Initialize ContentBloc for content data management
    _contentBloc = getIt<ContentBloc>();

    // Initialize SearchBloc to check for saved search state
    _searchBloc = getIt<SearchBloc>();

    _initializeContent();
  }

  /// Initialize content - check for saved search state first
  Future<void> _initializeContent() async {
    try {
      // Load saved sorting preference
      final userDataRepository = getIt<UserDataRepository>();
      _currentSortOption = await userDataRepository.getSortingPreference();

      // Check if there's a saved search filter from local storage
      final savedFilterData =
          await getIt<LocalDataSource>().getLastSearchFilter();

      if (savedFilterData != null) {
        // Convert saved data back to SearchFilter
        final savedFilter = SearchFilter.fromJson(savedFilterData);

        if (savedFilter.hasFilters) {
          // Load search results if there's a saved filter, but use current sort option
          _currentSearchFilter =
              savedFilter.copyWith(sortBy: _currentSortOption);
          _isShowingSearchResults = true;
          _contentBloc.add(ContentSearchEvent(_currentSearchFilter!));
          Logger().i(
              'MainScreen: Loading saved search results with sort: $_currentSortOption');
        } else {
          // Load normal content list with saved sort option
          _isShowingSearchResults = false;
          _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
          Logger().i(
              'MainScreen: Loading normal content list with sort: $_currentSortOption');
        }
      } else {
        // Load normal content list with saved sort option
        _isShowingSearchResults = false;
        _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
        Logger().i(
            'MainScreen: Loading normal content list with sort: $_currentSortOption');
      }

      setState(() {});
    } catch (e) {
      Logger().e('MainScreen: Error initializing content: $e');
      // Fallback to normal content loading
      _isShowingSearchResults = false;
      _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
    }
  }

  @override
  void dispose() {
    _homeBloc.close();
    _contentBloc.close();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc),
        BlocProvider.value(value: _contentBloc),
        BlocProvider.value(value: _searchBloc),
      ],
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          // Show full screen loading during home initialization
          if (homeState is HomeLoading) {
            return Scaffold(
              backgroundColor: ColorsConst.darkBackground,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: ColorsConst.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyleConst.styleMedium(
                        textColor: ColorsConst.darkTextPrimary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Main screen UI when home is loaded
          return Scaffold(
            backgroundColor: ColorsConst.darkBackground,
            appBar: AppMainHeaderWidget(
              context: context,
              onSearchPressed: () async {
                // Navigate to search and wait for result
                final result = await context.push(AppRoute.search);
                if (result == true) {
                  // Search was performed, refresh content
                  _initializeContent();
                }
              },
            ),
            drawer: AppMainDrawerWidget(context: context),
            body: _buildBody(),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      color: ColorsConst.darkBackground,
      child: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          return Column(
            children: [
              // Search results header (if showing search results)
              if (_isShowingSearchResults) _buildSearchResultsHeader(),

              // Sorting widget - only visible when there's data
              if (_shouldShowSorting(state))
                SortingWidget(
                  currentSort: _currentSortOption,
                  onSortChanged: _onSortingChanged,
                ),

              // Content area with black theme
              Expanded(
                child: Container(
                  color: ColorsConst.darkBackground,
                  child: ContentListWidget(
                    onContentTap: _onContentTap,
                    enablePullToRefresh: true, // Allow pull-to-refresh
                    enableInfiniteScroll: false, // Use pagination instead
                  ),
                ),
              ),
              // Pagination footer with black theme
              _buildContentFooter(state),
            ],
          );
        },
      ),
    );
  }

  /// Handle content tap to navigate to detail screen
  void _onContentTap(Content content) {
    AppRouter.goToContentDetail(context, content.id);
  }

  /// Handle sorting option change
  Future<void> _onSortingChanged(SortOption newSort) async {
    if (_currentSortOption == newSort) return;

    setState(() {
      _currentSortOption = newSort;
    });

    try {
      // Save sorting preference
      final userDataRepository = getIt<UserDataRepository>();
      await userDataRepository.saveSortingPreference(newSort);

      // Apply sorting using ContentBloc event
      _contentBloc.add(ContentSortChangedEvent(newSort));
      Logger().i('MainScreen: Applied sorting $newSort');

      // Update current search filter if showing search results
      if (_isShowingSearchResults && _currentSearchFilter != null) {
        _currentSearchFilter = _currentSearchFilter!.copyWith(
          sortBy: newSort,
          page: 1, // Reset to first page when sorting changes
        );
      }
    } catch (e) {
      Logger().e('MainScreen: Error changing sorting: $e');
      // Revert sort option on error
      setState(() {
        _currentSortOption = _currentSortOption;
      });
    }
  }

  /// Check if sorting should be shown
  bool _shouldShowSorting(ContentState state) {
    // Show sorting only when there's data (loaded state with content)
    if (state is ContentLoaded && state.contents.isNotEmpty) {
      return true;
    }
    // Also show when loading more or refreshing (to maintain UI consistency)
    if (state is ContentLoadingMore || state is ContentRefreshing) {
      return true;
    }
    return false;
  }

  /// Build search results header
  Widget _buildSearchResultsHeader() {
    if (!_isShowingSearchResults || _currentSearchFilter == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkSurface,
        border: const Border(
          bottom: BorderSide(
            color: ColorsConst.borderDefault,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsConst.darkBackground.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorsConst.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.search,
                  color: ColorsConst.accentBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: TextStyleConst.headingSmall.copyWith(
                        color: ColorsConst.darkTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Showing filtered content',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _clearSearchResults,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: ColorsConst.accentRed,
                  backgroundColor: ColorsConst.accentRed.withValues(alpha: 0.1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsConst.darkCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsConst.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Filters:',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSearchFilterSummary(_currentSearchFilter!),
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get search filter summary for display
  String _getSearchFilterSummary(SearchFilter filter) {
    final parts = <String>[];

    if (filter.query != null && filter.query!.isNotEmpty) {
      parts.add('Query: "${filter.query}"');
    }

    if (filter.tags.isNotEmpty) {
      final includeTags = filter.tags
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeTags = filter.tags
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeTags.isNotEmpty) {
        parts.add('Tags: ${includeTags.join(', ')}');
      }
      if (excludeTags.isNotEmpty) {
        parts.add('Exclude Tags: ${excludeTags.join(', ')}');
      }
    }

    if (filter.groups.isNotEmpty) {
      final includeGroups = filter.groups
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeGroups = filter.groups
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeGroups.isNotEmpty) {
        parts.add('Groups: ${includeGroups.join(', ')}');
      }
      if (excludeGroups.isNotEmpty) {
        parts.add('Exclude Groups: ${excludeGroups.join(', ')}');
      }
    }

    if (filter.characters.isNotEmpty) {
      final includeCharacters = filter.characters
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeCharacters = filter.characters
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeCharacters.isNotEmpty) {
        parts.add('Characters: ${includeCharacters.join(', ')}');
      }
      if (excludeCharacters.isNotEmpty) {
        parts.add('Exclude Characters: ${excludeCharacters.join(', ')}');
      }
    }

    if (filter.parodies.isNotEmpty) {
      final includeParodies = filter.parodies
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeParodies = filter.parodies
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeParodies.isNotEmpty) {
        parts.add('Parodies: ${includeParodies.join(', ')}');
      }
      if (excludeParodies.isNotEmpty) {
        parts.add('Exclude Parodies: ${excludeParodies.join(', ')}');
      }
    }

    if (filter.artists.isNotEmpty) {
      final includeArtists = filter.artists
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeArtists = filter.artists
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeArtists.isNotEmpty) {
        parts.add('Artists: ${includeArtists.join(', ')}');
      }
      if (excludeArtists.isNotEmpty) {
        parts.add('Exclude Artists: ${excludeArtists.join(', ')}');
      }
    }

    if (filter.language != null) {
      parts.add('Language: ${filter.language}');
    }

    if (filter.category != null) {
      parts.add('Category: ${filter.category}');
    }

    return parts.join(' • ');
  }

  /// Clear search results and return to normal content
  void _clearSearchResults() async {
    setState(() {
      _isShowingSearchResults = false;
      _currentSearchFilter = null;
    });

    // Clear search filter from local storage
    try {
      await getIt<LocalDataSource>().clearSearchFilter();
      Logger().i('MainScreen: Cleared search filter from local storage');
    } catch (e) {
      Logger().e('MainScreen: Error clearing search filter: $e');
    }

    // Load normal content with current sort option
    _contentBloc
        .add(ContentLoadEvent(sortBy: _currentSortOption, forceRefresh: true));
  }

  Widget _buildContentFooter(ContentState state) {
    if (state is! ContentLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: const BoxDecoration(
        color: ColorsConst.darkSurface,
        border: Border(
          top: BorderSide(
            color: ColorsConst.borderDefault,
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
          if (_isShowingSearchResults && _currentSearchFilter != null) {
            // For search results, update the filter with new page
            final newFilter = _currentSearchFilter!.copyWith(
              page: state.currentPage + 1,
              sortBy: _currentSortOption, // Ensure current sort is maintained
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          } else {
            // For normal content
            _contentBloc.add(const ContentNextPageEvent());
          }
        },
        onPreviousPage: () {
          if (_isShowingSearchResults && _currentSearchFilter != null) {
            // For search results, update the filter with new page
            final newFilter = _currentSearchFilter!.copyWith(
              page: state.currentPage - 1,
              sortBy: _currentSortOption, // Ensure current sort is maintained
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          } else {
            // For normal content
            _contentBloc.add(const ContentPreviousPageEvent());
          }
        },
        onGoToPage: (page) {
          if (_isShowingSearchResults && _currentSearchFilter != null) {
            // For search results, update the filter with new page
            final newFilter = _currentSearchFilter!.copyWith(
              page: page,
              sortBy: _currentSortOption, // Ensure current sort is maintained
            );
            _contentBloc.add(ContentSearchEvent(newFilter));
          } else {
            // For normal content
            _contentBloc.add(ContentGoToPageEvent(page));
          }
        },
        showProgressBar: true,
        showPercentage: true,
        showPageInput: true, // Enable page input for large page counts
      ),
    );
  }

  /// Handle search results from SearchScreen
  void handleSearchResults(SearchFilter filter) {
    setState(() {
      _isShowingSearchResults = true;
      _currentSearchFilter = filter;
    });

    // Load search results
    _contentBloc.add(ContentSearchEvent(filter));
    Logger().i('MainScreen: Loading search results from SearchScreen');
  }
}
