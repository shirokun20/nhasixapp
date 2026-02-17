import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation page widget for reader
/// Shows at the end of chapter with next/prev chapter buttons
class ReaderNavigationPage extends StatelessWidget {
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final String? contentId;

  const ReaderNavigationPage({
    super.key,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    this.onPreviousChapter,
    this.onNextChapter,
    this.contentId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Akhir Halaman',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apa yang ingin Anda lakukan?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Navigation buttons
              Column(
                children: [
                  // Next Chapter
                  if (hasNextChapter)
                    _buildNavButton(
                      context: context,
                      icon: Icons.skip_next,
                      label: 'Chapter Berikutnya',
                      onPressed: onNextChapter,
                      isEnabled: true,
                      isPrimary: true,
                    ),

                  const SizedBox(height: 16),

                  // Back to Detail
                  _buildNavButton(
                    context: context,
                    icon: Icons.info_outline,
                    label: 'Kembali ke Detail Content',
                    onPressed: () {
                      context.pop();
                    },
                    isEnabled: true,
                    isPrimary: false,
                  ),

                  const SizedBox(height: 16),

                  // Previous Chapter
                  if (hasPreviousChapter)
                    _buildNavButton(
                      context: context,
                      icon: Icons.skip_previous,
                      label: 'Chapter Sebelumnya',
                      onPressed: onPreviousChapter,
                      isEnabled: true,
                      isPrimary: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isEnabled,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? theme.colorScheme.primary
              : isEnabled
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isPrimary
              ? theme.colorScheme.onPrimary
              : isEnabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          disabledForegroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isPrimary
                    ? theme.colorScheme.onPrimary
                    : isEnabled
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
