import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/colors_const.dart';
import '../../core/constants/text_style_const.dart';
import '../cubits/network/network_cubit.dart';

/// Widget that shows offline/online status indicator
class OfflineIndicatorWidget extends StatelessWidget {
  const OfflineIndicatorWidget({
    super.key,
    this.showWhenOnline = false,
    this.compact = false,
  });

  final bool showWhenOnline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        if (state is NetworkConnected && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        final isOffline = state is! NetworkConnected;
        final connectionType =
            state is NetworkConnected ? state.connectionType : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: isOffline
                ? ColorsConst.accentRed.withValues(alpha: 0.2)
                : _getConnectionColor(connectionType).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(compact ? 4 : 6),
            border: Border.all(
              color: isOffline
                  ? ColorsConst.accentRed
                  : _getConnectionColor(connectionType),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline
                    ? Icons.cloud_off
                    : _getConnectionIcon(connectionType),
                size: compact ? 12 : 16,
                color: isOffline
                    ? ColorsConst.accentRed
                    : _getConnectionColor(connectionType),
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  isOffline ? 'OFFLINE' : _getConnectionText(connectionType),
                  style: TextStyleConst.bodySmall.copyWith(
                    color: isOffline
                        ? ColorsConst.accentRed
                        : _getConnectionColor(connectionType),
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 10 : 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getConnectionColor(NetworkConnectionType? type) {
    switch (type) {
      case NetworkConnectionType.wifi:
      case NetworkConnectionType.ethernet:
        return ColorsConst.accentGreen;
      case NetworkConnectionType.mobile:
        return ColorsConst.accentYellow;
      case NetworkConnectionType.other:
        return ColorsConst.accentBlue;
      case null:
        return ColorsConst.accentRed;
    }
  }

  IconData _getConnectionIcon(NetworkConnectionType? type) {
    switch (type) {
      case NetworkConnectionType.wifi:
        return Icons.wifi;
      case NetworkConnectionType.ethernet:
        return Icons.lan;
      case NetworkConnectionType.mobile:
        return Icons.signal_cellular_4_bar;
      case NetworkConnectionType.other:
        return Icons.device_hub;
      case null:
        return Icons.cloud_off;
    }
  }

  String _getConnectionText(NetworkConnectionType? type) {
    switch (type) {
      case NetworkConnectionType.wifi:
        return 'WIFI';
      case NetworkConnectionType.ethernet:
        return 'ETHERNET';
      case NetworkConnectionType.mobile:
        return 'MOBILE';
      case NetworkConnectionType.other:
        return 'ONLINE';
      case null:
        return 'OFFLINE';
    }
  }
}

/// Compact offline indicator for app bars and small spaces
class CompactOfflineIndicator extends StatelessWidget {
  const CompactOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const OfflineIndicatorWidget(compact: true);
  }
}

/// Full offline indicator with text
class FullOfflineIndicator extends StatelessWidget {
  const FullOfflineIndicator({
    super.key,
    this.showWhenOnline = false,
  });

  final bool showWhenOnline;

  @override
  Widget build(BuildContext context) {
    return OfflineIndicatorWidget(
      showWhenOnline: showWhenOnline,
      compact: false,
    );
  }
}

/// Offline banner that appears at the top when offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        if (state is NetworkConnected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ColorsConst.accentRed.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: ColorsConst.accentRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: ColorsConst.accentRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Some features may not be available.',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.accentRed,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<NetworkCubit>().checkConnectivity();
                },
                child: Text(
                  'Retry',
                  style: TextStyleConst.buttonSmall.copyWith(
                    color: ColorsConst.accentRed,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Offline mode toggle for settings
class OfflineModeToggle extends StatelessWidget {
  const OfflineModeToggle({
    super.key,
    required this.isOfflineMode,
    required this.onToggle,
  });

  final bool isOfflineMode;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsConst.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOfflineMode
              ? ColorsConst.accentGreen
              : ColorsConst.borderDefault,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOfflineMode ? Icons.offline_bolt : Icons.cloud,
            color: isOfflineMode
                ? ColorsConst.accentGreen
                : ColorsConst.darkTextSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: ColorsConst.darkTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOfflineMode
                      ? 'Using downloaded content only'
                      : 'Online mode with network access',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: ColorsConst.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOfflineMode,
            onChanged: onToggle,
            activeColor: ColorsConst.accentGreen,
            inactiveThumbColor: ColorsConst.darkTextSecondary,
            inactiveTrackColor: ColorsConst.darkElevated,
          ),
        ],
      ),
    );
  }
}
