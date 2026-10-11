// Kuro mood as a pure domain concept — no Flutter import here so the mapping
// stays unit-testable (mirrors prototype/kuro-mascot-prototype.html).
enum KuroMood {
  happy, // A — Blob Cat
  reader, // B — Ninja Reader (book)
  ghost, // C — Ghost Hood
  cry, // D — Nangis (tears + sob)
  tsundere, // E — seminggu gak buka
  frozenCry, // F — beku design + cry motion
  waiting, // G — sedang menunggu (loading): noleh kiri-kanan lambat
}

/// Moods shown when the user read today. The in-app card rotates through
/// these so the mascot does not look frozen on a single frame.
const List<KuroMood> ceriaKuroMoods = [
  KuroMood.happy,
  KuroMood.reader,
  KuroMood.ghost,
];

bool isCeriaMood(KuroMood mood) =>
    mood == KuroMood.happy || mood == KuroMood.reader || mood == KuroMood.ghost;

/// Pure streak -> mood mapping, shared by the in-app card and the launcher
/// widget so both surfaces always agree.
///
/// Days are compared as UTC calendar days so DST shifts never change the
/// day count. Null history is treated as "never read" -> tsundere.
KuroMood resolveKuroMood(
  DateTime? lastReadDate,
  DateTime now, {
  bool rotateCeria = false,
}) {
  if (lastReadDate == null) return KuroMood.tsundere;

  final nowDayUtc = DateTime.utc(now.year, now.month, now.day);
  final lastDayUtc =
      DateTime.utc(lastReadDate.year, lastReadDate.month, lastReadDate.day);
  final diffDays = nowDayUtc.difference(lastDayUtc).inDays;

  if (diffDays <= 0) {
    if (!rotateCeria) return KuroMood.happy;
    final dayIndex =
        (nowDayUtc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay).abs();
    return ceriaKuroMoods[dayIndex % ceriaKuroMoods.length];
  }

  if (diffDays <= 7) return KuroMood.cry;

  return KuroMood.tsundere;
}
