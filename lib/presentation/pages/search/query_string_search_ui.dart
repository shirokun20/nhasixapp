import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart' show Tag;
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/core/utils/tag_data_manager.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

/// Nhentai-style search UI (Query String mode)
/// Follows mockup: search-screen-revised.html
class QueryStringSearchUI extends StatefulWidget {
  final SearchConfig config;
  final String? initialQuery;
  final String sourceId;

  const QueryStringSearchUI({
    super.key,
    required this.config,
    required this.sourceId,
    this.initialQuery,
  });

  @override
  State<QueryStringSearchUI> createState() => _QueryStringSearchUIState();
}

class _QueryStringSearchUIState extends State<QueryStringSearchUI> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Logger _logger = Logger();

  // UI State
  bool _showAdvancedFilters = false;

  // Selected filters
  String _selectedLanguage = '';
  String _selectedCategory = '';
  String _selectedSort = '';

  // Multi-select filter selections (tag type -> list of selected items)
  final Map<String, List<FilterItem>> _multiSelectFilters = {};

  // Cached tags by type
  final Map<String, List<Tag>> _tagsByType = {};

  // Filter support from config
  FilterSupportConfig? get _filterSupport => widget.config.filterSupport;
  List<String> get _singleSelectFilters => _filterSupport?.singleSelect ?? [];
  List<String> get _multiSelectFilters2 => _filterSupport?.multiSelect ?? [];
  bool get _supportsExclude => _filterSupport?.supportsExclude ?? false;

  // Sort options from config
  List<SortOptionConfig> get _sortOptions =>
      widget.config.sortingConfig?.options ?? [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    
    // Initialize SearchBloc with current source
    context.read<SearchBloc>().add(SearchInitializeEvent(sourceId: widget.sourceId));

    // Set default sort from config
    final defaultSort = _sortOptions.where((o) => o.isDefault).firstOrNull;
    _selectedSort = defaultSort?.apiValue ?? '';

    // Initialize multi-select filters
    for (var type in _multiSelectFilters2) {
      _multiSelectFilters[type] = [];
    }

    _loadTags();
    _restoreSavedFilter();
  }

  Future<void> _loadTags() async {
    try {
      // Only load tags for dropdowns (singleSelect filters like language, category)
      // MultiSelect filters use FilterDataScreen which has its own pagination

      if (_singleSelectFilters.contains('language')) {
        final langTags = await getIt<TagDataManager>().getTagsByType(
          'language',
          source: widget.sourceId,
        );
        _tagsByType['language'] = langTags;
      }

      if (_singleSelectFilters.contains('category')) {
        final catTags = await getIt<TagDataManager>().getTagsByType(
          'category',
          source: widget.sourceId,
        );
        _tagsByType['category'] = catTags;
      }

      if (mounted) setState(() {});
    } catch (e) {
      _logger.e('Failed to load tags: $e');
    }
  }

  Future<void> _restoreSavedFilter() async {
    try {
      final savedFilterJson =
          await getIt<LocalDataSource>().getLastSearchFilter(widget.sourceId);
      if (savedFilterJson == null) return;

      final savedFilter = SearchFilter.fromJson(savedFilterJson);

      // Restore query (skip raw: format)
      if (savedFilter.query != null &&
          savedFilter.query!.isNotEmpty &&
          !savedFilter.query!.startsWith('raw:')) {
        _searchController.text = savedFilter.query!;
      }

      // Restore sort
      if (savedFilter.sortBy.apiValue.isNotEmpty) {
        setState(() => _selectedSort = savedFilter.sortBy.apiValue);
      }

      // Restore language from filter
      if (savedFilter.language != null) {
        setState(() => _selectedLanguage = savedFilter.language!);
      }

      // Restore category from filter
      if (savedFilter.category != null) {
        setState(() => _selectedCategory = savedFilter.category!);
      }

      // Restore multi-select tags
      for (var tag in savedFilter.tags) {
        // Determine type from tag (we may need better mapping)
        _multiSelectFilters['tag'] ??= [];
        _multiSelectFilters['tag']!.add(tag);
      }

      for (var artist in savedFilter.artists) {
        _multiSelectFilters['artist'] ??= [];
        _multiSelectFilters['artist']!.add(artist);
      }

      for (var character in savedFilter.characters) {
        _multiSelectFilters['character'] ??= [];
        _multiSelectFilters['character']!.add(character);
      }

      for (var parody in savedFilter.parodies) {
        _multiSelectFilters['parody'] ??= [];
        _multiSelectFilters['parody']!.add(parody);
      }

      for (var group in savedFilter.groups) {
        _multiSelectFilters['group'] ??= [];
        _multiSelectFilters['group']!.add(group);
      }

      if (mounted) setState(() {});
    } catch (e) {
      _logger.w('Failed to restore saved filter: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  SortOption _mapSortToSortOption(String apiValue) {
    switch (apiValue) {
      case 'popular':
        return SortOption.popular;
      case 'popular-today':
        return SortOption.popularToday;
      case 'popular-week':
        return SortOption.popularWeek;
      default:
        return SortOption.newest;
    }
  }

  SearchFilter _buildSearchFilter() {
    final textQuery = _searchController.text.trim();

    return SearchFilter(
      // Set to null if empty - allows filter-only searches (language, tags, etc)
      query: textQuery.isNotEmpty ? textQuery : null,
      language: _selectedLanguage.isNotEmpty ? _selectedLanguage : null,
      category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      sortBy: _mapSortToSortOption(_selectedSort),
      popular: _selectedSort.contains('popular'),
      tags: _multiSelectFilters['tag'] ?? [],
      artists: _multiSelectFilters['artist'] ?? [],
      characters: _multiSelectFilters['character'] ?? [],
      parodies: _multiSelectFilters['parody'] ?? [],
      groups: _multiSelectFilters['group'] ?? [],
    );
  }

  Future<void> _onSearchSubmitted() async {
    final textQuery = _searchController.text.trim();

    // Check if this is a direct navigation to Nhentai gallery ID
    if (_isNhentaiDirectNavigation(textQuery)) {
      await _navigateToGalleryDetail(textQuery);
      return;
    }

    // Normal search flow
    final filter = _buildSearchFilter();

    try {
      await getIt<LocalDataSource>().saveSearchFilter(widget.sourceId, filter.toJson());

      if (mounted) {
        context.read<SearchBloc>().add(SearchUpdateFilterEvent(filter));
        context.read<SearchBloc>().add(const SearchSubmittedEvent());
        context.pop(true);
      }
    } catch (e) {
      _logger.e('Failed to save search filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply search: $e')),
        );
      }
    }
  }

  /// Check if query should trigger direct navigation to Nhentai gallery detail
  /// Returns true only if:
  /// 1. Source is Nhentai
  /// 2. Query contains only digits (no spaces, no special characters)
  bool _isNhentaiDirectNavigation(String query) {
    // Only for Nhentai source
    if (widget.sourceId != 'nhentai') return false;

    // Empty query should use normal search
    if (query.isEmpty) return false;

    // Check if query is purely numeric
    final numericPattern = RegExp(r'^\d+$');
    return numericPattern.hasMatch(query);
  }

  /// Navigate directly to gallery detail page for numeric Nhentai ID
  /// Handles return value from detail screen (SearchFilter if user applies filter)
  Future<void> _navigateToGalleryDetail(String galleryId) async {
    // Normalize: remove leading zeros (00123 -> 123)
    final normalizedId = int.tryParse(galleryId)?.toString() ?? galleryId;

    _logger.i('Direct navigation to Nhentai gallery: $normalizedId');

    if (!mounted) return;

    // Navigate to detail using existing router helper
    // This may return a SearchFilter if user applies filter from detail screen
    final returnedFilter = await AppRouter.goToContentDetail(
      context,
      normalizedId,
      sourceId: 'nhentai',
    );

    // If detail screen returned a filter, apply it to search
    if (returnedFilter != null && mounted) {
      try {
        await getIt<LocalDataSource>().saveSearchFilter(widget.sourceId, returnedFilter.toJson());
        if (!mounted) return;
        context.read<SearchBloc>().add(SearchUpdateFilterEvent(returnedFilter));
        context.read<SearchBloc>().add(const SearchSubmittedEvent());
        context.pop(true);
      } catch (e) {
        _logger.e('Failed to apply filter from detail screen: $e');
      }
    } else if (mounted) {
      // No filter returned, just close search screen
      context.pop(false);
    }
  }

  void _openFilterPicker(String filterType) async {
    final currentSelection = _multiSelectFilters[filterType] ?? [];

    // Navigate to FilterDataScreen which has proper pagination for large tag lists
    final result = await AppRouter.goToFilterData(
      context,
      filterType: filterType,
      selectedFilters: currentSelection,
      hideOtherTabs: true, // Only show this filter type
      supportsExclude: _supportsExclude,
    );

    if (result != null) {
      setState(() {
        _multiSelectFilters[filterType] = result;
      });
    }
  }

  String _getFilterTitle(String type) {
    switch (type) {
      case 'tag':
        return 'Tags';
      case 'artist':
        return 'Artists';
      case 'character':
        return 'Characters';
      case 'parody':
        return 'Parodies';
      case 'group':
        return 'Groups';
      default:
        return type;
    }
  }

  IconData _getFilterIcon(String type) {
    switch (type) {
      case 'tag':
        return Icons.label;
      case 'artist':
        return Icons.brush;
      case 'character':
        return Icons.person;
      case 'parody':
        return Icons.book;
      case 'group':
        return Icons.group;
      default:
        return Icons.filter_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Box
          _buildSearchBox(colorScheme),

          const SizedBox(height: 12),

          // 2. Advanced Filters Toggle
          _buildAdvancedToggle(colorScheme),

          // 3. Advanced Filters Section (Collapsible)
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 16),

            // Filter Categories (multiSelect)
            if (_multiSelectFilters2.isNotEmpty) ...[
              _buildSectionTitle('FILTER CATEGORIES'),
              const SizedBox(height: 12),
              _buildFilterCategoryGrid(colorScheme),
              const SizedBox(height: 20),
            ],

            // Language dropdown (singleSelect)
            if (_singleSelectFilters.contains('language')) ...[
              _buildSectionTitle('LANGUAGE'),
              const SizedBox(height: 8),
              _buildLanguageDropdown(colorScheme),
              const SizedBox(height: 16),
            ],

            // Category dropdown (singleSelect)
            if (_singleSelectFilters.contains('category')) ...[
              _buildSectionTitle('CATEGORY'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(colorScheme),
              const SizedBox(height: 16),
            ],

            // Note: Sort options di main screen, tidak di sini
          ],

          const SizedBox(height: 24),

          // 4. Search Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _onSearchSubmitted,
              icon: const Icon(Icons.search),
              label: const Text('SEARCH'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearchSubmitted(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle(ColorScheme colorScheme) {
    // Check if any filters are available
    final hasFilters = _singleSelectFilters.isNotEmpty || 
                       _multiSelectFilters2.isNotEmpty; // Use _multiSelectFilters2 from config getter

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showAdvancedFilters
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Advanced Filters',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFilterCategoryGrid(ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: _multiSelectFilters2.map((type) {
        final selectedCount = _multiSelectFilters[type]?.length ?? 0;
        final hasSelection = selectedCount > 0;

        return Material(
          color: hasSelection
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _openFilterPicker(type),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      hasSelection ? colorScheme.primary : colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFilterIcon(type),
                    size: 20,
                    color: hasSelection
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFilterTitle(type),
                      style: TextStyle(
                        fontSize: 13,
                        color: hasSelection
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight:
                            hasSelection ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasSelection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageDropdown(ColorScheme colorScheme) {
    final languages = _tagsByType['language'] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('All'),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          ...languages.map((lang) => DropdownMenuItem(
                value: lang.name,
                child: Text(lang.name),
              )),
        ],
        onChanged: (value) => setState(() => _selectedLanguage = value ?? ''),
      ),
    );
  }

  Widget _buildCategoryDropdown(ColorScheme colorScheme) {
    final categories = _tagsByType['category'] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('All'),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          ...categories.map((cat) => DropdownMenuItem(
                value: cat.name,
                child: Text(cat.name),
              )),
        ],
        onChanged: (value) => setState(() => _selectedCategory = value ?? ''),
      ),
    );
  }
}
