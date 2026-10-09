import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/data/adhkar_data.dart';
import 'package:allah_everywhere/services/adhkar_service.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';

const _languages = ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh'];

void main() {
  group('adhkar data', () {
    test('Hisn al-Muslim sets: 23 in the morning, 20 in the evening', () {
      expect(morningAdhkar.length, 23);
      expect(eveningAdhkar.length, 20);
      expect(adhkarFor(AdhkarTime.morning), same(morningAdhkar));
      expect(adhkarFor(AdhkarTime.evening), same(eveningAdhkar));
    });

    test('both sets start with Ayat al-Kursi and the three Quls', () {
      for (final list in [morningAdhkar, eveningAdhkar]) {
        expect(list[0].id, 'ayatAlKursi');
        expect(list[1].id, 'threeQuls');
        expect(list[1].repeat, 3);
      }
    });

    test('morning-only and evening-only adhkar are in the right set', () {
      final morningIds = morningAdhkar.map((d) => d.id).toSet();
      final eveningIds = eveningAdhkar.map((d) => d.id).toSet();
      for (final id in ['tahlilHundred', 'adadaKhalqihi', 'ilmanNafian', 'istighfarHundred', 'asbahnaMorning']) {
        expect(morningIds, contains(id));
        expect(eveningIds, isNot(contains(id)));
      }
      for (final id in ['audhuBiKalimat', 'amsaynaEvening']) {
        expect(eveningIds, contains(id));
        expect(morningIds, isNot(contains(id)));
      }
    });

    test('ids are unique within each set', () {
      for (final list in [morningAdhkar, eveningAdhkar]) {
        expect(list.map((d) => d.id).toSet().length, list.length);
      }
    });

    test('every dhikr has text, a count and a reference', () {
      for (final d in {...morningAdhkar, ...eveningAdhkar}) {
        expect(d.repeat, greaterThan(0), reason: d.id);
        expect(d.reference.trim(), isNotEmpty, reason: d.id);
        expect(d.transliteration.trim(), isNotEmpty, reason: d.id);
        if (d.isQuran) {
          expect(d.arabic, isEmpty, reason: d.id);
        } else {
          expect(d.arabic.trim(), isNotEmpty, reason: d.id);
          expect(d.translation.trim(), isNotEmpty, reason: d.id);
        }
      }
    });

    // A few short particles (ما, بي, على) are left unvowelled by the sources.
    test('Arabic is vowelled and has no tatweel', () {
      final harakat = RegExp('[ً-ْ]');
      for (final d in {...morningAdhkar, ...eveningAdhkar}.where((d) => !d.isQuran)) {
        expect(d.arabic.contains('ـ'), isFalse, reason: d.id);
        final words = d.arabic.split(' ');
        final vowelled = words.where((w) => harakat.hasMatch(w)).length;
        expect(vowelled / words.length, greaterThan(0.8), reason: d.id);
      }
    });

    test('Quran passages exist in the quran package', () {
      for (final d in {...morningAdhkar, ...eveningAdhkar}.where((d) => d.isQuran)) {
        for (final ref in d.quran) {
          for (int a = ref.fromAyah; a <= ref.toAyah; a++) {
            expect(quran.getVerse(ref.surah, a), isNotEmpty, reason: '${d.id} ${ref.surah}:$a');
          }
          expect(ref.toAyah, lessThanOrEqualTo(quran.getVerseCount(ref.surah)), reason: d.id);
        }
      }
    });

    test('every app language has a translation and virtue for every dhikr', () {
      for (final lang in _languages) {
        for (final d in {...morningAdhkar, ...eveningAdhkar}) {
          final translation = dhikrTranslation(d, lang);
          if (lang == 'ar' || d.isQuran) {
            expect(translation, isNull, reason: '$lang ${d.id}');
          } else {
            expect(translation?.trim(), isNotEmpty, reason: '$lang ${d.id}');
          }
          if (d.virtueKey != null) {
            expect(dhikrVirtue(d, lang)?.trim(), isNotEmpty, reason: '$lang ${d.id}');
          } else {
            expect(dhikrVirtue(d, lang), isNull);
          }
        }
      }
    });

    test('non-English translations differ from the English', () {
      for (final lang in ['ur', 'fr', 'de', 'hi', 'tr', 'zh']) {
        for (final d in morningAdhkar.where((d) => !d.isQuran)) {
          expect(dhikrTranslation(d, lang), isNot(d.translation), reason: '$lang ${d.id}');
        }
      }
    });

    test('total repetitions', () {
      expect(totalRepetitions(const []), 0);
      expect(totalRepetitions(morningAdhkar), morningAdhkar.fold<int>(0, (s, d) => s + d.repeat));
    });
  });

  group('AdhkarProgress', () {
    const list = morningAdhkar;

    test('starts empty and counts up to each repeat', () {
      var p = const AdhkarProgress(date: '2026-10-07');
      expect(p.firstIncomplete(list), 0);
      expect(p.remainingOf(list[1]), 3);
      p = p.withCount(list[1], 2);
      expect(p.remainingOf(list[1]), 1);
      expect(p.isComplete(list[1]), isFalse);
      p = p.withCount(list[1], 3);
      expect(p.isComplete(list[1]), isTrue);
    });

    test('never counts past the repeat number', () {
      final p = const AdhkarProgress(date: 'd').withCount(list[0], 99);
      expect(p.doneOf(list[0]), 1);
      expect(p.remainingOf(list[0]), 0);
    });

    test('firstIncomplete skips finished adhkar, and is length when all done', () {
      var p = const AdhkarProgress(date: 'd').withCount(list[0], 1);
      expect(p.firstIncomplete(list), 1);
      for (final d in list) {
        p = p.withCount(d, d.repeat);
      }
      expect(p.firstIncomplete(list), list.length);
      expect(p.completedCount(list), list.length);
    });

    test('stored progress from another day, or malformed, starts fresh', () {
      final today = AdhkarProgress.fromStored({'date': '2026-10-07', 'done': {'ayatAlKursi': 1}}, '2026-10-07');
      expect(today.isComplete(list[0]), isTrue);
      expect(AdhkarProgress.fromStored({'date': '2026-10-06', 'done': {'ayatAlKursi': 1}}, '2026-10-07').done, isEmpty);
      expect(AdhkarProgress.fromStored('junk', '2026-10-07').done, isEmpty);
      expect(AdhkarProgress.fromStored({'date': '2026-10-07', 'done': {'x': -3, 5: 1}}, '2026-10-07').done, isEmpty);
    });

    test('round-trips through toMap', () {
      final p = const AdhkarProgress(date: '2026-10-07').withCount(list[1], 2);
      expect(AdhkarProgress.fromStored(p.toMap(), '2026-10-07').doneOf(list[1]), 2);
    });
  });

  group('suggestedTime', () {
    final day = DateTime(2026, 10, 7);
    final fajr = DateTime(2026, 10, 7, 5, 10);
    final asr = DateTime(2026, 10, 7, 15, 40);

    test('morning from Fajr until Asr', () {
      expect(AdhkarService.suggestedTime(fajr, fajr: fajr, asr: asr), AdhkarTime.morning);
      expect(AdhkarService.suggestedTime(DateTime(2026, 10, 7, 12), fajr: fajr, asr: asr), AdhkarTime.morning);
    });

    test('evening from Asr until the next Fajr', () {
      expect(AdhkarService.suggestedTime(asr, fajr: fajr, asr: asr), AdhkarTime.evening);
      expect(AdhkarService.suggestedTime(DateTime(2026, 10, 7, 22), fajr: fajr, asr: asr), AdhkarTime.evening);
      expect(AdhkarService.suggestedTime(DateTime(2026, 10, 7, 3), fajr: fajr, asr: asr), AdhkarTime.evening);
    });

    test('falls back to 4 AM / 3 PM without prayer times', () {
      expect(AdhkarService.suggestedTime(day.add(const Duration(hours: 9))), AdhkarTime.morning);
      expect(AdhkarService.suggestedTime(day.add(const Duration(hours: 16))), AdhkarTime.evening);
      expect(AdhkarService.suggestedTime(day.add(const Duration(hours: 2))), AdhkarTime.evening);
    });

    test('date keys are zero-padded', () {
      expect(AdhkarService.dateKey(DateTime(2026, 3, 9)), '2026-03-09');
    });
  });

  group('Tasbeeh today total', () {
    final now = DateTime(2026, 10, 7, 18);

    test('adds up within the same day', () {
      var stored = TasbeehService.addToToday(null, now, 33);
      stored = TasbeehService.addToToday(stored, now, 10);
      expect(TasbeehService.todayCount(stored, now), 43);
    });

    test('resets on a new day', () {
      final stored = TasbeehService.addToToday(null, now, 33);
      final tomorrow = DateTime(2026, 10, 8, 6);
      expect(TasbeehService.todayCount(stored, tomorrow), 0);
      expect(TasbeehService.todayCount(TasbeehService.addToToday(stored, tomorrow, 5), tomorrow), 5);
    });

    test('malformed stored values count as 0', () {
      expect(TasbeehService.todayCount('junk', now), 0);
      expect(TasbeehService.todayCount({'date': '2026-10-07', 'count': 'x'}, now), 0);
      expect(TasbeehService.todayCount({'date': '2026-10-07', 'count': -4}, now), 0);
    });
  });
}
