import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/core/routing/app_route.dart';
import 'package:nhasixapp/core/routing/app_router.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/presentation/cubits/detail/detail_cubit.dart';
import 'package:nhasixapp/presentation/widgets/search_filter_widget.dart';
import 'package:nhasixapp/presentation/widgets/progressive_image_widget.dart';

class DetailScreen extends StatefulWidget {
  final String contentId;

  const DetailScreen({
    super.key,
    required this.contentId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final DetailCubit _detailCubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _detailCubit = getIt<DetailCubit>()..loadContentDetail(widget.contentId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _detailCubit.close();
    super.dispose();
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
          backgroundColor: ColorsConst.darkBackground,
          body: BlocBuilder<DetailCubit, DetailState>(
            builder: (context, state) {
              if (state is DetailLoading) {
                return _buildLoadingState(context);
              } else if (state is DetailLoaded) {
                return _buildDetailContent(state);
              } else if (state is DetailError) {
                return _buildErrorState(state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsConst.darkBackground,
      appBar: AppBar(
        backgroundColor: ColorsConst.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: ColorsConst.darkTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Loading...',
          style: TextStyleConst.headingMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ColorsConst.accentBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Loading content details...',
              style: TextStyle(
                color: ColorsConst.darkTextSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(DetailLoaded state) {
    final content = state.content;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // App bar with cover image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: ColorsConst.darkSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: ColorsConst.darkTextPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Favorite button
            IconButton(
              icon: Icon(
                state.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: state.isFavorited
                    ? ColorsConst.accentPink
                    : ColorsConst.darkTextPrimary,
              ),
              onPressed: state.isTogglingFavorite
                  ? null
                  : () => _detailCubit.toggleFavorite(),
            ),
            // Share button
            IconButton(
              icon: const Icon(Icons.share, color: ColorsConst.darkTextPrimary),
              onPressed: () => _shareContent(content),
            ),
            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: ColorsConst.darkTextPrimary),
              color: ColorsConst.darkCard,
              onSelected: (value) => _handleMenuAction(value, content),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      const Icon(Icons.download,
                          color: ColorsConst.darkTextPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'Download',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: ColorsConst.darkTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'copy_link',
                  child: Row(
                    children: [
                      const Icon(Icons.link,
                          color: ColorsConst.darkTextPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'Copy Link',
                        style: TextStyleConst.bodyMedium.copyWith(
                          color: ColorsConst.darkTextPrimary,
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
                // Cover image
                EnhancedCachedNetworkImage(
                  imageUrl: content.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: ColorsConst.darkCard,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: ColorsConst.accentBlue,
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    color: ColorsConst.darkCard,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: ColorsConst.darkTextTertiary,
                      ),
                    ),
                  ),
                  useProgressiveLoading: true,
                  compressionQuality: 90, // Higher quality for detail view
                  memCacheWidth: 800,
                  memCacheHeight: 1200,
                ),
                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x88000000),
                        Color(0xCC000000),
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
    );
  }

  Widget _buildTitleSection(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: TextStyleConst.headingLarge.copyWith(
            color: ColorsConst.darkTextPrimary,
            height: 1.3,
          ),
        ),
        if (content.englishTitle != null &&
            content.englishTitle != content.title) ...[
          const SizedBox(height: 8),
          Text(
            content.englishTitle!,
            style: TextStyleConst.bodyLarge.copyWith(
              color: ColorsConst.darkTextSecondary,
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
              color: ColorsConst.darkTextTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataSection(Content content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsConst.borderDefault),
      ),
      child: Column(
        children: [
          _buildMetadataRow('ID', content.id),
          _buildMetadataRow('Pages', '${content.pageCount}'),
          _buildMetadataRow(
              'Language', content.language.toLowerCase().capitalize()),
          if (content.artists.isNotEmpty)
            _buildMetadataRow('Artist', content.artists.join(', ')),
          if (content.characters.isNotEmpty)
            _buildMetadataRow('Characters', content.characters.join(', ')),
          if (content.parodies.isNotEmpty)
            _buildMetadataRow('Parodies', content.parodies.join(', ')),
          if (content.groups.isNotEmpty)
            _buildMetadataRow('Groups', content.groups.join(', ')),
          _buildMetadataRow('Uploaded', _formatDate(content.uploadDate)),
          _buildMetadataRow('Favorites', '${content.favorites}'),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyleConst.bodyMedium.copyWith(
                color: ColorsConst.darkTextPrimary,
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
          'Tags',
          style: TextStyleConst.headingSmall.copyWith(
            color: ColorsConst.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: content.tags.map((tag) {
            return GestureDetector(
              onTap: () => _searchByTag(tag.name),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      ColorsConst.getTagColor(tag.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorsConst.getTagColor(tag.type)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyleConst.contentTag.copyWith(
                        color: ColorsConst.getTagColor(tag.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (tag.count > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${tag.count}',
                        style: TextStyleConst.overline.copyWith(
                          color: ColorsConst.getTagColor(tag.type)
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
    return Row(
      children: [
        // Read button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _readContent(content),
            icon: const Icon(Icons.menu_book),
            label: const Text('Read'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsConst.accentBlue,
              foregroundColor: ColorsConst.darkBackground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Download button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _downloadContent(content),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorsConst.accentBlue,
              side: const BorderSide(color: ColorsConst.accentBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(Content content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorsConst.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: TextStyleConst.headingSmall.copyWith(
              color: ColorsConst.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // First row of stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.favorite,
                label: 'Favorites',
                value: _formatNumber(content.favorites),
                color: ColorsConst.accentPink,
              ),
              _buildStatItem(
                icon: Icons.menu_book,
                label: 'Pages',
                value: '${content.pageCount}',
                color: ColorsConst.accentBlue,
              ),
              _buildStatItem(
                icon: Icons.label,
                label: 'Tags',
                value: '${content.tags.length}',
                color: ColorsConst.accentGreen,
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
                    label: 'Artists',
                    value: '${content.artists.length}',
                    color: ColorsConst.accentOrange,
                  ),
                _buildStatItem(
                  icon: Icons.language,
                  label: 'Language',
                  value: content.language.toUpperCase(),
                  color: ColorsConst.accentPurple,
                ),
                if (content.relatedContent.isNotEmpty)
                  _buildStatItem(
                    icon: Icons.recommend,
                    label: 'Related',
                    value: '${content.relatedContent.length}',
                    color: ColorsConst.accentBlue,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedContentSection(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Like This',
          style: TextStyleConst.headingSmall.copyWith(
            color: ColorsConst.darkTextPrimary,
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
                color: ColorsConst.darkCard,
              ),
              child: EnhancedCachedNetworkImage(
                imageUrl: relatedContent.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                borderRadius: BorderRadius.circular(8),
                placeholder: Container(
                  color: ColorsConst.darkCard,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: ColorsConst.accentBlue,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: Container(
                  color: ColorsConst.darkCard,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 32,
                      color: ColorsConst.darkTextTertiary,
                    ),
                  ),
                ),
                useProgressiveLoading: true,
                compressionQuality: 80,
                memCacheWidth: 320,
                memCacheHeight: 400,
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              relatedContent.title,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextPrimary,
                fontWeight: FontWeight.w500,
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
                  color: ColorsConst.darkTextSecondary,
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
          style: TextStyleConst.bodyMedium.copyWith(
            color: ColorsConst.darkTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyleConst.bodySmall.copyWith(
            color: ColorsConst.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(DetailError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorsConst.accentRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: TextStyleConst.headingSmall.copyWith(
                color: ColorsConst.accentRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyleConst.bodySmall.copyWith(
                color: ColorsConst.darkTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _detailCubit.retryLoading(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsConst.accentBlue,
                  foregroundColor: ColorsConst.darkBackground,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsConst.darkTextSecondary,
                side: const BorderSide(color: ColorsConst.borderDefault),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
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

  void _readContent(Content content) {
    AppRouter.goToReader(context, content.id);
  }

  void _downloadContent(Content content) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Download functionality will be implemented in task 7.2',
          style: TextStyleConst.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsConst.accentOrange,
      ),
    );
  }

  void _shareContent(Content content) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share functionality will be implemented later',
          style: TextStyleConst.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ColorsConst.accentBlue,
      ),
    );
  }

  void _searchByTag(String tagName) {
    // context.pop(); // Go back to previous screen
    context.push('${AppRoute.search}/$tagName');
    // TODO: Pass tag as search parameter
  }

  void _handleMenuAction(String action, Content content) {
    switch (action) {
      case 'download':
        _downloadContent(content);
        break;
      case 'copy_link':
        // TODO: Implement copy link functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Link copied to clipboard',
              style: TextStyleConst.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: ColorsConst.accentGreen,
          ),
        );
        break;
    }
  }

  void _navigateToRelatedContent(Content relatedContent) {
    AppRouter.goToContentDetail(context, relatedContent.id);
  }
}
