import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/services/hifz_plan.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/hifz_words.dart';

void main() {
  group('buildHifzPlan', () {
    test('each ayah N times, range M times, a pause after every recitation but the last', () {
      const s = HifzSettings(repeatEachAyah: 3, rounds: 2, gapSeconds: 2);
      final plan = buildHifzPlan(from: 1, to: 5, settings: s);
      final recitations = plan.where((st) => !st.isPause).toList();
      expect(recitations.length, 5 * 3 * 2);
      expect(plan.where((st) => st.isPause).length, recitations.length - 1);
      expect(plan.last.isPause, isFalse);
      // Order: 1,1,1,2,2,2,... then the second round.
      expect(recitations.take(4).map((st) => st.ayah), [1, 1, 1, 2]);
      expect(recitations[15].round, 2);
      expect(recitations[15].ayah, 1);
      expect(recitations.map((st) => st.repeat).take(3), [1, 2, 3]);
    });

    test('no pauses when the gap is 0', () {
      final plan = buildHifzPlan(from: 3, to: 4, settings: const HifzSettings(repeatEachAyah: 2, rounds: 1, gapSeconds: 0));
      expect(plan.length, 4);
      expect(plan.any((st) => st.isPause), isFalse);
    });

    test('a pause keeps the ayah it follows highlighted', () {
      final plan = buildHifzPlan(from: 7, to: 8, settings: const HifzSettings(repeatEachAyah: 1, rounds: 1, gapSeconds: 3));
      expect(plan[1].isPause, isTrue);
      expect(plan[1].highlightedAyah, 7);
      expect(plan[2].highlightedAyah, 8);
    });

    test('single ayah, single repeat', () {
      final plan = buildHifzPlan(from: 1, to: 1, settings: const HifzSettings(repeatEachAyah: 1, rounds: 1, gapSeconds: 5));
      expect(plan.length, 1);
    });

    test('the largest allowed session stays a manageable queue', () {
      final plan = buildHifzPlan(
        from: 1,
        to: HifzSettings.maxRangeLength,
        settings: const HifzSettings(
          repeatEachAyah: HifzSettings.maxRepeat,
          rounds: HifzSettings.maxRounds,
          gapSeconds: HifzSettings.maxGapSeconds,
        ),
      );
      expect(plan.length, lessThanOrEqualTo(8000));
    });
  });

  group('HifzSettings', () {
    test('out-of-range values are clamped', () {
      final s = const HifzSettings(repeatEachAyah: 99, rounds: 0, gapSeconds: -4, speed: 3).clamped();
      expect(s.repeatEachAyah, HifzSettings.maxRepeat);
      expect(s.rounds, HifzSettings.minRounds);
      expect(s.gapSeconds, 0);
      expect(s.speed, HifzSettings.maxSpeed);
    });

    test('round-trips and tolerates junk', () {
      const s = HifzSettings(repeatEachAyah: 5, rounds: 2, gapSeconds: 4, speed: 0.85);
      expect(HifzSettings.fromMap(s.toMap()).toMap(), s.toMap());
      expect(HifzSettings.fromMap('junk').toMap(), const HifzSettings().toMap());
    });

    test('pause clips are stretched by the speed so the heard pause is right', () {
      expect(pauseClipLength(2, 1.0), const Duration(seconds: 2));
      expect(pauseClipLength(2, 1.25), const Duration(milliseconds: 2500));
      expect(pauseClipLength(4, 0.75), const Duration(seconds: 3));
    });
  });

  group('hide words', () {
    final fatiha1 = splitAyah(quran.getVerse(1, 1));

    test('splits Quran text into words', () {
      expect(fatiha1.length, 4);
      expect(fatiha1.every((w) => !w.isMark), isTrue);
    });

    // The quran package attaches pause marks to words; other texts (and
    // future editions) may not, so standalone marks are handled too. Dummy
    // words here, not Quran text.
    test('standalone pause marks are kept visible and not counted as words', () {
      final words = splitAyah('ب \u06DB ت');
      expect(words.map((w) => w.isMark), [false, true, false]);
      expect(visibleText(words[1], -1, HideLevel.all), '\u06DB');
      expect(visibleText(words[0], 0, HideLevel.all), isNull);
    });

    test('first letter: one letter plus the marks on it, from the start of the word', () {
      final letters = RegExp('[\u0621-\u064A\u0671-\u06D3\u06D5]');
      for (final w in splitAyah(quran.getVerse(1, 1))) {
        final first = firstLetter(w.text);
        expect(w.text.startsWith(first), isTrue, reason: w.text);
        expect(letters.allMatches(first).length, 1, reason: w.text);
      }
    });

    test('levels', () {
      final w = fatiha1[1];
      expect(visibleText(w, 1, HideLevel.none), w.text);
      expect(visibleText(w, 1, HideLevel.firstLetters), firstLetter(w.text));
      expect(visibleText(w, 0, HideLevel.everyOther), w.text);
      expect(visibleText(w, 1, HideLevel.everyOther), isNull);
      expect(visibleText(w, 0, HideLevel.all), isNull);
    });
  });

  group('spaced repetition', () {
    final day0 = DateTime(2026, 10, 1, 9);

    test('reviews move out 1, 3, 7, 14, 30 days, then stay at 30', () {
      var r = markRemembered(null, day0);
      expect(r.nextReview, '2026-10-02');
      var now = day0;
      final expected = ['2026-10-05', '2026-10-12', '2026-10-26', '2026-11-25', '2026-12-25'];
      for (final next in expected) {
        now = DateTime.parse(r.nextReview);
        r = markRemembered(r, now);
        expect(r.nextReview, next);
      }
      expect(r.stage, hifzReviewIntervals.length);
    });

    test('marking again before it is due changes nothing', () {
      final r = markRemembered(null, day0);
      expect(markRemembered(r, day0.add(const Duration(hours: 3))), same(r));
    });

    test('need practice resets and is due today', () {
      var r = markRemembered(null, day0);
      r = markRemembered(r, DateTime(2026, 10, 2));
      final p = markNeedsPractice(DateTime(2026, 10, 3));
      expect(p.status, HifzStatus.needsPractice);
      expect(p.stage, 0);
      expect(p.isDue(DateTime(2026, 10, 3)), isTrue);
      // Remembering it again starts the schedule over.
      expect(markRemembered(p, DateTime(2026, 10, 3)).nextReview, '2026-10-04');
    });

    test('records round-trip and reject junk', () {
      final r = markRemembered(null, day0);
      final back = AyahRecord.fromMap(r.toMap())!;
      expect(back.nextReview, r.nextReview);
      expect(back.updatedAt, r.updatedAt);
      expect(AyahRecord.fromMap({'status': 'nope'}), isNull);
      expect(AyahRecord.fromMap(null), isNull);
    });
  });

  group('progress', () {
    final now = DateTime(2026, 10, 10);
    AyahRecord rec(HifzStatus s, String next, int minute) =>
        AyahRecord(status: s, stage: 1, nextReview: next, updatedAt: DateTime(2026, 10, 1, 0, minute));

    test('counts memorized ayahs per surah, in total and in Juz Amma', () {
      final p = <int, Map<int, AyahRecord>>{
        67: {1: rec(HifzStatus.remembered, '2026-12-01', 0), 2: rec(HifzStatus.needsPractice, '2026-10-10', 0)},
        112: {1: rec(HifzStatus.remembered, '2026-12-01', 0), 2: rec(HifzStatus.remembered, '2026-12-01', 0)},
      };
      expect(memorizedIn(p, 67), 1);
      expect(totalMemorized(p), 3);
      expect(juzAmmaMemorized(p), 2); // only Al-Ikhlas is in Juz 30
    });

    test('Juz Amma is An-Naba to An-Nas', () {
      var sum = 0;
      for (int s = 78; s <= 114; s++) {
        sum += quran.getVerseCount(s);
      }
      expect(juzAmmaAyahCount, sum);
      expect(juzAmmaAyahCount, 564);
    });

    test('due list is in Quran order', () {
      final p = <int, Map<int, AyahRecord>>{
        112: {2: rec(HifzStatus.remembered, '2026-10-09', 0), 1: rec(HifzStatus.remembered, '2026-10-10', 0)},
        67: {5: rec(HifzStatus.needsPractice, '2026-10-01', 0), 6: rec(HifzStatus.remembered, '2026-10-11', 0)},
      };
      final due = dueForReview(p, now);
      expect(due.map((d) => '${d.surah}:${d.ayah}'), ['67:5', '112:1', '112:2']);
    });

    test('merge keeps the newer record per ayah', () {
      final device = <int, Map<int, AyahRecord>>{1: {1: rec(HifzStatus.remembered, 'a', 5), 2: rec(HifzStatus.remembered, 'b', 1)}};
      final cloud = <int, Map<int, AyahRecord>>{
        1: {1: rec(HifzStatus.needsPractice, 'c', 2), 2: rec(HifzStatus.needsPractice, 'd', 9)},
        2: {1: rec(HifzStatus.remembered, 'e', 0)},
      };
      final m = mergeHifzProgress(device, cloud);
      expect(m[1]![1]!.nextReview, 'a'); // device newer
      expect(m[1]![2]!.nextReview, 'd'); // cloud newer
      expect(m[2]![1]!.nextReview, 'e'); // only in cloud
      expect(device[1]![2]!.nextReview, 'b'); // inputs untouched
    });

    test('review ranges group consecutive ayahs, capped in length', () {
      final r = AyahRecord(status: HifzStatus.remembered, stage: 1, nextReview: '2026-10-01', updatedAt: DateTime(2026));
      final due = [
        for (final a in [1, 2, 3, 5]) (surah: 67, ayah: a, record: r),
        (surah: 68, ayah: 6, record: r),
      ];
      expect(groupReviewRanges(due, maxLength: 20).map((x) => '${x.surah}:${x.from}-${x.to}'),
          ['67:1-3', '67:5-5', '68:6-6']);
      expect(groupReviewRanges(due, maxLength: 2).map((x) => '${x.surah}:${x.from}-${x.to}'),
          ['67:1-2', '67:3-3', '67:5-5', '68:6-6']);
    });
  });
}
