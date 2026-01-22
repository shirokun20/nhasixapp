import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart';
import 'package:nhasixapp/presentation/blocs/download/download_bloc.dart';
import 'package:nhasixapp/core/utils/app_state_manager.dart';
import 'package:nhasixapp/presentation/cubits/source/source_cubit.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../widgets/download_button_widget.dart';
import '../../widgets/progressive_image_widget.dart';
import '../../widgets/shimmer_loading_widgets.dart';


class DetailScreen extends StatefulWidget {
  final String contentId;
  final String? sourceId;

  const DetailScreen({
    super.key,
    required this.contentId,
    this.sourceId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailCubit _detailCubit;
  final ScrollController _scrollController = ScrollController();
  bool _isNavigating =
      false; // Add navigation lock to prevent multiple simultaneous navigation

  @override
  void initState() {
    super.initState();
    _detailCubit = getIt<DetailCubit>();

    // Check if we need to switch source first
    if (widget.sourceId != null) {
      final sourceCubit = context.read<SourceCubit>();
      final currentSourceId = sourceCubit.state.activeSource?.id;

      if (currentSourceId != null &&
          currentSourceId != widget.sourceId &&
          // Don't switch if IDs are same (redundant check but safe)
          currentSourceId != widget.sourceId) {
        Logger().i(
            'DetailScreen: Switching source from $currentSourceId to ${widget.sourceId}');
        sourceCubit.switchSource(widget.sourceId!);
      }
    }

    // Load content detail first, then load related content separately
    _loadContentAndRelated();

    // Initialize download manager if not already initialized
    final downloadBloc = context.read<DownloadBloc>();
    if (downloadBloc.state is DownloadInitial) {
      downloadBloc.add(const DownloadInitializeEvent());
    }
  }

  /// Load content detail and related content as separate API calls
  Future<void> _loadContentAndRelated() async {
    // First call: Load main content detail
    await _detailCubit.loadContentDetail(widget.contentId);

    // Second call: Load related content independently
    if (mounted && _detailCubit.state is DetailLoaded) {
      _detailCubit.loadRelatedContent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _detailCubit.close();
    super.dispose();
  }

  /// Navigate to tag browsing mode (SIMPLIFIED routing)
  /// Navigate to tag browsing mode (SIMPLIFIED routing)
  void _searchByTag(String tagName,
      {String? tagId, String? tagType, String? sourceId}) async {
    // Prevent multiple simultaneous navigation attempts
    if (_isNavigating) {
      Logger()
          .w("Navigation already in progress, ignoring tag search: $tagName");
      return;
    }

    try {
      _isNavigating = true;

      String query = tagName;
      final actualSourceId = sourceId ??
          ((context.read<DetailCubit>().state is DetailLoaded)
              ? (context.read<DetailCubit>().state as DetailLoaded)
                  .content
                  .sourceId
              : 'nhentai');

      if (actualSourceId == SourceType.crotpedia.id) {
        // SPECIAL HANDLING FOR CROTPEDIA GENRES
        // Crotpedia supports specific genre browsing via /baca/genre/slug/
        // We pass 'genre:slug' as query, which CrotpediaSource intercepts.
        final slug = tagName.toLowerCase().replaceAll(' ', '-');
        query = 'genre:$slug';
      } else if (actualSourceId == 'nhentai') {
        // SPECIAL HANDLING FOR NHENTAI
        // User requested strict slug format: lowercase + hyphens
        // e.g. "Big Breasts" -> "big-breasts", "Lucy Heartfilia" -> "lucy-heartfilia"
        
        // Prioritize explicit slug/tagId if it's text (not numeric ID)
        String value = tagName.toLowerCase().replaceAll(' ', '-');
        if (tagId != null && int.tryParse(tagId) == null) {
           value = tagId;
        }

        if (tagType != null &&
            !['tag', 'category'].contains(tagType.toLowerCase())) {
           // type:slug syntax (e.g. artist:shidou, character:lucy-heartfilia)
           query = '${tagType.toLowerCase()}:$value';
        } else {
           // General tags: just the slug (e.g. big-breasts)
           // This will map to "q=big-breasts" in search
           query = value;
        }
      }

      // Navigate to ContentByTagScreen
      if (mounted) {
        AppRouter.goToContentByTag(context, query);
      } else {
        Logger().w("Widget unmounted before navigation for tag: $tagName");
      }
    } catch (e, stackTrace) {
      Logger().e("Error navigating to tag: $tagName",
          error: e, stackTrace: stackTrace);

      // Handle error gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorBrowsingTag),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _detailCubit,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // Handle custom pop logic if needed
            context.pop();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: StreamBuilder<bool>(
            // Listen to offline mode changes
            stream: AppStateManager().offlineModeStream,
            initialData: AppStateManager().isOfflineMode,
            builder: (context, offlineSnapshot) {
              final isOfflineMode = offlineSnapshot.data ?? false;

              return BlocListener<DetailCubit, DetailState>(
                listener: (context, state) {
                  if (state is DetailReaderReady) {
                    _readContent(state.chapterContent,
                        forceStartFromBeginning: true);
                    context.read<DetailCubit>().resetToLoaded();
                  } else if (state is DetailActionFailure) {
                    if (state.needsLogin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .loginRequiredForAction),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: AppLocalizations.of(context)!.login,
                            onPressed: () {
                              context.push('/crotpedia-login');
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    context.read<DetailCubit>().resetToLoaded();
                  } else if (state is DetailNeedsLogin) {
                    // Legacy support or fallback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Login required for this action'),
                        action: SnackBarAction(
                          label: 'Login',
                          onPressed: () {
                            context.push('/crotpedia-login');
                          },
                        ),
                      ),
                    );
                  }

                  if (state is DetailLoaded &&
                      state.content.sourceId == SourceType.crotpedia.id &&
                      state.isFavorited &&
                      !state.isTogglingFavorite) {
                    // This is where we might check if user was prompted to login
                    // and came back? Not strictly needed if Cubit handles it.
                  }
                },
                child: BlocBuilder<DetailCubit, DetailState>(
                  builder: (context, state) {
                    if (state is DetailLoading) {
                      return _buildLoadingState(context);
                    } else if (state is DetailLoaded) {
                      return Stack(
                        children: [
                          _buildDetailContent(state, isOfflineMode),
                          if (state is DetailOpeningChapter)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      );
                    } else if (state is DetailError) {
                      return _buildErrorState(state);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.loadingContentTitle,
          style: TextStyleConst.headingMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      body: const DetailScreenShimmer(),
    );
  }

  Widget _buildDetailContent(DetailLoaded state, bool isOfflineMode) {
    final content = state.content;

    return Column(children: [
      // Offline banner
      if (isOfflineMode)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.youAreOffline,
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showGoOnlineDialog(context),
                child: Text(
                  AppLocalizations.of(context)!.goOnline,
                  style: TextStyleConst.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      // Main content
      Expanded(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App bar with cover image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => context.pop(),
              ),
              actions: [
                // Offline indicator badge
                if (isOfflineMode)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.wifi_off,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      onPressed: () => _showGoOnlineDialog(context),
                      tooltip: AppLocalizations.of(context)!
                          .youAreOfflineTapToGoOnline,
                    ),
                  ),
                // Favorite button with feature flag check
                BlocBuilder<DetailCubit, DetailState>(
                  builder: (context, detailState) {
                    if (detailState is! DetailLoaded) {
                      return const SizedBox.shrink();
                    }
                    
                    final remoteConfig = getIt<RemoteConfigService>();
                    final favoriteEnabled = remoteConfig.isFeatureEnabled(
                      detailState.content.sourceId,
                      (f) => f.favorite,
                    );
                    
                    return IconButton(
                      icon: Icon(
                        detailState.isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: detailState.isFavorited
                            ? Theme.of(context).colorScheme.error
                            : (favoriteEnabled
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
                      onPressed: (detailState.isTogglingFavorite || !favoriteEnabled)
                          ? null
                          : () {
                              if (!favoriteEnabled) {
                                _showFeatureDisabledDialog('favorite');
                                return;
                              }
                              _detailCubit.toggleFavorite();
                            },
                    );
                  },
                ),
                // Share button
                IconButton(
                  icon: Icon(Icons.share,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => _shareContent(content),
                ),
                // More options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurface),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  onSelected: (value) => _handleMenuAction(value, content),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.download,
                            style: TextStyleConst.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_link',
                      child: Row(
                        children: [
                          Icon(Icons.link,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.copyLink,
                            style: TextStyleConst.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image with progressive loading
                    ProgressiveImageWidget(
                      networkUrl: content.imageUrls.isNotEmpty
                          ? content.imageUrls.first
                          : content.coverUrl,
                      contentId: content.id,
                      pageNumber: content.imageUrls.isNotEmpty ? 1 : null,
                      isThumbnail: false,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      memCacheHeight: 1200,
                      placeholder: Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    _buildTitleSection(content),
                    const SizedBox(height: 24),

                    // Metadata section
                    _buildMetadataSection(content),
                    const SizedBox(height: 24),

                    // Tags section
                    _buildTagsSection(content),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(content),
                    const SizedBox(height: 24),

                    // Statistics section
                    _buildStatisticsSection(content),
                    const SizedBox(height: 32),

                    // Related content section
                    if (content.relatedContent.isNotEmpty) ...[
                      _buildRelatedContentSection(content),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildTitleSection(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyleConst.headingLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.3,
          ),
        ),
        if (content.englishTitle != null &&
            content.englishTitle != content.title) ...[
          const SizedBox(height: 8),
          Text(
            content.englishTitle!,
            style: TextStyleConst.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (content.japaneseTitle != null &&
            content.japaneseTitle != content.title) ...[
          const SizedBox(height: 4),
          Text(
            content.japaneseTitle!,
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataSection(Content content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.contentInformation,
                style: TextStyleConst.headingMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Metadata rows with enhanced styling
          _buildMetadataRow('Source', content.source, Icons.dns_rounded),
          _buildMetadataRow(
              AppLocalizations.of(context)!.idLabel, content.id, Icons.tag),
          _buildMetadataRow(AppLocalizations.of(context)!.pagesLabel,
              '${content.pageCount}', Icons.menu_book),
          _buildMetadataRow(AppLocalizations.of(context)!.languageLabel,
              content.language.toLowerCase(), Icons.language),
          if (content.artists.isNotEmpty)
            _buildMetadataRow(AppLocalizations.of(context)!.artistLabel,
                content.artists.join(', '), Icons.person),
          if (content.characters.isNotEmpty)
            _buildMetadataRow(AppLocalizations.of(context)!.charactersLabel,
                content.characters.join(', '), Icons.people),
          if (content.parodies.isNotEmpty)
            _buildMetadataRow(AppLocalizations.of(context)!.parodiesLabel,
                content.parodies.join(', '), Icons.movie),
          if (content.groups.isNotEmpty)
            _buildMetadataRow(AppLocalizations.of(context)!.groupsLabel,
                content.groups.join(', '), Icons.group),
          _buildMetadataRow(AppLocalizations.of(context)!.uploadedLabel,
              _formatDate(content.uploadDate), Icons.schedule),
          _buildMetadataRow(AppLocalizations.of(context)!.favoritesLabel,
              _formatNumber(content.favorites), Icons.favorite),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, [IconData? icon]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyleConst.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyleConst.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(Content content) {
    if (content.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tagsLabel,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: content.tags.map((tag) {
            return GestureDetector(
              onTap: () => _searchByTag(
                tag.name,
                tagId: tag.slug ?? tag.id.toString(),
                tagType: tag.type,
                sourceId: content.sourceId,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTagColor(context, tag.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _getTagColor(context, tag.type).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyleConst.bodyMedium.copyWith(
                        color: _getTagColor(context, tag.type),
                      ),
                    ),
                    if (tag.count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${tag.count}',
                        style: TextStyleConst.overline.copyWith(
                          color: _getTagColor(context, tag.type)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Content content) {
    // Check if chapters feature is enabled for this source
    final remoteConfig = getIt<RemoteConfigService>();
    final hasChaptersFeature = remoteConfig.isFeatureEnabled(content.sourceId, (f) => f.chapters);

    // If content has chapters AND feature is enabled, show chapter list
    if (hasChaptersFeature && content.chapters != null && content.chapters!.isNotEmpty) {
      return _buildChapterList(content);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Read button - primary action
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _readContent(content, forceStartFromBeginning: true),
                icon: const Icon(Icons.menu_book, size: 24),
                label: Text(
                  AppLocalizations.of(context)!.readNow,
                  style: TextStyleConst.headingSmall.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Download button - conditional
          if (getIt<RemoteConfigService>()
              .isFeatureEnabled(content.sourceId, (f) => f.download)) ...[
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: DownloadButtonWidget(
                  content: content,
                  size: DownloadButtonSize.large,
                  showText: true,
                  showProgress: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterList(Content content) {
    final chapters = content.chapters!;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                // Icon with gradient container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chaptersTitle,
                      style: TextStyleConst.headingMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.chapterCount(chapters.length),
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Modern interactive chapter cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];

              // Create Content object for download widget
              final chapterContent = Content(
                id: chapter.id,
                title: '${content.title} - ${chapter.title}',
                coverUrl: content.coverUrl,
                uploadDate: chapter.uploadDate ?? DateTime.now(),
                language: content.language,
                pageCount: 0,
                imageUrls: const [],
                sourceId: content.sourceId,
                relatedContent: const [],
                tags: content.tags,
                artists: content.artists,
                groups: content.groups,
                characters: content.characters,
                parodies: content.parodies,
                favorites: 0,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _detailCubit.openChapter(chapter),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Chapter number badge with gradient
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyleConst.headingSmall.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Chapter info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chapter.title,
                                  style: TextStyleConst.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (chapter.uploadDate != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(chapter.uploadDate!),
                                        style: TextStyleConst.bodySmall.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Action buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Download button (if feature enabled)
                              if (getIt<RemoteConfigService>().isFeatureEnabled(
                                  content.sourceId, (f) => f.download)) ...[
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: DownloadButtonWidget(
                                    content: chapterContent,
                                    size: DownloadButtonSize.small,
                                    showText: false,
                                    showProgress: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Read button with modern styling
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.readChapter,
                                      style: TextStyleConst.labelMedium.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(Content content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.statistics,
            style: TextStyleConst.headingSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // First row of stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.favorite,
                label: AppLocalizations.of(context)!.favoritesLabel,
                value: _formatNumber(content.favorites),
                color: Theme.of(context).colorScheme.error,
              ),
              _buildStatItem(
                icon: Icons.menu_book,
                label: AppLocalizations.of(context)!.pagesLabel,
                value: '${content.pageCount}',
                color: Theme.of(context).colorScheme.primary,
              ),
              _buildStatItem(
                icon: Icons.label,
                label: AppLocalizations.of(context)!.tagsLabel,
                value: '${content.tags.length}',
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),

          // Second row of stats (if there are artists or other relevant data)
          if (content.artists.isNotEmpty || content.language.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (content.artists.isNotEmpty)
                  _buildStatItem(
                    icon: Icons.person,
                    label: AppLocalizations.of(context)!.artistsLabel,
                    value: '${content.artists.length}',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                _buildStatItem(
                  icon: Icons.language,
                  label: AppLocalizations.of(context)!.languageLabel,
                  value: content.language.toUpperCase(),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                if (content.relatedContent.isNotEmpty)
                  _buildStatItem(
                    icon: Icons.recommend,
                    label: AppLocalizations.of(context)!.relatedLabel,
                    value: '${content.relatedContent.length}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedContentSection(Content content) {
    // Check if related content feature is enabled for this source
    final remoteConfig = getIt<RemoteConfigService>();
    final hasRelatedFeature = remoteConfig.isFeatureEnabled(content.sourceId, (f) => f.related);

    if (!hasRelatedFeature || content.relatedContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.moreLikeThis,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: content.relatedContent.length,
            itemBuilder: (context, index) {
              final relatedItem = content.relatedContent[index];
              return _buildRelatedContentCard(relatedItem);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedContentCard(Content relatedContent) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _navigateToRelatedContent(relatedContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProgressiveImageWidget(
                  networkUrl: relatedContent.coverUrl,
                  contentId: relatedContent.id,
                  isThumbnail: true,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  memCacheHeight: 400,
                  placeholder: Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              relatedContent.title,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Metadata
            if (relatedContent.artists.isNotEmpty)
              Text(
                relatedContent.artists.first,
                style: TextStyleConst.overline.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyleConst.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(DetailError state) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.error,
          style: TextStyleConst.headingMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon with enhanced styling
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),

                // Error title
                Text(
                  AppLocalizations.of(context)!.failedToLoadContent,
                  style: TextStyleConst.headingLarge.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Error message in a container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    state.message,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.canRetry) ...[
                      ElevatedButton.icon(
                        onPressed: () => _detailCubit.retryLoading(),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(AppLocalizations.of(context)!.goBack),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.outline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return l10n.yearAgo(years, years > 1 ? 's' : '');
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n.monthAgo(months, months > 1 ? 's' : '');
    } else if (difference.inDays > 0) {
      return l10n.dayAgo(difference.inDays, difference.inDays > 1 ? 's' : '');
    } else if (difference.inHours > 0) {
      return l10n.hourAgo(
          difference.inHours, difference.inHours > 1 ? 's' : '');
    } else {
      return l10n.justNow;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Get theme-aware tag color based on tag type
  Color _getTagColor(BuildContext context, String tagType) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (tagType.toLowerCase()) {
      case 'artist':
        return colorScheme.primary;
      case 'character':
        return colorScheme.secondary;
      case 'parody':
        return colorScheme.tertiary;
      case 'group':
        return colorScheme.error;
      case 'language':
        // Use primary for language in light mode since onSurfaceVariant is too light
        return isDarkMode ? colorScheme.onSurfaceVariant : colorScheme.primary;
      case 'tag':
      default:
        // Use onSurface for default tags in light mode for better visibility
        // In dark mode, outline works fine
        return isDarkMode
            ? colorScheme.outline
            : colorScheme.onSurface.withValues(alpha: 0.8);
    }
  }

  void _readContent(Content content, {bool forceStartFromBeginning = false}) {
    // Get metadata from current state if available
    final currentState = _detailCubit.state;
    final imageMetadata =
        currentState is DetailLoaded ? currentState.imageMetadata : null;

    // Validate content before passing to reader
    // If content has no images, pass null to force reader to fetch fresh content
    final contentToPass = content.imageUrls.isNotEmpty ? content : null;
    Logger().w('Content to pass: $contentToPass');

    if (contentToPass == null) {
      Logger().w(
          '⚠️ Content passed from DetailScreen has no images, forcing reader to fetch fresh data: ${content.id}');
    }

    AppRouter.goToReader(
      context,
      content.id,
      forceStartFromBeginning: forceStartFromBeginning,
      content: contentToPass,
      imageMetadata: imageMetadata, // Pass metadata to reader
    );
  }

  /// Get active content source from SourceCubit
  String _getActiveSourceId() {
    final sourceState = context.read<SourceCubit>().state;
    return sourceState.activeSource?.id ?? 'nhentai';
  }

  /// Get base URL for active source
  String _getSourceBaseUrl() {
    final sourceState = context.read<SourceCubit>().state;
    return sourceState.activeSource?.baseUrl ?? 'https://nhentai.net';
  }

  /// Build source-aware content URL
  String _buildContentUrl(String contentId) {
    final baseUrl = _getSourceBaseUrl();
    final sourceId = _getActiveSourceId();

    if (sourceId == SourceType.crotpedia.id) {
      // Crotpedia uses slug-based URLs: /baca/series/{slug}/
      return '$baseUrl/baca/series/$contentId/';
    } else {
      // nhentai uses numeric IDs: /g/{id}/
      return '$baseUrl/g/$contentId/';
    }
  }

  void _shareContent(Content content) async {
    try {
      // Create shareable link and message (source-aware)
      final contentUrl = _buildContentUrl(content.id);
      final shareText = _buildShareMessage(content, contentUrl);

      // Share using share_plus package
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: content.title,
        ),
      );

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.sharePanelOpened,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      Logger().e('Error sharing content: $e');

      // Fallback: copy to clipboard if sharing fails
      final contentUrl = _buildContentUrl(content.id);
      await Clipboard.setData(ClipboardData(text: contentUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.content_copy,
                  color: Theme.of(context).colorScheme.onError,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.shareFailed,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Build share message with content details
  String _buildShareMessage(Content content, String url) {
    final List<String> messageParts = [];

    // Add title
    messageParts.add(content.title);

    // Add metadata if available
    final List<String> metadata = [];

    if (content.artists.isNotEmpty) {
      metadata.add('Artist: ${content.artists.first}');
    }

    if (content.pageCount > 0) {
      metadata.add('${content.pageCount} pages');
    }

    if (content.language.isNotEmpty) {
      metadata.add('Language: ${content.language.toUpperCase()}');
    }

    if (metadata.isNotEmpty) {
      messageParts.add(metadata.join(' • '));
    }

    // Add URL
    messageParts.add('Check it out: $url');

    return messageParts.join('\n\n');
  }

  void _handleMenuAction(String action, Content content) {
    final remoteConfig = getIt<RemoteConfigService>();
    
    switch (action) {
      case 'download':
        // Check feature flag before downloading
        if (!remoteConfig.isFeatureEnabled(content.sourceId, (f) => f.download)) {
          _showFeatureDisabledDialog('download');
          return;
        }
        _startDownload(content);
        break;
      case 'copy_link':
        _copyContentLink(content);
        break;
    }
  }

  /// Start download for the content
  void _startDownload(Content content) {
    // Check if download feature is enabled
    final remoteConfig = getIt<RemoteConfigService>();
    if (!remoteConfig.isFeatureEnabled(content.sourceId, (f) => f.download)) {
      _showFeatureDisabledDialog('download');
      return;
    }

    try {
      // Get download bloc and add download queue event
      final downloadBloc = context.read<DownloadBloc>();
      downloadBloc.add(DownloadQueueEvent(content: content));

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!
                      .downloadStartedFor(content.title),
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.viewDownloadsAction,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              context.go('/downloads');
            },
          ),
        ),
      );
    } catch (e) {
      Logger().e('Error starting download: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!
                      .failedToStartDownload('Unknown error'),
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showFeatureDisabledDialog(String feature) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.featureDisabledTitle),
        content: Text(
          feature == 'download'
              ? l10n.downloadFeatureDisabled
              : l10n.favoriteFeatureDisabled,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Copy content link to clipboard
  void _copyContentLink(Content content) {
    try {
      // Generate shareable link - source-aware URL
      final contentLink = _buildContentUrl(content.id);

      // Copy to clipboard
      Clipboard.setData(ClipboardData(text: contentLink));

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.linkCopiedToClipboard,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.viewDownloadsAction,
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              // Show copied link in a dialog for verification
              if (mounted) {
                _showCopiedLinkDialog(contentLink);
              }
            },
          ),
        ),
      );
    } catch (e) {
      Logger().e('Error copying link: $e');

      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.failedToCopyLink,
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show dialog with copied link for verification
  void _showCopiedLinkDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          AppLocalizations.of(context)!.copiedLink,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.linkCopiedToClipboardDescription,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: SelectableText(
                link,
                style: TextStyleConst.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.closeDialog,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRelatedContent(Content relatedContent) {
    // Option 1: Replace current detail instead of push to avoid nested navigation
    if (mounted) {
      context.pushReplacement('/content/${relatedContent.id}');
    }
  }

  void _showGoOnlineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          AppLocalizations.of(context)!.goOnlineDialogTitle,
          style: TextStyleConst.headingSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.goOnlineDialogContent,
          style: TextStyleConst.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppStateManager().setOfflineMode(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.goingOnline,
                    style: TextStyleConst.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              AppLocalizations.of(context)!.goOnline,
              style: TextStyleConst.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
