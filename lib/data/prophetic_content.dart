import 'seerah_data.dart';
import 'tib_e_nabwi_data.dart';
import 'i18n/prophetic_ar.dart';
import 'i18n/prophetic_de.dart';
import 'i18n/prophetic_fr.dart';
import 'i18n/prophetic_hi.dart';
import 'i18n/prophetic_tr.dart';
import 'i18n/prophetic_ur.dart';
import 'i18n/prophetic_zh.dart';

/// Screen text for the Seerat and Tib-e-Nabwi screens.
class PropheticScreenText {
  final String seeratTitle;
  final String seeratHeader;
  final String seeratSubtitle;
  final String tibTitle;
  final String tibHeader;
  final String tibSubtitle;
  final String tibDisclaimer;

  const PropheticScreenText({
    required this.seeratTitle,
    required this.seeratHeader,
    required this.seeratSubtitle,
    required this.tibTitle,
    required this.tibHeader,
    required this.tibSubtitle,
    required this.tibDisclaimer,
  });
}

/// The Seerah and Tib-e-Nabwi content in one language. Each translation
/// mirrors the English lists chapter-for-chapter and item-for-item.
class PropheticContent {
  final PropheticScreenText text;
  final List<SeerahChapter> seerah;
  final List<TibCategory> tib;

  const PropheticContent({required this.text, required this.seerah, required this.tib});
}

const _english = PropheticContent(
  text: PropheticScreenText(
    seeratTitle: 'SEERAT E NABWI',
    seeratHeader: 'سیرتِ نبوی',
    seeratSubtitle: 'The life of Prophet Muhammad (ﷺ), from birth to his passing',
    tibTitle: 'Tib e Nabwi (ﷺ)',
    tibHeader: 'طبِ نبوی',
    tibSubtitle: 'Prophetic guidance on health and natural remedies (Tib-e-Nabwi)',
    tibDisclaimer:
        'These are traditional teachings from authentic Hadith. They are not a substitute for medical treatment - consult a doctor for health conditions.',
  ),
  seerah: seerahChapters,
  tib: tibENabwiCategories,
);

const Map<String, PropheticContent> _byLanguage = {
  'en': _english,
  'ar': propheticAr,
  'ur': propheticUr,
  'hi': propheticHi,
  'zh': propheticZh,
  'fr': propheticFr,
  'tr': propheticTr,
  'de': propheticDe,
};

PropheticContent propheticContentFor(String languageCode) => _byLanguage[languageCode] ?? _english;
