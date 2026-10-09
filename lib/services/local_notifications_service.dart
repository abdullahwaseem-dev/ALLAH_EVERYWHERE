import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/data/prayer_reminders_data.dart';
import 'package:allah_everywhere/widgets/prayer_reminder_dialog.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/prayer_calculation.dart';
import 'package:allah_everywhere/data/jumuah_data.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/islamic_calendar.dart';
import 'package:allah_everywhere/adhkar.dart';
import 'package:allah_everywhere/data/adhkar_data.dart';
import 'package:allah_everywhere/services/adhkar_service.dart';
import 'package:allah_everywhere/data/adhan_sounds.dart';
import 'package:allah_everywhere/services/adhan_sound_service.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';
import 'package:allah_everywhere/data/islamic_events_data.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;

/// Schedules the two kinds of local notifications this app sends:
/// - The 5 daily prayer-time (Adhan) alerts, rescheduled every time
///   [PrayerTimesController] recomputes times (see main.dart wiring).
/// - A daily "Read Quran" reminder at a user-chosen time.
/// - Friday (Jumu'ah) reminders: a morning "read Al-Kahf" alert at a
///   user-chosen time, and an optional one an hour before Asr.
/// - Islamic calendar reminders (White Days, Monday/Thursday fasts and
///   important dates) the evening before, for the next 30 days.
/// - Morning/evening adhkar reminders, 30 minutes after Fajr and Asr.
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

  static const _reminderChannelId = 'daily_reminder';

  static const _jumuahEnabledKey = 'jumuah_reminder_enabled';
  static const _jumuahTimeKey = 'jumuah_reminder_time';
  static const _jumuahAsrEnabledKey = 'jumuah_asr_reminder_enabled';
  static const _jumuahChannelId = 'jumuah_reminder';
  static const _openSurahPayload = 'surah:';
  static const _calendarChannelId = 'islamic_calendar';
  static const _openCalendarPayload = 'calendar:';
  static const _adhkarChannelId = 'adhkar_reminder';
  static const _openAdhkarPayload = 'adhkar:';
  static const _challengeChannelId = 'challenges';
  static const _openChallengePayload = 'challenge:';
  static const _challengeRemindersKey = 'challenge_reminders';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Prayer settings from the last [reschedulePrayerNotifications] call. The
  /// Friday Asr reminder needs them, and only PrayerTimesController knows the
  /// location - null until it has found one.
  ({double latitude, double longitude, CalculationMethod method, Madhab madhab})? _lastPrayerArgs;

  /// Payload of the notification that cold-started the app. Opening a screen
  /// from init() would land under the splash/login flow, so HomeScreen
  /// consumes it once it's on screen (see [consumeLaunchPayload]).
  String? _launchPayload;

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

  bool get jumuahReminderEnabled => VoidStorage().readData<bool>(_jumuahEnabledKey) ?? true;
  bool get jumuahAsrReminderEnabled => VoidStorage().readData<bool>(_jumuahAsrEnabledKey) ?? false;

  /// Whether a location is known, i.e. the Friday Asr reminder can be timed.
  bool get hasPrayerLocation => _lastPrayerArgs != null;

  TimeOfDay get jumuahReminderTime {
    final stored = VoidStorage().readData<String>(_jumuahTimeKey);
    if (stored == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = stored.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> setJumuahReminderTime(TimeOfDay time) async {
    await VoidStorage().saveData(_jumuahTimeKey, '${time.hour}:${time.minute}');
    await scheduleJumuahReminder();
  }

  Future<void> setJumuahReminderEnabled(bool enabled) async {
    await VoidStorage().saveData(_jumuahEnabledKey, enabled);
    await scheduleJumuahReminder();
  }

  Future<void> setJumuahAsrReminderEnabled(bool enabled) async {
    await VoidStorage().saveData(_jumuahAsrEnabledKey, enabled);
    await scheduleJumuahAsrReminder();
  }

  // LanguageController persists the chosen language under this same key. Read
  // it directly (rather than via a BuildContext) because notifications are
  // scheduled from services with no widget context available.
  static const _languageCodeKey = 'app_language_code';

  Future<AppLocalizations> _localizations() {
    final code = VoidStorage().readData<String>(_languageCodeKey) ?? 'en';
    return AppLocalizations.delegate.load(Locale(code));
  }

  String _localizedPrayerName(AppLocalizations t, String englishKey) {
    switch (englishKey) {
      case 'Fajr':
        return t.fajr;
      case 'Dhuhr':
        return t.dhuhr;
      case 'Asr':
        return t.asr;
      case 'Maghrib':
        return t.maghrib;
      case 'Isha':
        return t.isha;
      default:
        return englishKey;
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
      // One channel per prayer sound: Android fixes a channel's sound when
      // it's created, so the notification picks the channel for the sound.
      // Placeholder sounds whose files aren't in the app yet are skipped.
      for (final sound in allAdhanSounds.where((s) => s.available)) {
        await android?.createNotificationChannel(_prayerChannel(sound));
      }
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _reminderChannelId,
        'Daily Quran Reminder',
        description: 'A daily reminder to read Quran',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _jumuahChannelId,
        "Jumu'ah Reminder",
        description: 'Friday reminders to read Surah Al-Kahf',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _calendarChannelId,
        'Islamic Calendar',
        description: 'Evening reminders for sunnah fasts and Islamic dates',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _challengeChannelId,
        'Challenges',
        description: 'Updates from your challenges and daily progress reminders',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _adhkarChannelId,
        'Adhkar Reminder',
        description: 'Reminders for the morning and evening adhkar',
        importance: Importance.defaultImportance,
      ));

      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch!.notificationResponse?.payload;
      }

      _initialized = true;
    } catch (e) {
      VoidLogger.error('Failed to initialize local notifications', e);
    }
    // On by default, so it must be scheduled without a visit to Settings.
    // Re-issuing it on every launch also keeps its text in the current
    // language.
    await scheduleJumuahReminder();
    // Only the next 30 days are scheduled, so top them up on every launch -
    // in the background, since init() runs before the first frame.
    unawaited(scheduleIslamicCalendarReminders());
    unawaited(scheduleChallengeReminders());
  }

  /// Opens whatever the launching notification points at (Surah Al-Kahf for
  /// the Friday reminder). Returns once; later calls do nothing.
  void consumeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    if (payload != null) _handlePayload(payload);
  }

  /// Reschedules the 5 daily prayer-time notifications across a rolling
  /// [_prayerScheduleDays]-day window (not just today), computing each
  /// day's times directly from [latitude]/[longitude] rather than relying
  /// on a single precomputed "today" map. This means notifications keep
  /// firing for days after the app was last opened, instead of silently
  /// stopping the day after the user last launched the app - a real
  /// complaint from testers when the previous version only ever scheduled
  /// today's 5 prayers.
  ///
  /// Wrapped entirely in try/catch: a plugin/platform failure here must
  /// never become an uncaught error, since this is frequently invoked from
  /// fire-and-forget call sites (e.g. PrayerTimesController right after a
  /// location fetch) with no caller around to catch it.
  Future<void> reschedulePrayerNotifications({
    required double latitude,
    required double longitude,
    required CalculationMethod calculationMethod,
    required Madhab madhab,
  }) async {
    _lastPrayerArgs = (latitude: latitude, longitude: longitude, method: calculationMethod, madhab: madhab);
    // Asr moves with location/method/madhab, so it's re-timed alongside the
    // prayers. Has its own try/catch, so it can't break prayer scheduling.
    await scheduleJumuahAsrReminder();
    // Same for the adhkar reminders, which follow Fajr and Asr.
    await scheduleAdhkarReminders();
    try {
      for (int i = 0; i < _prayerScheduleDays * _prayersPerDay; i++) {
        await _plugin.cancel(_prayerBaseId + i);
      }
      // Also clear the old fixed 5-id scheme from earlier app versions, so
      // upgraders don't end up with stale duplicate notifications.
      for (final legacyId in _legacyPrayerIds) {
        await _plugin.cancel(legacyId);
      }
      if (!notificationsEnabled) return;

      final coordinates = Coordinates(latitude, longitude);

      final t = await _localizations();
      // For Arabic, use the original ayah/hadith text; other languages only
      // have the English translation available in the curated data.
      final useArabicBody = (VoidStorage().readData<String>(_languageCodeKey) ?? 'en') == 'ar';
      final now = DateTime.now();

      var id = _prayerBaseId;
      for (int dayOffset = 0; dayOffset < _prayerScheduleDays; dayOffset++) {
        final day = now.add(Duration(days: dayOffset));
        final prayerTimes = PrayerTimes(
          coordinates,
          DateComponents.from(day),
          prayerParameters(calculationMethod, madhab, day),
        );
        final dayEntries = {
          'Fajr': prayerTimes.fajr,
          'Dhuhr': prayerTimes.dhuhr,
          'Asr': prayerTimes.asr,
          'Maghrib': prayerTimes.maghrib,
          'Isha': prayerTimes.isha,
        };

        for (final entry in dayEntries.entries) {
          final thisId = id++;
          final scheduledTime = entry.value;
          if (scheduledTime.isBefore(now)) {
            continue; // that prayer already passed - nothing to schedule
          }
          // The user's Adhan / Beep / Silent / Off choice for this prayer.
          final sound = AdhanSoundService.soundForPrayer(entry.key);
          if (sound == null) continue;
          // Rotates through the curated reminders by day-of-year and prayer
          // slot, so the 5 daily notifications each carry a different
          // ayah/hadith, and the set changes from day to day.
          final dayOfYear = scheduledTime.difference(DateTime(scheduledTime.year)).inDays;
          final reminderIndex = (dayOfYear + (thisId - _prayerBaseId)) % prayerReminders.length;
          final reminder = prayerReminders[reminderIndex];
          final reminderText = useArabicBody ? reminder.arabic : reminder.translation;
          final body = '$reminderText — ${reminder.reference}';
          final title = t.prayerTimeTitle(_localizedPrayerName(t, entry.key));
          try {
            await _plugin.zonedSchedule(
              thisId,
              title,
              body,
              tz.TZDateTime.from(scheduledTime, tz.local),
              _prayerDetails(sound, title, body),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'reminder:$reminderIndex',
            );
          } catch (e) {
            VoidLogger.error('Failed to schedule ${entry.key} notification', e);
          }
        }
      }
    } catch (e) {
      VoidLogger.error('Failed to reschedule prayer notifications', e);
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

    final t = await _localizations();

    try {
      await _plugin.zonedSchedule(
        _reminderNotificationId,
        t.quranReminderTitle,
        t.quranReminderBody,
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

  /// The next Friday (today if it's Friday and [at] hasn't passed yet) at
  /// [at], in local time.
  tz.TZDateTime _nextFridayAt(TimeOfDay at) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, at.hour, at.minute);
    while (scheduled.weekday != DateTime.friday || scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(tz.local, scheduled.year, scheduled.month, scheduled.day + 1, at.hour, at.minute);
    }
    return scheduled;
  }

  NotificationDetails _jumuahDetails(String title, String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _jumuahChannelId,
        "Jumu'ah Reminder",
        channelDescription: 'Friday reminders to read Surah Al-Kahf',
        importance: Importance.defaultImportance,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      ),
      iOS: const DarwinNotificationDetails(presentSound: true),
    );
  }

  /// Weekly Friday-morning reminder to read Surah Al-Kahf; tapping it opens
  /// the surah.
  Future<void> scheduleJumuahReminder() async {
    try {
      await _plugin.cancel(_jumuahNotificationId);
      if (!notificationsEnabled || !jumuahReminderEnabled) return;

      final t = await _localizations();
      final title = t.jumuahReminderTitle;
      final body = t.jumuahReminderBody;
      await _plugin.zonedSchedule(
        _jumuahNotificationId,
        title,
        body,
        _nextFridayAt(jumuahReminderTime),
        _jumuahDetails(title, body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '$_openSurahPayload$jumuahSurahNumber',
      );
    } catch (e) {
      VoidLogger.error("Failed to schedule Jumu'ah reminder", e);
    }
  }

  /// Weekly Friday reminder an hour before Asr about the hour of accepted
  /// duas. Repeats at next Friday's time; Asr only drifts a few minutes a
  /// week and this is re-timed whenever prayers are rescheduled. Skipped
  /// until a location is known.
  Future<void> scheduleJumuahAsrReminder() async {
    try {
      await _plugin.cancel(_jumuahAsrNotificationId);
      final args = _lastPrayerArgs;
      if (!notificationsEnabled || !jumuahAsrReminderEnabled || args == null) return;

      // Asr on the coming Friday (today included while it's still ahead).
      final now = DateTime.now();
      DateTime? scheduled;
      for (int dayOffset = 0; dayOffset <= 7 && scheduled == null; dayOffset++) {
        final day = DateTime(now.year, now.month, now.day + dayOffset);
        if (day.weekday != DateTime.friday) continue;
        final asr = PrayerTimes(
          Coordinates(args.latitude, args.longitude),
          DateComponents.from(day),
          prayerParameters(args.method, args.madhab, day),
        ).asr.subtract(const Duration(hours: 1));
        if (asr.isAfter(now)) scheduled = asr;
      }
      if (scheduled == null) return;

      final t = await _localizations();
      final title = t.jumuahAsrReminderTitle;
      final body = t.jumuahAsrReminderBody(jumuahAcceptedHourReference);
      await _plugin.zonedSchedule(
        _jumuahAsrNotificationId,
        title,
        body,
        tz.TZDateTime.from(scheduled, tz.local),
        _jumuahDetails(title, body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      VoidLogger.error("Failed to schedule Jumu'ah Asr reminder", e);
    }
  }

  /// Re-issues both Friday reminders, e.g. after a language change.
  Future<void> scheduleJumuahReminders() async {
    await scheduleJumuahReminder();
    await scheduleJumuahAsrReminder();
  }

  /// Evening-before reminders for the next 30 days, per the three Settings
  /// toggles (see [IslamicCalendarService.planReminders] for what's planned
  /// and what's never planned, e.g. fasts on Eid). One notification per day,
  /// id 500 + days from today.
  Future<void> scheduleIslamicCalendarReminders() async {
    try {
      for (int id = _calendarBaseId; id <= _calendarMaxId; id++) {
        await _plugin.cancel(id);
      }
      if (!notificationsEnabled) return;

      final plan = IslamicCalendarService.planReminders(
        now: DateTime.now(),
        whiteDays: IslamicCalendarService.whiteDaysReminder,
        mondayThursday: IslamicCalendarService.mondayThursdayReminder,
        importantDates: IslamicCalendarService.importantDatesReminder,
      );
      if (plan.isEmpty) return;

      final t = await _localizations();
      for (final reminder in plan) {
        final id = _calendarBaseId + reminder.dayOffset;
        if (id > _calendarMaxId) break;
        final names = reminder.events.map((e) => islamicEventName(t, e)).join(' · ');
        final title = t.calendarReminderTitle(names);
        final lines = <String>[
          formatHijriDate(t, reminder.hijri),
          if (IslamicCalendarService.isFastingForbidden(reminder.hijri))
            t.calendarFastingForbidden
          else if (reminder.isFast)
            t.calendarReminderFastBody
          else
            t.calendarReminderEventBody,
          if (reminder.events.any(moonSightingEvents.contains)) t.calendarExpectedNote,
        ];
        final body = lines.join('\n');
        final d = reminder.day;
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(reminder.fireAt, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                _calendarChannelId,
                'Islamic Calendar',
                channelDescription: 'Evening reminders for sunnah fasts and Islamic dates',
                importance: Importance.defaultImportance,
                styleInformation: BigTextStyleInformation(body, contentTitle: title),
              ),
              iOS: const DarwinNotificationDetails(presentSound: true),
            ),
            // Inexact is fine for an evening heads-up, and keeps 30 alarms
            // from counting against Android's exact-alarm budget.
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: '$_openCalendarPayload${d.year}-${d.month}-${d.day}',
          );
        } catch (e) {
          VoidLogger.error('Failed to schedule calendar reminder $id', e);
        }
      }
    } catch (e) {
      VoidLogger.error('Failed to schedule Islamic calendar reminders', e);
    }
  }

  static AndroidNotificationChannel _prayerChannel(AdhanSound sound) => AndroidNotificationChannel(
        sound.channelId,
        sound.channelName,
        description: 'Prayer-time alerts',
        importance: sound.kind == AdhanSoundKind.silent ? Importance.high : Importance.max,
        playSound: sound.kind != AdhanSoundKind.silent,
        // null = the device's default notification sound (the "beep").
        sound: sound.androidRaw == null ? null : RawResourceAndroidNotificationSound(sound.androidRaw!),
      );

  /// Notification details for a prayer alert with [sound]. The Android
  /// channel carries the sound; iOS names a bundled .caf (30 s or less).
  NotificationDetails _prayerDetails(AdhanSound sound, String title, String body) {
    final channel = _prayerChannel(sound);
    final isAdhan = sound.kind == AdhanSoundKind.adhan;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        playSound: channel.playSound,
        sound: channel.sound,
        // Adhans play through the alarm stream, like an alarm clock; the beep
        // and silent alerts behave like normal notifications.
        audioAttributesUsage: isAdhan ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      ),
      iOS: DarwinNotificationDetails(
        sound: isAdhan ? sound.iosFile : null,
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: sound.kind != AdhanSoundKind.silent,
      ),
    );
  }

  /// Daily reminders [AdhkarService.reminderDelay] after Fajr (morning
  /// adhkar) and Asr (evening adhkar). Each repeats daily at its next
  /// occurrence's time; Fajr and Asr drift only a minute or two a day and
  /// these are re-timed whenever prayers are rescheduled (e.g. every launch).
  /// Skipped until a location is known.
  Future<void> scheduleAdhkarReminders() async {
    try {
      await _plugin.cancel(_adhkarMorningNotificationId);
      await _plugin.cancel(_adhkarEveningNotificationId);
      final args = _lastPrayerArgs;
      if (!notificationsEnabled || args == null) return;

      final t = await _localizations();
      final now = DateTime.now();
      for (final time in AdhkarTime.values) {
        final morning = time == AdhkarTime.morning;
        if (!(morning ? AdhkarService.morningReminderEnabled : AdhkarService.eveningReminderEnabled)) continue;

        DateTime? scheduled;
        for (int dayOffset = 0; dayOffset <= 1 && scheduled == null; dayOffset++) {
          final day = DateTime(now.year, now.month, now.day + dayOffset);
          final prayers = PrayerTimes(
            Coordinates(args.latitude, args.longitude),
            DateComponents.from(day),
            prayerParameters(args.method, args.madhab, day),
          );
          final at = (morning ? prayers.fajr : prayers.asr).add(AdhkarService.reminderDelay);
          if (at.isAfter(now)) scheduled = at;
        }
        if (scheduled == null) continue;

        final title = morning ? t.adhkarMorningReminderTitle : t.adhkarEveningReminderTitle;
        final body = morning ? t.adhkarMorningReminderBody : t.adhkarEveningReminderBody;
        await _plugin.zonedSchedule(
          morning ? _adhkarMorningNotificationId : _adhkarEveningNotificationId,
          title,
          body,
          tz.TZDateTime.from(scheduled, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _adhkarChannelId,
              'Adhkar Reminder',
              channelDescription: 'Reminders for the morning and evening adhkar',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(presentSound: true),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '$_openAdhkarPayload${time.name}',
        );
      }
    } catch (e) {
      VoidLogger.error('Failed to schedule adhkar reminders', e);
    }
  }

  // --- Challenge reminders (ids 700-799) ---------------------------------------

  /// The stored per-challenge reminders: challenge id -> slot (0-99, the id
  /// is 700 + slot), time, title and end date.
  Map<String, Map<String, dynamic>> _challengeReminders() {
    final raw = VoidStorage().readData<Object>(_challengeRemindersKey);
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is Map) e.key as String: Map<String, dynamic>.from(e.value as Map),
    };
  }

  /// The daily "Log your progress" time for [challengeId], or null if off.
  TimeOfDay? challengeReminderTime(String challengeId) {
    final r = _challengeReminders()[challengeId];
    if (r == null || r['hour'] is! int || r['minute'] is! int) return null;
    return TimeOfDay(hour: r['hour'] as int, minute: r['minute'] as int);
  }

  /// Sets (or with a null [time], removes) [challengeId]'s daily reminder.
  /// Returns false if all 100 reminder slots are taken.
  Future<bool> setChallengeReminder(String challengeId,
      {required String title, required DateTime endAt, TimeOfDay? time}) async {
    final all = _challengeReminders();
    final existing = all.remove(challengeId);
    if (existing != null) await _plugin.cancel(_challengeBaseId + (existing['slot'] as int? ?? 0));
    if (time != null) {
      final used = {for (final r in all.values) r['slot']};
      final slot = existing?['slot'] as int? ??
          List.generate(_challengeMaxSlots, (i) => i).where((i) => !used.contains(i)).firstOrNull;
      if (slot == null) return false;
      all[challengeId] = {
        'slot': slot,
        'hour': time.hour,
        'minute': time.minute,
        'title': title,
        'endAt': endAt.millisecondsSinceEpoch,
      };
    }
    await VoidStorage().saveData(_challengeRemindersKey, all);
    if (time != null) await scheduleChallengeReminders();
    return true;
  }

  /// (Re)schedules every challenge reminder in the current language and
  /// drops those whose challenge has ended. Runs on every launch.
  Future<void> scheduleChallengeReminders() async {
    try {
      final all = _challengeReminders();
      final now = DateTime.now();
      final ended = [
        for (final e in all.entries)
          if (DateTime.fromMillisecondsSinceEpoch(e.value['endAt'] as int? ?? 0).isBefore(now)) e.key,
      ];
      for (final id in ended) {
        await _plugin.cancel(_challengeBaseId + (all.remove(id)!['slot'] as int? ?? 0));
      }
      if (ended.isNotEmpty) await VoidStorage().saveData(_challengeRemindersKey, all);
      if (!notificationsEnabled || all.isEmpty) return;

      final t = await _localizations();
      final tzNow = tz.TZDateTime.now(tz.local);
      for (final e in all.entries) {
        final r = e.value;
        final slot = r['slot'] as int? ?? 0;
        var at = tz.TZDateTime(tz.local, tzNow.year, tzNow.month, tzNow.day, r['hour'] as int? ?? 20, r['minute'] as int? ?? 0);
        if (at.isBefore(tzNow)) at = at.add(const Duration(days: 1));
        await _plugin.zonedSchedule(
          _challengeBaseId + slot,
          t.challengesTitle,
          t.challengesReminderBody(r['title'] as String? ?? ''),
          at,
          NotificationDetails(
            android: const AndroidNotificationDetails(
              _challengeChannelId,
              'Challenges',
              channelDescription: 'Updates from your challenges and daily progress reminders',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(presentSound: true, threadIdentifier: 'challenge_${e.key}'),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '$_openChallengePayload${e.key}',
        );
      }
    } catch (e) {
      VoidLogger.error('Failed to schedule challenge reminders', e);
    }
  }

  /// Opens Surah [surahId] in the reader. Used by the Friday notification
  /// and the Home screen's Jumu'ah card.
  static void openSurah(int surahId) {
    Get.to(() => SurahScreen(surahName: quran.getSurahName(surahId), surahId: surahId));
  }

  /// Tapping a prayer-time notification reopens the full reminder as an
  /// in-app dialog (Arabic text + reference, which doesn't fit in the
  /// notification body itself). Static because it's registered once with
  /// the plugin and may run before any screen is on-screen.
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    _handlePayload(payload);
  }

  static void _handlePayload(String payload) {
    if (payload.startsWith(_openChallengePayload)) {
      openChallenge(payload.substring(_openChallengePayload.length));
      return;
    }
    if (payload.startsWith(_openAdhkarPayload)) {
      final name = payload.substring(_openAdhkarPayload.length);
      final time = AdhkarTime.values.where((t) => t.name == name).firstOrNull;
      Get.to(() => AdhkarScreen(initialTime: time));
      return;
    }
    if (payload.startsWith(_openCalendarPayload)) {
      final parts = payload.substring(_openCalendarPayload.length).split('-').map(int.tryParse).toList();
      final date = parts.length == 3 && !parts.contains(null) ? DateTime(parts[0]!, parts[1]!, parts[2]!) : null;
      Get.to(() => IslamicCalendarScreen(initialDate: date));
      return;
    }
    if (payload.startsWith(_openSurahPayload)) {
      final surahId = int.tryParse(payload.substring(_openSurahPayload.length));
      if (surahId != null && surahId >= 1 && surahId <= quran.totalSurahCount) openSurah(surahId);
      return;
    }
    if (!payload.startsWith('reminder:')) return;
    final index = int.tryParse(payload.substring('reminder:'.length));
    if (index == null || index < 0 || index >= prayerReminders.length) return;
    showPrayerReminderDialog(prayerReminders[index]);
  }

  /// Cancels every scheduled notification this service owns - called when
  /// the Settings "Notification" master toggle is turned off.
  Future<void> cancelAll() async {
    for (int i = 0; i < _prayerScheduleDays * _prayersPerDay; i++) {
      await _plugin.cancel(_prayerBaseId + i);
    }
    for (final legacyId in _legacyPrayerIds) {
      await _plugin.cancel(legacyId);
    }
    await _plugin.cancel(_reminderNotificationId);
    await _plugin.cancel(_jumuahNotificationId);
    await _plugin.cancel(_jumuahAsrNotificationId);
    await _plugin.cancel(_adhkarMorningNotificationId);
    await _plugin.cancel(_adhkarEveningNotificationId);
    for (int id = _calendarBaseId; id <= _calendarMaxId; id++) {
      await _plugin.cancel(id);
    }
    for (int id = _challengeBaseId; id < _challengeBaseId + _challengeMaxSlots; id++) {
      await _plugin.cancel(id);
    }
  }

  static const int _prayerBaseId = 300;
  static const int _prayerScheduleDays = 7;
  static const int _prayersPerDay = 5;
  static const List<int> _legacyPrayerIds = [100, 101, 102, 103, 104];
  static const int _reminderNotificationId = 200;
  static const int _jumuahNotificationId = 400;
  static const int _jumuahAsrNotificationId = 401;
  static const int _adhkarMorningNotificationId = 410;
  static const int _adhkarEveningNotificationId = 411;
  static const int _calendarBaseId = 500;
  // Challenges own ids 700-799: one daily reminder per challenge.
  static const int _challengeBaseId = 700;
  static const int _challengeMaxSlots = 100;
  // Ids 500-599 are reserved for the calendar; only 501-530 are used
  // (one per day of the 30-day window), so only those are cancelled.
  static const int _calendarMaxId = _calendarBaseId + IslamicCalendarService.reminderDays;
}
