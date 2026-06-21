import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/text_style_const.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';
import 'package:nhasixapp/presentation/widgets/progressive_image_widget.dart';

class DetailContentView extends StatelessWidget {
  const DetailContentView({
    super.key,
    required this.scrollController,
    required this.isOfflineMode,
    required this.headerImageUrl,
    required this.contentId,
    required this.sourceId,
    required this.onBack,
    required this.onGoOnline,
    required this.appBarActions,
    required this.sections,
    this.pageNumber,
    this.imageHeaders,
    this.blurOverlay,
  });

  final ScrollController scrollController;
  final bool isOfflineMode;
  final String headerImageUrl;
  final String contentId;
  final String sourceId;
  final int? pageNumber;
  final Map<String, String>? imageHeaders;
  final Widget? blurOverlay;
  final VoidCallback onBack;
  final VoidCallback onGoOnline;
  final List<Widget> appBarActions;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (isOfflineMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.secondaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: colorScheme.onSecondaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.youAreOffline,
                    style: TextStyleConst.bodySmall.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onGoOnline,
                  child: Text(
                    l10n.goOnline,
                    style: TextStyleConst.labelMedium.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: colorScheme.surface,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: onBack,
                ),
                actions: appBarActions,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProgressiveImageWidget(
                        networkUrl: headerImageUrl,
                        contentId: contentId,
                        pageNumber: pageNumber,
                        isThumbnail: false,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                        memCacheHeight: 1200,
                        httpHeaders: imageHeaders,
                        placeholder: Container(
                          color: colorScheme.surfaceContainer,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          color: colorScheme.surfaceContainer,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      if (blurOverlay != null) blurOverlay!,
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              colorScheme.onSurface.withValues(alpha: 0.5),
                              colorScheme.onSurface.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sections,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
