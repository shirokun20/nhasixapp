import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_route.dart';
import '../../cubits/genre_list/genre_list_cubit.dart';
import '../../widgets/genre_card_widget.dart';
import '../../widgets/app_main_drawer_widget.dart';

/// Genre list screen for KomikTap
/// Displays all genres with counts (no pagination)
class GenreListScreen extends StatelessWidget {
  final String sourceId;

  const GenreListScreen({
    super.key,
    required this.sourceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GenreListCubit(
        getGenreListUseCase: getIt(),
        sourceId: sourceId,
        logger: getIt(),
      )..initialize(),
      child: const _GenreListView(),
    );
  }
}

class _GenreListView extends StatelessWidget {
  const _GenreListView();

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
        drawer: AppMainDrawerWidget(context: context),
        appBar: AppBar(
          title: const Text('Genres'),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        body: BlocBuilder<GenreListCubit, GenreListState>(
          builder: (context, state) {
            if (state is GenreListLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is GenreListError) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<GenreListCubit>().refresh();
                },
              );
            }

            if (state is GenreListLoaded) {
              if (state.genres.isEmpty) {
                return EmptyGenreWidget(
                  onRetry: () {
                    context.read<GenreListCubit>().refresh();
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<GenreListCubit>().refresh();
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: state.genres.length,
                  itemBuilder: (context, index) {
                    final genre = state.genres[index];
                    return GenreCardWidget(
                      genre: genre,
                      onTap: () {
                        // Navigate to genre filtered content
                        context.push(
                          '${AppRoute.contentByTag}?q=${genre.slug}',
                        );
                      },
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
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
