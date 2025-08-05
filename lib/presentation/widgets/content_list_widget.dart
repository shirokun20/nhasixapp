import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../../domain/entities/entities.dart';
import '../blocs/content/content_bloc.dart';

/// Widget that displays a grid of content with pagination support
/// Designed to work with PaginationWidget for page navigation
class ContentListWidget extends StatefulWidget {
  const ContentListWidget({
    super.key,
    this.onContentTap,
    this.enablePullToRefresh = true,
    this.enableInfiniteScroll = false, // Disabled by default for pagination
  });

  final void Function(Content content)? onContentTap;
  final bool enablePullToRefresh;
  final bool enableInfiniteScroll;

  @override
  State<ContentListWidget> createState() => _ContentListWidgetState();
}

class _ContentListWidgetState extends State<ContentListWidget> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

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
    // Only setup infinite scroll if enabled
    if (widget.enableInfiniteScroll) {
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
  }

  void _onRefresh() {
    if (_isRefreshing) return; // Prevent multiple refresh calls

    _isRefreshing = true;
    final currentState = context.read<ContentBloc>().state;
    if (currentState is ContentLoaded) {
      // Refresh current page instead of going back to page 1
      context
          .read<ContentBloc>()
          .add(ContentGoToPageEvent(currentState.currentPage));
    } else {
      context.read<ContentBloc>().add(const ContentRefreshEvent());
    }
  }

  void _onLoadMore() {
    context.read<ContentBloc>().add(const ContentLoadMoreEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContentBloc, ContentState>(
      listener: (context, state) {
        if (state is ContentLoaded) {
          // Complete refresh if we were refreshing
          if (_isRefreshing) {
            // Only call SmartRefresher methods if infinite scroll is enabled
            if (widget.enableInfiniteScroll) {
              _refreshController.refreshCompleted();
            }
            _isRefreshing = false;
          }

          if (state.isLoadingMore && widget.enableInfiniteScroll) {
            // Load more completed (only for infinite scroll)
            _refreshController.loadComplete();
          }
        } else if (state is ContentError) {
          // Reset refresh state and notify controller
          if (_isRefreshing) {
            if (widget.enableInfiniteScroll) {
              _refreshController.refreshFailed();
            }
            _isRefreshing = false;
          }

          if (widget.enableInfiniteScroll) {
            _refreshController.loadFailed();
          }

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

        if (state is ContentLoading) {
          // Show overlay loading for pagination changes if we have previous content
          if (state.previousContents != null &&
              state.previousContents!.isNotEmpty) {
            return Stack(
              children: [
                // Show previous content with reduced opacity
                Opacity(
                  opacity: 0.3,
                  child: _buildContentGrid(ContentLoaded(
                    contents: state.previousContents!,
                    currentPage: 1, // Temporary values
                    totalPages: 1,
                    totalCount: state.previousContents!.length,
                    hasNext: false,
                    hasPrevious: false,
                    sortBy: SortOption.newest,
                    lastUpdated: DateTime.now(),
                  )),
                ),
                // Loading overlay
                Container(
                  color: ColorsConst.darkBackground.withValues(alpha: 0.7),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsConst.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorsConst.darkBackground
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: ColorsConst.accentBlue,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            state.message.isNotEmpty
                                ? state.message
                                : 'Loading...',
                            style: TextStyleConst.bodyMedium.copyWith(
                              color: ColorsConst.darkTextPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Full loading for initial load
          return Container(
            color: ColorsConst.darkBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: ColorsConst.accentBlue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state.message.isNotEmpty
                        ? state.message
                        : 'Loading content...',
                    style: TextStyleConst.bodyLarge.copyWith(
                      color: ColorsConst.darkTextPrimary,
                    ),
                  ),
                ],
              ),
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
          // For pagination mode, we don't use SmartRefresher at all
          // Only use SmartRefresher when infinite scroll is explicitly enabled
          if (widget.enableInfiniteScroll) {
            return SmartRefresher(
              controller: _refreshController,
              enablePullDown: widget.enablePullToRefresh,
              enablePullUp: widget.enableInfiniteScroll && state.hasNext,
              onRefresh: _onRefresh,
              onLoading: _onLoadMore,
              header: widget.enablePullToRefresh
                  ? const WaterDropMaterialHeader()
                  : null,
              footer: CustomFooter(
                builder: (context, mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = const Text("Pull up to load more");
                  } else if (mode == LoadStatus.loading) {
                    body = const CircularProgressIndicator(
                        color: ColorsConst.accentBlue);
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
              child: _buildContentGrid(state),
            );
          } else {
            // Simple grid for pagination mode
            // For pagination, we use pagination controls instead of pull-to-refresh
            return _buildContentGrid(state);
          }
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Build the content grid layout
  Widget _buildContentGrid(ContentLoaded state) {
    return CustomScrollView(
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
                        style: TextStyleConst.bodyLarge.copyWith(
                          color: ColorsConst.darkTextPrimary,
                        ),
                      ),
                      Text(
                        '${state.totalCount} items • Page ${state.currentPage} of ${state.totalPages}',
                        style: TextStyleConst.bodySmall.copyWith(
                          color: ColorsConst.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.lastUpdated != null)
                  Text(
                    'Updated: ${_formatTime(state.lastUpdated!)}',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: ColorsConst.darkTextTertiary,
                    ),
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

        // Loading more indicator (only for infinite scroll)
        if (widget.enableInfiniteScroll && state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: ColorsConst.accentBlue),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
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
      color: ColorsConst.darkCard,
      elevation: 2,
      shadowColor: ColorsConst.darkBackground.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        splashColor: ColorsConst.accentBlue.withValues(alpha: 0.1),
        highlightColor: ColorsConst.hoverColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ColorsConst.darkElevated,
                ),
                child: content.coverUrl.isNotEmpty
                    ? Image.network(
                        content.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image,
                            size: 48,
                            color: ColorsConst.darkTextTertiary,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: ColorsConst.accentBlue,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: ColorsConst.darkTextTertiary,
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
                      style: TextStyleConst.bodySmall.copyWith(
                        color: ColorsConst.darkTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Artist
                    if (content.artists.isNotEmpty)
                      Text(
                        content.artists.join(', ').capitalize,
                        style: TextStyleConst.bodySmall.copyWith(
                          color: ColorsConst.accentBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Bottom info
                    Row(
                      children: [
                        const Spacer(),
                        if (content.language.isNotEmpty)
                          Image.asset(
                            'assets/images/${content.language.toLowerCase()}.gif', width: 30,),
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
