import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart' show Tag;
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/config/config_models.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/domain/entities/search_filter.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';
import 'package:nhasixapp/domain/usecases/tags/get_tags_by_type_usecase.dart';
import 'package:nhasixapp/presentation/blocs/search/search_bloc.dart';

import 'package:nhasixapp/l10n/app_localizations.dart';

/// Nhentai-style search UI (Query String mode)
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
  final TextEditingController _pagesMinCtrl = TextEditingController();
  final TextEditingController _pagesMaxCtrl = TextEditingController();
  final TextEditingController _favMinCtrl = TextEditingController();
  final Logger _logger = Logger();

  // UI State
  bool _showAdvancedFilters = false;

  // Filters
  String _selectedLanguage = '';
  String _selectedCategory = '';
  String _selectedSort = '';

  // Date filter: '', '<1d', '<7d', '<1m', '<1y', '>1y'
  String _uploadedPreset = '';

  // Multi-select filter selections (tag type -> list of selected items)
  final Map<String, List<FilterItem>> _multiSelectFilters = {};

  // API-loaded tags for language/category chips
  final Map<String, List<Tag>> _tagsByType = {};
  bool _tagsLoading = false;

  // Config helpers
  FilterSupportConfig? get _filterSupport => widget.config.filterSupport;
  List<String> get _singleSelectFilters => _filterSupport?.singleSelect ?? [];
  List<String> get _multiSelectFilters2 => _filterSupport?.multiSelect ?? [];
  bool get _supportsExclude => _filterSupport?.supportsExclude ?? false;
  List<SortOptionConfig> get _sortOptions =>
      widget.config.sortingConfig?.options ?? [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _searchController.addListener(() => setState(() {}));

    context
        .read<SearchBloc>()
        .add(SearchInitializeEvent(sourceId: widget.sourceId));

    final defaultSort = _sortOptions.where((o) => o.isDefault).firstOrNull;
    _selectedSort = defaultSort?.apiValue ?? '';

    for (var type in _multiSelectFilters2) {
      _multiSelectFilters[type] = [];
    }

    _loadTagsFromApi();
    _restoreSavedFilter();
  }

  /// Fetch language & category from API v2 instead of local JSON
  Future<void> _loadTagsFromApi() async {
    if (_singleSelectFilters.isEmpty) return;
    setState(() => _tagsLoading = true);
    try {
      final useCase = getIt<GetTagsByTypeUseCase>();
      final futures = <String, Future<List<TagEntity>>>{};

      if (_singleSelectFilters.contains('language')) {
        futures['language'] = useCase(const GetTagsByTypeParams(
          tagType: 'language',
          sourceId: 'nhentai',
          page: 1,
          perPage: 25,
        ));
      }
      if (_singleSelectFilters.contains('category')) {
        futures['category'] = useCase(const GetTagsByTypeParams(
          tagType: 'category',
          sourceId: 'nhentai',
          page: 1,
          perPage: 25,
        ));
      }

      for (final entry in futures.entries) {
        final entities = await entry.value;
        _tagsByType[entry.key] = entities
            .map((e) => Tag(
                  id: e.id,
                  name: e.name,
                  type: e.type,
                  count: e.count,
                  url: e.url ?? '',
                  slug: e.slug,
                ))
            .toList();
      }
      if (mounted) setState(() => _tagsLoading = false);
    } catch (e) {
      _logger.e('Failed to load tags from API: $e');
      if (mounted) setState(() => _tagsLoading = false);
    }
  }

  Future<void> _restoreSavedFilter() async {
    try {
      final savedFilterJson =
          await getIt<LocalDataSource>().getLastSearchFilter(widget.sourceId);
      if (savedFilterJson == null) return;

      final savedFilter = SearchFilter.fromJson(savedFilterJson);

      // Parse query string and extract date/numeric filters
      String cleanedQuery = '';
      if (savedFilter.query != null &&
          savedFilter.query!.isNotEmpty &&
          !savedFilter.query!.startsWith('raw:')) {
        cleanedQuery = _parseAndExtractFilters(savedFilter.query!);
      }

      if (cleanedQuery.isNotEmpty) {
        _searchController.text = cleanedQuery;
      }

      if (savedFilter.sortBy.apiValue.isNotEmpty) {
        _selectedSort = savedFilter.sortBy.apiValue;
      }
      if (savedFilter.language != null) {
        _selectedLanguage = savedFilter.language!;
      }
      if (savedFilter.category != null) {
        _selectedCategory = savedFilter.category!;
      }

      for (var tag in savedFilter.tags) {
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

  /// Parse query string and extract date/numeric filters into their respective state variables.
  /// Returns the cleaned query string without the filter tokens.
  String _parseAndExtractFilters(String query) {
    final tokens = query.split(' ').toList();
    final cleanTokens = <String>[];

    for (final token in tokens) {
      // Extract uploaded: filters (date)
      if (token.startsWith('uploaded:')) {
        final value = token.substring('uploaded:'.length);
        _uploadedPreset = value;
      }
      // Extract pages: filters (min & max)
      else if (token.startsWith('pages:')) {
        final match = RegExp(r'pages:(>=|<=|>|<)(\d+)').firstMatch(token);
        if (match != null) {
          final op = match.group(1)!;
          final num = match.group(2)!;
          if (op == '>=' || op == '>') _pagesMinCtrl.text = num;
          if (op == '<=' || op == '<') _pagesMaxCtrl.text = num;
        }
      }
      // Extract favorites: filters
      else if (token.startsWith('favorites:')) {
        final match = RegExp(r'favorites:(>=|>)(\d+)').firstMatch(token);
        if (match != null) {
          final num = match.group(2)!;
          _favMinCtrl.text = num;
        }
      }
      // Keep non-filter tokens
      else if (token.isNotEmpty) {
        cleanTokens.add(token);
      }
    }

    return cleanTokens.join(' ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pagesMinCtrl.dispose();
    _pagesMaxCtrl.dispose();
    _favMinCtrl.dispose();
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

  /// Build token suffixes for date/numeric filters appended to query
  String _buildExtraTokens() {
    final tokens = <String>[];
    if (_uploadedPreset.isNotEmpty) tokens.add('uploaded:$_uploadedPreset');

    final pMin = int.tryParse(_pagesMinCtrl.text.trim());
    final pMax = int.tryParse(_pagesMaxCtrl.text.trim());
    if (pMin != null) tokens.add('pages:>=$pMin');
    if (pMax != null) tokens.add('pages:<=$pMax');

    final fMin = int.tryParse(_favMinCtrl.text.trim());
    if (fMin != null) tokens.add('favorites:>=$fMin');

    return tokens.join(' ');
  }

  SearchFilter _buildSearchFilter() {
    final textQuery = _searchController.text.trim();
    final extraTokens = _buildExtraTokens();
    final combinedQuery =
        [textQuery, extraTokens].where((s) => s.isNotEmpty).join(' ');

    return SearchFilter(
      query: combinedQuery.isNotEmpty ? combinedQuery : null,
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

    if (_isNhentaiDirectNavigation(textQuery)) {
      await _navigateToGalleryDetail(textQuery);
      return;
    }

    final filter = _buildSearchFilter();

    try {
      await getIt<LocalDataSource>()
          .saveSearchFilter(widget.sourceId, filter.toJson());

      if (mounted) {
        context.read<SearchBloc>().add(SearchUpdateFilterEvent(filter));
        context.read<SearchBloc>().add(const SearchSubmittedEvent());
        context.pop(true);
      }
    } catch (e) {
      _logger.e('Failed to save search filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToApplySearch(e.toString()))),
        );
      }
    }
  }

  bool _isNhentaiDirectNavigation(String query) {
    if (query.isEmpty) return false;
    final config = getIt<RemoteConfigService>().getConfig(widget.sourceId);
    if (config?.api?.endpoints?.containsKey('galleryDetail') != true) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(query);
  }

  Future<void> _navigateToGalleryDetail(String galleryId) async {
    final normalizedId = int.tryParse(galleryId)?.toString() ?? galleryId;
    if (!mounted) return;

    final returnedFilter = await AppRouter.goToContentDetail(
      context,
      normalizedId,
      sourceId: widget.sourceId,
    );

    if (returnedFilter != null && mounted) {
      try {
        await getIt<LocalDataSource>()
            .saveSearchFilter(widget.sourceId, returnedFilter.toJson());
        if (!mounted) return;
        context.read<SearchBloc>().add(SearchUpdateFilterEvent(returnedFilter));
        context.read<SearchBloc>().add(const SearchSubmittedEvent());
        context.pop(true);
      } catch (e) {
        _logger.e('Failed to apply filter from detail screen: $e');
      }
    } else if (mounted) {
      context.pop(false);
    }
  }

  void _openFilterPicker(String filterType) async {
    final currentSelection = _multiSelectFilters[filterType] ?? [];

    final result = await AppRouter.goToFilterData(
      context,
      filterType: filterType,
      selectedFilters: currentSelection,
      sourceId: widget.sourceId,
      hideOtherTabs: true,
      supportsExclude: _supportsExclude,
    );

    if (result != null) {
      setState(() => _multiSelectFilters[filterType] = result);
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _getFilterTitle(String type) {
    switch (type) {
      case 'tag':
        return AppLocalizations.of(context)!.tags;
      case 'artist':
        return AppLocalizations.of(context)!.artists;
      case 'character':
        return AppLocalizations.of(context)!.characters;
      case 'parody':
        return AppLocalizations.of(context)!.parodies;
      case 'group':
        return AppLocalizations.of(context)!.groups;
      default:
        return type;
    }
  }

  IconData _getFilterIcon(String type) {
    switch (type) {
      case 'tag':
        return Icons.label_outline;
      case 'artist':
        return Icons.brush_outlined;
      case 'character':
        return Icons.person_outline;
      case 'parody':
        return Icons.book_outlined;
      case 'group':
        return Icons.group_outlined;
      default:
        return Icons.filter_alt_outlined;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final advancedFiltersPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Filter Categories
        if (_multiSelectFilters2.isNotEmpty) ...[
          _buildSectionTitle(AppLocalizations.of(context)!.filterCategories),
          const SizedBox(height: 10),
          _buildFilterCategoryList(colorScheme),
          const SizedBox(height: 20),
        ],

        // Language
        if (_singleSelectFilters.contains('language')) ...[
          _buildSectionTitle('LANGUAGE'),
          const SizedBox(height: 10),
          _buildTagChipSelector('language', colorScheme),
          const SizedBox(height: 20),
        ],

        // Category
        if (_singleSelectFilters.contains('category')) ...[
          _buildSectionTitle('CATEGORY'),
          const SizedBox(height: 10),
          _buildTagChipSelector('category', colorScheme),
          const SizedBox(height: 20),
        ],

        // Date Filter
        _buildSectionTitle(AppLocalizations.of(context)!.dateUploaded),
        const SizedBox(height: 10),
        _buildDateFilter(colorScheme),
        const SizedBox(height: 20),

        // Numeric Filters
        _buildSectionTitle(AppLocalizations.of(context)!.numericFilters),
        const SizedBox(height: 10),
        _buildNumericFilters(colorScheme),
        const SizedBox(height: 8),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBox(colorScheme),
          const SizedBox(height: 16),
          _buildAdvancedToggle(colorScheme),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _showAdvancedFilters
                  ? KeyedSubtree(
                      key: const ValueKey('advanced_filters_open'),
                      child: advancedFiltersPanel,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('advanced_filters_closed'),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchButton(colorScheme),
        ],
      ),
    );
  }

  // ── Search Box ──────────────────────────────────────────────────────────────

  Widget _buildSearchBox(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? cs.primary
              : cs.outline.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByTitleHint,
                hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearchSubmitted(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: Icon(Icons.close_rounded,
                  color: cs.onSurfaceVariant, size: 20),
            ),
        ],
      ),
    );
  }

  // ── Toggle ──────────────────────────────────────────────────────────────────

  Widget _buildAdvancedToggle(ColorScheme cs) {
    final totalSelected = _multiSelectFilters2.fold(
        0, (sum, t) => sum + (_multiSelectFilters[t]?.length ?? 0));
    final hasExtra = _uploadedPreset.isNotEmpty ||
        _pagesMinCtrl.text.isNotEmpty ||
        _pagesMaxCtrl.text.isNotEmpty ||
        _favMinCtrl.text.isNotEmpty ||
        _selectedLanguage.isNotEmpty ||
        _selectedCategory.isNotEmpty;
    final activeCount = totalSelected + (hasExtra ? 1 : 0);

    return InkWell(
      onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showAdvancedFilters
              ? cs.primaryContainer.withValues(alpha: 0.6)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _showAdvancedFilters
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: _showAdvancedFilters ? 1.08 : 1.0,
              child: Icon(
                Icons.tune_rounded,
                color: _showAdvancedFilters ? cs.primary : cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.advancedFilters,
              style: TextStyle(
                color: _showAdvancedFilters ? cs.primary : cs.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(activeCount),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              turns: _showAdvancedFilters ? 0.5 : 0,
              child: Icon(
                Icons.expand_more,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Title ───────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ── Filter Category List (full-width cards with selected chip preview) ───────

  Widget _buildFilterCategoryList(ColorScheme cs) {
    return Column(
      children: _multiSelectFilters2.map((type) {
        final selected = _multiSelectFilters[type] ?? [];
        final included = selected.where((f) => !f.isExcluded).toList();
        final excluded = selected.where((f) => f.isExcluded).toList();
        final hasSelection = selected.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: hasSelection
                ? cs.primaryContainer.withValues(alpha: 0.3)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _openFilterPicker(type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasSelection
                        ? cs.primary.withValues(alpha: 0.6)
                        : cs.outline.withValues(alpha: 0.3),
                    width: hasSelection ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getFilterIcon(type),
                            size: 18,
                            color: hasSelection
                                ? cs.primary
                                : cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          _getFilterTitle(type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasSelection ? cs.onSurface : cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (hasSelection)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${selected.length}',
                                style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          )
                        else
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: cs.onSurfaceVariant),
                      ],
                    ),
                    // Show selected chips preview
                    if (hasSelection) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...included.map((f) => _miniChip(f.value, cs.primary,
                              cs.onPrimary, Icons.add_rounded)),
                          ...excluded.map((f) => _miniChip(f.value, cs.error,
                              cs.onError, Icons.remove_rounded)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniChip(String label, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  // ── Language / Category chip selector (from API) ─────────────────────────────

  Widget _buildTagChipSelector(String type, ColorScheme cs) {
    if (_tagsLoading && _tagsByType[type] == null) {
      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) => Container(
            width: 72,
            height: 34,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    final tags = _tagsByType[type] ?? [];
    final selected = type == 'language' ? _selectedLanguage : _selectedCategory;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All" chip
        _singleSelectChip(
          label: AppLocalizations.of(context)!.all,
          isSelected: selected.isEmpty,
          onTap: () => setState(() {
            if (type == 'language') {
              _selectedLanguage = '';
            } else {
              _selectedCategory = '';
            }
          }),
          cs: cs,
        ),
        ...tags.map((tag) => _singleSelectChip(
              label: tag.name,
              count: tag.count,
              isSelected: selected == tag.name,
              onTap: () => setState(() {
                if (type == 'language') {
                  _selectedLanguage =
                      _selectedLanguage == tag.name ? '' : tag.name;
                } else {
                  _selectedCategory =
                      _selectedCategory == tag.name ? '' : tag.name;
                }
              }),
              cs: cs,
            )),
      ],
    );
  }

  Widget _singleSelectChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: cs.outline.withValues(alpha: 0.4)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? cs.onPrimary : cs.onSurface,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? cs.onPrimary.withValues(alpha: 0.75)
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Date Filter ─────────────────────────────────────────────────────────────

  Widget _buildDateFilter(ColorScheme cs) {
    final presets = [
      [AppLocalizations.of(context)!.today, '<1d'],
      ['7 days', '<7d'],
      ['30 days', '<1m'],
      ['1 year', '<1y'],
      [AppLocalizations.of(context)!.older, '>1y'],
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final label = p[0];
        final value = p[1];
        final isSelected = _uploadedPreset == value;
        return GestureDetector(
          onTap: () =>
              setState(() => _uploadedPreset = isSelected ? '' : value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? cs.tertiary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: cs.outline.withValues(alpha: 0.4)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: cs.tertiary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.schedule_rounded, size: 13, color: cs.onTertiary),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? cs.onTertiary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Numeric Filters ─────────────────────────────────────────────────────────

  Widget _buildNumericFilters(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pages row
        Row(
          children: [
            Icon(Icons.menu_book_outlined,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.pagesLabel2,
                style: TextStyle(fontSize: 13, color: cs.onSurface)),
            const Spacer(),
            _numericInput(
                controller: _pagesMinCtrl,
                hint: AppLocalizations.of(context)!.min,
                cs: cs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('–', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            _numericInput(
                controller: _pagesMaxCtrl,
                hint: AppLocalizations.of(context)!.max,
                cs: cs),
          ],
        ),
        const SizedBox(height: 12),
        // Favorites row
        Row(
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.favoritesGte,
                style: TextStyle(fontSize: 13, color: cs.onSurface)),
            const Spacer(),
            _numericInput(
                controller: _favMinCtrl,
                hint: AppLocalizations.of(context)!.min,
                cs: cs,
                width: 90),
          ],
        ),
      ],
    );
  }

  Widget _numericInput({
    required TextEditingController controller,
    required String hint,
    required ColorScheme cs,
    double width = 72,
  }) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.primary),
          ),
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ── Search Button ───────────────────────────────────────────────────────────

  Widget _buildSearchButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _onSearchSubmitted,
        icon: const Icon(Icons.search_rounded),
        label: Text(AppLocalizations.of(context)!.search),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}
