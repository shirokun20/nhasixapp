import 'dart:async';
import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../domain/entities/kuro_mood.dart';
import '../../domain/entities/reading_statistics.dart';

// Bridge between the reading streak and the two surfaces that show it: the
// Android launcher widget (push) and the in-app card (pull).
//
// Push side: [syncWidget] writes the privacy-safe subset — streak count,
// calendar days, a generic total, the mood name. Never a title, cover, tag
// or source name.
// Pull side: [notifyStreakChanged] fires whenever a read is recorded, so the
// card reloads without polling.
class StreakWidgetSyncService {
  StreakWidgetSyncService._();

  static const String receiverName = 'KuroStreakWidgetReceiver';
  static const String qualifiedReceiverName =
      'id.nhasix.app.widget.KuroStreakWidgetReceiver';

  static const List<String> variantReceiverNames = [
    'KuroStreakWidgetReceiver',
    'KuroStreakStripWidgetReceiver',
    'KuroStreakSmallWidgetReceiver',
  ];
  static const String keyStreakCount = 'streak_count';
  static const String keyStreakLastDate = 'streak_last_date';
  static const String keyStreakReadDays = 'streak_read_days';
  static const String keyStreakTotalRead = 'streak_total_read';
  static const String keyStreakMood = 'streak_mood';

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static void notifyStreakChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  // Best-effort by design: unit and widget tests run without the platform
  // channel, and a device with no widget provider must still record reads.
  static Future<void> syncWidget(
    ReadingStatistics stats, {
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    try {
      await HomeWidget.saveWidgetData<int>(keyStreakCount, stats.readingStreak);
      await HomeWidget.saveWidgetData<String>(
          keyStreakLastDate, _formatDay(stats.lastReadDate));
      await HomeWidget.saveWidgetData<String>(
          keyStreakReadDays,
          jsonEncode(
              stats.readDays?.map(_formatDay).toList() ?? const <String>[]));
      await HomeWidget.saveWidgetData<int>(
          keyStreakTotalRead, stats.totalContentRead);
      await HomeWidget.saveWidgetData<String>(
          keyStreakMood, resolveKuroMood(stats.lastReadDate, ref).name);
      for (final variant in variantReceiverNames) {
        await HomeWidget.updateWidget(
          name: variant,
          androidName: variant,
          qualifiedAndroidName: 'id.nhasix.app.widget.$variant',
        );
      }
    } catch (_) {
      // Launcher view keeps its last snapshot; the streak itself is unaffected.
    }
  }

  static String _formatDay(DateTime? day) {
    if (day == null) return '';
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}
