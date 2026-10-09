import 'package:hijri/hijri_calendar.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// A Hijri date. Kept separate from [HijriCalendar], whose month names come
/// from a static, app-wide language setting.
class HijriDate implements Comparable<HijriDate> {
  final int year;
  final int month;
  final int day;

  const HijriDate(this.year, this.month, this.day);

  @override
  int compareTo(HijriDate other) =>
      year != other.year ? year - other.year : (month != other.month ? month - other.month : day - other.day);

  @override
  bool operator ==(Object other) =>
      other is HijriDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$day/$month/$year AH';
}

/// Everything the calendar marks. Fasting-related flags are on
/// [IslamicCalendarService] (see [isFastingForbidden] and [isRecommendedFast]).
enum IslamicEventType {
  newYear,
  tasua,
  ashura,
  mawlid,
  israMiraj,
  midShaban,
  ramadanStart,
  lastTenNights,
  oddNight,
  eidFitr,
  shawwalSix,
  arafah,
  eidAdha,
  tashreeq,
  mondayThursday,
  whiteDays,
}

/// Events whose date or observance scholars differ on. They are shown on
/// the calendar with that note, but never sent as notifications.
const Set<IslamicEventType> debatedEvents = {
  IslamicEventType.mawlid,
  IslamicEventType.israMiraj,
  IslamicEventType.midShaban,
};

/// Sunnah fasts that recur through the year.
const Set<IslamicEventType> recurringFasts = {IslamicEventType.mondayThursday, IslamicEventType.whiteDays};

/// Days on which a voluntary fast is recommended.
const Set<IslamicEventType> recommendedFasts = {
  IslamicEventType.tasua,
  IslamicEventType.ashura,
  IslamicEventType.shawwalSix,
  IslamicEventType.arafah,
  IslamicEventType.mondayThursday,
  IslamicEventType.whiteDays,
};

/// Dates that depend on sighting the new moon, so are only "expected".
const Set<IslamicEventType> moonSightingEvents = {
  IslamicEventType.ramadanStart,
  IslamicEventType.eidFitr,
  IslamicEventType.eidAdha,
};

/// One evening-before notification: [day] is the date being reminded of,
/// [fireAt] the evening before it at [IslamicCalendarService.reminderHour].
class CalendarReminder {
  final DateTime day;
  final DateTime fireAt;
  final HijriDate hijri;
  final List<IslamicEventType> events;

  /// Days from today (1 = tomorrow); also the notification id offset.
  final int dayOffset;

  const CalendarReminder({
    required this.day,
    required this.fireAt,
    required this.hijri,
    required this.events,
    required this.dayOffset,
  });

  bool get isFast => events.any(recommendedFasts.contains);
}

/// Hijri dates (with the user's moon-sighting adjustment), Islamic events
/// and sunnah fasts, and the plan for evening-before reminders.
///
/// Conversion uses the Umm al-Qura table from the `hijri` package, which
/// only covers [minYear]-[maxYear] AH; dates outside it return null.
class IslamicCalendarService {
  static const adjustmentKey = 'hijri_adjustment';
  static const whiteDaysReminderKey = 'reminder_white_days';
  static const mondayThursdayReminderKey = 'reminder_monday_thursday';
  static const importantDatesReminderKey = 'reminder_important_dates';

  static const int minAdjustment = -2;
  static const int maxAdjustment = 2;
  static const int minYear = 1356;
  static const int maxYear = 1500;

  /// Evening-before reminders fire at 8 PM, after Maghrib in most places
  /// for most of the year, in time to plan suhoor.
  static const int reminderHour = 20;
  static const int reminderDays = 30;

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Days added to the Umm al-Qura date to match local moon sighting.
  static int get adjustment {
    final stored = VoidStorage().readData<int>(adjustmentKey) ?? 0;
    return stored.clamp(minAdjustment, maxAdjustment);
  }

  static Future<void> setAdjustment(int days) =>
      VoidStorage().saveData(adjustmentKey, days.clamp(minAdjustment, maxAdjustment));

  static bool get whiteDaysReminder => VoidStorage().readData<bool>(whiteDaysReminderKey) ?? false;
  static bool get mondayThursdayReminder => VoidStorage().readData<bool>(mondayThursdayReminderKey) ?? false;
  static bool get importantDatesReminder => VoidStorage().readData<bool>(importantDatesReminderKey) ?? true;

  // ---------------------------------------------------------------------------
  // Conversion
  // ---------------------------------------------------------------------------

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The Hijri date of the civil day [date], shifted by [adjustment] days.
  static HijriDate? hijriOf(DateTime date, {int? adjustment}) {
    final shifted = _dateOnly(date).add(Duration(days: adjustment ?? IslamicCalendarService.adjustment));
    try {
      final h = HijriCalendar.fromDate(shifted);
      return HijriDate(h.hYear, h.hMonth, h.hDay);
    } catch (_) {
      return null;
    }
  }

  /// The civil day on which Hijri [date] falls, with the same adjustment.
  static DateTime? gregorianOf(HijriDate date, {int? adjustment}) {
    try {
      final g = HijriCalendar().hijriToGregorian(date.year, date.month, date.day);
      return _dateOnly(g).subtract(Duration(days: adjustment ?? IslamicCalendarService.adjustment));
    } catch (_) {
      return null;
    }
  }

  /// 29 or 30, or null outside the supported range.
  static int? monthLength(int year, int month) {
    try {
      return HijriCalendar().getDaysInMonth(year, month);
    } catch (_) {
      return null;
    }
  }

  /// Month index counted from Muharram [minYear]; used for paging.
  static int monthIndex(int year, int month) => (year - minYear) * 12 + (month - 1);
  static int get monthCount => monthIndex(maxYear, 12) + 1;
  static ({int year, int month}) monthAt(int index) => (year: minYear + index ~/ 12, month: index % 12 + 1);

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Eid al-Fitr, Eid al-Adha and the three Days of Tashreeq.
  static bool isFastingForbidden(HijriDate h) =>
      (h.month == 10 && h.day == 1) || (h.month == 12 && h.day >= 10 && h.day <= 13);

  static bool isRamadan(HijriDate h) => h.month == 9;

  /// The events on Hijri [h], which falls on civil day [date]. Sunnah fasts
  /// are left out on days fasting is forbidden, and in Ramadan (when fasting
  /// is obligatory anyway).
  static List<IslamicEventType> eventsOn(HijriDate h, DateTime date) {
    final events = <IslamicEventType>[];
    final m = h.month;
    final d = h.day;
    if (m == 1 && d == 1) events.add(IslamicEventType.newYear);
    if (m == 1 && d == 9) events.add(IslamicEventType.tasua);
    if (m == 1 && d == 10) events.add(IslamicEventType.ashura);
    if (m == 3 && d == 12) events.add(IslamicEventType.mawlid);
    if (m == 7 && d == 27) events.add(IslamicEventType.israMiraj);
    if (m == 8 && d == 15) events.add(IslamicEventType.midShaban);
    if (m == 9 && d == 1) events.add(IslamicEventType.ramadanStart);
    if (m == 9 && d == 21) events.add(IslamicEventType.lastTenNights);
    // The night belongs to the day after it: the 21st night is the evening
    // before 21 Ramadan.
    if (m == 9 && d >= 21 && d.isOdd) events.add(IslamicEventType.oddNight);
    if (m == 10 && d == 1) events.add(IslamicEventType.eidFitr);
    if (m == 10 && d == 2) events.add(IslamicEventType.shawwalSix);
    if (m == 12 && d == 9) events.add(IslamicEventType.arafah);
    if (m == 12 && d == 10) events.add(IslamicEventType.eidAdha);
    if (m == 12 && d >= 11 && d <= 13) events.add(IslamicEventType.tashreeq);

    if (!isFastingForbidden(h) && !isRamadan(h)) {
      if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) {
        events.add(IslamicEventType.mondayThursday);
      }
      if (d >= 13 && d <= 15) events.add(IslamicEventType.whiteDays);
    }
    return events;
  }

  /// Whether a voluntary fast is recommended on [h] / [date].
  static bool isRecommendedFast(HijriDate h, DateTime date) =>
      !isFastingForbidden(h) && eventsOn(h, date).any(recommendedFasts.contains);

  // ---------------------------------------------------------------------------
  // Reminders
  // ---------------------------------------------------------------------------

  /// Evening-before reminders for the next [days] days after [now], at most
  /// one per day. Fasting reminders are never planned for a day on which
  /// fasting is forbidden; debated events are never planned.
  static List<CalendarReminder> planReminders({
    required DateTime now,
    required bool whiteDays,
    required bool mondayThursday,
    required bool importantDates,
    int? adjustment,
    int days = reminderDays,
  }) {
    final plan = <CalendarReminder>[];
    final today = _dateOnly(now);
    for (int offset = 1; offset <= days; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final fireAt = DateTime(day.year, day.month, day.day - 1, reminderHour);
      if (!fireAt.isAfter(now)) continue;
      final h = hijriOf(day, adjustment: adjustment);
      if (h == null) continue;
      final forbidden = isFastingForbidden(h);

      final wanted = eventsOn(h, day).where((e) {
        if (debatedEvents.contains(e)) return false;
        if (e == IslamicEventType.whiteDays) return whiteDays && !forbidden;
        if (e == IslamicEventType.mondayThursday) return mondayThursday && !forbidden;
        if (recommendedFasts.contains(e) && forbidden) return false;
        return importantDates;
      }).toList();
      if (wanted.isEmpty) continue;
      plan.add(CalendarReminder(day: day, fireAt: fireAt, hijri: h, events: wanted, dayOffset: offset));
    }
    return plan;
  }
}
