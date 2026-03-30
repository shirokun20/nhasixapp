import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading widget for offline content cards
class OfflineContentShimmer extends StatelessWidget {
  const OfflineContentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      highlightColor:
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle placeholder
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.6,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading widget for offline content grid
class OfflineContentGridShimmer extends StatelessWidget {
  final int itemCount;

  const OfflineContentGridShimmer({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const OfflineContentShimmer(),
    );
  }
}
