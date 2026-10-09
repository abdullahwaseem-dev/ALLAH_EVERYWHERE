import 'package:allah_everywhere/data/adhkar_data.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Today's progress through one adhkar set: how many repetitions of each
/// dhikr are done. Resets on a new day.
class AdhkarProgress {
  final String date;
  final Map<String, int> done;

  const AdhkarProgress({required this.date, this.done = const {}});

  int doneOf(Dhikr dhikr) => (done[dhikr.id] ?? 0).clamp(0, dhikr.repeat);
  int remainingOf(Dhikr dhikr) => dhikr.repeat - doneOf(dhikr);
  bool isComplete(Dhikr dhikr) => remainingOf(dhikr) == 0;

  /// Index of the first dhikr not yet finished, or [adhkar].length if all are.
  int firstIncomplete(List<Dhikr> adhkar) {
    final i = adhkar.indexWhere((d) => !isComplete(d));
    return i == -1 ? adhkar.length : i;
  }

  int completedCount(List<Dhikr> adhkar) => adhkar.where(isComplete).length;

  AdhkarProgress withCount(Dhikr dhikr, int count) =>
      AdhkarProgress(date: date, done: {...done, dhikr.id: count.clamp(0, dhikr.repeat)});

  Map<String, dynamic> toMap() => {'date': date, 'done': done};

  /// Defensive: stored data may be missing, malformed, or from another day.
  static AdhkarProgress fromStored(Object? raw, String today) {
    if (raw is! Map || raw['date'] != today || raw['done'] is! Map) return AdhkarProgress(date: today);
    final done = <String, int>{};
    (raw['done'] as Map).forEach((k, v) {
      if (k is String && v is num && v >= 0) done[k] = v.toInt();
    });
    return AdhkarProgress(date: today, done: done);
  }
}

/// Morning/evening adhkar: saved progress, "completed today", which set to
/// open, reminder settings, and the link to the Tasbeeh totals.
class AdhkarService {
  static const _progressKeyPrefix = 'adhkar_progress_';
  static const _completedKeyPrefix = 'adhkar_completed_';
  static const morningReminderKey = 'adhkar_morning_reminder';
  static const eveningReminderKey = 'adhkar_evening_reminder';

  /// Reminders go out this long after Fajr / Asr.
  static const reminderDelay = Duration(minutes: 30);

  final TasbeehService _tasbeeh;

  AdhkarService({TasbeehService? tasbeeh}) : _tasbeeh = tasbeeh ?? TasbeehService();

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Morning from Fajr until Asr; evening from Asr until the next Fajr (the
  /// evening adhkar may still be said after Maghrib). Without prayer times
  /// (no location yet), 4 AM and 3 PM stand in for Fajr and Asr.
  static AdhkarTime suggestedTime(DateTime now, {DateTime? fajr, DateTime? asr}) {
    final f = fajr ?? DateTime(now.year, now.month, now.day, 4);
    final a = asr ?? DateTime(now.year, now.month, now.day, 15);
    return !now.isBefore(f) && now.isBefore(a) ? AdhkarTime.morning : AdhkarTime.evening;
  }

  static bool get morningReminderEnabled => VoidStorage().readData<bool>(morningReminderKey) ?? false;
  static bool get eveningReminderEnabled => VoidStorage().readData<bool>(eveningReminderKey) ?? false;

  AdhkarProgress progress(AdhkarTime time, {DateTime? now}) {
    try {
      return AdhkarProgress.fromStored(
        VoidStorage().readData<Object>('$_progressKeyPrefix${time.name}'),
        dateKey(now ?? DateTime.now()),
      );
    } catch (e) {
      VoidLogger.error('Saved adhkar progress was unreadable', e);
      return AdhkarProgress(date: dateKey(now ?? DateTime.now()));
    }
  }

  Future<void> saveProgress(AdhkarTime time, AdhkarProgress progress) =>
      VoidStorage().saveData('$_progressKeyPrefix${time.name}', progress.toMap());

  bool isCompletedToday(AdhkarTime time, {DateTime? now}) =>
      VoidStorage().readData<String>('$_completedKeyPrefix${time.name}') == dateKey(now ?? DateTime.now());

  Future<void> markCompletedToday(AdhkarTime time, {DateTime? now}) =>
      VoidStorage().saveData('$_completedKeyPrefix${time.name}', dateKey(now ?? DateTime.now()));

  /// Adds finished repetitions to the Tasbeeh lifetime and today's totals.
  Future<void> addToTasbeehTotals(int count) => _tasbeeh.addToLifetimeTotal(count);
}
