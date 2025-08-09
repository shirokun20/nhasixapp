import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/datasources/remote/tag_resolver.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/widgets/content_card_widget.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';

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

  /// Setup search listeners for text inputs (no API calls)
  void _setupSearchListeners() {
    // Main search query listener (updates filter state only)
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      _currentFilter = _currentFilter.copyWith(
        query: query.isEmpty ? null : query,
      );
      _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
    });

    // Removed complex tag search listeners - now handled by FilterDataScreen
  }

  // Removed complex tag search methods - now handled by FilterDataScreen

  @override
  void dispose() {
    _tagSearchTimer?.cancel();
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
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.darkTextSecondary,
            fontWeight: FontWeight.w500,
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
                        ? ColorsConst.accentBlue.withValues(alpha: 0.1)
                        : ColorsConst.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasFilters
                          ? ColorsConst.accentBlue
                          : ColorsConst.borderDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: hasFilters
                            ? ColorsConst.accentBlue
                            : ColorsConst.darkTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyleConst.bodySmall.copyWith(
                            color: hasFilters
                                ? ColorsConst.accentBlue
                                : ColorsConst.darkTextPrimary,
                            fontWeight: hasFilters
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasFilters) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorsConst.accentBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            filters.length.toString(),
                            style: TextStyleConst.caption.copyWith(
                              color: ColorsConst.darkBackground,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: ColorsConst.darkTextTertiary,
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
      );

      if (result != null && result.isNotEmpty) {
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
            content: Text('Error opening filter selection: $e'),
            backgroundColor: ColorsConst.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        backgroundColor: ColorsConst.darkBackground,
        resizeToAvoidBottomInset: false,
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
      backgroundColor: ColorsConst.darkSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: ColorsConst.darkTextPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Advanced Search',
        style: TextStyleConst.headingMedium.copyWith(
          color: ColorsConst.darkTextPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showAdvancedFilters ? Icons.filter_list : Icons.filter_list_off,
            color: _showAdvancedFilters
                ? ColorsConst.accentBlue
                : ColorsConst.darkTextSecondary,
          ),
          onPressed: () {
            setState(() {
              _showAdvancedFilters = !_showAdvancedFilters;
            });
          },
        ),
        IconButton(
          tooltip: 'Clear all filters',
          icon:
              const Icon(Icons.clear_all, color: ColorsConst.darkTextSecondary),
          onPressed: _clearAllFilters,
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ColorsConst.darkSurface,
        border: Border(
          bottom: BorderSide(
            color: ColorsConst.borderDefault,
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
              color: ColorsConst.darkTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter search query (e.g. "big breasts english")',
              hintStyle: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextTertiary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: ColorsConst.darkTextSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: ColorsConst.darkTextSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _currentFilter = _currentFilter.copyWith(query: null);
                        _searchBloc
                            .add(SearchUpdateFilterEvent(_currentFilter));
                      },
                    )
                  : null,
              filled: true,
              fillColor: ColorsConst.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColorsConst.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColorsConst.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ColorsConst.accentBlue, width: 2),
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
      decoration: const BoxDecoration(
        color: ColorsConst.darkCard,
        border: Border(
          bottom: BorderSide(
            color: ColorsConst.borderDefault,
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
                  color: ColorsConst.darkTextPrimary,
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
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
            fontWeight: FontWeight.w500,
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
                label: const Text('Clear'),
                selected: false,
                onSelected: (selected) => onChanged(null),
                backgroundColor: ColorsConst.darkSurface,
                labelStyle: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.darkTextSecondary,
                ),
                side: const BorderSide(color: ColorsConst.borderDefault),
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
                backgroundColor: ColorsConst.darkSurface,
                selectedColor:
                    _getColorForTagType(title).withValues(alpha: 0.2),
                labelStyle: TextStyleConst.bodySmall.copyWith(
                  color: isSelected
                      ? _getColorForTagType(title)
                      : ColorsConst.darkTextSecondary,
                ),
                side: BorderSide(
                  color: isSelected
                      ? _getColorForTagType(title)
                      : ColorsConst.borderDefault,
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
            color: ColorsConst.darkSurface,
            border: const Border(
              bottom: BorderSide(
                color: ColorsConst.borderDefault,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: ColorsConst.darkBackground.withValues(alpha: 0.3),
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
                  onPressed: hasFilters && !isLoading ? _performSearch : null,
                  icon: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: hasFilters
                                ? ColorsConst.darkBackground
                                : ColorsConst.darkTextTertiary,
                          ),
                        )
                      : Icon(
                          Icons.search,
                          size: 24,
                          color: hasFilters
                              ? ColorsConst.darkBackground
                              : ColorsConst.darkTextTertiary,
                        ),
                  label: Text(
                    isLoading ? 'Searching...' : 'Apply Search',
                    style: TextStyleConst.buttonLarge.copyWith(
                      color: hasFilters
                          ? ColorsConst.darkBackground
                          : ColorsConst.darkTextTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFilters
                        ? ColorsConst.accentBlue
                        : ColorsConst.darkCard,
                    foregroundColor: hasFilters
                        ? ColorsConst.darkBackground
                        : ColorsConst.darkTextTertiary,
                    elevation: hasFilters ? 4 : 0,
                    shadowColor: hasFilters
                        ? ColorsConst.accentBlue.withValues(alpha: 0.3)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: hasFilters
                            ? ColorsConst.accentBlue
                            : ColorsConst.borderDefault,
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
                    color: ColorsConst.darkTextTertiary,
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
                color: ColorsConst.darkTextPrimary,
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
                  backgroundColor: ColorsConst.darkCard,
                  labelStyle: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                  side: const BorderSide(color: ColorsConst.borderDefault),
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
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchBloc.add(const SearchClearHistoryEvent());
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: ColorsConst.accentRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...history.take(10).map((query) {
              return ListTile(
                leading: const Icon(
                  Icons.history,
                  color: ColorsConst.darkTextSecondary,
                  size: 20,
                ),
                title: Text(
                  query,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: ColorsConst.darkTextSecondary,
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
                    color: ColorsConst.darkTextTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start searching',
                    style: TextStyleConst.headingSmall.copyWith(
                      color: ColorsConst.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter keywords, tags, or use advanced filters to find content',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: ColorsConst.darkTextTertiary,
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
              color: ColorsConst.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Filters Ready',
              style: TextStyleConst.headingSmall.copyWith(
                color: ColorsConst.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Press the Search button to find content with your current filters',
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.hasFilters) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsConst.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorsConst.borderDefault),
                ),
                child: Text(
                  state.filterSummary,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorsConst.accentBlue,
          ),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: ColorsConst.darkTextSecondary,
              fontSize: 16,
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
                color: ColorsConst.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.totalCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} results',
                style: TextStyleConst.headingMedium.copyWith(
                  color: ColorsConst.darkTextPrimary,
                  fontWeight: FontWeight.w700,
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
                    color: ColorsConst.accentBlue,
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
              color: ColorsConst.darkTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyleConst.headingSmall.copyWith(
                color: ColorsConst.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsConst.accentBlue,
                side: const BorderSide(color: ColorsConst.accentBlue),
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
              color: ColorsConst.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: TextStyleConst.headingSmall.copyWith(
                color: ColorsConst.accentRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.userMessage,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextTertiary,
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
                  backgroundColor: ColorsConst.accentBlue,
                  foregroundColor: ColorsConst.darkBackground,
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
      color: ColorsConst.accentBlue,
      backgroundColor: ColorsConst.darkSurface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
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
      ),
    );
  }

  // Removed helper methods for complex filter management - now handled by FilterDataScreen

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
    _searchController.clear();
    // Removed complex filter controllers clearing - now handled by FilterDataScreen

    _currentFilter = const SearchFilter();
    _searchBloc.add(SearchUpdateFilterEvent(_currentFilter));
    _searchBloc.add(const SearchClearEvent());

    setState(() {
      // Removed complex filter results clearing - now handled by FilterDataScreen
    });
  }

  Color _getColorForTagType(String type) {
    switch (type.toLowerCase()) {
      case 'language':
        return ColorsConst.tagLanguage;
      case 'category':
        return ColorsConst.tagCategory;
      default:
        return ColorsConst.accentBlue;
    }
  }
}
