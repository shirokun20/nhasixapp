import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/constants/text_style_const.dart';
import '../../core/di/service_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/responsive_grid_delegate.dart';
import '../../core/utils/title_parser_utils.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../../services/local_image_preloader.dart';
import '../blocs/content/content_bloc.dart';
import '../blocs/download/download_bloc.dart'; // 🐛 FIXED: Added import for DownloadBloc
import '../cubits/settings/settings_cubit.dart';
import '../pages/main/widgets/main_featured_card.dart';
import '../pages/main/widgets/main_grid_card.dart';

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

  static String _buildCacheKey(String contentId, String? sourceId) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    return '$normalizedSource::$contentId';
  }

  static bool _matchesCompletedDownload(
    DownloadStatus download,
    String contentId, {
    String? sourceId,
  }) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    final downloadSource = (download.sourceId ?? '').trim().toLowerCase();

    if (normalizedSource.isNotEmpty && downloadSource != normalizedSource) {
      return false;
    }

    if (download.contentId == contentId) {
      return true;
    }

    // Chapter-based sources keep completed download IDs as composite values
    // like "slug/17". Highlight the parent series card when any descendant
    // chapter under the same source has been downloaded.
    return download.contentId.startsWith('$contentId/');
  }

  static Future<bool> isDownloaded(
    String contentId, {
    String? sourceId,
    BuildContext? context,
  }) async {
    final cacheKey = _buildCacheKey(contentId, sourceId);

    // Priority 1 - Read DownloadBloc state when available. This is both the
    // cheapest and most accurate source because it already reflects source-aware
    // completed downloads in memory.
    if (context != null && context.mounted) {
      try {
        final downloadState = context.read<DownloadBloc>().state;
        if (downloadState is DownloadLoaded) {
          final isDownloaded = downloadState.completedDownloads.any(
            (download) => _matchesCompletedDownload(
              download,
              contentId,
              sourceId: sourceId,
            ),
          );

          _cache[cacheKey] = isDownloaded;
          _cacheTime[cacheKey] = DateTime.now();
          return isDownloaded;
        }
      } catch (e) {
        Logger().w(
          'Failed to read DownloadBloc state, falling back to cached/filesystem check: $e',
        );
      }
    }

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _cache[cacheKey]!;
      }
    }

    bool isDownloaded = false;

    // Priority 2 - Fallback to filesystem check only when DownloadBloc is not
    // reachable. This remains an exact content ID check; chapter-descendant
    // matching is intentionally handled from DownloadBloc state to avoid doing
    // expensive directory scans for every card build.
    try {
      isDownloaded = await LocalImagePreloader.isContentDownloaded(contentId);

      // Cache result
      _cache[cacheKey] = isDownloaded;
      _cacheTime[cacheKey] = DateTime.now();

      return isDownloaded;
    } catch (e) {
      // If error checking, assume not downloaded and cache negative result briefly
      _cache[cacheKey] = false;
      _cacheTime[cacheKey] = DateTime.now();
      return false;
    }
  }

  /// Invalidate cache for specific content to force refresh
  static void invalidateCache(String contentId, {String? sourceId}) {
    if (sourceId != null) {
      final cacheKey = _buildCacheKey(contentId, sourceId);
      _cache.remove(cacheKey);
      _cacheTime.remove(cacheKey);
      return;
    }

    final suffix = '::$contentId';
    final keysToRemove =
        _cache.keys.where((key) => key.endsWith(suffix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTime.remove(key);
    }
  }

  /// Clear all cache entries
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}

/// Cache for read status to avoid repeated history lookups per card build.
class ContentReadCache {
  static final Map<String, double?> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static String _buildCacheKey(String contentId, String? sourceId) {
    final normalizedSource = (sourceId ?? '').trim().toLowerCase();
    return '$normalizedSource::$contentId';
  }

  static bool _isValidProgress(History history, String? sourceId) {
    if (sourceId != null &&
        sourceId.trim().isNotEmpty &&
        history.sourceId.trim().toLowerCase() !=
            sourceId.trim().toLowerCase()) {
      return false;
    }
    return history.isCompleted || history.progress > 0;
  }

  static double _normalizeProgress(History history) {
    if (history.isCompleted) return 1.0;
    return history.progress.clamp(0.0, 1.0);
  }

  static Future<double?> readProgress(
    Content content,
  ) async {
    final contentId = content.id;
    final sourceId = content.sourceId;
    final cacheKey = _buildCacheKey(contentId, sourceId);

    if (_cache.containsKey(cacheKey)) {
      final cacheTime = _cacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _cache[cacheKey];
      }
    }

    try {
      final userDataRepository = getIt<UserDataRepository>();

      final history = await userDataRepository.getHistoryEntry(contentId);
      if (history != null && _isValidProgress(history, sourceId)) {
        final progress = _normalizeProgress(history);
        _cache[cacheKey] = progress;
        _cacheTime[cacheKey] = DateTime.now();
        return progress;
      }

      final chapterHistory =
          await userDataRepository.getAllChapterHistory(contentId);
      final chapterProgress = chapterHistory
          .where((item) => _isValidProgress(item, sourceId))
          .map(_normalizeProgress)
          .fold<double?>(null, (previous, value) {
        if (previous == null || value > previous) return value;
        return previous;
      });
      if (chapterProgress != null) {
        _cache[cacheKey] = chapterProgress;
        _cacheTime[cacheKey] = DateTime.now();
        return chapterProgress;
      }

      final cardBaseTitle =
          TitleParserUtils.getBaseTitle(content.getDisplayTitle())
              .toLowerCase();
      final recentHistory = await userDataRepository.getHistory(limit: 100);
      History? matchedHistory;
      for (final item in recentHistory) {
        if (sourceId.isNotEmpty &&
            item.sourceId.trim().toLowerCase() != sourceId.toLowerCase()) {
          continue;
        }

        final historyTitle = item.title?.trim();
        if (historyTitle == null || historyTitle.isEmpty) continue;
        if (TitleParserUtils.getBaseTitle(historyTitle).toLowerCase() ==
            cardBaseTitle) {
          matchedHistory = item;
          break;
        }
      }
      if (matchedHistory != null &&
          _isValidProgress(matchedHistory, sourceId)) {
        final progress = _normalizeProgress(matchedHistory);
        _cache[cacheKey] = progress;
        _cacheTime[cacheKey] = DateTime.now();
        return progress;
      }
    } catch (e) {
      Logger().w('Failed to resolve read progress for $contentId: $e');
    }

    _cache[cacheKey] = null;
    _cacheTime[cacheKey] = DateTime.now();
    return null;
  }

  static void invalidateCache(String contentId, {String? sourceId}) {
    if (sourceId != null) {
      final cacheKey = _buildCacheKey(contentId, sourceId);
      _cache.remove(cacheKey);
      _cacheTime.remove(cacheKey);
      return;
    }

    final suffix = '::$contentId';
    final keysToRemove =
        _cache.keys.where((key) => key.endsWith(suffix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTime.remove(key);
    }
  }

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
    this.blurThumbnails = false,
    this.shouldBlurContent, // NEW: Function to determine if content should be blurred
    this.shouldHighlightContent, // NEW: Function to determine if content should be highlighted
    this.highlightReason, // NEW: Function to get highlight reason
  });

  final void Function(Content content)? onContentTap;
  final bool enablePullToRefresh;
  final bool enableInfiniteScroll;
  final bool showHeader;
  final bool blurThumbnails;
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
          final l10n = AppLocalizations.of(context)!;

          // Resolve l10n key from message
          String getDisplayMessage(String key) {
            switch (key) {
              case 'noContentAtMoment':
                return l10n.noContentAtMoment;
              case 'noContentMatchingSearch':
                return l10n.noContentMatchingSearch;
              case 'noPopularContent':
                return l10n.noPopularContent;
              case 'noContentForTag':
                return l10n.noContentForTag;
              case 'noContentOnPage':
                return l10n.noContentOnPage;
              default:
                return key;
            }
          }

          // Resolve suggestion keys to l10n
          List<String> getSuggestions(List<String> keys) {
            return keys.map((key) {
              switch (key) {
                case 'tryAdjustingFilters':
                  return l10n.tryAdjustingFilters;
                case 'tryRemovingSomeFilters':
                  return l10n.tryAdjustingFilters;
                case 'tryBrowsingOtherTags':
                  return l10n.tryBrowsingOtherTags;
                case 'checkPopularContent':
                  return l10n.checkPopularContent;
                case 'checkInternetConnection':
                  return l10n.checkInternetConnectionSuggestion;
                case 'checkInternetConnectionSuggestion':
                  return l10n.checkInternetConnectionSuggestion;
                case 'tryADifferentSearchTerm':
                  return l10n.tryADifferentSearchTerm;
                default:
                  return key;
              }
            }).toList();
          }

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
                  getDisplayMessage(state.message),
                  textAlign: TextAlign.center,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.suggestions.isNotEmpty) ...[
                  Text(
                    l10n.suggestions,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...getSuggestions(state.suggestions).map((suggestion) => Text(
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
                    child: Text(l10n.tryAgain),
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
            child: Builder(
              builder: (context) {
                final isBlacklisted =
                    widget.shouldBlurContent?.call(state.contents.first) ??
                        false;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: MainFeaturedCard(
                    content: state.contents.first,
                    onTap: () =>
                        widget.onContentTap?.call(state.contents.first),
                    blurThumbnails: widget.blurThumbnails,
                    isBlacklisted: isBlacklisted,
                  ),
                );
              },
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

                final isBlacklisted =
                    widget.shouldBlurContent?.call(content) ?? false;
                return MainGridCard(
                  content: content,
                  onTap: () => widget.onContentTap?.call(content),
                  blurThumbnails: widget.blurThumbnails,
                  isBlacklisted: isBlacklisted,
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
