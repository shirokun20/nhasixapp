import 'package:flutter/widgets.dart';
import 'package:nhasixapp/l10n/app_localizations.dart';

/// Shared relative-time formatter used by cards (home, by-tag, detail).
///
/// Reuses existing ARB keys: `justNow`, `minutesAgo`, `hoursAgo`, `daysAgo`,
/// `monthAgo`, `yearAgo`. Returns null when date is invalid/epoch/future so
/// caller can hide the label.
class RelativeTimeUtils {
  const RelativeTimeUtils._();

  /// Returns localized relative time or null if date should be hidden.
  ///
  /// Hidden when: epoch (ms==0), future, or difference negative.
  static String? format(
    DateTime date,
    BuildContext context, {
    DateTime? now,
  }) {
    if (date.millisecondsSinceEpoch == 0) return null;
    final current = now ?? DateTime.now();
    if (date.isAfter(current)) return null;

    final diff = current.difference(date);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return l10n.yearAgo(years, years > 1 ? 's' : '');
    }
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return l10n.monthAgo(months, months > 1 ? 's' : '');
    }
    if (diff.inDays > 0) {
      return l10n.daysAgo(diff.inDays, diff.inDays == 1 ? '' : 's');
    }
    if (diff.inHours > 0) {
      return l10n.hoursAgo(diff.inHours, diff.inHours == 1 ? '' : 's');
    }
    if (diff.inMinutes > 0) {
      return l10n.minutesAgo(diff.inMinutes, diff.inMinutes == 1 ? '' : 's');
    }
    return l10n.justNow;
  }

  /// Returns true if date should be hidden (epoch or future).
  static bool shouldHide(DateTime date, {DateTime? now}) {
    if (date.millisecondsSinceEpoch == 0) return true;
    final current = now ?? DateTime.now();
    return date.isAfter(current);
  }

  /// Resolves "last update" for content: prefers latest chapter date if more
  /// recent than [contentDate]. Used in detail context where chapters are
  /// available; in list context caller should pass only [contentDate].
  static DateTime resolveLastUpdate(
    DateTime contentDate,
    List<DateTime?> chapterDates,
  ) {
    DateTime best = contentDate;
    for (final d in chapterDates) {
      if (d == null) continue;
      if (d.millisecondsSinceEpoch == 0) continue;
      if (d.isAfter(best)) best = d;
    }
    return best;
  }
}
