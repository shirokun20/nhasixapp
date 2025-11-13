import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/core/utils/responsive_grid_delegate.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/content_repository.dart';
import 'package:nhasixapp/presentation/blocs/content/content_bloc.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';
import 'package:nhasixapp/presentation/blocs/home/home_bloc.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart';
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
        try {
          // Convert saved data back to SearchFilter
          final savedFilter = SearchFilter.fromJson(savedFilterData);

          // Validate if the filter is meaningful and not just empty/cleared data
          if (savedFilter.hasFilters && _isValidSearchFilter(savedFilter)) {
            // Load search results if there's a saved filter, but use current sort option
            _currentSearchFilter =
                savedFilter.copyWith(sortBy: _currentSortOption);
            _isShowingSearchResults = true;
            _contentBloc.add(ContentSearchEvent(_currentSearchFilter!));
            Logger().i(
                'MainScreen: Loading saved search results with sort: $_currentSortOption');
          } else {
            // Invalid or empty filter, clear it and load normal content
            await getIt<LocalDataSource>().removeLastSearchFilter();
            _isShowingSearchResults = false;
            _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
            Logger().i(
                'MainScreen: Cleared invalid search filter, loading normal content with sort: $_currentSortOption');
          }
        } catch (filterError) {
          // Error parsing filter data, clear it and load normal content
          Logger().w(
              'MainScreen: Error parsing saved filter, clearing it: $filterError');
          await getIt<LocalDataSource>().removeLastSearchFilter();
          _isShowingSearchResults = false;
          _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
        }
      } else {
        // No saved filter, load normal content list with saved sort option
        _isShowingSearchResults = false;
        _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
        Logger().i(
            'MainScreen: No saved search filter, loading normal content with sort: $_currentSortOption');
      }

      setState(() {});
    } catch (e) {
      Logger().e('MainScreen: Error initializing content: $e');
      // Fallback to normal content loading
      _isShowingSearchResults = false;
      _contentBloc.add(ContentLoadEvent(sortBy: _currentSortOption));
    }
  }

  /// Validate if search filter is meaningful and not empty/cleared
  bool _isValidSearchFilter(SearchFilter filter) {
    // Check if filter has any meaningful content beyond just having non-null values
    return filter.query != null && filter.query!.trim().isNotEmpty ||
        filter.tags.isNotEmpty ||
        filter.groups.isNotEmpty ||
        filter.characters.isNotEmpty ||
        filter.parodies.isNotEmpty ||
        filter.artists.isNotEmpty ||
        filter.language != null ||
        filter.category != null;
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
              title: AppLocalizations.of(context)?.appTitle ?? 'NHentai',
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.initializing,
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
            title: AppLocalizations.of(context)?.appTitle ?? 'Nhentai',
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
              onOpenBrowser: () => _openInBrowser(),
              onDownloadAll: () => _downloadAllGalleries(),
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
                      label: AppLocalizations.of(context)!.retry,
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
              AppLocalizations.of(context)?.tapToLoadContent ??
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
                      color:
                          Theme.of(context).shadowColor.withValues(alpha: 0.5),
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
                      state.message.isNotEmpty
                          ? state.message
                          : AppLocalizations.of(context)!.loading,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
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
              state.message.isNotEmpty
                  ? state.message
                  : AppLocalizations.of(context)?.loadingContent ??
                      'Loading content...',
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
              AppLocalizations.of(context)?.suggestions ?? 'Suggestions:',
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
              child:
                  Text(AppLocalizations.of(context)?.tryAgain ?? 'Try Again'),
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
            style: TextStyleConst.displayLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
          if (state.hasPreviousContent) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Show cached content
                // This would require additional implementation
              },
              child: Text(AppLocalizations.of(context)!.showCachedContent),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the main scrollable content grid with integrated components
  Widget _buildScrollableContentGrid(ContentLoaded state) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SortingWidget(
                  currentSort: _currentSortOption,
                  onSortChanged: _onSortingChanged,
                ),
              ),
            ),

          // Content grid dengan downloaded highlight effect
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: ResponsiveGridDelegate.createGridDelegate(
                    context,
                    context.read<SettingsCubit>(),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final content = state.contents[index];

                      // Use FutureBuilder to check download status for highlight
                      return FutureBuilder<bool>(
                        future: ContentDownloadCache.isDownloaded(content.id,
                            context), // 🐛 FIXED: Pass context for DownloadBloc access
                        builder: (context, snapshot) {
                          final isDownloaded = snapshot.data ?? false;

                          return ContentCard(
                            content: content,
                            onTap: () => _onContentTap(content),
                            isHighlighted:
                                isDownloaded, // Phase 4: Highlight downloaded content
                          );
                        },
                      );
                    },
                    childCount: state.contents.length,
                  ),
                ),
              );
            },
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
      ),
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

  /// Handle refresh indicator pull-to-refresh
  Future<void> _handleRefresh() async {
    try {
      Logger().i('MainScreen: Refresh triggered by user pull-to-refresh');

      // Show refresh feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)?.refreshingContent ??
                    'Refreshing content...'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Get current page from ContentBloc state
      final contentState = _contentBloc.state;
      final currentPage =
          contentState is ContentLoaded ? contentState.currentPage : 1;

      // Trigger ContentRefreshEvent with current sort option and current page
      _contentBloc.add(ContentRefreshEvent(
          sortBy: _currentSortOption, currentPage: currentPage));

      Logger().i(
          'MainScreen: Refresh event sent with sort: $_currentSortOption, page: $currentPage');
    } catch (e) {
      Logger().e('MainScreen: Error during refresh: $e');
      // Error handling is managed by ContentBloc state changes
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
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
                      AppLocalizations.of(context)?.searchResults ??
                          'Search Results',
                      style: TextStyleConst.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _clearSearchResults,
                icon: const Icon(Icons.clear, size: 16),
                label: Text(AppLocalizations.of(context)!.clear),
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
      parts.add(
          '${AppLocalizations.of(context)?.queryLabel ?? 'Query'}: "${filter.query}"');
    }

    if (filter.tags.isNotEmpty) {
      final includeTags = filter.tags
          .where((item) => !item.isExcluded)
          .map((item) => item.value);
      final excludeTags = filter.tags
          .where((item) => item.isExcluded)
          .map((item) => item.value);

      if (includeTags.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.tagsLabel ?? 'Tags'}: ${includeTags.join(', ')}');
      }
      if (excludeTags.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.excludeTagsLabel ?? 'Exclude Tags'}: ${excludeTags.join(', ')}');
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
        parts.add(
            '${AppLocalizations.of(context)?.groupsLabel ?? 'Groups'}: ${includeGroups.join(', ')}');
      }
      if (excludeGroups.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.excludeGroupsLabel ?? 'Exclude Groups'}: ${excludeGroups.join(', ')}');
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
        parts.add(
            '${AppLocalizations.of(context)?.charactersLabel ?? 'Characters'}: ${includeCharacters.join(', ')}');
      }
      if (excludeCharacters.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.excludeCharactersLabel ?? 'Exclude Characters'}: ${excludeCharacters.join(', ')}');
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
        parts.add(
            '${AppLocalizations.of(context)?.parodiesLabel ?? 'Parodies'}: ${includeParodies.join(', ')}');
      }
      if (excludeParodies.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.excludeParodiesLabel ?? 'Exclude Parodies'}: ${excludeParodies.join(', ')}');
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
        parts.add(
            '${AppLocalizations.of(context)?.artistsLabel ?? 'Artists'}: ${includeArtists.join(', ')}');
      }
      if (excludeArtists.isNotEmpty) {
        parts.add(
            '${AppLocalizations.of(context)?.excludeArtistsLabel ?? 'Exclude Artists'}: ${excludeArtists.join(', ')}');
      }
    }

    if (filter.language != null) {
      parts.add(
          '${AppLocalizations.of(context)?.languageLabel ?? 'Language'}: ${filter.language}');
    }

    if (filter.category != null) {
      parts.add(
          '${AppLocalizations.of(context)?.categoryLabel ?? 'Category'}: ${filter.category}');
    }

    return parts.join(' • ');
  }

  /// Clear search results and return to normal content
  void _clearSearchResults() {
    // Update local UI state immediately
    setState(() {
      _currentSearchFilter = null;
      _isShowingSearchResults = false;
    });

    // Trigger clear search event in ContentBloc - this will handle:
    // 1. Show proper loading state via _buildLoadingState
    // 2. Clear search filter from local storage
    // 3. Load normal content with current sort option
    // 4. Show success/error states properly
    _contentBloc.add(ContentClearSearchEvent(sortBy: _currentSortOption));

    Logger().i(
        'MainScreen: Triggered clear search event with sort: $_currentSortOption');
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

  /// Open current page in browser
  Future<void> _openInBrowser() async {
    try {
      final contentState = _contentBloc.state;
      if (contentState is! ContentLoaded) {
        Logger().w('Cannot open in browser: no content loaded');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noContentToBrowse),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Build URL based on current page and context
      String url;

      if (_isShowingSearchResults && _currentSearchFilter != null) {
        // Search results page - use current search filter
        final filter =
            _currentSearchFilter!.copyWith(page: contentState.currentPage);

        if (filter.isEmpty) {
          // Empty filter - redirect to main page
          url = _buildMainPageUrl(contentState.currentPage);
        } else {
          // Use SearchFilter's complete URL building
          final queryParams = filter.toQueryString();
          if (queryParams.trim().isEmpty) {
            // Fallback to main page if query params are empty
            url = _buildMainPageUrl(contentState.currentPage);
          } else {
            url = 'https://nhentai.net/search/?$queryParams';
          }
        }
      } else {
        // Not showing search results - build URL based on content state context
        url = _buildContentStateUrl(contentState);
      }

      // Clean up URL (remove trailing ? or & and empty parameters)
      url = _cleanUrl(url);

      Logger().i('Built URL for browser: $url');

      // Validate URL format
      if (url.isEmpty) {
        throw 'Generated URL is empty';
      }

      final uri = Uri.parse(url);
      Logger().i('Parsed URI: $uri');
      Logger()
          .i('URI scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
      Logger().i('URI query: ${uri.query}');

      // Additional validation
      if (uri.scheme.isEmpty || uri.host.isEmpty) {
        throw 'Invalid URL format: $url';
      }

      // Try to launch the URL
      bool launched = false;
      String lastError = '';

      // First try with canLaunchUrl check
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          Logger().i('Successfully opened in browser via canLaunchUrl: $url');
        } else {
          Logger().w('canLaunchUrl returned false for: $url');
          lastError = 'canLaunchUrl returned false';
        }
      } catch (e) {
        Logger().e('canLaunchUrl failed: $e');
        lastError = 'canLaunchUrl failed: $e';
      }

      // Fallback: try launching directly for https URLs
      if (!launched && uri.scheme == 'https') {
        try {
          Logger().i('Attempting direct launch for https URL: $url');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          Logger().i('Successfully opened in browser via direct launch: $url');
        } catch (e) {
          Logger().e('Direct launch failed: $e');
          lastError = 'Direct launch failed: $e';
        }
      }

      if (launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.open_in_browser, color: Colors.white),
                  SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.openedInBrowser),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch $url - $lastError';
      }
    } catch (e) {
      Logger().e('Error opening in browser: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '${AppLocalizations.of(context)?.failedToOpenBrowser ?? 'Failed to open browser'}: ${e.toString().replaceAll('Exception: ', '')}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.retry ?? 'Retry',
              textColor: Colors.white,
              onPressed: () => _openInBrowser(),
            ),
          ),
        );
      }
    }
  }

  /// Build URL for content state context (non-search)
  String _buildContentStateUrl(ContentLoaded contentState) {
    if (contentState.tag != null) {
      // Tag browsing page
      final tagName = Uri.encodeComponent(contentState.tag!.name);
      final pageParam = contentState.currentPage > 1
          ? '?page=${contentState.currentPage}'
          : '';
      return 'https://nhentai.net/tag/$tagName/$pageParam';
    } else if (contentState.timeframe != null) {
      // Popular content page
      final timeframe = contentState.timeframe!;
      final timeframeSuffix =
          timeframe.apiValue.isNotEmpty ? '-${timeframe.apiValue}' : '';
      final pageParam = contentState.currentPage > 1
          ? '?page=${contentState.currentPage}'
          : '';
      return 'https://nhentai.net/popular$timeframeSuffix/$pageParam';
    } else {
      // Main page with sort options
      return _buildMainPageUrl(contentState.currentPage, contentState.sortBy);
    }
  }

  /// Build main page URL with optional sort and page parameters
  String _buildMainPageUrl(int currentPage, [SortOption? sortBy]) {
    final sort = sortBy ?? SortOption.newest;
    final sortParam = sort == SortOption.newest ? '' : '?sort=${sort.apiValue}';
    final pageParam = currentPage > 1
        ? (sortParam.isEmpty ? '?page=$currentPage' : '&page=$currentPage')
        : '';
    return 'https://nhentai.net/$sortParam$pageParam';
  }

  /// Clean URL by removing trailing ? or & characters and empty parameters
  String _cleanUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Clean query parameters by removing empty values
      final cleanParams = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        // Only add non-empty values
        if (value.trim().isNotEmpty) {
          cleanParams[key] = value;
        }
      });

      // Rebuild the URL with clean parameters
      final cleanUri = uri.replace(
          queryParameters: cleanParams.isEmpty ? null : cleanParams);
      String cleanedUrl = cleanUri.toString();

      Logger().i('URL cleaned from: $url');
      Logger().i('URL cleaned to: $cleanedUrl');

      return cleanedUrl;
    } catch (e) {
      Logger().e('Error cleaning URL: $e');
      // Fallback: simple string cleaning
      String cleaned = url;
      if (cleaned.endsWith('?') || cleaned.endsWith('&')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      // Remove empty parameters (basic approach)
      cleaned =
          cleaned.replaceAllMapped(RegExp(r'[?&]([^=]+)=(?=[&]|$)'), (match) {
        // Remove empty parameters, but keep the separator if needed
        return cleaned.indexOf(match.group(0)!) == cleaned.indexOf('?')
            ? '?'
            : '';
      });
      return cleaned;
    }
  }

  /// Download all galleries in current page
  Future<void> _downloadAllGalleries() async {
    try {
      final contentState = _contentBloc.state;
      if (contentState is! ContentLoaded) {
        Logger().w('Cannot download all: no content loaded');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noContentToDownload),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (contentState.contents.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noGalleriesFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading while checking download status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.checkingDownloadStatus),
              ],
            ),
            duration:
                Duration(seconds: 10), // Longer duration for checking process
          ),
        );
      }

      // Filter out already downloaded galleries
      final galleriesNeedDownload = <Content>[];
      int alreadyDownloadedCount = 0;

      for (final content in contentState.contents) {
        try {
          final isDownloaded = await ContentDownloadCache.isDownloaded(
              content.id, mounted ? context : null);
          if (isDownloaded) {
            alreadyDownloadedCount++;
            Logger().i('Skipping already downloaded gallery: ${content.title}');
          } else {
            galleriesNeedDownload.add(content);
          }
        } catch (e) {
          Logger().e('Error checking download status for ${content.id}: $e');
          // If we can't check status, assume it needs download to be safe
          galleriesNeedDownload.add(content);
        }
      }

      // Hide the loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Check if there are any galleries to download
      if (galleriesNeedDownload.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        AppLocalizations.of(context)!.allGalleriesDownloaded),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Show confirmation dialog with accurate count
      if (mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.downloadNewGalleries),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.foundGalleries),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)!
                    .newGalleriesToDownload(galleriesNeedDownload.length)),
                Text(AppLocalizations.of(context)!
                    .alreadyDownloaded(alreadyDownloadedCount)),
                SizedBox(height: 12),
                if (galleriesNeedDownload.isNotEmpty)
                  Text(
                    AppLocalizations.of(context)!
                        .downloadInfo(galleriesNeedDownload.length),
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!
                    .downloadNew(galleriesNeedDownload.length)),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }

      if (!mounted) return;

      // Get download bloc and queue only new downloads
      final downloadBloc = context.read<DownloadBloc>();
      int queuedCount = 0;

      for (final content in galleriesNeedDownload) {
        try {
          downloadBloc.add(DownloadQueueEvent(content: content));
          queuedCount++;
          Logger().i('Queued download for: ${content.title}');
        } catch (e) {
          Logger().e('Failed to queue download for ${content.id}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.download, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!
                          .queuedDownloads(queuedCount)),
                      if (alreadyDownloadedCount > 0)
                        Text(
                          AppLocalizations.of(context)!
                              .countAlreadyDownloaded(alreadyDownloadedCount),
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: queuedCount > 0 ? Colors.green : Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.viewDownloads ??
                  'View Downloads',
              textColor: Colors.white,
              onPressed: () {
                AppRouter.goToDownloads(context);
              },
            ),
          ),
        );
      }

      Logger().i(
          'Bulk download completed: $queuedCount/${galleriesNeedDownload.length} queued successfully, $alreadyDownloadedCount skipped');
    } catch (e) {
      Logger().e('Error in bulk download: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.failedToDownload),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
