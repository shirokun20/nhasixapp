import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/services/streak_widget_sync_service.dart';
import 'package:nhasixapp/domain/entities/reading_statistics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakWidgetSyncService', () {
    test('notifyStreakChanged emits on changes broadcast stream', () async {
      var notified = 0;
      final sub = StreakWidgetSyncService.changes.listen((_) {
        notified++;
      });
      addTearDown(sub.cancel);

      StreakWidgetSyncService.notifyStreakChanged();
      await Future<void>.delayed(Duration.zero);

      expect(notified, 1);
    });

    test('syncWidget swallows missing platform channel in unit tests',
        () async {
      final stats = ReadingStatistics.streak(
        readingStreak: 3,
        lastReadDate: DateTime(2026, 10, 12),
        readDays: [
          DateTime(2026, 10, 10),
          DateTime(2026, 10, 11),
          DateTime(2026, 10, 12),
        ],
        totalContentRead: 15,
      );

      await expectLater(
        StreakWidgetSyncService.syncWidget(
          stats,
          now: DateTime(2026, 10, 12, 10),
        ),
        completes,
      );
    });

    test('syncWidget saves data and updates all 3 widget receiver variants',
        () async {
      const channel = MethodChannel('home_widget');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final stats = ReadingStatistics.streak(
        readingStreak: 5,
        lastReadDate: DateTime(2026, 10, 12),
        readDays: [DateTime(2026, 10, 12)],
        totalContentRead: 20,
      );

      await StreakWidgetSyncService.syncWidget(
        stats,
        now: DateTime(2026, 10, 12, 12),
      );

      final updatedReceivers = calls
          .where((c) => c.method == 'updateWidget')
          .map((c) => (c.arguments as Map)['qualifiedAndroidName'] as String?)
          .toList();

      expect(
        updatedReceivers,
        equals([
          'id.nhasix.app.widget.KuroStreakWidgetReceiver',
          'id.nhasix.app.widget.KuroStreakStripWidgetReceiver',
          'id.nhasix.app.widget.KuroStreakSmallWidgetReceiver',
        ]),
      );
    });
  });
}
