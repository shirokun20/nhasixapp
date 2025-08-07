import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/data/datasources/remote/tag_resolver.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';
import 'package:nhasixapp/presentation/widgets/content_card_widget.dart';
import 'package:nhasixapp/presentation/widgets/pagination_widget.dart';
import 'package:nhasixapp/presentation/widgets/search_filter_widget.dart';

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

  bool _showAdvancedFilters = false;
  final Map<String, bool> _selectedTags = {};
  final Map<String, bool> _selectedArtists = {};
  List<Tag> _languages = [];
  List<Tag> _categories = [];
  String? _selectedLanguage;
  String? _selectedCategory;
  SortOption _selectedSort = SortOption.newest;

  @override
  void initState() {
    super.initState();
    _getLocalTags();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchBloc = getIt<SearchBloc>();
    _getWidgetSearch();
  }

  _getLocalTags() async {
    _languages = await TagResolver().getTagsByType('languages').then(
          (value) => value,
        );
    _categories = await TagResolver().getTagsByType('categories').then(
          (value) => value,
        );
  }

  _getWidgetSearch() {
    if (widget.query != null) {
      _searchController.text = "${widget.query}";
      _searchBloc.add(SearchQueryEvent(widget.query!));
    } else {
      _searchBloc.add(const SearchInitializeEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchBloc.close();
    super.dispose();
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
            if (widget.query == null) _buildSearchHeader(),
            if (_showAdvancedFilters && widget.query == null)
              _buildAdvancedFilters(),
            Expanded(child: _buildSearchResults()),
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
        widget.query != null
            ? widget.query!.toLowerCase().capitalize()
            : 'Search',
        style: TextStyleConst.headingMedium.copyWith(
          color: ColorsConst.darkTextPrimary,
        ),
      ),
      actions: widget.query == null
          ? [
              IconButton(
                icon: Icon(
                  _showAdvancedFilters
                      ? Icons.filter_list
                      : Icons.filter_list_off,
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
            ]
          : [],
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
          // Search input field
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyleConst.bodyMedium.copyWith(
              color: ColorsConst.darkTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. idolmaster exhibitionism uploaded:7d',
              hintStyle: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextTertiary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: ColorsConst.darkTextSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: ColorsConst.darkTextSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchBloc.add(const SearchClearEvent());
                      },
                    )
                  : null,
              filled: true,
              fillColor: ColorsConst.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorsConst.borderDefault,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorsConst.borderDefault,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorsConst.accentBlue,
                  width: 2,
                ),
              ),
            ),
            onChanged: (query) {
              setState(() {}); // Update UI for clear button
              if (query.trim().isNotEmpty) {
                _searchBloc.add(SearchQueryEvent(query.trim()));
              } else {
                _searchBloc.add(const SearchClearEvent());
              }
            },
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                _searchBloc.add(SearchQueryEvent(query.trim()));
              }
            },
          ),

          // Sort options
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyleConst.bodySmall.copyWith(
                  color: ColorsConst.darkTextSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SortOption.newest,
                      SortOption.popularToday,
                      SortOption.popularWeek,
                      SortOption.popular,
                    ].map((sort) {
                      final isSelected = _selectedSort == sort;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getSortLabel(sort)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSort = sort;
                            });
                            _searchBloc.add(SearchUpdateSortEvent(sort));
                          },
                          backgroundColor: ColorsConst.darkCard,
                          selectedColor:
                              ColorsConst.accentBlue.withValues(alpha: 0.2),
                          labelStyle: TextStyleConst.bodySmall.copyWith(
                            color: isSelected
                                ? ColorsConst.accentBlue
                                : ColorsConst.darkTextSecondary,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? ColorsConst.accentBlue
                                : ColorsConst.borderDefault,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ColorsConst.darkCard,
        border: Border(
          bottom: BorderSide(
            color: ColorsConst.borderDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Filters',
            style: TextStyleConst.headingSmall.copyWith(
              color: ColorsConst.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Language filter
          _buildFilterSection(
            title: 'Language',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) {
                final isSelected = _selectedLanguage == lang.name;
                return FilterChip(
                  label: Text(lang.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLanguage = selected ? lang.name : null;
                    });
                    _applyFilters();
                  },
                  backgroundColor: ColorsConst.darkSurface,
                  selectedColor: ColorsConst.tagLanguage.withValues(alpha: 0.2),
                  labelStyle: TextStyleConst.bodySmall.copyWith(
                    color: isSelected
                        ? ColorsConst.tagLanguage
                        : ColorsConst.darkTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorsConst.tagLanguage
                        : ColorsConst.borderDefault,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Category filter
          _buildFilterSection(
            title: 'Category',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category.name;
                return FilterChip(
                  label: Text(category.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category.name : null;
                    });
                    _applyFilters();
                  },
                  backgroundColor: ColorsConst.darkSurface,
                  selectedColor: ColorsConst.tagCategory.withValues(alpha: 0.2),
                  labelStyle: TextStyleConst.bodySmall.copyWith(
                    color: isSelected
                        ? ColorsConst.tagCategory
                        : ColorsConst.darkTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorsConst.tagCategory
                        : ColorsConst.borderDefault,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Clear filters button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsConst.darkTextSecondary,
                side: const BorderSide(color: ColorsConst.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
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
        child,
      ],
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchInitial || state is SearchHistory) {
          return _buildSearchHistory(state);
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
                    _searchBloc.add(SearchQueryEvent(query));
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
                  _searchBloc.add(SearchQueryEvent(query));
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
                    'Enter keywords, tags, or artist names to find content',
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
        // Results header (nhentai style)
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Results count with search icon (nhentai style)
              Row(
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
                ],
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: _buildSearchResultsGrid(state),
        ),

        // Pagination (nhentai style)
        if (state.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: PaginationWidget(
              currentPage: state.currentPage,
              totalPages: state.totalPages,
              hasNext: state.hasNext,
              hasPrevious: state.hasPrevious,
              onNextPage: () {
                final nextPage = state.currentPage + 1;
                final filter = SearchFilter(
                  query: _searchController.text.trim().isNotEmpty
                      ? _searchController.text.trim()
                      : null,
                  language: _selectedLanguage,
                  category: _selectedCategory,
                  sortBy: _selectedSort,
                  page: nextPage,
                );
                _searchBloc.add(SearchWithFiltersEvent(filter));
              },
              onPreviousPage: () {
                final filter = SearchFilter(
                  query: _searchController.text.trim().isNotEmpty
                      ? _searchController.text.trim()
                      : null,
                  language: _selectedLanguage,
                  category: _selectedCategory,
                  sortBy: _selectedSort,
                  page: state.currentPage - 1,
                );
                _searchBloc.add(SearchWithFiltersEvent(filter));
              },
              onGoToPage: (page) {
                final filter = SearchFilter(
                  query: _searchController.text.trim().isNotEmpty
                      ? _searchController.text.trim()
                      : null,
                  language: _selectedLanguage,
                  category: _selectedCategory,
                  sortBy: _selectedSort,
                  page: page,
                );
                _searchBloc.add(SearchWithFiltersEvent(filter));
              },
              showProgressBar: false, // Disable for cleaner nhentai style
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
              onPressed: _clearFilters,
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
              state.message,
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
                label: const Text('Retry'),
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

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.newest:
        return 'Recent';
      case SortOption.popular:
        return 'Popular All Time';
      case SortOption.popularWeek:
        return 'Popular Week';
      case SortOption.popularToday:
        return 'Popular Today';
      case SortOption.random:
        return 'Random';
    }
  }

  void _applyFilters() {
    final filter = SearchFilter(
      query: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
      language: _selectedLanguage,
      category: _selectedCategory,
      sortBy: _selectedSort,
      page: 1,
    );

    Logger().i('Applying filters: ${filter.language}');

    // _searchBloc.add(SearchWithFiltersEvent(filter));
  }

  Widget _buildSearchResultsGrid(SearchLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _searchBloc.add(SearchRefreshEvent());
      },
      color: ColorsConst.accentBlue,
      backgroundColor: ColorsConst.darkSurface,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7, // Adjust for content card ratio
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
            showUploadDate: false, // Clean look for search results
          );
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedArtists.clear();
      _selectedLanguage = null;
      _selectedCategory = null;
      _selectedSort = SortOption.newest;
    });

    if (_searchController.text.trim().isNotEmpty) {
      _searchBloc.add(SearchQueryEvent(_searchController.text.trim()));
    } else {
      _searchBloc.add(const SearchClearEvent());
    }
  }
}
