import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';
import '../blocs/content/content_bloc.dart';

/// Widget that displays a list of content with pull-to-refresh and infinite scrolling
class ContentListWidget extends StatefulWidget {
  const ContentListWidget({
    super.key,
    this.onContentTap,
    this.showLoadMoreButton = false,
  });

  final void Function(Content content)? onContentTap;
  final bool showLoadMoreButton;

  @override
  State<ContentListWidget> createState() => _ContentListWidgetState();
}

class _ContentListWidgetState extends State<ContentListWidget> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when near bottom
        final state = context.read<ContentBloc>().state;
        if (state is ContentLoaded && state.canLoadMore) {
          context.read<ContentBloc>().add(const ContentLoadMoreEvent());
        }
      }
    });
  }

  void _onRefresh() {
    context.read<ContentBloc>().add(const ContentRefreshEvent());
  }

  void _onLoadMore() {
    context.read<ContentBloc>().add(const ContentLoadMoreEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContentBloc, ContentState>(
      listener: (context, state) {
        if (state is ContentLoaded) {
          if (state.isRefreshing) {
            // Refresh completed
            _refreshController.refreshCompleted();
          }
          if (state.isLoadingMore) {
            // Load more completed
            _refreshController.loadComplete();
          }
        } else if (state is ContentError) {
          _refreshController.refreshFailed();
          _refreshController.loadFailed();

          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              action: state.canRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        context
                            .read<ContentBloc>()
                            .add(const ContentRetryEvent());
                      },
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ContentInitial) {
          return Center(
            child: Text(
              'Tap to load content',
              style: TextStyleConst.placeholderText,
            ),
          );
        }

        if (state is ContentLoading &&
            state.message.contains('Loading content')) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: ColorsConst.accentBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading content...',
                  style: TextStyleConst.loadingText,
                ),
              ],
            ),
          );
        }

        if (state is ContentEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  state.contextualMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.suggestions.isNotEmpty) ...[
                  Text(
                    'Suggestions:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  ...state.suggestions.map((suggestion) => Text(
                        '• $suggestion',
                        style: Theme.of(context).textTheme.bodySmall,
                      )),
                ],
                if (state.canRetry) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ContentBloc>()
                          .add(const ContentRetryEvent());
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ],
            ),
          );
        }

        if (state is ContentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorIcon,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  state.errorType.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.userFriendlyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (state.canRetry) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ContentBloc>()
                          .add(const ContentRetryEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
                if (state.hasPreviousContent) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Show cached content
                      // This would require additional implementation
                    },
                    child: const Text('Show Cached Content'),
                  ),
                ],
              ],
            ),
          );
        }

        if (state is ContentLoaded) {
          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: state.hasNext && !widget.showLoadMoreButton,
            onRefresh: _onRefresh,
            onLoading: _onLoadMore,
            header: const WaterDropMaterialHeader(),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget body;
                if (mode == LoadStatus.idle) {
                  body = const Text("Pull up to load more");
                } else if (mode == LoadStatus.loading) {
                  body = const CircularProgressIndicator();
                } else if (mode == LoadStatus.failed) {
                  body = const Text("Load Failed! Click retry!");
                } else if (mode == LoadStatus.canLoading) {
                  body = const Text("Release to load more");
                } else {
                  body = const Text("No more content");
                }
                return SizedBox(
                  height: 55.0,
                  child: Center(child: body),
                );
              },
            ),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Content type header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.contentTypeDescription,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${state.totalCount} items • Page ${state.currentPage} of ${state.totalPages}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (state.lastUpdated != null)
                          Text(
                            'Updated: ${_formatTime(state.lastUpdated!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),

                // Content grid
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final content = state.contents[index];
                      return ContentCard(
                        content: content,
                        onTap: () => widget.onContentTap?.call(content),
                      );
                    },
                    childCount: state.contents.length,
                  ),
                ),

                // Loading more indicator
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // Load more button (alternative to pull-up)
                if (widget.showLoadMoreButton &&
                    state.hasNext &&
                    !state.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _onLoadMore,
                        child: const Text('Load More'),
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Individual content card widget
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
  });

  final Content content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: content.coverUrl.isNotEmpty
                    ? Image.network(
                        content.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 48,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 48,
                      ),
              ),
            ),

            // Content info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      content.getDisplayTitle(),
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Artist
                    if (content.artists.isNotEmpty)
                      Text(
                        content.artists.first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Bottom info
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${content.pageCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (content.language.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              content.language.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
