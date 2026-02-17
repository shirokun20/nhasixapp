import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_route.dart';
import '../../../core/routing/app_router.dart';
import '../../../domain/entities/entities.dart';
import '../../cubits/content_list/content_list_cubit.dart';
import '../../widgets/alphabet_filter_widget.dart';
import '../../widgets/content_grid.dart';
import '../../widgets/pagination_widget.dart';

/// Generic content list screen for KomikTap
/// Used for: Manga, Manhua, Manhwa, A-Z, Project
class ContentListScreen extends StatelessWidget {
  final ContentListType listType;
  final String sourceId;
  final int initialPage;
  final String? initialFilter;

  const ContentListScreen({
    super.key,
    required this.listType,
    required this.sourceId,
    this.initialPage = 1,
    this.initialFilter,
  });

  String get _title => listType.displayName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContentListCubit(
        getContentListByTypeUseCase: getIt(),
        listType: listType,
        sourceId: sourceId,
        logger: getIt(),
      )..initialize(filter: initialFilter),
      child: _ContentListView(
        title: _title,
        listType: listType,
      ),
    );
  }
}

class _ContentListView extends StatelessWidget {
  final String title;
  final ContentListType listType;

  const _ContentListView({
    required this.title,
    required this.listType,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.go(AppRoute.home);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        body: Column(
          children: [
            // Alphabet filter for A-Z list
            if (listType.hasAlphabetFilter)
              BlocBuilder<ContentListCubit, ContentListState>(
                builder: (context, state) {
                  final currentFilter =
                      state is ContentListLoaded ? state.currentFilter : null;
                  return CompactAlphabetFilterWidget(
                    selectedLetter: currentFilter,
                    onLetterSelected: (letter) {
                      context.read<ContentListCubit>().changeFilter(letter);
                    },
                  );
                },
              ),

            // Content list
            Expanded(
              child: BlocBuilder<ContentListCubit, ContentListState>(
                builder: (context, state) {
                  if (state is ContentListLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is ContentListError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () {
                        context.read<ContentListCubit>().refresh();
                      },
                    );
                  }

                  if (state is ContentListLoaded) {
                    if (state.items.isEmpty) {
                      return const _EmptyView();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await context.read<ContentListCubit>().refresh();
                      },
                      child: Column(
                        children: [
                          // Content grid
                          Expanded(
                            child: ContentGrid(
                              contents: state.items,
                              onContentTap: (content) {
                                AppRouter.goToContentDetail(
                                  context,
                                  content.id,
                                  sourceId: content.sourceId,
                                );
                              },
                            ),
                          ),

                          // Pagination (if supported)
                          if (listType.hasPagination)
                            PaginationWidget(
                              currentPage: state.currentPage,
                              totalPages: state.totalPages,
                              hasNext: state.hasNext,
                              hasPrevious: state.hasPrevious,
                              onPreviousPage: () {
                                context.read<ContentListCubit>().previousPage();
                              },
                              onNextPage: () {
                                context.read<ContentListCubit>().nextPage();
                              },
                              onGoToPage: (page) {
                                context.read<ContentListCubit>().goToPage(page);
                              },
                            ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Failed to Load',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Content Found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
