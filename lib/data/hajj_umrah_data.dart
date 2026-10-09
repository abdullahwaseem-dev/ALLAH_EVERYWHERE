// CONTENT REVIEW REQUIRED: verify against source before release

// Hajj & Umrah guide content. Where it comes from:
// - Dua Arabic: Hisn al-Muslim's Hajj chapters, as vowelled in
//   github.com/osamayy/azkar-db; the Quran fragment said at Safa and the
//   Yemeni-corner dua (2:201) come from the `quran` package. Nothing typed.
// - Dua English: sunnah.com's translation of the cited hadith where it gives
//   the words; entries marked appTranslation are the app's own.
// - Rulings and madhab notes, guidance, mistakes, packing and places text:
//   the app's own summary with the sources listed per step - to be checked
//   by a scholar. Non-English text is in lib/data/i18n/hajj_umrah_*.dart.
// - References: checked against the hadith collections' standard numbering.

import 'package:allah_everywhere/share_cards/mood_data.dart' show QuranRef;
import 'i18n/hajj_umrah_ar.dart';
import 'i18n/hajj_umrah_ur.dart';
import 'i18n/hajj_umrah_fr.dart';
import 'i18n/hajj_umrah_de.dart';
import 'i18n/hajj_umrah_hi.dart';
import 'i18n/hajj_umrah_tr.dart';
import 'i18n/hajj_umrah_zh.dart';

enum HajjGuide { umrah, hajj }

enum HajjRuling { rukn, wajib, sunnah }

class HajjDua {
  final String id;

  /// Vowelled Arabic; empty when the dua is a Quran passage ([quran]).
  final String arabic;
  final QuranRef? quran;
  final String transliteration;

  /// English; empty for Quran passages (translated by the `quran` package).
  final String translation;
  final String source;

  /// The transliteration / English are the app's own, not from a source.
  final bool appTransliteration;
  final bool appTranslation;

  const HajjDua({
    required this.id,
    this.arabic = '',
    this.quran,
    required this.transliteration,
    this.translation = '',
    required this.source,
    this.appTransliteration = false,
    this.appTranslation = false,
  });
}

class HajjStep {
  final String id;
  final HajjGuide guide;

  /// Day of Dhul Hijjah for Hajj steps: '8', '9', '10', '11-13' or 'depart'.
  final String? day;
  final HajjRuling ruling;
  final List<String> duaIds;
  final String sources;

  /// Shows the Ihram restrictions list ('ihram.restrictions').
  final bool showsRestrictions;

  const HajjStep({
    required this.id,
    required this.guide,
    this.day,
    required this.ruling,
    this.duaIds = const [],
    required this.sources,
    this.showsRestrictions = false,
  });
}

class HajjPlace {
  final String id;

  /// Google Maps search text (by name, so no coordinates are hard-coded).
  final String mapsQuery;

  const HajjPlace(this.id, this.mapsQuery);
}

const Map<String, HajjDua> hajjDuas = {
  'talbiyah': HajjDua(
      id: 'talbiyah',
      arabic:
          'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لاَ شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ، وَالنِّعْمَةَ، لَكَ وَالْمُلْكَ، لاَ شَرِيكَ لَكَ',
      transliteration:
          'Labbaika Allahumma labbaik, Labbaika la sharika Laka labbaik, Inna-l-hamda wan-ni\'mata Laka walmulk, La sharika Laka',
      translation:
          'I respond to Your call O Allah, I respond to Your call, and I am obedient to Your orders, You have no partner, I respond to Your call. All the praises and blessings are for You, All the sovereignty is for You, And You have no partners with You.',
      source: 'Sahih al-Bukhari 1549; Sahih Muslim 1184'),
  'enterMosque': HajjDua(
      id: 'enterMosque',
      arabic:
          'أَعُوذُ بِاللَّهِ العَظِيمِ، وَبِوَجْهِهِ الْكَرِيمِ، وَسُلْطَانِهِ الْقَدِيمِ، مِنَ الشَّيْطَانِ الرَّجِيمِ\nبِسْمِ اللَّهِ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى رَسُولِ اللَّهِ\nاللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      transliteration:
          'a\'udhu billahil-\'azim, wa bi-wajhihil-karim, wa sultanihil-qadim, minash-shaytanir-rajim. bismillah, was-salatu was-salamu \'ala rasulillah. allahummaftah li abwaba rahmatik',
      translation:
          'I seek refuge in Allah, the Magnificent, and in His noble face, and in His eternal domain, from the accursed Devil. In the name of Allah, and blessings and peace be upon the Messenger of Allah. O Allah! Open for me the doors of Your mercy.',
      source: 'Sunan Abi Dawud 466 (sahih); Sahih Muslim 713; Ibn as-Sunni 88 (hasan per al-Albani)',
      appTransliteration: true),
  'takbirStone': HajjDua(
      id: 'takbirStone',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu akbar',
      translation: 'Allah is the Greatest.',
      source: 'Sahih al-Bukhari 1613 (the Prophet ﷺ said takbir each time he reached the Black Stone)',
      appTranslation: true),
  'yemeniCorner': HajjDua(
      id: 'yemeniCorner',
      quran: QuranRef(2, 201),
      transliteration: 'rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar',
      source: 'Quran 2:201; Sunan Abi Dawud 1892 (hasan)',
      appTransliteration: true),
  'safa': HajjDua(
      id: 'safa',
      arabic:
          'إِنَّ ٱلصَّفَا وَٱلۡمَرۡوَةَ مِن شَعَآئِرِ ٱللَّهِ\nأَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ\nلاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
      transliteration:
          'inna as-safa wal-marwata min sha\'a\'irillah. abda\'u bima bada\'allahu bih. la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa \'ala kulli shay\'in qadir, la ilaha illallahu wahdah, anjaza wa\'dah, wa nasara \'abdah, wa hazamal-ahzaba wahdah',
      translation:
          'Al-Safa\' and al-Marwa are among the signs appointed by Allah. I begin with what Allah (has commanded me) to begin. There is no god but Allah, One, there is no partner with Him. His is the Sovereignty, to Him praise is due, and He is Powerful over everything. There is no god but Allah alone, Who fulfilled His promise, helped His servant and routed the confederates alone.',
      source: 'Quran 2:158; Sahih Muslim 1218 (said three times on Safa and on Marwah, making dua between)',
      appTransliteration: true),
  'arafah': HajjDua(
      id: 'arafah',
      arabic:
          'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      transliteration:
          'Lā ilāha illallāh, waḥdahu lā sharīka lahu, lahul-mulku wa lahul-ḥamdu, wa huwa \'alā kulli shai\'in qadīr',
      translation:
          'None has the right to be worshipped but Allah, Alone, without partner, to Him belongs all that exists, and to Him belongs the Praise, and He is powerful over all things.',
      source: 'Jami\' at-Tirmidhi 3585 (hasan per al-Albani; Zubair Ali Zai: da\'if)'),
  'rami': HajjDua(
      id: 'rami',
      arabic: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu akbar',
      translation: 'Allah is the Greatest.',
      source: 'Sahih al-Bukhari 1751, 1753 (takbir with each pebble)',
      appTranslation: true),
  'sacrifice': HajjDua(
      id: 'sacrifice',
      arabic: 'بِسْمِ اللَّهِ وَاللَّهُ أَكْبَرُ [اللَّهُمَّ مِنْكَ وَلَكَ] اللَّهُمَّ تَقَبَّلْ مِنِّي',
      transliteration: 'bismillahi wallahu akbar, [allahumma minka wa lak,] allahumma taqabbal minni',
      translation:
          'In the name of Allah, and Allah is the Greatest. [O Allah, from You and for You.] O Allah, accept it from me.',
      source:
          'Sahih Muslim 1967; the part in [ ] is from al-Bayhaqi 9/287 (as given in Hisn al-Muslim, which notes "accept from me" gives the meaning of Muslim\'s wording)',
      appTransliteration: true,
      appTranslation: true),
};

const List<HajjStep> hajjSteps = [
  HajjStep(
      id: 'umrahIhram',
      guide: HajjGuide.umrah,
      ruling: HajjRuling.rukn,
      duaIds: ['talbiyah'],
      sources:
          'Sahih al-Bukhari 1524 (the miqats), 1542 and 1838 (what is not worn); Quran 2:196-197; Sahih Muslim 1409 (no marriage contract)',
      showsRestrictions: true),
  HajjStep(
      id: 'umrahTawaf',
      guide: HajjGuide.umrah,
      ruling: HajjRuling.rukn,
      duaIds: ['enterMosque', 'takbirStone', 'yemeniCorner'],
      sources: 'Quran 22:29; Sahih al-Bukhari 1604 (ramal), 1613; Sunan Abi Dawud 1883 (idtiba)'),
  HajjStep(
      id: 'umrahSai',
      guide: HajjGuide.umrah,
      ruling: HajjRuling.rukn,
      duaIds: ['safa'],
      sources: 'Quran 2:158; Sahih Muslim 1218'),
  HajjStep(
      id: 'umrahHalq', guide: HajjGuide.umrah, ruling: HajjRuling.wajib, sources: 'Quran 48:27; Sahih al-Bukhari 1727'),
  HajjStep(
      id: 'hajjIhram',
      guide: HajjGuide.hajj,
      day: '8',
      ruling: HajjRuling.rukn,
      duaIds: ['talbiyah'],
      sources: 'Sahih al-Bukhari 1524, 1542, 1838; Quran 2:196-197',
      showsRestrictions: true),
  HajjStep(
      id: 'mina8',
      guide: HajjGuide.hajj,
      day: '8',
      ruling: HajjRuling.sunnah,
      duaIds: ['talbiyah'],
      sources: 'Sahih al-Bukhari 1653; Sahih Muslim 1218'),
  HajjStep(
      id: 'arafah',
      guide: HajjGuide.hajj,
      day: '9',
      ruling: HajjRuling.rukn,
      duaIds: ['arafah'],
      sources: 'Sunan Abi Dawud 1949; Jami\' at-Tirmidhi 889 ("Hajj is Arafah"); Sahih Muslim 1218'),
  HajjStep(
      id: 'muzdalifah',
      guide: HajjGuide.hajj,
      day: '9',
      ruling: HajjRuling.wajib,
      sources: 'Quran 2:198; Sahih Muslim 1218; Sahih al-Bukhari 1676 (the weak may leave early)'),
  HajjStep(
      id: 'rami10',
      guide: HajjGuide.hajj,
      day: '10',
      ruling: HajjRuling.wajib,
      duaIds: ['rami'],
      sources: 'Sahih al-Bukhari 1753; Sahih Muslim 1297'),
  HajjStep(
      id: 'qurbani',
      guide: HajjGuide.hajj,
      day: '10',
      ruling: HajjRuling.wajib,
      duaIds: ['sacrifice'],
      sources: 'Quran 2:196; Sahih Muslim 1218'),
  HajjStep(
      id: 'hajjHalq',
      guide: HajjGuide.hajj,
      day: '10',
      ruling: HajjRuling.wajib,
      sources: 'Sahih al-Bukhari 1727; Sahih al-Bukhari 1736 (the order of the day may be changed)'),
  HajjStep(
      id: 'ifadah',
      guide: HajjGuide.hajj,
      day: '10',
      ruling: HajjRuling.rukn,
      duaIds: ['takbirStone', 'yemeniCorner', 'safa'],
      sources: 'Quran 22:29; Sahih Muslim 1218'),
  HajjStep(
      id: 'tashreeq',
      guide: HajjGuide.hajj,
      day: '11-13',
      ruling: HajjRuling.wajib,
      duaIds: ['rami'],
      sources: 'Sahih al-Bukhari 1751, 1753; Sahih al-Bukhari 1634 (the nights of Mina); Quran 2:203'),
  HajjStep(
      id: 'wada',
      guide: HajjGuide.hajj,
      day: 'depart',
      ruling: HajjRuling.wajib,
      duaIds: ['takbirStone', 'yemeniCorner'],
      sources: 'Sahih al-Bukhari 1755 (excused for women in menses)'),
];

/// Default packing list (the user can add and remove items).
const List<String> hajjPackingDefaults = [
  'ihram',
  'belt',
  'sandals',
  'unscentedSoap',
  'documents',
  'medicine',
  'waterBottle',
  'umbrella',
  'sunscreen',
  'powerBank',
  'pebbleBag',
  'prayerMat',
  'duaBook',
  'sanitizer',
  'masks',
  'blanket',
  'cash',
  'nailClipper',
];

const List<HajjPlace> hajjPlaces = [
  HajjPlace('haram', 'Masjid al-Haram, Makkah'),
  HajjPlace('nabawi', 'Masjid an-Nabawi, Madinah'),
  HajjPlace('mina', 'Mina, Makkah'),
  HajjPlace('arafah', 'Jabal ar-Rahmah, Arafat'),
  HajjPlace('muzdalifah', 'Al-Mashar Al-Haram Mosque, Muzdalifah'),
  HajjPlace('jamarat', 'Jamarat Bridge, Mina'),
];

const Map<String, String> _english = {
  'ihram.restrictions':
      'No cutting hair or nails.\nNo perfume on the body or clothes, and no scented soap.\nMen: no stitched, fitted clothing and no covering the head.\nWomen: no niqab over the face and no gloves.\nNo hunting land animals.\nNo marriage contract, and no marital relations.',
  'umrahIhram.title': 'Ihram',
  'umrahIhram.what':
      'Before the miqat: bathe, trim nails and hair if needed, and (men) put on the two white Ihram sheets. Women wear ordinary modest clothes.\nAt or before the miqat, make the intention for Umrah and begin the Talbiyah.\nRepeat the Talbiyah often - men aloud, women quietly - until you begin Tawaf.',
  'umrahIhram.mistakes':
      'Passing the miqat without entering Ihram (most scholars say a sacrifice is then due unless you go back).\nThinking Ihram is just the clothes - it begins with the intention.\nUsing scented soap, wipes or cream after entering Ihram.',
  'umrahIhram.note':
      'The Hanafi school treats Ihram as a condition of Umrah and Hajj; the other schools count it as a pillar.',
  'umrahTawaf.title': 'Tawaf',
  'umrahTawaf.what':
      'Enter Masjid al-Haram with the right foot, saying the dua for entering a mosque.\nBe in wudu. Start at the line of the Black Stone with the Ka\'bah on your left; kiss, touch or point to the Stone and say \'Allahu akbar\'.\nWalk seven rounds outside the Hijr (the low semicircular wall). Men uncover the right shoulder (idtiba) and walk briskly in the first three rounds (ramal).\nBetween the Yemeni corner and the Black Stone say the dua below; make any dua you like in the rest of each round.\nAfter the seventh round, pray two rak\'ahs behind Maqam Ibrahim if you can (or anywhere in the mosque), and drink Zamzam.',
  'umrahTawaf.mistakes':
      'Walking through the Hijr - it is part of the Ka\'bah, so that round does not count.\nPushing or harming others to kiss the Black Stone; pointing from afar is enough.\nWomen doing idtiba or ramal, or men doing them in Tawafs where they are not Sunnah.',
  'umrahTawaf.note':
      'Most scholars make wudu a condition of Tawaf; the Hanafi school holds it is wajib, so a Tawaf without it is valid but must be made up for.',
  'umrahSai.title': 'Sa\'i',
  'umrahSai.what':
      'Go to Safa. At the start of the first round recite the verse below, face the Ka\'bah, and say the dhikr three times with dua in between.\nWalk to Marwah and do the same there. Safa to Marwah is one round; Marwah back to Safa is the second.\nComplete seven rounds, ending at Marwah. Men walk quickly between the green lights.',
  'umrahSai.mistakes':
      'Starting at Marwah - the count begins at Safa.\nCounting Safa to Marwah and back as one round (it is two).\nThinking Sa\'i is invalid without wudu - most scholars recommend it but do not require it.',
  'umrahSai.note': 'Sa\'i is a pillar for the Maliki, Shafi\'i and Hanbali schools, and wajib for the Hanafi school.',
  'umrahHalq.title': 'Shaving or shortening',
  'umrahHalq.what':
      'Men shave the head (better) or shorten the hair from all over the head.\nWomen cut about a fingertip\'s length from the ends of their hair.\nYour Umrah is complete and the Ihram restrictions end.',
  'umrahHalq.mistakes': 'Cutting only a few hairs from one side.\nWomen shaving the head - they only shorten.',
  'umrahHalq.note':
      'The Shafi\'i school counts it as a pillar; the others hold it is wajib. On how much hair: the Shafi\'i school accepts three hairs, the Hanafi a quarter of the head, and the Maliki and Hanbali schools the whole head.',
  'hajjIhram.title': 'Ihram for Hajj (8th)',
  'hajjIhram.what':
      'Pilgrims doing Tamattu\' enter Ihram for Hajj on the 8th from where they stay in Makkah; those doing Qiran or Ifrad are still in Ihram from the miqat.\nMake the intention for Hajj and begin the Talbiyah.\nThe Ihram restrictions apply until the first release on the 10th.',
  'hajjIhram.mistakes':
      'Forgetting to make the new intention for Hajj when doing Tamattu\'.\nApplying perfume after making the intention.',
  'hajjIhram.note': 'The Hanafi school treats Ihram as a condition of Hajj; the other schools count it as a pillar.',
  'mina8.title': 'Mina',
  'mina8.what':
      'Go to Mina before midday if you can.\nPray Dhuhr, Asr, Maghrib, Isha and the next Fajr there, shortening the four-rak\'ah prayers as the Prophet ﷺ did, without combining them.\nKeep repeating the Talbiyah.',
  'mina8.mistakes': 'Worrying that missing Mina on the 8th spoils Hajj - it is a Sunnah.',
  'arafah.title': 'Standing at Arafah',
  'arafah.what':
      'After sunrise go to Arafah. At midday pray Dhuhr and Asr, shortened and combined at the time of Dhuhr.\nMake sure you are inside the boundaries of Arafah (follow the signs).\nUntil sunset, devote yourself to dua, dhikr and Quran, facing the Qiblah; the dhikr below is the best of what is said.\nAfter sunset, leave calmly for Muzdalifah.',
  'arafah.mistakes':
      'Staying outside the boundary (for example in the valley of Uranah) - then the standing does not count.\nLeaving Arafah before sunset.\nExhausting yourself climbing Jabal ar-Rahmah - it is not required.',
  'arafah.note':
      'For most scholars the time of this pillar begins at midday (the Hanbali school: from dawn of the 9th) and lasts until dawn of the 10th. Staying until sunset is wajib for most; the Maliki school requires being there for part of the night.',
  'muzdalifah.title': 'Muzdalifah',
  'muzdalifah.what':
      'On arrival pray Maghrib and Isha together, with Isha shortened.\nSleep there. After Fajr, stand facing the Qiblah in dua and dhikr until it is quite light, then leave for Mina before sunrise.\nPick up pebbles here or in Mina: 7 for the 10th and 21 for each following day.',
  'muzdalifah.mistakes':
      'Praying Maghrib on the way before reaching Muzdalifah.\nLeaving soon after arriving without an excuse; the weak and elderly (and those with them) may leave after midnight.',
  'muzdalifah.note':
      'Most scholars hold staying at Muzdalifah is wajib but differ on how long: the Shafi\'i and Hanbali schools require being there after midnight, the Hanafi school after dawn, and the Maliki school a stop long enough to pray and rest.',
  'rami10.title': 'Stoning Jamrat al-Aqabah',
  'rami10.what':
      'Stop the Talbiyah when you begin the stoning.\nThrow seven small pebbles, one at a time, at Jamrat al-Aqabah (the last, largest pillar), saying \'Allahu akbar\' with each.\nDo not stop to make dua after this Jamrah.',
  'rami10.mistakes':
      'Throwing all seven at once (it counts as one), or throwing large stones or shoes.\nNot throwing again when a pebble misses the basin.',
  'qurbani.title': 'Sacrifice (Hady)',
  'qurbani.what':
      'Pilgrims doing Tamattu\' or Qiran offer a sacrifice (a sheep or goat, or a share of a camel or cow) in the Haram on the 10th or the days of Tashreeq.\nMost pilgrims buy an official voucher; keep the receipt and confirm when the sacrifice is done.\nIf you cannot afford it, fast three days during Hajj and seven when you return home.',
  'qurbani.mistakes': 'Assuming it is done without confirmation, when your school requires it before shaving.',
  'qurbani.note':
      'Wajib for Tamattu\' and Qiran (Quran 2:196) and not required for Ifrad. The Hanafi school requires the order stoning, sacrifice, then shaving for these pilgrims.',
  'hajjHalq.title': 'Shaving or shortening',
  'hajjHalq.what':
      'Men shave the head (better) or shorten it; women cut a fingertip\'s length.\nAfter this, all Ihram restrictions end except marital relations (the first release).',
  'hajjHalq.mistakes':
      'Cutting only a few hairs from one side.\nThinking a change in the order of the day ruins Hajj - the Prophet ﷺ said: "Do it, there is no harm."',
  'hajjHalq.note':
      'Scholars differ on what brings the first release: for the Shafi\'i and Hanbali schools, any two of stoning, shaving and Tawaf al-Ifadah; for the Hanafi school, shaving; for the Maliki school, stoning.',
  'ifadah.title': 'Tawaf al-Ifadah',
  'ifadah.what':
      'Go to Makkah and perform seven rounds of Tawaf as in Umrah (without idtiba or ramal), then pray two rak\'ahs.\nPilgrims doing Tamattu\' then perform Sa\'i. Those doing Qiran or Ifrad who did Sa\'i after their arrival Tawaf do not repeat it.\nIt is best done on the 10th; ask your scholar how late it may be delayed.\nAfter it, all Ihram restrictions end (the second release).',
  'ifadah.mistakes': 'Confusing it with the farewell Tawaf - Tawaf al-Ifadah is a pillar and cannot be skipped.',
  'ifadah.note':
      'A woman in menses waits until she is pure before this Tawaf; if her travel cannot wait, she should ask a scholar.',
  'tashreeq.title': 'Days of Tashreeq in Mina',
  'tashreeq.what':
      'Spend the nights of the 11th and 12th (and the 13th if you stay) in Mina.\nEach day after midday, stone the three Jamarat in order - small, middle, then Aqabah - seven pebbles each, with takbir.\nAfter the small and middle Jamrah, step aside, face the Qiblah and make a long dua; do not stop after Aqabah.\nYou may leave on the 12th after stoning, before sunset; otherwise stay and stone on the 13th.',
  'tashreeq.mistakes':
      'Stoning before midday on these days (for most scholars it does not count).\nStarting with Jamrat al-Aqabah instead of the small Jamrah.',
  'tashreeq.note':
      'Spending these nights in Mina is wajib for most scholars and Sunnah for the Hanafi school. Some scholars allow stoning before midday when crowds make it necessary - follow your scholar.',
  'wada.title': 'Farewell Tawaf',
  'wada.what':
      'When leaving Makkah, make seven rounds of Tawaf as your last act there.\nThen leave; buying what you need on the way is fine, but do not stay on.\nWomen in menses or after childbirth are excused from it.',
  'wada.mistakes': 'Doing it and then staying in Makkah for a long time - repeat it if you stay.',
  'wada.note': 'Wajib for the Hanafi, Shafi\'i and Hanbali schools; Sunnah for the Maliki school.',
  'dua.talbiyah':
      'I respond to Your call O Allah, I respond to Your call. You have no partner, I respond to Your call. All praise and blessings are Yours, and all sovereignty. You have no partner.',
  'dua.enterMosque':
      'I seek refuge in Allah the Magnificent, in His noble Face and His eternal authority, from the accursed devil. In the name of Allah, and blessings and peace be upon the Messenger of Allah. O Allah, open for me the doors of Your mercy.',
  'dua.takbirStone': 'Allah is the Greatest.',
  'dua.safa':
      'Safa and Marwah are among the symbols of Allah. I begin with what Allah began with. There is no god but Allah alone, without partner; His is the dominion and His is the praise, and He has power over all things. There is no god but Allah alone; He fulfilled His promise, helped His servant and alone defeated the confederates.',
  'dua.arafah':
      'There is no god but Allah alone, without partner; His is the dominion and His is the praise, and He has power over all things.',
  'dua.rami': 'Allah is the Greatest.',
  'dua.sacrifice':
      'In the name of Allah, and Allah is the Greatest. [O Allah, from You and for You.] O Allah, accept it from me.',
  'pack.ihram': 'Two Ihram sheets (men)',
  'pack.belt': 'Ihram belt or safety pins',
  'pack.sandals': 'Comfortable sandals',
  'pack.unscentedSoap': 'Unscented soap, shampoo and deodorant',
  'pack.documents': 'Passport, visa, Nusuk card and copies',
  'pack.medicine': 'Personal medicines and a first-aid kit',
  'pack.waterBottle': 'Refillable water bottle',
  'pack.umbrella': 'Umbrella for the sun',
  'pack.sunscreen': 'Unscented sunscreen',
  'pack.powerBank': 'Phone charger and power bank',
  'pack.pebbleBag': 'Small bag for pebbles',
  'pack.prayerMat': 'Light prayer mat',
  'pack.duaBook': 'Small Quran or dua book',
  'pack.sanitizer': 'Unscented hand sanitizer',
  'pack.masks': 'Face masks',
  'pack.blanket': 'Light blanket or mat for Muzdalifah',
  'pack.cash': 'Some cash and a bank card',
  'pack.nailClipper': 'Nail clipper and razor (for before and after Ihram)',
  'place.haram.name': 'Masjid al-Haram',
  'place.haram.desc': 'The Sacred Mosque in Makkah around the Ka\'bah, where Tawaf and Sa\'i are done.',
  'place.nabawi.name': 'Masjid an-Nabawi',
  'place.nabawi.desc':
      'The Prophet\'s ﷺ Mosque in Madinah. Visiting it is not part of Hajj or Umrah, but many pilgrims go before or after.',
  'place.mina.name': 'Mina',
  'place.mina.desc': 'The valley of tents where pilgrims stay on the 8th and the Days of Tashreeq.',
  'place.arafah.name': 'Arafah',
  'place.arafah.desc':
      'The plain where pilgrims stand on the 9th - the heart of Hajj. Jabal ar-Rahmah is the hill within it.',
  'place.muzdalifah.name': 'Muzdalifah',
  'place.muzdalifah.desc':
      'Between Arafah and Mina, where pilgrims spend the night before the 10th. Al-Mash\'ar al-Haram mosque is here.',
  'place.jamarat.name': 'Jamarat',
  'place.jamarat.desc': 'The three pillars in Mina stoned from the 10th to the 13th, reached by a multi-level bridge.',
};

const Map<String, Map<String, String>> _byLanguage = {
  'ar': hajjUmrahAr,
  'ur': hajjUmrahUr,
  'fr': hajjUmrahFr,
  'de': hajjUmrahDe,
  'hi': hajjUmrahHi,
  'tr': hajjUmrahTr,
  'zh': hajjUmrahZh,
};

/// Guide text for [key] in [languageCode] (English if missing), e.g.
/// 'umrahTawaf.what'. List entries are separated by newlines.
String hajjText(String key, String languageCode) => _byLanguage[languageCode]?[key] ?? _english[key] ?? '';

bool hajjHasText(String key) => _english.containsKey(key);

List<HajjStep> hajjStepsFor(HajjGuide guide) => hajjSteps.where((s) => s.guide == guide).toList();
