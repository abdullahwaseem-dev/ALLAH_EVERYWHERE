import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/data/daily_reminder_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/services/home_widget_service.dart';

void main() {
  final now = DateTime(2026, 10, 8, 14, 30);

  Map<String, dynamic> payload(String lang, {bool located = true}) => HomeWidgetService.buildPayload(
        t: lookupAppLocalizations(Locale(lang)),
        languageCode: lang,
        now: now,
        latitude: located ? 31.5204 : null, // Lahore
        longitude: located ? 74.3587 : null,
        method: CalculationMethod.karachi,
        madhab: Madhab.hanafi,
      );

  test('a week of prayer times, five a day, in order and localized', () {
    final p = payload('ar');
    final days = p['prayers'] as List;
    expect(days.length, 7);
    expect(days.first['day'], '2026-10-08');
    for (final day in days) {
      final items = (day['items'] as List).cast<Map<String, dynamic>>();
      expect(items.map((i) => i['id']), ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      final times = items.map((i) => i['t'] as int).toList();
      expect([...times]..sort(), times);
    }
    final t = lookupAppLocalizations(const Locale('ar'));
    expect((days.first['items'] as List).first['n'], t.fajr);
    expect(p['rtl'], isTrue);
    expect(p['labels']['next'], t.widgetNextPrayer);
  });

  test('without a location: no prayers, but date and reminders still work', () {
    final p = payload('en', located: false);
    expect(p['prayers'], isEmpty);
    expect((p['hijri'] as List).length, 30);
    expect((p['reminders'] as List).length, 14);
    expect(p['rtl'], isFalse);
  });

  test('Hijri entries and the daily reminder match the app', () {
    final p = payload('en');
    final today = (p['hijri'] as List).first;
    expect(today['day'], '2026-10-08');
    expect(today['h'], contains(today['m']));
    final reminder = (p['reminders'] as List).first;
    expect(reminder['ar'], reminderForDay(now).arabic);
    expect(reminder['ref'], reminderForDay(now).reference);
  });

  test('payload is valid JSON', () {
    for (final lang in ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh']) {
      final encoded = jsonEncode(payload(lang));
      expect(jsonDecode(encoded), isA<Map>());
      // Sample data for the native widget previews (see WIDGET_PREVIEW_OUT).
      final out = Platform.environment['WIDGET_PREVIEW_OUT'];
      if (out != null) File('$out/widget_data_$lang.json').writeAsStringSync(encoded);
    }
  });
}
