import 'package:flutter/material.dart';
import '../../cubits/reader/reader_cubit.dart';

/// End-of-Chapter Overlay Widget
/// Shows at the last page of content with navigation options
class EndOfChapterOverlay extends StatelessWidget {
  final ReaderState state;
  final VoidCallback onBackToDetail;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final bool isChapterMode;

  const EndOfChapterOverlay({
    super.key,
    required this.state,
    required this.onBackToDetail,
    this.onPreviousChapter,
    this.onNextChapter,
    required this.isChapterMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                isChapterMode ? 'Chapter Complete!' : 'Finished Reading',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                state.content?.title ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 32),

              // Buttons
              if (isChapterMode) ...[
                // Chapter Mode: Show prev/next/back buttons
                if (onPreviousChapter != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPreviousChapter,
                      icon: const Icon(Icons.skip_previous),
                      label: const Text('Prev Chapter',
                          textAlign: TextAlign.center),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                if (onPreviousChapter != null && onNextChapter != null)
                  const SizedBox(height: 12),

                // Next Chapter
                if (onNextChapter != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onNextChapter,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Next Chapter',
                          textAlign: TextAlign.center),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Back to Detail
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onBackToDetail,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Detail'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ] else ...[
                // Single Content Mode: Only back button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onBackToDetail,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Detail'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
