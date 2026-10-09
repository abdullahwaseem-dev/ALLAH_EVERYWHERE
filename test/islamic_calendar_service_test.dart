import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';

typedef S = IslamicCalendarService;
typedef E = IslamicEventType;

void main() {
  group('conversion (Umm al-Qura)', () {
    test('matches known Saudi dates for 1446-1447 AH', () {
      expect(S.hijriOf(DateTime(2025, 3, 1), adjustment: 0), const HijriDate(1446, 9, 1));
      expect(S.hijriOf(DateTime(2025, 3, 30), adjustment: 0), const HijriDate(1446, 10, 1));
      expect(S.hijriOf(DateTime(2025, 6, 6), adjustment: 0), const HijriDate(1446, 12, 10));
      expect(S.hijriOf(DateTime(2025, 6, 26), adjustment: 0), const HijriDate(1447, 1, 1));
    });

    test('ignores the time of day', () {
      expect(S.hijriOf(DateTime(2025, 3, 1, 23, 59), adjustment: 0), const HijriDate(1446, 9, 1));
    });

    test('round-trips every day of a year, with every adjustment', () {
      for (int adj = S.minAdjustment; adj <= S.maxAdjustment; adj++) {
        for (var d = DateTime(2026, 1, 1); d.year == 2026; d = DateTime(d.year, d.month, d.day + 1)) {
          final h = S.hijriOf(d, adjustment: adj)!;
          expect(S.gregorianOf(h, adjustment: adj), d, reason: '$d adj $adj');
        }
      }
    });

    test('an adjustment of +1 shows the next day\'s Umm al-Qura date', () {
      final d = DateTime(2025, 2, 28);
      expect(S.hijriOf(d, adjustment: 1), S.hijriOf(DateTime(2025, 3, 1), adjustment: 0));
      expect(S.hijriOf(DateTime(2025, 3, 2), adjustment: -1), const HijriDate(1446, 9, 1));
    });

    test('outside the supported table returns null instead of throwing', () {
      expect(S.hijriOf(DateTime(2100, 1, 1), adjustment: 0), isNull);
      expect(S.gregorianOf(const HijriDate(1600, 1, 1), adjustment: 0), isNull);
      expect(S.monthLength(1600, 1), isNull);
    });

    test('months are 29 or 30 days', () {
      for (int m = 1; m <= 12; m++) {
        expect(S.monthLength(1447, m), anyOf(29, 30));
      }
    });

    test('month paging index round-trips', () {
      expect(S.monthAt(S.monthIndex(1447, 9)), (year: 1447, month: 9));
      expect(S.monthAt(0), (year: S.minYear, month: 1));
      expect(S.monthAt(S.monthCount - 1), (year: S.maxYear, month: 12));
    });
  });

  group('eventsOn', () {
    // A Wednesday, so no Monday/Thursday fast gets in the way.
    final wednesday = DateTime(2026, 10, 7);
    final monday = DateTime(2026, 10, 5);

    test('fixed-date events', () {
      expect(S.eventsOn(const HijriDate(1448, 1, 1), wednesday), [E.newYear]);
      expect(S.eventsOn(const HijriDate(1448, 1, 9), wednesday), [E.tasua]);
      expect(S.eventsOn(const HijriDate(1448, 1, 10), wednesday), [E.ashura]);
      expect(S.eventsOn(const HijriDate(1448, 3, 12), wednesday), [E.mawlid]);
      expect(S.eventsOn(const HijriDate(1448, 7, 27), wednesday), [E.israMiraj]);
      expect(S.eventsOn(const HijriDate(1448, 8, 15), wednesday), [E.midShaban, E.whiteDays]);
      expect(S.eventsOn(const HijriDate(1448, 9, 1), wednesday), [E.ramadanStart]);
      expect(S.eventsOn(const HijriDate(1448, 10, 1), wednesday), [E.eidFitr]);
      expect(S.eventsOn(const HijriDate(1448, 10, 2), wednesday), [E.shawwalSix]);
      expect(S.eventsOn(const HijriDate(1448, 12, 9), wednesday), [E.arafah]);
      expect(S.eventsOn(const HijriDate(1448, 12, 10), wednesday), [E.eidAdha]);
      for (final d in [11, 12, 13]) {
        expect(S.eventsOn(HijriDate(1448, 12, d), wednesday), [E.tashreeq]);
      }
    });

    test('last ten nights and the odd nights', () {
      expect(S.eventsOn(const HijriDate(1448, 9, 21), wednesday), [E.lastTenNights, E.oddNight]);
      for (final d in [23, 25, 27, 29]) {
        expect(S.eventsOn(HijriDate(1448, 9, d), wednesday), [E.oddNight]);
      }
      for (final d in [20, 22, 24, 26, 28, 30]) {
        expect(S.eventsOn(HijriDate(1448, 9, d), wednesday), isEmpty);
      }
    });

    test('White Days are 13-15 of every month', () {
      for (final d in [13, 14, 15]) {
        expect(S.eventsOn(HijriDate(1448, 4, d), wednesday), [E.whiteDays]);
      }
      expect(S.eventsOn(const HijriDate(1448, 4, 12), wednesday), isEmpty);
      expect(S.eventsOn(const HijriDate(1448, 4, 16), wednesday), isEmpty);
    });

    test('Mondays and Thursdays', () {
      expect(S.eventsOn(const HijriDate(1448, 4, 24), monday), [E.mondayThursday]);
      expect(S.eventsOn(const HijriDate(1448, 4, 27), DateTime(2026, 10, 8)), [E.mondayThursday]);
    });

    test('no sunnah fasts on forbidden days', () {
      expect(S.eventsOn(const HijriDate(1448, 10, 1), monday), [E.eidFitr]);
      expect(S.eventsOn(const HijriDate(1448, 12, 10), monday), [E.eidAdha]);
      // 13 Dhul Hijjah is both a White Day and a Day of Tashreeq.
      expect(S.eventsOn(const HijriDate(1448, 12, 13), monday), [E.tashreeq]);
    });

    test('no extra sunnah fasts listed in Ramadan', () {
      expect(S.eventsOn(const HijriDate(1448, 9, 14), monday), isEmpty);
    });

    test('forbidden and recommended days', () {
      expect(S.isFastingForbidden(const HijriDate(1448, 10, 1)), isTrue);
      expect(S.isFastingForbidden(const HijriDate(1448, 12, 10)), isTrue);
      expect(S.isFastingForbidden(const HijriDate(1448, 12, 13)), isTrue);
      expect(S.isFastingForbidden(const HijriDate(1448, 12, 9)), isFalse);
      expect(S.isFastingForbidden(const HijriDate(1448, 12, 14)), isFalse);
      expect(S.isRecommendedFast(const HijriDate(1448, 12, 9), wednesday), isTrue);
      expect(S.isRecommendedFast(const HijriDate(1448, 12, 13), monday), isFalse);
    });
  });

  group('planReminders', () {
    List<CalendarReminder> plan(DateTime now, {bool white = true, bool monThu = true, bool important = true, int days = 30}) =>
        S.planReminders(
          now: now,
          whiteDays: white,
          mondayThursday: monThu,
          importantDates: important,
          adjustment: 0,
          days: days,
        );

    test('fires at 8 PM the evening before, in the future, at most once a day', () {
      final now = DateTime(2026, 10, 7, 9);
      final reminders = plan(now);
      expect(reminders, isNotEmpty);
      final offsets = <int>{};
      for (final r in reminders) {
        expect(r.fireAt, DateTime(r.day.year, r.day.month, r.day.day - 1, 20));
        expect(r.fireAt.isAfter(now), isTrue);
        expect(offsets.add(r.dayOffset), isTrue);
        expect(r.dayOffset, inInclusiveRange(1, 30));
        expect(r.day.difference(DateTime(2026, 10, 7)).inDays, r.dayOffset);
      }
    });

    test('skips tomorrow once tonight\'s 8 PM has passed', () {
      // Thursday 8 Oct 2026 is a Monday/Thursday fast.
      expect(plan(DateTime(2026, 10, 7, 19, 59)).first.day, DateTime(2026, 10, 8));
      expect(plan(DateTime(2026, 10, 7, 20, 0)).first.day.isAfter(DateTime(2026, 10, 8)), isTrue);
    });

    test('never plans a fasting reminder on a forbidden day, nor debated events', () {
      // A whole year, so both Eids and Tashreeq are covered.
      final reminders = plan(DateTime(2026, 1, 1), days: 366);
      for (final r in reminders) {
        expect(r.events.any(debatedEvents.contains), isFalse, reason: '${r.hijri}');
        if (S.isFastingForbidden(r.hijri)) {
          expect(r.events.any(recommendedFasts.contains), isFalse, reason: '${r.hijri}');
        }
      }
      // Eid itself is still announced as an important date.
      expect(reminders.any((r) => r.events.contains(E.eidAdha)), isTrue);
      expect(reminders.any((r) => r.events.contains(E.tashreeq)), isTrue);
    });

    test('respects the three toggles', () {
      final now = DateTime(2026, 1, 1);
      final onlyImportant = plan(now, white: false, monThu: false, days: 366);
      expect(onlyImportant.any((r) => r.events.contains(E.mondayThursday)), isFalse);
      expect(onlyImportant.any((r) => r.events.contains(E.whiteDays)), isFalse);
      expect(onlyImportant.any((r) => r.events.contains(E.arafah)), isTrue);

      final onlyWhite = plan(now, monThu: false, important: false, days: 366);
      expect(onlyWhite.every((r) => r.events.every((e) => e == E.whiteDays)), isTrue);
      expect(onlyWhite.length, greaterThan(30)); // 3 a month, minus Ramadan and 13 Dhul Hijjah

      expect(plan(now, white: false, monThu: false, important: false, days: 366), isEmpty);
    });

    test('30 days of reminders fit in the 500-599 id range', () {
      final reminders = plan(DateTime(2026, 10, 7));
      for (final r in reminders) {
        expect(500 + r.dayOffset, inInclusiveRange(500, 599));
      }
    });
  });
}
