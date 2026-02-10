import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_cubit.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_state.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_drawer_content.dart';

class CrotpediaGenreListScreen extends StatelessWidget {
  const CrotpediaGenreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CrotpediaFeatureCubit>()..loadGenreList(),
      child: Scaffold(
        drawer: const AppDrawerContent(),
        appBar: AppBar(
          title: const Text('Genre List'),
          centerTitle: true,
        ),
        body: BlocBuilder<CrotpediaFeatureCubit, CrotpediaFeatureState>(
          builder: (context, state) {
            if (state is CrotpediaFeatureLoading) {
              return const Center(child: AppProgressIndicator());
            } else if (state is CrotpediaFeatureError) {
              return Center(
                child: AppErrorWidget(
                  title: 'Error Loading Genres',
                  message: state.message,
                  onRetry: () => context.read<CrotpediaFeatureCubit>().loadGenreList(),
                ),
              );
            } else if (state is GenreListLoaded) {
              if (state.genres.isEmpty) {
                return const Center(child: Text('No genres found'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<CrotpediaFeatureCubit>().loadGenreList();
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Adjust based on screen width if needed
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.genres.length,
                  itemBuilder: (context, index) {
                    final genre = state.genres[index];
                    return InkWell(
                      onTap: () {
                         // Use 'genre:' prefix as supported by CrotpediaSource
                         AppRouter.goToContentByTag(context, 'genre:${genre.slug}');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                genre.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (genre.count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  genre.count.toString(),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
