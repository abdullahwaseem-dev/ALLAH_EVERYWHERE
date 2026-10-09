import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:allah_everywhere/data/daily_reminder_data.dart';
import 'package:allah_everywhere/data/islamic_events_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/islamic_calendar_service.dart';
import 'package:allah_everywhere/services/prayer_calculation.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Feeds the home screen widgets (iOS WidgetKit / Android App Widgets):
/// Next Prayer, Hijri Date and Verse/Hadith of the Day.
///
/// Widgets can't run Dart, so everything they show is computed here, in the
/// app language, for several days ahead - the widgets then pick today's
/// entry themselves and stay correct even if the app isn't opened for a
/// while. All of it is local; nothing needs the internet.
class HomeWidgetService {
  /// iOS App Group shared with the widget extension.
  static const appGroupId = 'group.com.allaheverywhere.app';

  /// Single JSON payload, so a widget never sees half an update.
  static const dataKey = 'widget_data';

  static const iOSWidgetKind = ['NextPrayerWidget', 'HijriDateWidget', 'DailyReminderWidget'];
  static const androidProviders = [
    'com.allaheverywhere.app.widgets.NextPrayerWidgetProvider',
    'com.allaheverywhere.app.widgets.HijriDateWidgetProvider',
    'com.allaheverywhere.app.widgets.DailyReminderWidgetProvider',
  ];

  static const _prayerDays = 7;
  static const _hijriDays = 30;
  static const _reminderDays = 14;

  // Same keys PrayerTimesController stores its settings and location under.
  static const _lastLatKey = 'prayer_last_latitude';
  static const _lastLngKey = 'prayer_last_longitude';
  static const _methodKey = 'prayer_calculation_method';
  static const _madhabKey = 'prayer_madhab';
  static const _countryKey = 'prayer_country_code';

  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Builds the payload. Pure apart from [now], so it can be unit tested.
  static Map<String, dynamic> buildPayload({
    required AppLocalizations t,
    required String languageCode,
    required DateTime now,
    double? latitude,
    double? longitude,
    CalculationMethod? method,
    Madhab? madhab,
    int hijriAdjustment = 0,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final names = {
      'Fajr': t.fajr,
      'Dhuhr': t.dhuhr,
      'Asr': t.asr,
      'Maghrib': t.maghrib,
      'Isha': t.isha,
    };
    final timeFormat = DateFormat('hh:mm a');

    final prayers = <Map<String, dynamic>>[];
    if (latitude != null && longitude != null && method != null && madhab != null) {
      for (var i = 0; i < _prayerDays; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final times = PrayerTimes(Coordinates(latitude, longitude), DateComponents.from(day),
            prayerParameters(method, madhab, day));
        final byName = {
          'Fajr': times.fajr,
          'Dhuhr': times.dhuhr,
          'Asr': times.asr,
          'Maghrib': times.maghrib,
          'Isha': times.isha,
        };
        prayers.add({
          'day': dayKey(day),
          'items': [
            for (final e in byName.entries)
              {
                'id': e.key.toLowerCase(),
                'n': names[e.key],
                't': e.value.toLocal().millisecondsSinceEpoch,
                's': timeFormat.format(e.value.toLocal()),
              },
          ],
        });
      }
    }

    final hijri = <Map<String, dynamic>>[];
    for (var i = 0; i < _hijriDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final h = IslamicCalendarService.hijriOf(day, adjustment: hijriAdjustment);
      if (h == null) continue; // outside the Umm al-Qura table
      final events = IslamicCalendarService.eventsOn(h, day)
          .where((e) => e != IslamicEventType.mondayThursday && e != IslamicEventType.whiteDays);
      hijri.add({
        'day': dayKey(day),
        'h': formatHijriDate(t, h),
        'd': '${h.day}',
        'm': t.hijriMonthName('${h.month}'),
        'y': t.hijriYear('${h.year}'),
        'g': DateFormat('EEE, dd MMM yyyy').format(day),
        'e': events.isEmpty ? '' : islamicEventName(t, events.first),
      });
    }

    final reminders = <Map<String, dynamic>>[];
    for (var i = 0; i < _reminderDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final r = reminderForDay(day);
      reminders.add({
        'day': dayKey(day),
        'title': r.isHadith ? t.hadithOfTheDay : t.verseOfTheDay,
        'ar': r.arabic,
        'tr': r.translation,
        'ref': r.reference,
      });
    }

    return {
      'v': 1,
      'lang': languageCode,
      'rtl': const {'ar', 'ur'}.contains(languageCode),
      'labels': {
        'next': t.widgetNextPrayer,
        'prayers': t.widgetPrayerTimes,
        'setLocation': t.widgetSetLocation,
        'openApp': t.widgetOpenApp,
      },
      'prayers': prayers,
      'hijri': hijri,
      'reminders': reminders,
    };
  }

  /// Recomputes and pushes the data to every widget. Safe to call often and
  /// from anywhere; failures (e.g. no widget extension in tests) are logged.
  static Future<void> sync({
    double? latitude,
    double? longitude,
    CalculationMethod? method,
    Madhab? madhab,
  }) async {
    try {
      final storage = VoidStorage();
      final languageCode = storage.readData<String>('app_language_code') ?? 'en';
      final t = lookupAppLocalizations(Locale(languageCode));
      final lat = latitude ?? (storage.readData<num>(_lastLatKey))?.toDouble();
      final lng = longitude ?? (storage.readData<num>(_lastLngKey))?.toDouble();
      final payload = buildPayload(
        t: t,
        languageCode: languageCode,
        now: DateTime.now(),
        latitude: lat,
        longitude: lng,
        method: method ?? _storedMethod(storage),
        madhab: madhab ?? (storage.readData<String>(_madhabKey) == 'hanafi' ? Madhab.hanafi : Madhab.shafi),
        hijriAdjustment: IslamicCalendarService.adjustment,
      );
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(payload));
      for (final kind in iOSWidgetKind) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
      for (final provider in androidProviders) {
        await HomeWidget.updateWidget(qualifiedAndroidName: provider);
      }
    } catch (e) {
      VoidLogger.error('Home screen widget update failed', e);
    }
  }

  /// The method chosen in Settings, else automatic for the saved country -
  /// the same rule PrayerTimesController uses.
  static CalculationMethod _storedMethod(VoidStorage storage) {
    final stored = storage.readData<String>(_methodKey);
    for (final m in CalculationMethod.values) {
      if (m.name == stored) return m;
    }
    return methodForCountry(storage.readData<String>(_countryKey));
  }
}
