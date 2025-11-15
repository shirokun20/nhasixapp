import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/routing/app_route.dart';
import '../../../domain/entities/entities.dart';
import '../../../services/analytics_service.dart';
import '../../../utils/app_animations.dart';
import '../../cubits/random_gallery/random_gallery_cubit.dart';
import '../../widgets/progressive_image_widget.dart';
import '../../widgets/shimmer_loading_widgets.dart';

/// Random Gallery Screen similar to NClientV2's RandomActivity
/// Displays random galleries with shuffle functionality and preloading
class RandomGalleryScreen extends StatefulWidget {
  const RandomGalleryScreen({super.key});

  static const String routeName = '/random-gallery';

  @override
  State<RandomGalleryScreen> createState() => _RandomGalleryScreenState();
}

class _RandomGalleryScreenState extends State<RandomGalleryScreen> {
  late final AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = getIt<AnalyticsService>();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await _analyticsService.trackScreenView(
      'random_gallery',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RandomGalleryCubit>()..initialize(),
      child: const _RandomGalleryView(),
    );
  }
}

class _RandomGalleryView extends StatelessWidget {
  const _RandomGalleryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.randomGallery),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: BlocBuilder<RandomGalleryCubit, RandomGalleryState>(
        builder: (context, state) {
          if (state is RandomGalleryLoading) {
            return _buildLoadingView(context, state);
          } else if (state is RandomGalleryLoaded) {
            return _buildLoadedView(context, state);
          } else if (state is RandomGalleryError) {
            return _buildErrorView(context, state);
          }
          return _buildInitialView(context);
        },
      ),
      floatingActionButton: BlocBuilder<RandomGalleryCubit, RandomGalleryState>(
        builder: (context, state) {
          final cubit = context.read<RandomGalleryCubit>();

          if (state is RandomGalleryLoaded) {
            return FloatingActionButton(
              onPressed: cubit.canShuffle ? () => cubit.shuffleToNext() : null,
              tooltip: AppLocalizations.of(context)?.shuffleToNextGallery ??
                  'Shuffle to next gallery',
              child: state.isShuffling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shuffle),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return const DetailScreenShimmer();
  }

  Widget _buildLoadingView(BuildContext context, RandomGalleryLoading state) {
    return const DetailScreenShimmer();
  }

  Widget _buildLoadedView(BuildContext context, RandomGalleryLoaded state) {
    final gallery = state.currentGallery;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedAppContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gallery Cover Image
            _buildGalleryCover(context, gallery, state.hasIgnoredTags),

            const SizedBox(height: 24),

            // Gallery Information
            _buildGalleryInfo(context, gallery),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, gallery, state),

            const SizedBox(height: 16),

            // Preload Status
            if (state.preloadedCount > 0)
              _buildPreloadStatus(context, state.preloadedCount),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCover(
      BuildContext context, Content gallery, bool hasIgnoredTags) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            ProgressiveImageWidget(
              networkUrl: gallery.coverUrl,
              contentId: gallery.id,
              isThumbnail: true,
              fit: BoxFit.cover,
            ),

            // Censor Overlay
            if (hasIgnoredTags) _buildCensorOverlay(context),

            // Gradient Overlay for better text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Tap to view gesture
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToDetail(context, gallery),
                  child: const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCensorOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 48,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.contentHidden ?? 'Content Hidden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.tapToViewAnyway ??
                  'Tap to view anyway',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryInfo(BuildContext context, Content gallery) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          gallery.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 12),

        // Metadata Row
        Row(
          children: [
            // Language Flag
            _buildLanguageFlag(context, gallery.language),

            const SizedBox(width: 12),

            // Page Count
            Icon(
              Icons.photo_library_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${gallery.pageCount} pages',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const Spacer(),

            // ID
            Text(
              '#${gallery.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageFlag(BuildContext context, String language) {
    // Map language codes to flag emojis
    const languageFlags = {
      'english': '🇺🇸',
      'japanese': '🇯🇵',
      'chinese': '🇨🇳',
      'korean': '🇰🇷',
      'spanish': '🇪🇸',
      'french': '🇫🇷',
      'german': '🇩🇪',
      'italian': '🇮🇹',
      'portuguese': '🇵🇹',
      'russian': '🇷🇺',
    };

    final flag = languageFlags[language.toLowerCase()] ?? '🌐';
    final languageName = language.isNotEmpty
        ? language[0].toUpperCase() + language.substring(1)
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            languageName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Content gallery, RandomGalleryLoaded state) {
    return Row(
      children: [
        // Favorite Button
        Expanded(
          child: BlocBuilder<RandomGalleryCubit, RandomGalleryState>(
            builder: (context, state) {
              if (state is RandomGalleryLoaded) {
                return ElevatedButton.icon(
                  onPressed: state.isToggling
                      ? null
                      : () =>
                          context.read<RandomGalleryCubit>().toggleFavorite(),
                  icon: state.isToggling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: state.isFavorite ? Colors.red : null,
                        ),
                  label: Text(state.isFavorite
                      ? AppLocalizations.of(context)!.favorited
                      : AppLocalizations.of(context)!.favorite),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isFavorite
                        ? Colors.red.withValues(alpha: 0.1)
                        : null,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        const SizedBox(width: 12),

        // Share Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareGallery(context, gallery),
            icon: const Icon(Icons.share),
            label: Text(AppLocalizations.of(context)!.share),
          ),
        ),

        const SizedBox(width: 12),

        // View Button
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _navigateToDetail(context, gallery),
            icon: const Icon(Icons.visibility),
            label: Text(AppLocalizations.of(context)!.view),
          ),
        ),
      ],
    );
  }

  Widget _buildPreloadStatus(BuildContext context, int preloadedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cached,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)?.galleriesPreloaded(preloadedCount) ??
                '$preloadedCount galleries preloaded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, RandomGalleryError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.oopsSomethingWentWrong ??
                  'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.userMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.canRetry) ...[
                  ElevatedButton.icon(
                    onPressed: () => context.read<RandomGalleryCubit>().retry(),
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retry),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalizations.of(context)!.goBack),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Content gallery) {
    context.push(AppRoute.contentDetail.replaceFirst(':id', gallery.id));
  }

  void _shareGallery(BuildContext context, Content gallery) {
    final shareText =
        '${gallery.title}\n\nCheck out this gallery: ${gallery.id}';
    Share.share(
      shareText,
      subject: AppLocalizations.of(context)?.checkOutThisGallery ??
          'Check out this gallery!',
    );
  }
}
