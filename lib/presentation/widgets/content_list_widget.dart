import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/constants/text_style_const.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import '../../domain/entities/entities.dart';
import '../../services/local_image_preloader.dart';
import '../blocs/content/content_bloc.dart';
import '../blocs/download/download_bloc.dart'; // 🐛 FIXED: Added import for DownloadBloc
import '../cubits/settings/settings_cubit.dart';
import 'content_card_widget.dart';
import 'featured_content_card.dart';

extension StringCapitalize on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Cache for download status to prevent repeated file system checks
/// Public class to allow cache invalidation from other components
/// 🐛 FIXED: Use DownloadBloc state as single source of truth to prevent false positives
class ContentDownloadCache {
  static final Map<String, bool> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static Future<bool> isDownloaded(String contentId,
      [BuildContext? context]) async {
    // Check cache first
    if (_cache.containsKey(contentId)) {
      final cacheTime = _cacheTime[contentId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _cache[contentId]!;
      }
    }

    // 🐛 FIXED: Priority 1 - Check DownloadBloc state (single source of truth)
    bool isDownloaded = false;
    if (context != null && context.mounted) {
      try {
        final downloadState = context.read<DownloadBloc>().state;
        if (downloadState is DownloadLoaded) {
          isDownloaded = downloadState.isDownloaded(contentId);

          // Cache DownloadBloc result as it's authoritative
          _cache[contentId] = isDownloaded;
          _cacheTime[contentId] = DateTime.now();

          return isDownloaded;
        }
      } catch (e) {
        // DownloadBloc not available or context invalid, fallback to filesystem check
        Logger().w(
            'Failed to read DownloadBloc state, falling back to filesystem check: $e');
      }
    }

    // Priority 2 - Fallback to filesystem check only when DownloadBloc unavailable
    try {
      isDownloaded = await LocalImagePreloader.isContentDownloaded(contentId);

      // Cache result
      _cache[contentId] = isDownloaded;
      _cacheTime[contentId] = DateTime.now();

      return isDownloaded;
    } catch (e) {
      // If error checking, assume not downloaded and cache negative result briefly
      _cache[contentId] = false;
      _cacheTime[contentId] = DateTime.now();
      return false;
    }
  }

  /// Invalidate cache for specific content to force refresh
  static void invalidateCache(String contentId) {
    _cache.remove(contentId);
    _cacheTime.remove(contentId);
  }

  /// Clear all cache entries
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}

/// Widget that displays a grid of content with pagination support
/// Designed to work with PaginationWidget for page navigation
///
/// Usage:
/// - Main screen: showHeader = false (default) - clean design like nhentai main page
/// - Search/Browse: showHeader = true - shows metadata and pagination info
/// - Content cards: showUploadDate controlled per card basis
class ContentListWidget extends StatefulWidget {
  const ContentListWidget({
    super.key,
    this.onContentTap,
    this.enablePullToRefresh = true,
    this.enableInfiniteScroll = false, // Disabled by default for pagination
    this.showHeader = false, // Hidden by default for main screen style
    this.shouldBlurContent, // NEW: Function to determine if content should be blurred
    this.shouldHighlightContent, // NEW: Function to determine if content should be highlighted
    this.highlightReason, // NEW: Function to get highlight reason
  });

  final void Function(Content content)? onContentTap;
  final bool enablePullToRefresh;
  final bool enableInfiniteScroll;
  final bool showHeader;
  final bool Function(Content content)? shouldBlurContent; // NEW: Blur logic
  final bool Function(Content content)?
      shouldHighlightContent; // NEW: Highlight logic
  final String? Function(Content content)?
      highlightReason; // NEW: Highlight reason logic

  @override
  State<ContentListWidget> createState() => _ContentListWidgetState();
}

class _ContentListWidgetState extends State<ContentListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContentBloc, ContentState>(
      listener: (context, state) {
        if (state is ContentError) {
          // Reset refresh state and notify controller
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              action: state.canRetry
                  ? SnackBarAction(
                      label: AppLocalizations.of(context)!.retry,
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
              AppLocalizations.of(context)!.tapToLoadContent,
              style: TextStyleConst.placeholderText.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  state.contextualMessage,
                  textAlign: TextAlign.center,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.suggestions.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.suggestions,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...state.suggestions.map((suggestion) => Text(
                        '• $suggestion',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                    child: Text(AppLocalizations.of(context)!.tryAgain),
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
                  style: TextStyleConst.displayMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
                if (state.hasPreviousContent) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Show cached content
                      // This would require additional implementation
                    },
                    child:
                        Text(AppLocalizations.of(context)!.showCachedContent),
                  ),
                ],
              ],
            ),
          );
        }

        if (state is ContentLoaded) {
          return _buildContentGrid(state);
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
        // Content type header (conditional based on showHeader parameter)
        if (widget.showHeader)
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${state.totalCount} ${AppLocalizations.of(context)?.content ?? 'items'} • ${AppLocalizations.of(context)?.pageOf ?? 'Page'} ${state.currentPage} ${AppLocalizations.of(context)?.ofWord ?? 'of'} ${state.totalPages}',
                          style: TextStyleConst.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.lastUpdated != null)
                    Text(
                      '${AppLocalizations.of(context)!.lastUpdatedLabel} ${_formatTime(state.lastUpdated!)}',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Featured content card (first item displayed as full-width)
        if (state.contents.isNotEmpty && state.currentPage == 1)
          SliverToBoxAdapter(
            child: FeaturedContentCard(
              content: state.contents.first,
              onTap: () => widget.onContentTap?.call(state.contents.first),
            ),
          ),

        // Content grid (skip first item if on page 1 since it's featured)
        SliverPadding(
          padding: EdgeInsets.all(widget.showHeader ? 8.0 : 16.0),
          sliver: SliverGrid(
            gridDelegate: ResponsiveGridDelegate.createGridDelegate(
              context,
              context.read<SettingsCubit>(),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Skip index 0 on page 1 (already shown as featured)
                final adjustedIndex =
                    state.currentPage == 1 ? index + 1 : index;
                if (adjustedIndex >= state.contents.length) {
                  return const SizedBox.shrink();
                }
                final content = state.contents[adjustedIndex];

                // Use FutureBuilder to check download status for highlight
                return FutureBuilder<bool>(
                  future: ContentDownloadCache.isDownloaded(content.id,
                      context), // 🐛 FIXED: Pass context for DownloadBloc access
                  builder: (context, snapshot) {
                    final isDownloaded = snapshot.data ?? false;

                    return ContentCard(
                      content: content,
                      onTap: () => widget.onContentTap?.call(content),
                      // Using default settings (showUploadDate: false) for main screen style
                      // For search/browse screens, set showUploadDate: true
                      isBlurred: widget.shouldBlurContent?.call(content) ??
                          false, // NEW: Apply blur logic
                      isHighlighted:
                          isDownloaded, // NEW: Highlight downloaded content instead of search match
                      highlightReason: isDownloaded
                          ? AppLocalizations.of(context)!.downloaded
                          : null, // NEW: Indicate download status
                    );
                  },
                );
              },
              // Reduce child count by 1 on first page (featured card is separate)
              childCount: state.currentPage == 1
                  ? (state.contents.length > 1 ? state.contents.length - 1 : 0)
                  : state.contents.length,
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
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inHours < 1) {
      return AppLocalizations.of(context)!.minutesAgo(
          difference.inMinutes, difference.inMinutes == 1 ? '' : 's');
    } else if (difference.inDays < 1) {
      return AppLocalizations.of(context)!
          .hoursAgo(difference.inHours, difference.inHours == 1 ? '' : 's');
    } else {
      return AppLocalizations.of(context)!
          .daysAgo(difference.inDays, difference.inDays == 1 ? '' : 's');
    }
  }
}

// ContentCard is now imported from content_card_widget.dart
