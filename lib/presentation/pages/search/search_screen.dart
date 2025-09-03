import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/localization/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/utils/responsive_grid_delegate.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/tag_resolver.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/cubits/settings/settings_cubit.dart';
import 'package:nhasixapp/presentation/widgets/content_card_widget.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

class SearchScreen extends StatefulWidget {
  final String? query;
  const SearchScreen({super.key, this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchBloc _searchBloc;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final TagResolver _tagResolver;

  // UI state
  bool _showAdvancedFilters = false;

  // Current search filter state (not triggering API calls)
  SearchFilter _currentFilter = const SearchFilter();

  // Removed complex filter search controllers and results
  // These are now handled by FilterDataScreen

  // Available options for single select
  List<Tag> _languages = [];
  List<Tag> _categories = [];

  Timer? _tagSearchTimer;
  Timer? _debounceTimer;
  final RegExp _contentIdPattern = RegExp(r'^\d{1,6}$'); // Match 1-6 digit numbers

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchBloc = getIt<SearchBloc>();
    _tagResolver = TagResolver();

    _initializeSearch();
    _loadTagOptions();
    _setupSearchListeners();
  }

  /// Initialize search with existing filter state
  void _initializeSearch() async {
    try {
      // Load saved search filter from local storage
      final savedFilterData =
          await getIt<LocalDataSource>().getLastSearchFilter();
      if (savedFilterData != null) {
        final savedFilter = SearchFilter.fromJson(savedFilterData);
        if (savedFilter.hasFilters) {
          _currentFilter = savedFilter;
          _searchController.text = savedFilter.query ?? '';
          Logger().i('SearchScreen: Loaded saved search filter');
        }
      }

      // Override with query parameter if provided
      if (widget.query != null) {
        _searchController.text = widget.query!;
        _currentFilter = _currentFilter.copyWith(query: widget.query);
      }

      _searchBloc.add(const SearchInitializeEvent());

      // Update the filter in bloc
      if (_currentFilter.hasFilters) {
        _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
      }
    } catch (e) {
      Logger().e('SearchScreen: Error loading saved filter: $e');
      _searchBloc.add(const SearchInitializeEvent());
    }
  }

  /// Load tag options for single select filters
  Future<void> _loadTagOptions() async {
    try {
      _languages = await _tagResolver.getTagsByType('language', limit: 50);
      _categories = await _tagResolver.getTagsByType('category', limit: 20);
      setState(() {});
    } catch (e) {
      Logger().e('Error loading tag options: $e');
    }
  }

  /// Setup search listeners for text inputs with debounce (NO direct navigation)
  void _setupSearchListeners() {
    // Enhanced main search query listener with debounce only
    _searchController.addListener(() {
      // Cancel previous debounce timer
      _debounceTimer?.cancel();
      
      // Start new debounce timer - ONLY for regular search, no direct navigation
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        final query = _searchController.text.trim();
        
        // Regular search behavior with debounce (REMOVED numeric direct navigation)
        _currentFilter = _currentFilter.copyWith(
          query: query.isEmpty ? null : query,
        );
        _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
      });
    });

    // Removed complex tag search listeners - now handled by FilterDataScreen
  }

  /// Direct navigation for numeric content IDs (nhentai-like behavior)
  void _navigateToContentById(String contentId) async {
    try {
      // Clear search field for better UX
      _searchController.clear();
      
      // Navigate directly to detail screen
      if (mounted) {
        AppRouter.goToContentDetail(context, contentId);
      }
    } catch (e) {
      // Handle error - show "Content not found" dialog
      _showContentNotFoundDialog(contentId);
    }
  }

  /// Show dialog for content not found
  void _showContentNotFoundDialog(String contentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Content Not Found',
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Content with ID "$contentId" was not found.',
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed complex tag search methods - now handled by FilterDataScreen

  @override
  void dispose() {
    _tagSearchTimer?.cancel();
    _debounceTimer?.cancel(); // Clean up debounce timer
    _searchController.dispose();
    _searchFocusNode.dispose();
    // Removed complex filter controllers disposal - now handled by FilterDataScreen
    _searchBloc.close();
    super.dispose();
  }

  /// Build navigation buttons for complex filter types
  Widget _buildFilterNavigationButtons() {
    final filterTypes = [
      {
        'type': 'tag',
        'label': 'Tags',
        'icon': Icons.label,
        'filters': _currentFilter.tags
      },
      {
        'type': 'artist',
        'label': 'Artists',
        'icon': Icons.person,
        'filters': _currentFilter.artists
      },
      {
        'type': 'character',
        'label': 'Characters',
        'icon': Icons.face,
        'filters': _currentFilter.characters
      },
      {
        'type': 'parody',
        'label': 'Parodies',
        'icon': Icons.movie,
        'filters': _currentFilter.parodies
      },
      {
        'type': 'group',
        'label': 'Groups',
        'icon': Icons.group,
        'filters': _currentFilter.groups
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Categories',
          style: TextStyleConst.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
          ),
          itemCount: filterTypes.length,
          itemBuilder: (context, index) {
            final filterType = filterTypes[index];
            final type = filterType['type'] as String;
            final label = filterType['label'] as String;
            final icon = filterType['icon'] as IconData;
            final filters = filterType['filters'] as List<FilterItem>;
            final hasFilters = filters.isNotEmpty;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToFilterData(type, filters),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasFilters
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasFilters
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: hasFilters
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: hasFilters
                              ? TextStyleConst.labelMedium.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                )
                              : TextStyleConst.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                        ),
                      ),
                      if (hasFilters) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            filters.length.toString(),
                            style: TextStyleConst.labelSmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Navigate to FilterDataScreen for advanced filter selection
  Future<void> _navigateToFilterData(
      String filterType, List<FilterItem> selectedFilters) async {
    try {
      final result = await AppRouter.goToFilterData(
        context,
        filterType: filterType,
        selectedFilters: selectedFilters,
        hideOtherTabs: true, // Hide other tabs when navigating from Filter Categories
      );

      // Update filter if result is not null (including empty results for clearing filters)
      if (result != null) {
        // Update the current filter with the returned filters
        switch (filterType.toLowerCase()) {
          case 'tag':
            _currentFilter = _currentFilter.copyWith(tags: result);
            break;
          case 'artist':
            _currentFilter = _currentFilter.copyWith(artists: result);
            break;
          case 'character':
            _currentFilter = _currentFilter.copyWith(characters: result);
            break;
          case 'parody':
            _currentFilter = _currentFilter.copyWith(parodies: result);
            break;
          case 'group':
            _currentFilter = _currentFilter.copyWith(groups: result);
            break;
        }

        // Update the search bloc with the new filter
        _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));

        // Update UI
        setState(() {});

        Logger().i(
            'SearchScreen: Updated $filterType filters with ${result.length} items');
      }
    } catch (e) {
      Logger().e('SearchScreen: Error navigating to filter data: $e');

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: AppScaffoldWithOffline(
        title: 'Search',
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchHeader(),
            if (_showAdvancedFilters) _buildAdvancedFilters(),
            Expanded(child: _buildSearchResults()),
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Advanced Search',
        style: TextStyleConst.headingMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showAdvancedFilters ? Icons.filter_list : Icons.filter_list_off,
            color: _showAdvancedFilters
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() {
              _showAdvancedFilters = !_showAdvancedFilters;
            });
          },
        ),
        IconButton(
          tooltip: 'Clear all filters',
          icon: Icon(Icons.clear_all, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: _clearAllFilters,
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Main search query input
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Enter search query (e.g. "big breasts english")',
              hintStyle: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      onPressed: () {
                        // Enhanced clear method with proper timer cleanup
                        _debounceTimer?.cancel();
                        _searchController.clear();
                        _currentFilter = _currentFilter.copyWith(query: null);
                        _searchBloc
                            .add(SearchUpdateFilterEvent(_currentFilter));
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 400, // Limit height to prevent overflow
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Advanced Filters',
                style: TextStyleConst.headingSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Navigation buttons for complex filters
              _buildFilterNavigationButtons(),
              const SizedBox(height: 16),

              // Single select filters (kept in SearchScreen)
              _buildSingleSelectFilter(
                  'Language', _languages, _currentFilter.language, (value) {
                _currentFilter = _currentFilter.copyWith(language: value);
                Logger().i(_currentFilter.language);
                _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
                setState(() {});
              }),
              const SizedBox(height: 16),
              _buildSingleSelectFilter(
                  'Category', _categories, _currentFilter.category, (value) {
                _currentFilter = _currentFilter.copyWith(category: value);
                _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
                setState(() {});
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _buildMultipleSelectFilter method - complex filters now handled by FilterDataScreen

  Widget _buildSingleSelectFilter(
    String title,
    List<Tag> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyleConst.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Clear selection chip
            if (selectedValue != null)
              FilterChip(
                label: Text(AppLocalizations.of(context)!.clear),
                selected: false,
                onSelected: (selected) => onChanged(null),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                labelStyle: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            // Option chips
            ...options.map((option) {
              final isSelected = selectedValue == option.name;
              return FilterChip(
                label: Text(option.name.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  onChanged(selected ? option.name : null);
                },
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                selectedColor:
                    _getColorForTagType(title, context).withValues(alpha: 0.2),
                labelStyle: TextStyleConst.bodySmall.copyWith(
                  color: isSelected
                      ? _getColorForTagType(title, context)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: isSelected
                      ? _getColorForTagType(title, context)
                      : Theme.of(context).colorScheme.outline,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final hasFilters = _currentFilter.hasFilters;
        final isLoading = state is SearchLoading;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search button with enhanced styling
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: hasFilters && !isLoading ? _onSearchButtonPressed : null,
                  icon: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: hasFilters
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.search,
                          size: 24,
                          color: hasFilters
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  label: Text(
                    isLoading ? 'Searching...' : 'Apply Search',
                    style: TextStyleConst.labelLarge.copyWith(
                      color: hasFilters
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFilters
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainer,
                    foregroundColor: hasFilters
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    elevation: hasFilters ? 4 : 0,
                    shadowColor: hasFilters
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: hasFilters
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: hasFilters ? 0 : 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Helper text
              if (!hasFilters) ...[
                const SizedBox(height: 8),
                Text(
                  'Add filters above to enable search',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchInitial || state is SearchHistory) {
          return _buildSearchHistory(state);
        } else if (state is SearchFilterUpdated) {
          return _buildFilterUpdatedState(state);
        } else if (state is SearchLoading) {
          return _buildLoadingState();
        } else if (state is SearchLoaded) {
          return _buildSearchResultsList(state);
        } else if (state is SearchEmpty) {
          return _buildEmptyState(state);
        } else if (state is SearchError) {
          return _buildErrorState(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchHistory(SearchState state) {
    final history = state is SearchHistory ? state.history : <String>[];
    final popular = state is SearchHistory ? state.popularSearches : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (popular.isNotEmpty) ...[
            Text(
              'Popular Searches',
              style: TextStyleConst.headingSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popular.map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    _currentFilter = _currentFilter.copyWith(query: query);
                    _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  labelStyle: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyleConst.headingSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchBloc.add(const SearchClearHistoryEvent());
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...history.take(10).map((query) {
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                title: Text(
                  query,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchBloc.add(SearchRemoveFromHistoryEvent(query));
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _currentFilter = _currentFilter.copyWith(query: query);
                  _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
          if (history.isEmpty && popular.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start searching',
                    style: TextStyleConst.headingSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter keywords, tags, or use advanced filters to find content',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterUpdatedState(SearchFilterUpdated state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Filters Ready',
              style: TextStyleConst.headingSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press the Search button to find content with your current filters',
              style: TextStyleConst.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.hasFilters) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  state.filterSummary,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(SearchLoaded state) {
    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.totalCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} results',
                style: TextStyleConst.headingLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate back to MainScreen with search results
                  context.pop();
                },
                child: Text(
                  'View in Main',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results grid
        Expanded(
          child: _buildSearchResultsGrid(state),
        ),

        // Pagination
        if (state.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: PaginationWidget(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              hasNext: state.hasNext,
              hasPrevious: state.hasPrevious,
              onNextPage: () => _goToPage(state.currentPage + 1),
              onPreviousPage: () => _goToPage(state.currentPage - 1),
              onGoToPage: _goToPage,
              showProgressBar: false,
              showPercentage: false,
              showPageInput: true,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(SearchEmpty state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyleConst.headingSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyleConst.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: Text(AppLocalizations.of(context)!.clearFilters),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SearchError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: TextStyleConst.headingSmall.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.userMessage,
              style: TextStyleConst.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchBloc.add(const SearchRetryEvent());
                },
                icon: const Icon(Icons.refresh),
                label: Text(state.retryButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsGrid(SearchLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _searchBloc.add(const SearchRefreshEvent());
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: ResponsiveGridDelegate.createStandardGridDelegate(
              context,
              context.read<SettingsCubit>(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final content = state.results[index];
              return ContentCard(
                content: content,
                onTap: () {
                  AppRouter.goToContentDetail(context, content.id);
            },
            showUploadDate: false,
          );
        },
          );
        },
      ),
    );
  }

  // Removed helper methods for complex filter management - now handled by FilterDataScreen

  /// Handle search button press - check for numeric input first
  void _onSearchButtonPressed() {
    final query = _searchController.text.trim();
    
    // Check if input is numeric content ID (direct navigation without debounce)
    if (_contentIdPattern.hasMatch(query)) {
      _navigateToContentById(query);
      return;
    }
    
    // Regular search behavior for non-numeric input
    _performSearch();
  }

  void _performSearch() async {
    try {
      // Save search filter to local storage for persistence
      await getIt<LocalDataSource>().saveSearchFilter(_currentFilter.toJson());
      Logger().i('SearchScreen: Saved search filter to local storage');

      // Add to search history if there's a query
      if (_currentFilter.query != null && _currentFilter.query!.isNotEmpty) {
        await getIt<LocalDataSource>().addSearchHistory(_currentFilter.query!);
      }

      // Navigate back to MainScreen with result flag
      if (mounted) {
        context.pop(true); // Pass true to indicate search was performed
      }
    } catch (e) {
      Logger().e('SearchScreen: Error saving search filter: $e');
      // Still try to navigate back even if saving fails
      if (mounted) {
        context.pop(true);
      }
    }
  }

  void _goToPage(int page) {
    final newFilter = _currentFilter.copyWith(page: page);
    _searchBloc.add(SearchWithFiltersEvent(newFilter));
  }

  void _clearAllFilters() {
    // Cancel any pending debounce
    _debounceTimer?.cancel();
    
    _searchController.clear();
    // Removed complex filter controllers clearing - now handled by FilterDataScreen

    _currentFilter = const SearchFilter();
    _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
    _searchBloc.add(const SearchClearEvent());

    setState(() {
      // Removed complex filter results clearing - now handled by FilterDataScreen
    });
  }

  Color _getColorForTagType(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'language':
        return Theme.of(context).colorScheme.secondary;
      case 'category':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
