import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/kuro_mood.dart';

void main() {
  // Fixed clock: 2026-01-10 14:30 local.
  final now = DateTime(2026, 1, 10, 14, 30);

  group('resolveKuroMood — read today', () {
    test('same calendar day is ceria (happy)', () {
      final lastRead = DateTime(2026, 1, 10, 1, 5);

      expect(resolveKuroMood(lastRead, now), KuroMood.happy);
      expect(isCeriaMood(resolveKuroMood(lastRead, now)), isTrue);
    });

    test('time of day does not change the day diff', () {
      final justAfterMidnight = DateTime(2026, 1, 10, 0, 0, 1);
      final lateNight = DateTime(2026, 1, 9, 23, 59, 59);

      expect(resolveKuroMood(justAfterMidnight, now), KuroMood.happy);
      expect(resolveKuroMood(lateNight, now), KuroMood.cry);
    });

    test('future timestamp on the same day is still ceria', () {
      expect(
        resolveKuroMood(DateTime(2026, 1, 10, 23, 0), now),
        KuroMood.happy,
      );
    });

    test('UTC last-read date maps to the same local day', () {
      // 2026-01-10T22:00Z is still 2026-01-10 in UTC terms.
      expect(
        resolveKuroMood(
          DateTime.utc(2026, 1, 10, 22),
          DateTime.utc(2026, 1, 10, 23),
        ),
        KuroMood.happy,
      );
    });
  });

  group('resolveKuroMood — ceria rotation', () {
    // Epoch-day indexes: 2026-01-01 -> 20454 (%3 == 0), so the rotation
    // starts at happy and walks the ceria list once every 3 days.
    const rotating = [KuroMood.happy, KuroMood.reader, KuroMood.ghost];

    test('rotateCeria false pins to happy even on a rotating day', () {
      // 2026-01-02 rotates to reader, but only when rotation is on.
      final day = DateTime(2026, 1, 2, 9);

      expect(resolveKuroMood(day, day, rotateCeria: false), KuroMood.happy);
      expect(resolveKuroMood(day, day, rotateCeria: true), KuroMood.reader);
    });

    test('rotateCeria cycles happy -> reader -> ghost then wraps', () {
      for (var offset = 0; offset < 4; offset++) {
        final day = DateTime(2026, 1, 1 + offset, 9);
        expect(
          resolveKuroMood(day, day, rotateCeria: true),
          rotating[offset % 3],
          reason: 'offset $offset',
        );
      }
    });

    test('rotation result is always a ceria mood', () {
      for (var day = 1; day <= 20; day++) {
        final d = DateTime(2026, 1, day);
        final mood = resolveKuroMood(d, d, rotateCeria: true);
        expect(isCeriaMood(mood), isTrue, reason: '$d -> $mood');
      }
    });
  });

  group('resolveKuroMood — cry window', () {
    test('1 day gap is cry (lower boundary)', () {
      expect(resolveKuroMood(DateTime(2026, 1, 9), now), KuroMood.cry);
    });

    test('7 day gap is cry (upper boundary)', () {
      expect(resolveKuroMood(DateTime(2026, 1, 3), now), KuroMood.cry);
    });

    test('gaps in between are cry', () {
      for (var gap = 1; gap <= 7; gap++) {
        expect(
          resolveKuroMood(DateTime(2026, 1, 10 - gap), now),
          KuroMood.cry,
          reason: 'gap $gap',
        );
      }
    });
  });

  group('resolveKuroMood — tsundere', () {
    test('null last read is tsundere', () {
      expect(resolveKuroMood(null, now), KuroMood.tsundere);
      expect(
        resolveKuroMood(null, now, rotateCeria: true),
        KuroMood.tsundere,
        reason: 'rotation never resurrects a missing history',
      );
    });

    test('8 day gap is tsundere', () {
      expect(resolveKuroMood(DateTime(2026, 1, 2), now), KuroMood.tsundere);
    });

    test('long gap is tsundere', () {
      expect(resolveKuroMood(DateTime(2025, 12, 1), now), KuroMood.tsundere);
    });
  });

  group('isCeriaMood', () {
    test('happy, reader and ghost are ceria', () {
      expect(isCeriaMood(KuroMood.happy), isTrue);
      expect(isCeriaMood(KuroMood.reader), isTrue);
      expect(isCeriaMood(KuroMood.ghost), isTrue);
    });

    test('sad and loading moods are not ceria', () {
      expect(isCeriaMood(KuroMood.cry), isFalse);
      expect(isCeriaMood(KuroMood.frozenCry), isFalse);
      expect(isCeriaMood(KuroMood.tsundere), isFalse);
      expect(isCeriaMood(KuroMood.waiting), isFalse);
    });
  });

  test('ceriaKuroMoods matches the rotation table', () {
    expect(ceriaKuroMoods, [
      KuroMood.happy,
      KuroMood.reader,
      KuroMood.ghost,
    ]);
  });
}
