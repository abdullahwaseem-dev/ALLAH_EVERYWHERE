import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/data/mushaf_data.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// A run of consecutive ayahs of one surah on a Mushaf page.
class PageSegment {
  final int surah;
  final int start;
  final int end;

  const PageSegment(this.surah, this.start, this.end);

  /// The surah begins on this page, so the page shows its header.
  bool get startsSurah => start == 1;

  /// Bismillah is shown above a surah's first ayah, except for At-Tawbah
  /// (which has none) and Al-Fatiha (where it is ayah 1 itself).
  bool get showsBismillah => startsSurah && surah != 1 && surah != 9;
}

enum MushafBackground { auto, white, sepia, night }

/// Madani Mushaf page structure (604 pages) from the `quran` package, plus
/// Juz/Hizb positions (lib/data/mushaf_data.dart) and reader preferences.
class MushafService {
  static const int pageCount = quran.totalPagesCount;
  static const double minFontScale = 0.8, maxFontScale = 1.6;

  static const _lastPageKey = 'mushaf_last_page';
  static const _fontScaleKey = 'mushaf_font_scale';
  static const _backgroundKey = 'mushaf_background';
  static const _viewModeKey = 'quran_view_mode';

  /// The surahs and ayah ranges on [page] (1-604), in reading order.
  static List<PageSegment> segments(int page) => [
        for (final e in quran.getPageData(page))
          PageSegment(e['surah'] as int, e['start'] as int, e['end'] as int),
      ];

  /// Juz shown in the page header: the Juz of the page's first ayah.
  static int juzOfPage(int page) {
    final first = segments(page).first;
    return juzOf(first.surah, first.start);
  }

  /// Juz of an ayah, from the Tanzil Juz starts.
  static int juzOf(int surah, int ayah) => _indexOfStart(juzStarts, surah, ayah) + 1;

  /// Hizb (1-60) of an ayah.
  static int hizbOf(int surah, int ayah) => _indexOfStart(hizbStarts, surah, ayah) + 1;

  static int _indexOfStart(List<(int, int)> starts, int surah, int ayah) {
    var index = 0;
    for (int i = 0; i < starts.length; i++) {
      final (s, a) = starts[i];
      if (s < surah || (s == surah && a <= ayah)) index = i;
    }
    return index;
  }

  static int pageOf(int surah, int ayah) => quran.getPageNumber(surah, ayah);
  static int pageForSurah(int surah) => pageOf(surah, 1);
  static int pageForJuz(int juz) => pageOf(juzStarts[juz - 1].$1, juzStarts[juz - 1].$2);
  static int pageForHizb(int hizb) => pageOf(hizbStarts[hizb - 1].$1, hizbStarts[hizb - 1].$2);

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  /// The last page read, or null if the Mushaf hasn't been opened.
  static int? get lastPage {
    final v = VoidStorage().readData<int>(_lastPageKey);
    return v != null && v >= 1 && v <= pageCount ? v : null;
  }

  static Future<void> setLastPage(int page) => VoidStorage().saveData(_lastPageKey, page);

  static double get fontScale {
    final v = VoidStorage().readData<num>(_fontScaleKey)?.toDouble() ?? 1.0;
    return v.clamp(minFontScale, maxFontScale);
  }

  static Future<void> setFontScale(double scale) =>
      VoidStorage().saveData(_fontScaleKey, scale.clamp(minFontScale, maxFontScale));

  static MushafBackground get background {
    final v = VoidStorage().readData<String>(_backgroundKey);
    return MushafBackground.values.where((b) => b.name == v).firstOrNull ?? MushafBackground.auto;
  }

  static Future<void> setBackground(MushafBackground b) => VoidStorage().saveData(_backgroundKey, b.name);

  /// Quran screen list mode: Surah view (false) or Mushaf view (true).
  static bool get mushafViewSelected => VoidStorage().readData<String>(_viewModeKey) == 'mushaf';
  static Future<void> setMushafViewSelected(bool mushaf) =>
      VoidStorage().saveData(_viewModeKey, mushaf ? 'mushaf' : 'surah');
}
