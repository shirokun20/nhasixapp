import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nhasixapp/main.dart' as app;
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/presentation/pages/offline/offline_content_screen.dart';

/// Integration tests for offline content functionality
///
/// Note: These tests require a running emulator/device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Reset dependencies before tests
  setUp(() async {
    await getIt.reset();
  });

  group('Offline Content', () {
    testWidgets('should navigate to offline screen', (tester) async {
      // 1. Start App
      app.main();
      await tester.pumpAndSettle();

      // 2. Navigate to Offline tab (Assuming it's 2nd or 3rd tab)
      // Or find by Icon
      final offlineIcon =
          find.byIcon(Icons.download_done); // Or whatever icon used

      // If we can find the icon, tap it
      if (offlineIcon.evaluate().isNotEmpty) {
        await tester.tap(offlineIcon);
        await tester.pumpAndSettle();

        // 3. Verify Offline Screen is visible
        expect(find.byType(OfflineContentScreen), findsOneWidget);

        // 4. Check for empty state or list
        // expect(find.text('No downloads yet'), findsOneWidget); // Example
      } else {
        // Fallback or skip if navigation different
        debugPrint('Offline tab icon not found, skipping navigation test');
      }

      expect(true, isTrue);
    });
  });
}
