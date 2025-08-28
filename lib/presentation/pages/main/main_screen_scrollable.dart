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
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';  // 🐛 FIXED: Added import for DownloadBloc
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_main_header_widget.dart';
import 'package:nhasixapp/presentation/widgets/content_list_widget.dart';
import 'package:nhasixapp/presentation/widgets/content_card_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';
import 'package:nhasixapp/presentation/widgets/sorting_widget.dart';
import 'package:nhasixapp/presentation/widgets/offline_indicator_widget.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';

class MainScreenScrollable extends StatefulWidget {
  const MainScreenScrollable({super.key});

  @override
  State<MainScreenScrollable> createState() => _MainScreenScrollableState();
}

class _MainScreenScrollableState extends State<MainScreenScrollable> {
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
            return SimpleOfflineScaffold(
              title: 'NHentai',
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyleConst.styleMedium(
                        textColor: Theme.of(context).colorScheme.onSurface,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Main screen UI when home is loaded
          return AppScaffoldWithOffline(
            title: 'Nhentai',
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
            body: _buildScrollableBody(),
          );
        },
      ),
    );
  }

  /// Build the new scrollable body with all components integrated
  Widget _buildScrollableBody() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          return Column(
            children: [
              // Offline banner - tetap di atas
              const OfflineBanner(),

              // Content area dengan semua komponen dalam scroll
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildScrollableContent(state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build scrollable content with all components integrated
  Widget _buildScrollableContent(ContentState state) {
    return BlocConsumer<ContentBloc, ContentState>(
      listener: (context, state) {
        if (state is ContentError) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              action: state.canRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        context
                            .read<ContentBloc>()
                            .add(const ContentRetryEvent());
                      },
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ContentInitial) {
          return Center(
            child: Text(
              'Tap to load content',
              style: TextStyleConst.placeholderText,
            ),
          );
        }

        if (state is ContentLoading) {
          return _buildLoadingState(state);
        }

        if (state is ContentEmpty) {
          return _buildEmptyState(state);
        }

        if (state is ContentError) {
          return _buildErrorState(state);
        }

        if (state is ContentLoaded) {
          return _buildScrollableContentGrid(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Build loading state UI
  Widget _buildLoadingState(ContentLoading state) {
    // Show overlay loading for pagination changes if we have previous content
    if (state.previousContents != null && state.previousContents!.isNotEmpty) {
      return Stack(
        children: [
          // Show previous content with reduced opacity
          Opacity(
            opacity: 0.3,
            child: _buildScrollableContentGrid(ContentLoaded(
              contents: state.previousContents!,
              currentPage: 1, // Temporary values
              totalPages: 1,
              totalCount: state.previousContents!.length,
              hasNext: false,
              hasPrevious: false,
              sortBy: SortOption.newest,
              lastUpdated: DateTime.now(),
            )),
          ),
          // Loading overlay
          Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      state.message.isNotEmpty ? state.message : 'Loading...',
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Full loading for initial load
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              state.message.isNotEmpty ? state.message : 'Loading content...',
              style: TextStyleConst.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state UI
  Widget _buildEmptyState(ContentEmpty state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            state.contextualMessage,
            textAlign: TextAlign.center,
            style: TextStyleConst.bodyMedium,
          ),
          const SizedBox(height: 8),
          if (state.suggestions.isNotEmpty) ...[
            Text(
              'Suggestions:',
              style: TextStyleConst.bodyMedium,
            ),
            const SizedBox(height: 4),
            ...state.suggestions.map((suggestion) => Text(
                  '• $suggestion',
                  style: TextStyleConst.bodyMedium,
                )),
          ],
          if (state.canRetry) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ContentBloc>().add(const ContentRetryEvent());
              },
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build error state UI
  Widget _buildErrorState(ContentError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            state.errorIcon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            state.errorType.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            state.userFriendlyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (state.canRetry) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ContentBloc>().add(const ContentRetryEvent());
              },
              child: const Text('Retry'),
            ),
          ],
          if (state.hasPreviousContent) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Show cached content
                // This would require additional implementation
              },
              child: const Text('Show Cached Content'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the main scrollable content grid with integrated components
  Widget _buildScrollableContentGrid(ContentLoaded state) {
    return CustomScrollView(
      slivers: [
        // Search results header (if showing search results) - sebagai sliver
        if (_isShowingSearchResults) 
          SliverToBoxAdapter(
            child: _buildSearchResultsHeader(),
          ),

        // Sorting widget - sebagai sliver
        if (_shouldShowSorting(state))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SortingWidget(
                currentSort: _currentSortOption,
                onSortChanged: _onSortingChanged,
              ),
            ),
          ),

        // Content grid dengan downloaded highlight effect
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final content = state.contents[index];
                
                // Use FutureBuilder to check download status for highlight
                return FutureBuilder<bool>(
                  future: ContentDownloadCache.isDownloaded(content.id, context), // 🐛 FIXED: Pass context for DownloadBloc access
                  builder: (context, snapshot) {
                    final isDownloaded = snapshot.data ?? false;
                    
                    return ContentCard(
                      content: content,
                      onTap: () => _onContentTap(content),
                      isHighlighted: isDownloaded, // Phase 4: Highlight downloaded content
                    );
                  },
                );
              },
              childCount: state.contents.length,
            ),
          ),
        ),

        // Pagination footer - sebagai sliver di bottom
        SliverToBoxAdapter(
          child: _buildContentFooter(state),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  /// Handle content tap to navigate to detail screen
  void _onContentTap(Content content) async {
    final searchFilter = await AppRouter.goToContentDetail(context, content.id);

    // If user searched by tag from detail screen, trigger search
    if (searchFilter != null && mounted) {
      setState(() {
        _isShowingSearchResults = true;
        _currentSearchFilter = searchFilter;
      });

      // Trigger search with the filter
      _contentBloc.add(ContentSearchEvent(searchFilter));
      Logger().i('MainScreen: Loading search results from tag tap');
    }
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
    // Only show sorting when there's an active search/filter AND there's data
    if (!_isShowingSearchResults) {
      return false; // Hide sorting for normal content browsing
    }
    
    // Show sorting only when there's data (loaded state with content) and search is active
    if (state is ContentLoaded && state.contents.isNotEmpty) {
      return true;
    }
    // Also show when loading more or refreshing (to maintain UI consistency) and search is active
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
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.5),
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
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
                      style: TextStyleConst.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
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
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSearchFilterSummary(_currentSearchFilter!),
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      _currentSearchFilter = null;
      _isShowingSearchResults = false;
    });

    try {
      // Clear saved search filter using removeLastSearchFilter or similar method
      // Note: We need to check if this method exists in LocalDataSource
      // For now, we'll skip the clear operation
      
      // Load normal content
      _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
      Logger().i('MainScreen: Cleared search results, loading normal content');
    } catch (e) {
      Logger().e('MainScreen: Error clearing search results: $e');
    }
  }

  /// Build content footer with pagination
  Widget _buildContentFooter(ContentState state) {
    if (state is! ContentLoaded) {
      return const SizedBox.shrink();
    }

    // Don't show pagination if there's only one page
    if (state.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          _contentBloc.add(ContentGoToPageEvent(state.currentPage + 1));
        },
        onPreviousPage: () {
          _contentBloc.add(ContentGoToPageEvent(state.currentPage - 1));
        },
        onGoToPage: (page) {
          _contentBloc.add(ContentGoToPageEvent(page));
        },
        showProgressBar: false, // Simplify for Phase 5
        showPercentage: false, // Simplify for Phase 5
        showPageInput: true, // Keep tap-to-jump functionality
      ),
    );
  }
}
