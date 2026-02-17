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
                'End of Chapter',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What would you like to do?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Chapter
                  _buildNavButton(
                    context: context,
                    icon: Icons.skip_previous,
                    label: 'Prev Chapter',
                    onPressed: hasPreviousChapter ? onPreviousChapter : null,
                    isEnabled: hasPreviousChapter,
                  ),

                  // Back to Detail
                  _buildNavButton(
                    context: context,
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onPressed: () {
                      context.pop();
                    },
                    isEnabled: true,
                    isPrimary: true,
                  ),

                  // Next Chapter
                  _buildNavButton(
                    context: context,
                    icon: Icons.skip_next,
                    label: 'Next Chapter',
                    onPressed: hasNextChapter ? onNextChapter : null,
                    isEnabled: hasNextChapter,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
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
                    : theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.38),
            disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
            disabledForegroundColor:
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isEnabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
            fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
