import 'package:flutter/material.dart';
import 'package:nhasixapp/services/app_update_service.dart';

/// Test script to verify AppUpdateService behavior
/// Run this from a test button or debug menu
class AppUpdateTest {
  static Future<void> runTests(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    // Test 1: Check current version
    messenger.showSnackBar(
      const SnackBar(content: Text('🔍 Checking current app version...')),
    );

    final currentVersion = await AppUpdateService.getCurrentAppVersion();
    final lastVersion = await AppUpdateService.getLastAppVersion();

    messenger.showSnackBar(
      SnackBar(
          content: Text(
              '📱 Current: $currentVersion, Last: ${lastVersion ?? 'null'}')),
    );

    await Future.delayed(const Duration(seconds: 2));

    // Test 2: Simulate app update
    messenger.showSnackBar(
      const SnackBar(content: Text('🎭 Simulating app update...')),
    );

    await AppUpdateService.simulateAppUpdate();

    await Future.delayed(const Duration(seconds: 1));

    // Test 3: Re-initialize to trigger cache clearing
    messenger.showSnackBar(
      const SnackBar(content: Text('🔄 Re-initializing AppUpdateService...')),
    );

    await AppUpdateService.initialize();

    messenger.showSnackBar(
      const SnackBar(content: Text('✅ Cache clearing test completed!')),
    );
  }

  static Future<void> forceClearCache(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(content: Text('🧹 Force clearing all caches...')),
    );

    await AppUpdateService.forceClearAllCaches();

    messenger.showSnackBar(
      const SnackBar(content: Text('✅ All caches cleared!')),
    );
  }
}
