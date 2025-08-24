import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/utils/app_state_manager.dart';
import '../../core/constants/text_style_const.dart';

/// Reusable scaffold widget that shows offline indicators and "Go Online" functionality
/// This widget wraps around any page content to provide consistent offline mode UI
class AppScaffoldWithOffline extends StatelessWidget {
  const AppScaffoldWithOffline({
    super.key,
    required this.body,
    required this.title,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
  });

  final Widget body;
  final String title;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      // Listen to offline mode changes from AppStateManager
      stream: AppStateManager().offlineModeStream,
      initialData: AppStateManager().isOfflineMode,
      builder: (context, snapshot) {
        final isOfflineMode = snapshot.data ?? false;
        
        return Scaffold(
          appBar: appBar ?? _buildAppBarWithOfflineIndicator(context, isOfflineMode),
          backgroundColor: backgroundColor,
          drawer: drawer,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          body: Column(
            children: [
              // Show offline banner when in offline mode
              // This provides clear visual feedback to users about their connection status
              if (isOfflineMode) _buildOfflineBanner(context),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  /// Build app bar with offline indicator badge
  /// Shows orange badge when offline, normal appearance when online
  AppBar _buildAppBarWithOfflineIndicator(BuildContext context, bool isOfflineMode) {
    return AppBar(
      title: Text(title),
      backgroundColor: isOfflineMode ? Colors.orange[700] : null,
      actions: [
        // Show offline badge in app bar when in offline mode
        if (isOfflineMode) _buildOfflineBadge(),
        // Add any additional actions here
      ],
    );
  }

  /// Build compact offline badge for app bar
  /// Small badge that clearly indicates offline status
  Widget _buildOfflineBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[800]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_bolt,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            'OFFLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Build prominent offline banner below app bar
  /// Provides information and "Go Online" action button
  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[800],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are offline',
                  style: TextStyleConst.bodyMedium.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Some features are limited. Connect to internet for full access.',
                  style: TextStyleConst.bodySmall.copyWith(
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // "Go Online" button to manually check connection
          TextButton.icon(
            onPressed: () => _checkConnectionAndGoOnline(context),
            icon: Icon(
              Icons.wifi,
              size: 16,
              color: Colors.orange[800],
            ),
            label: Text(
              'Go Online',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange[300]!, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check internet connection and switch to online mode if available
  /// Provides feedback to user about connection status
  void _checkConnectionAndGoOnline(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Checking connection...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      // Check actual connectivity
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();
      
      if (connectivityResult != ConnectivityResult.none) {
        // Connection available - switch to online mode
        AppStateManager().enableOnlineMode();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Back online! All features available.'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Still no connection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Text('Still no internet connection.'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Error checking connection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Unable to check connection.'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Simplified version for pages that don't need custom app bars
/// Provides quick offline-aware scaffold for simple pages
class SimpleOfflineScaffold extends StatelessWidget {
  const SimpleOfflineScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return AppScaffoldWithOffline(
      title: title,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Mixin to add offline awareness to any StatefulWidget
/// Provides convenient methods for checking offline status
mixin OfflineAwareMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription<bool>? _offlineSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to offline mode changes
    _offlineSubscription = AppStateManager().offlineModeStream.listen(
      (isOffline) {
        onOfflineModeChanged(isOffline);
      },
    );
  }

  @override
  void dispose() {
    _offlineSubscription?.cancel();
    super.dispose();
  }

  /// Override this method to handle offline mode changes
  /// Called whenever the app switches between online/offline mode
  void onOfflineModeChanged(bool isOffline) {
    // Default implementation - can be overridden by widgets
  }

  /// Check if app is currently in offline mode
  bool get isOffline => AppStateManager().isOfflineMode;

  /// Check if app is currently in online mode
  bool get isOnline => !AppStateManager().isOfflineMode;

  /// Show offline-specific message to user
  void showOfflineMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.offline_bolt, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show online-specific message to user
  void showOnlineMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
