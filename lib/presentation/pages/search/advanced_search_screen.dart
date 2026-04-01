import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/tags/tag_entity.dart';
import 'package:nhasixapp/domain/usecases/tags/get_tags_by_type_usecase.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/blocs/tag_autocomplete/tag_autocomplete_bloc.dart';
import 'package:nhasixapp/presentation/widgets/app_scaffold_with_offline.dart';

/// Advanced search screen with dynamic tag lists from API v2
class AdvancedSearchScreen extends StatefulWidget {
  final String sourceId;

  const AdvancedSearchScreen({
    super.key,
    required this.sourceId,
  });

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late TabController _tabController;
  late TagAutocompleteBloc _autocompleteBloc;

  // Tab types
  static const List<String> _tagTypes = [
    'tag',
    'artist',
    'character',
    'parody',
    'group',
  ];

  // Selected tags for building query
  final Map<String, Set<TagEntity>> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tagTypes.length, vsync: this);
    
    // Initialize autocomplete bloc
    _autocompleteBloc = TagAutocompleteBloc(
      getAutocompleteUseCase: getIt<GetTagAutocompleteUseCase>(),
      logger: getIt<Logger>(),
      sourceId: widget.sourceId,
    );

    // Initialize selected tags map
    for (final type in _tagTypes) {
      _selectedTags[type] = {};
    }

    // Listen to search input
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    _autocompleteBloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Get current tab type for filtered autocomplete
      final currentType = _tagTypes[_tabController.index];
      _autocompleteBloc.add(TagAutocompleteSearchEvent(
        query: query,
        tagType: currentType,
      ));
    } else {
      _autocompleteBloc.add(const TagAutocompleteClearEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _autocompleteBloc,
      child: AppScaffoldWithOffline(
        title: l10n?.advancedSearch ?? 'Advanced Search',
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear all selections',
          ),
        ],
        body: Column(
          children: [
            // Search bar with autocomplete
            _buildSearchBar(colorScheme),

            // Tab bar for tag types
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _tagTypes
                  .map((type) => Tab(text: _formatTagType(type)))
                  .toList(),
              onTap: (_) {
                // Clear search and autocomplete when switching tabs
                _searchController.clear();
                _autocompleteBloc.add(const TagAutocompleteClearEvent());
              },
            ),

            // Tab views with tag lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tagTypes
                    .map((type) => _buildTagListView(type, colorScheme))
                    .toList(),
              ),
            ),

            // Bottom action bar
            _buildBottomActionBar(colorScheme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search tags...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _autocompleteBloc.add(const TagAutocompleteClearEvent());
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Autocomplete results
          BlocBuilder<TagAutocompleteBloc, TagAutocompleteState>(
            builder: (context, state) {
              if (state is TagAutocompleteLoading) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                );
              } else if (state is TagAutocompleteLoaded &&
                  state.suggestions.isNotEmpty) {
                return _buildAutocompleteResults(state, colorScheme);
              } else if (state is TagAutocompleteError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.message,
                    style: TextStyle(color: colorScheme.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteResults(
    TagAutocompleteLoaded state,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final tag = state.suggestions[index];
          final isSelected = _selectedTags[tag.type]?.contains(tag) ?? false;

          return ListTile(
            leading: Icon(
              _getIconForType(tag.type),
              color: isSelected ? colorScheme.primary : null,
            ),
            title: Text(tag.name),
            subtitle: Text('${tag.count} galleries'),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: colorScheme.primary)
                : null,
            selected: isSelected,
            onTap: () => _toggleTag(tag),
          );
        },
      ),
    );
  }

  Widget _buildTagListView(String tagType, ColorScheme colorScheme) {
    return FutureBuilder<DataState<List<TagEntity>>>(
      future: _loadTagsByType(tagType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), colorScheme);
        }

        final dataState = snapshot.data;
        if (dataState is DataFailed) {
          return _buildErrorView(
            dataState.exception?.message ?? 'Failed to load tags',
            colorScheme,
          );
        }

        if (dataState is DataSuccess) {
          final tags = dataState.data ?? [];
          if (tags.isEmpty) {
            return _buildEmptyView(tagType, colorScheme);
          }

          return _buildTagGrid(tags, tagType, colorScheme);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTagGrid(
    List<TagEntity> tags,
    String tagType,
    ColorScheme colorScheme,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = _selectedTags[tagType]?.contains(tag) ?? false;

        return Material(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _toggleTag(tag),
            onLongPress: () => _showTagDetail(tag),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(tag.type),
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${tag.count}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                    .withOpacity(0.7)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String message, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading tags',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String tagType, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No ${_formatTagType(tagType).toLowerCase()} found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ColorScheme colorScheme, AppLocalizations? l10n) {
    final selectedCount = _selectedTags.values.fold<int>(
      0,
      (sum, tags) => sum + tags.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected tags summary
          if (selectedCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$selectedCount tag${selectedCount > 1 ? 's' : ''} selected',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Search button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedCount > 0 ? _performSearch : null,
              icon: const Icon(Icons.search),
              label: Text(l10n?.search ?? 'Search'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<DataState<List<TagEntity>>> _loadTagsByType(String tagType) async {
    try {
      final useCase = getIt<GetTagsByTypeUseCase>();
      return await useCase(GetTagsByTypeParams(
        tagType: tagType,
        sourceId: widget.sourceId,
        page: 1,
        perPage: 50, // Load top 50 tags
      ));
    } catch (e) {
      _logger.e('Error loading tags by type: $tagType', error: e);
      rethrow;
    }
  }

  void _toggleTag(TagEntity tag) {
    setState(() {
      final selectedSet = _selectedTags[tag.type]!;
      if (selectedSet.contains(tag)) {
        selectedSet.remove(tag);
      } else {
        selectedSet.add(tag);
      }
    });
  }

  void _showTagDetail(TagEntity tag) {
    // TODO: Navigate to TagDetailScreen
    _logger.i('Show tag detail: ${tag.name} (type: ${tag.type})');
  }

  void _clearAll() {
    setState(() {
      for (final type in _tagTypes) {
        _selectedTags[type]!.clear();
      }
    });
    _searchController.clear();
    _autocompleteBloc.add(const TagAutocompleteClearEvent());
  }

  void _performSearch() {
    // TODO: Build query from selected tags and navigate to results
    _logger.i('Perform search with selected tags: $_selectedTags');
    
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search with ${_selectedTags.values.fold<int>(0, (sum, tags) => sum + tags.length)} tags'),
      ),
    );
  }

  String _formatTagType(String type) {
    return type[0].toUpperCase() + type.substring(1) + 's';
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'artist':
        return Icons.brush;
      case 'character':
        return Icons.person;
      case 'parody':
        return Icons.book;
      case 'group':
        return Icons.group;
      case 'tag':
      default:
        return Icons.label;
    }
  }
}
