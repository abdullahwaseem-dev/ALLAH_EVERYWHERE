import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';

void main() {
  group('asmaUlHusna', () {
    test('has 99 names numbered 1-99 in order', () {
      expect(asmaUlHusna.length, 99);
      for (int i = 0; i < asmaUlHusna.length; i++) {
        expect(asmaUlHusna[i].number, i + 1);
      }
    });

    test('every name has all its fields', () {
      for (final name in asmaUlHusna) {
        expect(name.arabic.trim(), isNotEmpty, reason: '#${name.number} arabic');
        expect(name.transliteration.trim(), isNotEmpty, reason: '#${name.number} transliteration');
        expect(name.meaning.trim(), isNotEmpty, reason: '#${name.number} meaning');
        expect(name.explanation.trim(), isNotEmpty, reason: '#${name.number} explanation');
      }
    });

    test('Arabic names are unique', () {
      expect(asmaUlHusna.map((n) => n.arabic).toSet().length, 99);
    });

    test('every app language has a meaning for every name', () {
      for (final code in ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh']) {
        for (final name in asmaUlHusna) {
          expect(divineNameMeaning(name, code).trim(), isNotEmpty, reason: '$code #${name.number}');
        }
      }
      // An unknown language falls back to English.
      expect(divineNameMeaning(asmaUlHusna[1], 'xx'), asmaUlHusna[1].meaning);
    });
  });

  group('nameOfTheDay', () {
    test('Jan 1 is the first name and it wraps after 99 days', () {
      expect(nameOfTheDay(DateTime(2026, 1, 1)).number, 1);
      expect(nameOfTheDay(DateTime(2026, 4, 9)).number, 99); // day-of-year 98
      expect(nameOfTheDay(DateTime(2026, 4, 10)).number, 1); // day-of-year 99
    });

    test('stays in range for every day of a leap year', () {
      for (var d = DateTime(2028, 1, 1); d.year == 2028; d = DateTime(d.year, d.month, d.day + 1)) {
        final n = nameOfTheDay(d).number;
        expect(n >= 1 && n <= 99, isTrue);
      }
    });
  });

  group('foldForSearch', () {
    test('ignores accents, apostrophes and hyphens', () {
      expect(foldForSearch('Ar-Raḥmān'), 'arrahman');
      expect(foldForSearch('Al-ʿAlīm'), 'alalim');
      expect(foldForSearch("Al-Mu'min"), foldForSearch('Al-Muʾmin'));
    });
  });
}
