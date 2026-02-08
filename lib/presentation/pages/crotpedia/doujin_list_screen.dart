import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/blocs/crotpedia/doujin_list/doujin_list_cubit.dart';
import 'package:nhasixapp/presentation/blocs/crotpedia/doujin_list/doujin_list_state.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';
import 'package:kuron_core/kuron_core.dart'; // For ContentSourceRegistry


class CrotpediaDoujinListScreen extends StatelessWidget {
  const CrotpediaDoujinListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DoujinListCubit(
        getIt<CrotpediaFeatureRepository>(),
      )..fetchDoujins(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doujin List (A-Z)'),
          centerTitle: true,
        ),
        body: BlocBuilder<DoujinListCubit, DoujinListState>(
          builder: (context, state) {
            if (state is DoujinListLoading) {
              return const Center(child: AppProgressIndicator());
            } else if (state is DoujinListError) {
              return Center(
                child: AppErrorWidget(
                  title: 'Error Loading Doujin List',
                  message: state.message,
                  onRetry: () => context.read<DoujinListCubit>().fetchDoujins(forceRefresh: true),
                ),
              );
            } else if (state is DoujinListLoaded) {
              if (state.doujins.isEmpty) {
                return const Center(child: Text('No doujins found'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<DoujinListCubit>().fetchDoujins(forceRefresh: true);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.doujins.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doujin = state.doujins[index];
                    return ListTile(
                      title: Text(
                        doujin.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                         // Extract slug from URL using basic parsing
                         try {
                             final uri = Uri.parse(doujin.url);
                             // Path usually /baca/series/slug/
                             final segments = uri.pathSegments;
                             // segments: ['baca', 'series', 'slug', ''] or ['baca', 'series', 'slug']
                             // find 'series' index and take next
                             int seriesIndex = segments.indexOf('series');
                             if (seriesIndex != -1 && seriesIndex + 1 < segments.length) {
                                 final slug = segments[seriesIndex + 1];
                                 AppRouter.goToContentDetail(context, slug, sourceId: SourceType.crotpedia.id);
                             } else {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text('Cannot parse slug from URL: ${doujin.url}'))
                                 );
                             }
                         } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Error parsing URL: ${doujin.url}'))
                             );
                         }
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
