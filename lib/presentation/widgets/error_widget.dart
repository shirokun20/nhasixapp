import 'package:flutter/material.dart';

import '../../core/constants/text_style_const.dart';

/// Custom error widget with black theme and contextual information
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.onRetry,
    this.retryText = 'Retry',
    this.onSecondaryAction,
    this.secondaryActionText,
    this.showDetails = false,
    this.details,
    this.suggestions = const [],
  });

  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final String retryText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final bool showDetails;
  final String? details;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          Icon(
            icon ?? Icons.error_outline,
            size: 64,
            color: iconColor ?? Theme.of(context).colorScheme.error,
          ),

          const SizedBox(height: 16),

          // Error title
          Text(
            title,
            style: TextStyleConst.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Error message
          Text(
            message,
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          // Suggestions
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSuggestions(context),
          ],

          // Error details (expandable)
          if (showDetails && details != null) ...[
            const SizedBox(height: 16),
            _buildErrorDetails(context),
          ],

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions:',
            style: TextStyleConst.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyleConst.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyleConst.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorDetails(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Error Details',
        style: TextStyleConst.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            details!,
            style: TextStyleConst.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action (Retry)
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                retryText,
                style: TextStyleConst.buttonMedium.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Secondary action
        if (onSecondaryAction != null && secondaryActionText != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                secondaryActionText!,
                style: TextStyleConst.buttonMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.onGoOffline,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Connection Problem',
      message:
          'Unable to connect to the internet. Please check your connection and try again.',
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
      onRetry: onRetry,
      retryText: 'Try Again',
      onSecondaryAction: onGoOffline,
      secondaryActionText: 'Browse Offline',
      suggestions: const [
        'Check your internet connection',
        'Try switching between WiFi and mobile data',
        'Restart your router if using WiFi',
        'Check if the website is down',
      ],
    );
  }
}

/// Server error widget
class ServerErrorWidget extends StatelessWidget {
  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.statusCode,
  });

  final VoidCallback? onRetry;
  final int? statusCode;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Server Error',
      message: statusCode != null
          ? 'Server returned error $statusCode. The service might be temporarily unavailable.'
          : 'The server is currently unavailable. Please try again later.',
      icon: Icons.dns,
      iconColor: Colors.red,
      onRetry: onRetry,
      suggestions: const [
        'Wait a few minutes and try again',
        'Check if the service is under maintenance',
        'Try refreshing the page',
      ],
    );
  }
}

/// Cloudflare error widget
class CloudflareErrorWidget extends StatelessWidget {
  const CloudflareErrorWidget({
    super.key,
    this.onRetry,
    this.onBypass,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onBypass;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Access Blocked',
      message:
          'The website is protected by Cloudflare. We\'re trying to bypass the protection.',
      icon: Icons.security,
      iconColor: Colors.orange,
      onRetry: onRetry,
      retryText: 'Try Again',
      onSecondaryAction: onBypass,
      secondaryActionText: 'Force Bypass',
      suggestions: const [
        'Wait for automatic bypass to complete',
        'Try using a VPN if available',
        'Check back in a few minutes',
      ],
    );
  }
}

/// Parse error widget
class ParseErrorWidget extends StatelessWidget {
  const ParseErrorWidget({
    super.key,
    this.onRetry,
    this.onReport,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Data Error',
      message:
          'Unable to process the received data. The website structure might have changed.',
      icon: Icons.code_off,
      iconColor: Colors.red,
      onRetry: onRetry,
      retryText: 'Retry',
      onSecondaryAction: onReport,
      secondaryActionText: 'Report Issue',
      suggestions: const [
        'Try refreshing the content',
        'Check if the app needs an update',
        'Report the issue if it persists',
      ],
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
    this.suggestions = const [],
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyleConst.headingMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyleConst.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $suggestion',
                    style: TextStyleConst.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )),
          ],
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionText!,
                style: TextStyleConst.buttonMedium.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// No search results widget
class NoSearchResultsWidget extends StatelessWidget {
  const NoSearchResultsWidget({
    super.key,
    this.query,
    this.onClearFilters,
    this.onTryDifferentSearch,
  });

  final String? query;
  final VoidCallback? onClearFilters;
  final VoidCallback? onTryDifferentSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Results Found',
      message: query != null
          ? 'No content found for "$query". Try adjusting your search terms or filters.'
          : 'No content found. Try adjusting your search terms or filters.',
      icon: Icons.search_off,
      onAction: onClearFilters,
      actionText: 'Clear Filters',
      suggestions: const [
        'Try different keywords',
        'Remove some filters',
        'Check spelling',
        'Use broader search terms',
      ],
    );
  }
}

/// Maintenance mode widget
class MaintenanceWidget extends StatelessWidget {
  const MaintenanceWidget({
    super.key,
    this.onCheckAgain,
  });

  final VoidCallback? onCheckAgain;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Under Maintenance',
      message:
          'The service is currently under maintenance. Please check back later.',
      icon: Icons.build,
      iconColor: Colors.orange,
      onRetry: onCheckAgain,
      retryText: 'Check Again',
      suggestions: const [
        'Maintenance usually takes a few hours',
        'Check social media for updates',
        'Try again later',
      ],
    );
  }
}
