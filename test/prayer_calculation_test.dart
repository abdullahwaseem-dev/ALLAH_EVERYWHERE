import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:allah_everywhere/services/prayer_calculation.dart';

String _utc(DateTime t) => DateFormat('HH:mm').format(t.toUtc());

PrayerTimes _times(double lat, double lng, DateTime day, CalculationMethod method) => PrayerTimes(
      Coordinates(lat, lng),
      DateComponents.from(day),
      prayerParameters(method, Madhab.shafi, day),
    );

void main() {
  group('methodForCountry', () {
    test('picks the regional method', () {
      expect(methodForCountry('SA'), CalculationMethod.umm_al_qura);
      expect(methodForCountry('PK'), CalculationMethod.karachi);
      expect(methodForCountry('IN'), CalculationMethod.karachi);
      expect(methodForCountry('US'), CalculationMethod.north_america);
      expect(methodForCountry('AE'), CalculationMethod.dubai);
      expect(methodForCountry('QA'), CalculationMethod.qatar);
      expect(methodForCountry('EG'), CalculationMethod.egyptian);
      expect(methodForCountry('TR'), CalculationMethod.turkey);
      expect(methodForCountry('MY'), CalculationMethod.singapore);
    });

    test('is case-insensitive and falls back to MWL', () {
      expect(methodForCountry('pk'), CalculationMethod.karachi);
      expect(methodForCountry('GB'), CalculationMethod.muslim_world_league);
      expect(methodForCountry(null), CalculationMethod.muslim_world_league);
      expect(methodForCountry(''), CalculationMethod.muslim_world_league);
    });
  });

  // Reference times from api.aladhan.com for the same method and date.
  group('Isha matches the AlAdhan reference', () {
    test('Makkah, Umm al-Qura, normal month: Maghrib + 90 min', () {
      final t = _times(21.3891, 39.8579, DateTime(2026, 10, 7), CalculationMethod.umm_al_qura);
      expect(_utc(t.maghrib), '15:03');
      expect(_utc(t.isha), '16:33');
    });

    test('Makkah, Umm al-Qura, Ramadan: Maghrib + 120 min', () {
      final t = _times(21.3891, 39.8579, DateTime(2027, 2, 20), CalculationMethod.umm_al_qura);
      expect(_utc(t.maghrib), '15:21');
      expect(_utc(t.isha), '17:21');
    });

    test('Karachi, Karachi method (18°)', () {
      final t = _times(24.8607, 67.0011, DateTime(2026, 10, 7), CalculationMethod.karachi);
      expect(_utc(t.isha), '14:29');
    });

    test('New York, MWL (17°)', () {
      final t = _times(40.7128, -74.0060, DateTime(2026, 10, 7), CalculationMethod.muslim_world_league);
      expect(_utc(t.isha), '23:54');
    });

    test('the Ramadan rule only applies to Umm al-Qura', () {
      final qatar = _times(25.2854, 51.5310, DateTime(2027, 2, 20), CalculationMethod.qatar);
      expect(qatar.isha.difference(qatar.maghrib).inMinutes, 90);
    });
  });
}
