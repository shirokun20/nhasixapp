import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/presentation/blocs/crotpedia/request_list/request_list_cubit.dart';
import 'package:nhasixapp/presentation/blocs/crotpedia/request_list/request_list_state.dart';
import 'package:nhasixapp/domain/repositories/crotpedia/crotpedia_feature_repository.dart';
import 'package:nhasixapp/presentation/widgets/error_widget.dart';
import 'package:nhasixapp/presentation/widgets/progress_indicator_widget.dart';
import 'package:kuron_core/kuron_core.dart'; // For ContentSourceRegistry
import 'package:cached_network_image/cached_network_image.dart';

class CrotpediaRequestListScreen extends StatefulWidget {
  const CrotpediaRequestListScreen({super.key});

  @override
  State<CrotpediaRequestListScreen> createState() => _CrotpediaRequestListScreenState();
}

class _CrotpediaRequestListScreenState extends State<CrotpediaRequestListScreen> {
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
      context.read<RequestListCubit>().loadNextPage();
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
    return BlocProvider(
      create: (context) => RequestListCubit(
        getIt<CrotpediaFeatureRepository>(),
      )..loadFirstPage(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Project Requests'),
          centerTitle: true,
        ),
        body: BlocBuilder<RequestListCubit, RequestListState>(
          builder: (context, state) {
            if (state is RequestListLoading) {
              return const Center(child: AppProgressIndicator());
            } else if (state is RequestListError) {
              return Center(
                child: AppErrorWidget(
                  title: 'Error Loading Requests',
                  message: state.message,
                  onRetry: () => context.read<RequestListCubit>().loadFirstPage(),
                ),
              );
            } else if (state is RequestListLoaded) {
              if (state.requests.isEmpty) {
                return const Center(child: Text('No requests found'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<RequestListCubit>().loadFirstPage();
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
                               int seriesIndex = segments.indexOf('series');
                               if (seriesIndex != -1 && seriesIndex + 1 < segments.length) {
                                   final slug = segments[seriesIndex + 1];
                                   AppRouter.goToContentDetail(context, slug, sourceId: SourceType.crotpedia.id);
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
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                              ),
                            ),
                            
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(request.status, context).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _getStatusColor(request.status, context),
                                        ),
                                      ),
                                      child: Text(
                                        request.status,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: _getStatusColor(request.status, context),
                                          fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    final s = status.toLowerCase();
    if (s.contains('open') || s.contains('ongoing')) {
      return Colors.green;
    } else if (s.contains('close') || s.contains('drop') || s.contains('completed')) {
      return Colors.red;
    } else if (s.contains('pending')) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.primary;
  }
}
