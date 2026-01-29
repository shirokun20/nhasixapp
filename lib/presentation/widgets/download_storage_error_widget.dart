import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/text_style_const.dart';
import '../../core/routing/app_router.dart';

/// A dedicated widget to show when a download error occurs due to missing storage path.
class DownloadStorageErrorWidget extends StatelessWidget {
  final bool isFullScreen;
  final VoidCallback? onDismiss;

  const DownloadStorageErrorWidget({
    super.key,
    this.isFullScreen = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.downloadError,
            style: TextStyleConst.headingLarge.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.pleaseSetStorageLocation,
            textAlign: TextAlign.center,
            style: TextStyleConst.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDismiss != null) ...[
                OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  if (onDismiss != null) onDismiss!();
                  AppRouter.goToSettings(context);
                },
                icon: const Icon(Icons.settings),
                label: Text(l10n.settings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(l10n.downloads),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
