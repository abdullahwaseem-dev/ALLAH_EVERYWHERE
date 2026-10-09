import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';

import 'mood_data.dart';

enum ShareContentKind { quran, hadith, divineName }

/// One ayah (or run of ayat) or hadith, ready to lay out on a card.
class ShareContent {
  final ShareContentKind kind;
  final String arabic;

  /// Translation in the app language; empty when there is none to show
  /// (Arabic UI, or a hadith with no translation in that language).
  final String translation;

  /// Whether [translation] is Urdu, so it's set in Nastaliq.
  final bool translationIsUrdu;
  final String reference;

  const ShareContent({
    required this.kind,
    required this.arabic,
    required this.translation,
    required this.reference,
    this.translationIsUrdu = false,
  });

  static quran.Translation? _quranTranslation(String code) {
    switch (code) {
      case 'ar':
        return null;
      case 'ur':
        return quran.Translation.urdu;
      case 'zh':
        return quran.Translation.chinese;
      case 'fr':
        return quran.Translation.frHamidullah;
      case 'tr':
        return quran.Translation.trSaheeh;
      default:
        return quran.Translation.enSaheeh;
    }
  }

  factory ShareContent.fromQuran(QuranRef ref, String languageCode) {
    final ayat = [for (int a = ref.fromAyah; a <= ref.toAyah; a++) a];
    final arabic = ayat.map((a) => quran.getVerse(ref.surah, a, verseEndSymbol: true)).join(' ');
    final translation = _quranTranslation(languageCode);
    final translated = translation == null
        ? ''
        : ayat.map((a) => quran.getVerseTranslation(ref.surah, a, translation: translation)).join(' ');
    final range = ref.fromAyah == ref.toAyah ? '${ref.fromAyah}' : '${ref.fromAyah}-${ref.toAyah}';
    return ShareContent(
      kind: ShareContentKind.quran,
      arabic: arabic,
      translation: translated,
      translationIsUrdu: languageCode == 'ur',
      reference: 'Surah ${quran.getSurahName(ref.surah)} ${ref.surah}:$range',
    );
  }

  factory ShareContent.fromHadith(MoodHadith hadith, String languageCode) {
    return ShareContent.hadith(
      arabic: hadith.arabic,
      english: hadith.english,
      urdu: hadith.urdu,
      reference: hadith.reference,
      languageCode: languageCode,
    );
  }

  /// One of the 99 Names: the Arabic, then its transliteration and meaning
  /// (meaning only in the app language; none on an Arabic UI).
  factory ShareContent.fromDivineName(DivineName name, String languageCode) {
    return ShareContent(
      kind: ShareContentKind.divineName,
      arabic: name.arabic,
      translation:
          languageCode == 'ar' ? '' : '${name.transliteration}\n${divineNameMeaning(name, languageCode)}',
      translationIsUrdu: languageCode == 'ur',
      reference: asmaUlHusnaReference,
    );
  }

  /// Hadith text is available in Arabic, English and Urdu only, so other
  /// languages get the English.
  factory ShareContent.hadith({
    required String arabic,
    required String english,
    required String urdu,
    required String reference,
    required String languageCode,
  }) {
    final useUrdu = languageCode == 'ur' && urdu.trim().isNotEmpty;
    return ShareContent(
      kind: ShareContentKind.hadith,
      arabic: arabic.trim(),
      translation: languageCode == 'ar' ? '' : (useUrdu ? urdu : english).trim(),
      translationIsUrdu: useUrdu,
      reference: reference,
    );
  }
}
