import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/data/mushaf_data.dart';
import 'package:allah_everywhere/services/mushaf_service.dart';

void main() {
  test('604 pages cover all 6236 ayahs once, in order', () {
    var count = 0;
    (int, int)? previous;
    for (int p = 1; p <= MushafService.pageCount; p++) {
      for (final seg in MushafService.segments(p)) {
        for (int a = seg.start; a <= seg.end; a++) {
          if (previous != null) {
            final (ps, pa) = previous;
            expect(seg.surah > ps || (seg.surah == ps && a == pa + 1), isTrue, reason: 'page $p $seg.surah:$a');
          }
          previous = (seg.surah, a);
          count++;
        }
      }
    }
    expect(count, quran.totalVerseCount);
  });

  test('page numbers of well-known positions', () {
    expect(MushafService.pageForSurah(1), 1);
    expect(MushafService.pageForSurah(2), 2);
    expect(MushafService.pageForSurah(18), MushafService.pageOf(18, 1));
    expect(MushafService.pageOf(114, 6), 604);
    expect(MushafService.pageForJuz(1), 1);
    expect(MushafService.pageForJuz(30), MushafService.pageForSurah(78));
  });

  test('every Juz starts every second Hizb, and 30 Juz / 60 Hizb are increasing', () {
    expect(juzStarts.length, 30);
    expect(hizbStarts.length, 60);
    for (int j = 0; j < 30; j++) {
      expect(hizbStarts[j * 2], juzStarts[j]);
    }
    for (int i = 1; i < 60; i++) {
      expect(MushafService.pageForHizb(i + 1), greaterThanOrEqualTo(MushafService.pageForHizb(i)));
    }
  });

  test('Juz 11 starts at At-Tawbah 9:93 (the quran package says 9:92)', () {
    expect(juzStarts[10], (9, 93));
    expect(MushafService.juzOf(9, 92), 10);
    expect(MushafService.juzOf(9, 93), 11);
    expect(MushafService.hizbOf(1, 1), 1);
    expect(MushafService.hizbOf(114, 6), 60);
  });

  test('our Juz agrees with the quran package for every ayah (its lookup takes the first match at 9:92)', () {
    for (int s = 1; s <= 114; s++) {
      for (int a = 1; a <= quran.getVerseCount(s); a++) {
        expect(MushafService.juzOf(s, a), quran.getJuzNumber(s, a), reason: '$s:$a');
      }
    }
  });

  test('surah headers and Bismillah', () {
    final first = MushafService.segments(1).single;
    expect(first.startsSurah, isTrue);
    expect(first.showsBismillah, isFalse); // Al-Fatiha: Bismillah is ayah 1
    final tawbah = MushafService.segments(MushafService.pageForSurah(9)).firstWhere((s) => s.surah == 9);
    expect(tawbah.showsBismillah, isFalse);
    final last = MushafService.segments(604);
    expect(last.map((s) => s.surah), [112, 113, 114]);
    expect(last.every((s) => s.showsBismillah), isTrue);
    expect(MushafService.segments(3).single.startsSurah, isFalse);
  });

  test('page Juz header', () {
    expect(MushafService.juzOfPage(1), 1);
    expect(MushafService.juzOfPage(604), 30);
  });
}
