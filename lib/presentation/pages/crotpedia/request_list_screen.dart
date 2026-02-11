import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_cubit.dart';
import 'package:nhasixapp/presentation/cubits/crotpedia_feature/crotpedia_feature_state.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/app_main_drawer_widget.dart';
import 'package:nhasixapp/presentation/widgets/shimmer_loading_widgets.dart';
import 'package:kuron_core/kuron_core.dart'; // For ContentSourceRegistry
import 'package:cached_network_image/cached_network_image.dart';

class CrotpediaRequestListScreen extends StatelessWidget {
  const CrotpediaRequestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CrotpediaFeatureCubit>()..loadRequestList(),
      child: Scaffold(
        drawer: AppMainDrawerWidget(context: context),
        appBar: AppBar(
          title: const Text('Project Requests'),
          centerTitle: true,
        ),
        body: const _RequestListBody(),
      ),
    );
  }
}

// Separate widget with its own context INSIDE the BlocProvider
class _RequestListBody extends StatefulWidget {
  const _RequestListBody();

  @override
  State<_RequestListBody> createState() => _RequestListBodyState();
}

class _RequestListBodyState extends State<_RequestListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CrotpediaFeatureCubit>().loadNextRequestPage();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrotpediaFeatureCubit, CrotpediaFeatureState>(
      builder: (context, state) {
        if (state is CrotpediaFeatureLoading) {
          return const ListShimmer(itemCount: 8);
        } else if (state is CrotpediaFeatureError) {
          return Center(
            child: AppErrorWidget(
              title: 'Error Loading Requests',
              message: state.message,
              onRetry: () =>
                  context.read<CrotpediaFeatureCubit>().loadRequestList(page: 1),
            ),
          );
        } else if (state is RequestListLoaded) {
          if (state.requests.isEmpty) {
            return const Center(child: Text('No requests found'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<CrotpediaFeatureCubit>().loadRequestList(page: 1);
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index >= state.requests.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final request = state.requests[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      // Extract slug from URL using basic parsing
                      try {
                        final uri = Uri.parse(request.url);
                        final segments = uri.pathSegments;
                        // Path usually /baca/series/slug/
                        final int seriesIndex = segments.indexOf('series');
                        if (seriesIndex != -1 &&
                            seriesIndex + 1 < segments.length) {
                          final slug = segments[seriesIndex + 1];
                          AppRouter.goToContentDetail(context, slug,
                              sourceId: SourceType.crotpedia.id);
                        }
                      } catch (e) {
                        // Ignore
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image
                        SizedBox(
                          width: 80,
                          height: 120,
                          child: CachedNetworkImage(
                            imageUrl: request.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  request.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Genres (wrapped chips)
                                if (request.genres.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: request.genres.values
                                        .take(5)
                                        .map((genre) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          genre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                // Show count if there are more genres
                                if (request.genres.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '+${request.genres.length - 5} more',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
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
    );
  }
}
