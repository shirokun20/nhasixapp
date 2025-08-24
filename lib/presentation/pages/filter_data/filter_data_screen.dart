import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/routing/app_router.dart';

import '../../../core/constants/colors_const.dart';
import '../../../core/constants/text_style_const.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/entities.dart';
import '../../cubits/filter_data/filter_data_cubit.dart';
import '../../widgets/filter_data_search_widget.dart';
import '../../widgets/filter_item_card_widget.dart';
import '../../widgets/selected_filters_widget.dart';
import '../../widgets/filter_type_tab_bar_widget.dart';
import '../../widgets/app_scaffold_with_offline.dart';

/// Screen for advanced filter data selection with modern UI
class FilterDataScreen extends StatefulWidget {
  const FilterDataScreen({
    super.key,
    required this.filterType,
    required this.selectedFilters,
  });

  final String filterType;
  final List<FilterItem> selectedFilters;

  @override
  State<FilterDataScreen> createState() => _FilterDataScreenState();
}

class _FilterDataScreenState extends State<FilterDataScreen>
    with TickerProviderStateMixin {
  late final FilterDataCubit _filterDataCubit;
  late final TabController _tabController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  // Filter types for tab bar
  final List<String> _filterTypes = [
    'tag',
    'artist',
    'character',
    'parody',
    'group',
  ];

  // Add ValueNotifier for real-time updates

  @override
  void initState() {
    super.initState();
    _filterDataCubit = getIt<FilterDataCubit>();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Initialize tab controller
    final initialIndex = _filterTypes.indexOf(widget.filterType.toLowerCase());
    _tabController = TabController(
      length: _filterTypes.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );

    // Listen to tab changes
    _tabController.addListener(_onTabChanged);

    // Initialize cubit
    _filterDataCubit.initialize(
      filterType: widget.filterType,
      selectedFilters: widget.selectedFilters,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filterDataCubit.close();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final newFilterType = _filterTypes[_tabController.index];
      _searchController.clear();
      _filterDataCubit.switchFilterType(newFilterType);
    }
  }

  void _onSearchChanged(String query) {
    _filterDataCubit.searchFilterData(query);
  }

  void _onFilterItemTap(Tag tag) {
    _filterDataCubit.toggleFilterItem(tag);
  }

  void _onFilterItemInclude(Tag tag) {
    _filterDataCubit.addIncludeFilter(tag);
  }

  void _onFilterItemExclude(Tag tag) {
    _filterDataCubit.addExcludeFilter(tag);
  }

  void _onRemoveSelectedFilter(String value) {
    _filterDataCubit.removeFilterItem(value);
  }

  void _onClearAllFilters() {
    _filterDataCubit.clearAllFilters();
  }

  void _onApplyFilters() {
    final selectedFilters = _filterDataCubit.getSelectedFilters();
    AppRouter.returnFromFilterData(context, selectedFilters);
  }

  void _onCancel() {
    AppRouter.cancelFilterData(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _filterDataCubit,
      child: BlocListener<FilterDataCubit, FilterDataState>(
        listener: (context, state) {
          debugPrint('FilterDataScreen: State changed to ${state.runtimeType}');
          if (state is FilterDataLoaded) {
            debugPrint("FilterDataScreen: lastUpdated: ${state.lastUpdated}");
          }
        },
        child: AppScaffoldWithOffline(
          title: 'Filter Data',
          backgroundColor: ColorsConst.darkBackground,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Filter type tab bar
              _buildFilterTypeTabBar(),

              // Search bar
              _buildSearchBar(),

              // Selected filters (horizontal scrollable)
              _buildSelectedFiltersSection(),

              // Filter results
              Expanded(
                child: _buildFilterResults(),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ColorsConst.darkSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: ColorsConst.darkTextPrimary),
        onPressed: _onCancel,
      ),
      title: Text(
        'Filter Data',
        style: TextStyleConst.headingSmall.copyWith(
          color: ColorsConst.darkTextPrimary,
        ),
      ),
      actions: [
        BlocBuilder<FilterDataCubit, FilterDataState>(
          buildWhen: (previous, current) {
            // Always rebuild when state changes
            if (previous != current) {
              debugPrint(
                  'FilterDataScreen: AppBar Clear All button rebuilding - ${current.runtimeType}');
              if (current is FilterDataLoaded && previous is FilterDataLoaded) {
                return current.lastUpdated != previous.lastUpdated;
              }
            }
            return true;
          },
          builder: (context, state) {
            if (state is FilterDataLoaded && state.hasSelectedFilters) {
              return TextButton(
                onPressed: _onClearAllFilters,
                child: Text(
                  'Clear All',
                  style: TextStyleConst.label.copyWith(
                    color: ColorsConst.accentRed,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildFilterTypeTabBar() {
    return Container(
      color: ColorsConst.darkSurface,
      child: FilterTypeTabBar(
        controller: _tabController,
        filterTypes: _filterTypes,
        onTabChanged: (index) {
          // Tab change is handled by listener
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ColorsConst.darkSurface,
      child: FilterDataSearchWidget(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        hintText: 'Search ${_getCurrentFilterTypeDisplayName()}...',
      ),
    );
  }

  Widget _buildSelectedFiltersSection() {
    return BlocBuilder<FilterDataCubit, FilterDataState>(
      buildWhen: (previous, current) {
        // Always rebuild when state changes
        if (previous != current) {
          debugPrint(
              'FilterDataScreen: Selected filters section rebuilding - ${current.runtimeType}');
          if (current is FilterDataLoaded) {
            debugPrint(
                'FilterDataScreen: Selected filters count: ${current.selectedFilters?.length ?? 0}');
          }
        }
        return true;
      },
      builder: (context, state) {
        if (state is FilterDataLoaded && state.hasSelectedFilters) {
          return Container(
            color: ColorsConst.darkSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Selected (${state.selectedCount})',
                    style: TextStyleConst.headingSmall.copyWith(
                      color: ColorsConst.darkTextPrimary,
                    ),
                  ),
                ),
                SelectedFiltersWidget(
                  selectedFilters: state.selectedFilters ?? [],
                  onRemove: _onRemoveSelectedFilter,
                ),
                const Divider(height: 1, color: ColorsConst.borderDefault),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterResults() {
    return BlocBuilder<FilterDataCubit, FilterDataState>(
      buildWhen: (previous, current) {
        // Always rebuild when state changes
        if (previous != current) {
          debugPrint(
              'FilterDataScreen: Filter results rebuilding - ${current.runtimeType}');
          if (current is FilterDataLoaded) {
            debugPrint(
                'FilterDataScreen: Search results count: ${current.searchResults?.length ?? 0}');
            debugPrint(
                'FilterDataScreen: Selected filters count: ${current.selectedFilters?.length ?? 0}');
          }
        }
        return true;
      },
      builder: (context, state) {
        if (state is FilterDataLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorsConst.accentBlue,
            ),
          );
        }

        if (state is FilterDataError) {
          return Center(
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
                  'Error loading filter data',
                  style: TextStyleConst.headingMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message ?? "Unknown error",
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _filterDataCubit.initialize(
                      filterType: widget.filterType,
                      selectedFilters: widget.selectedFilters,
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is FilterDataLoaded) {
          if (state.searchResults?.isEmpty == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: ColorsConst.darkTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.searchQuery?.isEmpty == true
                        ? 'No ${_getCurrentFilterTypeDisplayName().toLowerCase()} available'
                        : 'No results found for "${state.searchQuery}"',
                    style: TextStyleConst.headingMedium.copyWith(
                      color: ColorsConst.darkTextPrimary,
                    ),
                  ),
                  if (state.searchQuery?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: ColorsConst.darkTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.searchResults?.length,
            itemBuilder: (context, index) {
              final tag = state.searchResults![index];
              final isIncluded = state.isIncluded(tag.name);
              final isExcluded = state.isExcluded(tag.name);

              debugPrint(
                  'FilterDataScreen: Building FilterItemCard for ${tag.name} - included: $isIncluded, excluded: $isExcluded');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilterItemCard(
                  key: ValueKey('${tag.name}_${isIncluded}_$isExcluded'),
                  tag: tag,
                  isIncluded: isIncluded,
                  isExcluded: isExcluded,
                  onTap: () => _onFilterItemTap(tag),
                  onInclude: () => _onFilterItemInclude(tag),
                  onExclude: () => _onFilterItemExclude(tag),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBottomActions() {
    return BlocBuilder<FilterDataCubit, FilterDataState>(
      buildWhen: (previous, current) {
        // Always rebuild when state changes
        if (previous != current) {
          debugPrint(
              'FilterDataScreen: Bottom actions rebuilding - ${current.runtimeType}');
        }
        return true;
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsConst.darkSurface,
            border: Border(
              top: BorderSide(
                color: ColorsConst.borderDefault,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsConst.darkTextPrimary,
                    side: BorderSide(color: ColorsConst.borderDefault),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onApplyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsConst.accentBlue,
                    foregroundColor: ColorsConst.darkTextPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    state is FilterDataLoaded && state.hasSelectedFilters
                        ? 'Apply (${state.selectedCount})'
                        : 'Apply',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCurrentFilterTypeDisplayName() {
    final currentIndex = _tabController.index;
    if (currentIndex >= 0 && currentIndex < _filterTypes.length) {
      return TagType.getDisplayName(_filterTypes[currentIndex]);
    }
    return 'Filter';
  }
}
