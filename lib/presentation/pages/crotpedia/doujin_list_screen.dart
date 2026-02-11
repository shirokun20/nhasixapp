import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_cubit.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_state.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/shimmer_loading_widgets.dart';
import 'package:kuron_core/kuron_core.dart'; // For ContentSourceRegistry
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CrotpediaDoujinListScreen extends StatelessWidget {
  const CrotpediaDoujinListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CrotpediaFeatureCubit>()..loadDoujinList(),
      child: Scaffold(
        drawer: AppMainDrawerWidget(context: context),
        appBar: AppBar(
          title: const Text('Doujin List (A-Z)'),
          centerTitle: true,
        ),
        body: const _DoujinListBody(),
      ),
    );
  }
}

class _DoujinListBody extends StatefulWidget {
  const _DoujinListBody();

  @override
  State<_DoujinListBody> createState() => _DoujinListBodyState();
}

class _DoujinListBodyState extends State<_DoujinListBody> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  // Sections in order: -, #, A-Z
  final List<String> _sections = [
    '-',
    '#',
    ...List.generate(26, (i) => String.fromCharCode(65 + i))
  ];

  Map<String, List<dynamic>> _groupedDoujins = {};
  List<_ListItem> _listItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _groupDoujins(List<dynamic> doujins) {
    // Filter by search query first
    final filteredDoujins = _searchQuery.isEmpty
        ? doujins
        : doujins
            .where((d) =>
                d.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    _groupedDoujins = {for (var section in _sections) section: []};

    for (var doujin in filteredDoujins) {
      final title = doujin.title.toUpperCase();
      String section;

      if (title.startsWith('-')) {
        section = '-';
      } else if (RegExp(r'^[0-9]').hasMatch(title)) {
        section = '#';
      } else {
        final firstChar = title[0];
        if (RegExp(r'^[A-Z]').hasMatch(firstChar)) {
          section = firstChar;
        } else {
          section = '#'; // Fallback for special chars
        }
      }

      _groupedDoujins[section]?.add(doujin);
    }

    // Build flat list with headers
    _listItems = [];
    for (var section in _sections) {
      final items = _groupedDoujins[section] ?? [];
      if (items.isNotEmpty) {
        _listItems.add(_ListItem(isHeader: true, section: section));
        for (var item in items) {
          _listItems.add(_ListItem(isHeader: false, doujin: item));
        }
      }
    }
  }

  void _scrollToSection(String section) {
    final index = _listItems
        .indexWhere((item) => item.isHeader && item.section == section);
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrotpediaFeatureCubit, CrotpediaFeatureState>(
      builder: (context, state) {
        // Show syncing message
        if (state is CrotpediaFeatureSyncing) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few moments...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is CrotpediaFeatureLoading) {
          return const SimpleListShimmer();
        } else if (state is CrotpediaFeatureError) {
          return Center(
            child: AppErrorWidget(
              title: 'Error Loading Doujin List',
              message: state.message,
              onRetry: () => context
                  .read<CrotpediaFeatureCubit>()
                  .loadDoujinList(forceRefresh: true),
            ),
          );
        } else if (state is DoujinListLoaded) {
          if (state.doujins.isEmpty) {
            return const Center(child: Text('No doujins found'));
          }

          // Group doujins
          _groupDoujins(state.doujins);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doujins...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),

              // Results count
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Found ${_listItems.where((item) => !item.isHeader).length} results',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),

              // Main list
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        await context
                            .read<CrotpediaFeatureCubit>()
                            .loadDoujinList(forceRefresh: true);
                      },
                      child: _listItems.isEmpty
                          ? Center(
                              child: Text(
                                'No results found for "$_searchQuery"',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            )
                          : ScrollablePositionedList.builder(
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              itemCount: _listItems.length,
                              itemBuilder: (context, index) {
                                final item = _listItems[index];

                                if (item.isHeader) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: Text(
                                      item.section!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                  );
                                } else {
                                  final doujin = item.doujin!;
                                  return ListTile(
                                    title: Text(
                                      doujin.title,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    trailing: const Icon(Icons.chevron_right,
                                        size: 16),
                                    onTap: () {
                                      try {
                                        final uri = Uri.parse(doujin.url);
                                        final segments = uri.pathSegments;
                                        final int seriesIndex =
                                            segments.indexOf('series');
                                        if (seriesIndex != -1 &&
                                            seriesIndex + 1 < segments.length) {
                                          final slug =
                                              segments[seriesIndex + 1];
                                          AppRouter.goToContentDetail(
                                              context, slug,
                                              sourceId:
                                                  SourceType.crotpedia.id);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Cannot parse slug from URL: ${doujin.url}')));
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Error parsing URL: ${doujin.url}')));
                                      }
                                    },
                                  );
                                }
                              },
                            ),
                    ),

                    // Floating A-Z navigation (only show when not searching)
                    if (_searchQuery.isEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.9),
                            border: Border(
                              left: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: _sections.length,
                            itemBuilder: (context, index) {
                              final section = _sections[index];
                              final hasItems =
                                  (_groupedDoujins[section] ?? []).isNotEmpty;

                              return InkWell(
                                onTap: hasItems
                                    ? () => _scrollToSection(section)
                                    : null,
                                child: SizedBox(
                                  height: 20,
                                  child: Center(
                                    child: Text(
                                      section,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: hasItems
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ListItem {
  final bool isHeader;
  final String? section;
  final dynamic doujin;

  _ListItem({required this.isHeader, this.section, this.doujin});
}
