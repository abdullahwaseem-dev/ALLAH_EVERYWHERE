import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/widgets/prayer_reminder_dialog.dart';

/// Schedules the two kinds of local notifications this app sends:
/// - The 5 daily prayer-time (Adhan) alerts, rescheduled every time
///   [PrayerTimesController] recomputes times (see main.dart wiring).
/// - A daily "Read Quran" reminder at a user-chosen time.
///
/// Both are gated by the Settings "Notification" master toggle. Scheduling
/// only happens while the app is open at least once that day (there's no
/// native boot-time rescheduler here) - acceptable for an app opened daily
/// to check prayer times, but not a guarantee for days the app never runs.
class LocalNotificationsService {
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  static const notificationsEnabledKey = 'notifications_enabled';
  static const _reminderTimeKey = 'quran_reminder_time';
  static const _reminderEnabledKey = 'quran_reminder_enabled';

  static const _prayerChannelId = 'prayer_times';
  static const _reminderChannelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get notificationsEnabled => VoidStorage().readData<bool>(notificationsEnabledKey) ?? true;
  bool get quranReminderEnabled => VoidStorage().readData<bool>(_reminderEnabledKey) ?? false;

  TimeOfDay get reminderTime {
    final stored = VoidStorage().readData<String>(_reminderTimeKey);
    if (stored == null) return const TimeOfDay(hour: 20, minute: 0);
    final parts = stored.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await VoidStorage().saveData(_reminderTimeKey, '${time.hour}:${time.minute}');
    if (quranReminderEnabled) await scheduleDailyQuranReminder();
  }

  Future<void> setQuranReminderEnabled(bool enabled) async {
    await VoidStorage().saveData(_reminderEnabledKey, enabled);
    if (enabled) {
      await scheduleDailyQuranReminder();
    } else {
      await _plugin.cancel(_reminderNotificationId);
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _prayerChannelId,
        'Prayer Times',
        description: 'Adhan alerts for the 5 daily prayers',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('adhan'),
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _reminderChannelId,
        'Daily Quran Reminder',
        description: 'A daily reminder to read Quran',
        importance: Importance.defaultImportance,
      ));

      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (e) {
      VoidLogger.error('Failed to initialize local notifications', e);
    }
  }

  /// Reschedules the 5 prayer-time notifications for today's computed
  /// times. Called whenever PrayerTimesController recomputes.
  Future<void> reschedulePrayerNotifications(Map<String, DateTime> prayerTimes) async {
    for (int i = 0; i < _prayerIds.length; i++) {
      await _plugin.cancel(_prayerIds[i]);
    }
    if (!notificationsEnabled || prayerTimes.isEmpty) return;

    var id = _prayerIds.first;
    for (final entry in prayerTimes.entries) {
      var scheduledTime = entry.value;
      if (scheduledTime.isBefore(DateTime.now())) {
        continue; // that prayer already passed today - nothing to schedule
      }
      // Rotates through the curated reminders by day-of-year and prayer
      // slot, so the 5 daily notifications each carry a different
      // ayah/hadith, and the set changes from day to day.
      final dayOfYear = scheduledTime.difference(DateTime(scheduledTime.year)).inDays;
      final reminderIndex = (dayOfYear + (id - _prayerIds.first)) % prayerReminders.length;
      final reminder = prayerReminders[reminderIndex];
      final body = '${reminder.translation} — ${reminder.reference}';
      final title = '${entry.key} - it is time to pray';
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _prayerChannelId,
              'Prayer Times',
              channelDescription: 'Adhan alerts for the 5 daily prayers',
              importance: Importance.max,
              priority: Priority.high,
              sound: const RawResourceAndroidNotificationSound('adhan'),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              styleInformation: BigTextStyleInformation(body, contentTitle: title),
            ),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'reminder:$reminderIndex',
        );
      } catch (e) {
        VoidLogger.error('Failed to schedule ${entry.key} notification', e);
      }
      id++;
    }
  }

  Future<void> scheduleDailyQuranReminder() async {
    await _plugin.cancel(_reminderNotificationId);
    if (!notificationsEnabled || !quranReminderEnabled) return;

    final time = reminderTime;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        _reminderNotificationId,
        'Time to read Quran',
        "Take a few minutes today for your daily Quran reading.",
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            'Daily Quran Reminder',
            channelDescription: 'A daily reminder to read Quran',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      VoidLogger.error('Failed to schedule daily Quran reminder', e);
    }
  }

  /// Tapping a prayer-time notification reopens the full reminder as an
  /// in-app dialog (Arabic text + reference, which doesn't fit in the
  /// notification body itself). Static because it's registered once with
  /// the plugin and may run before any screen is on-screen.
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('reminder:')) return;
    final index = int.tryParse(payload.substring('reminder:'.length));
    if (index == null || index < 0 || index >= prayerReminders.length) return;
    showPrayerReminderDialog(prayerReminders[index]);
  }

  /// Cancels every scheduled notification this service owns - called when
  /// the Settings "Notification" master toggle is turned off.
  Future<void> cancelAll() async {
    for (final id in _prayerIds) {
      await _plugin.cancel(id);
    }
    await _plugin.cancel(_reminderNotificationId);
  }

  static const List<int> _prayerIds = [100, 101, 102, 103, 104];
  static const int _reminderNotificationId = 200;
}
