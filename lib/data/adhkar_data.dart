// CONTENT REVIEW REQUIRED: verify against source before release

// Morning and evening adhkar from Hisn al-Muslim (Sa'id al-Qahtani), in the
// book's order. Where each part comes from:
// - Wording: the Hisn al-Muslim chapter "Adhkar as-Sabah wal-Masa'"
//   (github.com/rn0x/hisn_almuslim_json), including its evening wordings.
// - Vowels (tashkeel): copied word by word from vowelled copies of the same
//   adhkar - github.com/osamayy/azkar-db and github.com/fitrahive/dua-dhikr
//   (MIT) - never added by hand.
// - Quran passages: the `quran` package, at runtime.
// - English translation and transliteration: fitrahive/dua-dhikr (MIT),
//   except entries marked appTranslated (not in that dataset).
// - Virtues: Arabic verbatim from Hisn al-Muslim's footnotes; the English
//   and other languages are the app's translation of it.
// - References: checked against the hadith collections' standard numbering;
//   gradings are quoted where scholars differ.

import 'package:allah_everywhere/share_cards/mood_data.dart' show QuranRef;
import 'i18n/adhkar_ur.dart';
import 'i18n/adhkar_fr.dart';
import 'i18n/adhkar_de.dart';
import 'i18n/adhkar_hi.dart';
import 'i18n/adhkar_tr.dart';
import 'i18n/adhkar_zh.dart';

enum AdhkarTime { morning, evening }

/// One dhikr of the morning or evening set.
class Dhikr {
  /// Stable id: saved progress and translations are keyed on it.
  final String id;

  /// Vowelled Arabic; empty for Quran passages, which come from [quran].
  final String arabic;

  /// Quran passages to recite (from the `quran` package), in order.
  final List<QuranRef> quran;

  /// Recited before the Quran text (the isti'adha before Ayat al-Kursi).
  final String quranPrefix;

  /// Whether each passage in [quran] is preceded by the basmala.
  final bool basmalaBeforeEach;

  final String transliteration;

  /// English; empty for Quran passages (translated by the `quran` package).
  final String translation;

  /// Key into the other languages' translations; shared by identical texts.
  final String translationKey;

  final int repeat;

  /// Key into [adhkarVirtuesArabic] and the virtue translations, if any.
  final String? virtueKey;

  final String reference;

  /// True when the English translation and transliteration are the app's
  /// own (not from fitrahive/dua-dhikr) - review these first.
  final bool appTranslated;

  const Dhikr({
    required this.id,
    this.arabic = '',
    this.quran = const [],
    this.quranPrefix = '',
    this.basmalaBeforeEach = false,
    required this.transliteration,
    this.translation = '',
    required this.translationKey,
    required this.repeat,
    this.virtueKey,
    required this.reference,
    this.appTranslated = false,
  });

  bool get isQuran => quran.isNotEmpty;
}

// Each dhikr once; [morningAdhkar] and [eveningAdhkar] list them in order.
const _ayatAlKursi = Dhikr(
  id: 'ayatAlKursi',
  quran: [QuranRef(2, 255)],
  quranPrefix: 'أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
  transliteration:
      'a\'udhu billahi minash-shaytanir-rajim. allahu la ilaha illa huwa, al-hayyul-qayyum. la ta\'khudhuhu sinatun wa la nawm. lahu ma fis-samawati wa ma fil-ard. man dhal-ladhi yashfa\'u \'indahu illa bi-idhnihi. ya\'lamu ma bayna aydihim wa ma khalfahum. wa la yuhituna bishay\'in min \'ilmihi illa bima sha\'. wa si\'a kursiyyuhu as-samawati wal-ard. wa la ya\'udu-hu hifdhuhuma. wa huwa al-\'aliyyul-\'azim',
  translationKey: 'ayatAlKursi',
  repeat: 1,
  virtueKey: 'ayatAlKursi',
  reference: 'Quran 2:255. Virtue: al-Hakim 1/562 (graded sahih by al-Albani, Sahih at-Targhib 1/273)',
);

const _threeQuls = Dhikr(
  id: 'threeQuls',
  quran: [QuranRef(112, 1, 4), QuranRef(113, 1, 5), QuranRef(114, 1, 6)],
  basmalaBeforeEach: true,
  transliteration:
      'bismillahir-rahmanir-rahim. qul huwa allahu ahad, allahu samad, lam yalid wa lam yulad, wa lam yakun lahu kufuwan ahad / bismillahir-rahmanir-rahim. qul a\'udhu birabbil-falaq, min sharri ma khalaq, wa min sharri ghasiqin idha waqab, wa min sharri naffathati fil-\'uqad, wa min sharri hasidin idha hasad / bismillahir-rahmanir-rahim. qul a\'udhu birabbin-nas, malikin-nas, ilahin-nas, min sharri al-waswasi al-khannas, alladhi yuwaswisu fi sudurin-nas, mina al-jinnati wan-nas',
  translationKey: 'threeQuls',
  repeat: 3,
  virtueKey: 'threeQuls',
  reference: 'Quran 112-114. Sunan Abi Dawud 5082; Jami\' at-Tirmidhi 3575 (hasan)',
);

const _asbahnaMorning = Dhikr(
  id: 'asbahnaMorning',
  arabic:
      'أَصْبَحْنا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ رَبِّ أَسْأَلُكَ خَيْرَ مَا فِيْ هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيْ هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ رَبِّ أَعُوْذُ بِكَ مِنَ الْكَسَلِ وَسوءِ الْكِبَرِ رَبِّ أَعُوْذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
  translation:
      'We have entered the morning and the dominion belongs to Allah, and all praise is for Allah. There is no deity worthy of worship except Allah alone, He has no partner. To Him belongs the dominion and to Him is praise, and He is over all things competent. My Lord, I ask You for the good of this day and the good of what follows it, and I seek refuge in You from the evil of this day and the evil of what follows it. My Lord, I seek refuge in You from laziness and the evil of old age. My Lord, I seek refuge in You from the punishment of the Fire and the punishment of the grave.',
  transliteration:
      'asbahna wa asbahal-mulku lillahi, wal-hamdu lillahi, la ilaha illa allah wahdahu la sharika lahu, lahu al-mulku wa lahu al-hamdu wa huwa \'ala kulli shay\'in qadir. rabbi as\'aluka khayra ma fi hadha al-yawm wa khayra ma ba\'dahu, wa a\'udhu bika min sharri ma fi hadha al-yawm wa sharri ma ba\'dahu. rabbi a\'udhu bika mina al-kasali wa su\'il-kibar. rabbi a\'udhu bika min \'adhabin fin-nar wa \'adhabin fil-qabr',
  translationKey: 'asbahnaMorning',
  repeat: 1,
  reference: 'Sahih Muslim 2723',
);

const _amsaynaEvening = Dhikr(
  id: 'amsaynaEvening',
  arabic:
      'أَمْسَيْنا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ لَا إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرُ رَبِّ أَسْأَلُكَ خَيْرَ مَا فِيْ هذهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَها وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيْ هذهِ اللَّيْلةِ وَشَرِّ مَا بَعْدَها رَبِّ أَعُوْذُ بِكَ مِنَ الْكَسَلِ وَسوءِ الْكِبَرِ رَبِّ أَعُوْذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
  translation:
      'We have entered the evening and the dominion belongs to Allah, and all praise is for Allah. There is no deity worthy of worship except Allah alone, He has no partner. To Him belongs the dominion and to Him is praise, and He is over all things competent. My Lord, I ask You for the good of this night and the good of what follows it, and I seek refuge in You from the evil of this night and the evil of what follows it. My Lord, I seek refuge in You from laziness and the evil of old age. My Lord, I seek refuge in You from the punishment of the Fire and the punishment of the grave.',
  transliteration:
      'amsayna wa amsal-mulku lillahi wal-hamdu lillahi, la ilaha illa allah wahdahu la sharika lahu, lahu al-mulku wa lahu al-hamdu wa huwa \'ala kulli shay\'in qadir. rabbi as\'aluka khayra ma fi hadhihil-laylah wa khayra ma ba\'daha, wa a\'udhu bika min sharri ma fi hadhihil-laylah wa sharri ma ba\'daha. rabbi a\'udhu bika mina al-kasali wa su\'il-kibar. rabbi a\'udhu bika min \'adhabin fin-nar wa \'adhabin fil-qabr',
  translationKey: 'amsaynaEvening',
  repeat: 1,
  reference: 'Sahih Muslim 2723',
);

const _bikaAsbahna = Dhikr(
  id: 'bikaAsbahna',
  arabic: 'اللّهُمَّ بِكَ أَصْبَحْنا وَبِكَ أَمْسَينا وَبِكَ نَحْيا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُور',
  translation:
      'O Allah, with Your grace and help we enter the morning, and with Your grace and help we enter the evening. By Your grace and will we live and by Your grace and will we die. And to You is the resurrection (for all creatures).',
  transliteration: 'allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namutu wa ilaykan-nushur',
  translationKey: 'bikaAsbahna',
  repeat: 1,
  reference: 'Jami\' at-Tirmidhi 3391; Sunan Abi Dawud 5068 (sahih)',
);

const _bikaAmsayna = Dhikr(
  id: 'bikaAmsayna',
  arabic: 'اللّهُمَّ بِكَ أَمْسَينا وَبِكَ أَصْبَحْنا وَبِكَ نَحْيا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
  translation:
      'O Allah, by Your grace and help we have entered the evening, and by Your grace and help we enter the morning. By Your grace and help we live and by Your will we die. And to You is the final return (of all creatures).',
  transliteration: 'allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namutu wa ilayka al-masir',
  translationKey: 'bikaAmsayna',
  repeat: 1,
  reference: 'Jami\' at-Tirmidhi 3391; Sunan Abi Dawud 5068 (sahih)',
);

const _sayyidAlIstighfar = Dhikr(
  id: 'sayyidAlIstighfar',
  arabic:
      'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ خَلَقْتَنِيْ وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوْذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوْءُ لَكَ بِنِعْمتِكَ عَلَيَّ وَأَبُوْءُ بِذَنْبِيْ فَاغْفِرْ لِيْ فَإِنَّهُ لَا يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ',
  translation:
      'O Allah, You are my Lord. There is no deity worthy of worship except You. You created me and I am Your servant. I will be true to my covenant and promise to You as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I acknowledge my sin, therefore, forgive me. Indeed, there is no one who can forgive sins except You.',
  transliteration:
      'allahumma anta rabbi, la ilaha illa anta, khalaqtani wa ana \'abduka, wa ana \'ala \'ahdika wa wa\'dika mastata\'tu. a\'udhu bika min sharri ma sana\'tu, abu\'u laka bini\'matika \'alayya, wa abu\'u bidhanbi faghfir li, fa innahu la yaghfirudh-dhunuba illa anta',
  translationKey: 'sayyidAlIstighfar',
  repeat: 1,
  virtueKey: 'sayyidAlIstighfar',
  reference: 'Sahih al-Bukhari 6306',
);

const _ushhidukaMorning = Dhikr(
  id: 'ushhidukaMorning',
  arabic:
      'اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُك وَأُشْهِدُ حَمَلَةَ عَرْشِك وَمَلَائِكَتَكَ وَجَميعَ خَلْقِك أَنَّكَ أَنْتَ اللهُ لاَ إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَك وَأَنَّ مُحَمّداً عَبْدُكَ وَرَسولُك',
  translation:
      'O Allah, I have entered the morning calling You to witness, and calling the bearers of Your Throne, Your angels and all of Your creation to witness, that You are Allah; there is no deity worthy of worship except You alone, without partner, and that Muhammad is Your servant and Messenger.',
  transliteration:
      'allahumma inni asbahtu ushhiduka, wa ushhidu hamalata \'arshika, wa mala\'ikataka, wa jami\'a khalqika, annaka antallahu la ilaha illa anta wahdaka la sharika laka, wa anna muhammadan \'abduka wa rasuluk',
  translationKey: 'ushhidukaMorning',
  repeat: 4,
  virtueKey: 'ushhiduka',
  reference: 'Sunan Abi Dawud 5069. Graded hasan by Ibn Baz and Zubair Ali Zai; da\'if by al-Albani',
  appTranslated: true,
);

const _ushhidukaEvening = Dhikr(
  id: 'ushhidukaEvening',
  arabic:
      'اللَّهُمَّ إِنِّي أَمسيتُ أُشْهِدُك وَأُشْهِدُ حَمَلَةَ عَرْشِك وَمَلَائِكَتَكَ وَجَميعَ خَلْقِك أَنَّكَ أَنْتَ اللهُ لاَ إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَك وَأَنَّ مُحَمّداً عَبْدُكَ وَرَسولُك',
  translation:
      'O Allah, I have entered the evening calling You to witness, and calling the bearers of Your Throne, Your angels and all of Your creation to witness, that You are Allah; there is no deity worthy of worship except You alone, without partner, and that Muhammad is Your servant and Messenger.',
  transliteration:
      'allahumma inni amsaytu ushhiduka, wa ushhidu hamalata \'arshika, wa mala\'ikataka, wa jami\'a khalqika, annaka antallahu la ilaha illa anta wahdaka la sharika laka, wa anna muhammadan \'abduka wa rasuluk',
  translationKey: 'ushhidukaEvening',
  repeat: 4,
  virtueKey: 'ushhiduka',
  reference: 'Sunan Abi Dawud 5069. Graded hasan by Ibn Baz and Zubair Ali Zai; da\'if by al-Albani',
  appTranslated: true,
);

const _maAsbahaBi = Dhikr(
  id: 'maAsbahaBi',
  arabic:
      'اللّهُمَّ ما أَصْبَحَ بي مِنْ نِعْمَةٍ أَو بِأَحَدٍ مِنْ خَلْقِك فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَك فَلَكَ الْحَمْدُ وَلَكَ الشُّكْر',
  translation:
      'O Allah, whatever blessing I or any of Your creation have received this morning is from You alone, without partner. So to You is all praise and to You is all thanks.',
  transliteration:
      'allahumma ma asbaha bi min ni\'matin aw bi-ahadin min khalqika fa-minka wahdaka la sharika laka, fa-lakal-hamdu wa lakash-shukr',
  translationKey: 'maAsbahaBi',
  repeat: 1,
  virtueKey: 'maAsbahaBi',
  reference: 'Sunan Abi Dawud 5073. Graded hasan by Ibn Baz; da\'if by al-Albani and Shu\'ayb al-Arna\'ut',
  appTranslated: true,
);

const _maAmsaBi = Dhikr(
  id: 'maAmsaBi',
  arabic:
      'اللّهُمَّ ما أَمسى بي مِنْ نِعْمَةٍ أَو بِأَحَدٍ مِنْ خَلْقِك فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَك فَلَكَ الْحَمْدُ وَلَكَ الشُّكْر',
  translation:
      'O Allah, whatever blessing I or any of Your creation have received this evening is from You alone, without partner. So to You is all praise and to You is all thanks.',
  transliteration:
      'allahumma ma amsa bi min ni\'matin aw bi-ahadin min khalqika fa-minka wahdaka la sharika laka, fa-lakal-hamdu wa lakash-shukr',
  translationKey: 'maAmsaBi',
  repeat: 1,
  virtueKey: 'maAsbahaBi',
  reference: 'Sunan Abi Dawud 5073. Graded hasan by Ibn Baz; da\'if by al-Albani and Shu\'ayb al-Arna\'ut',
  appTranslated: true,
);

const _afiniFiBadani = Dhikr(
  id: 'afiniFiBadani',
  arabic:
      'اللّهُمَّ عافِني فِيْ بَدَني اللّهُمَّ عافِني فِيْ سَمْعي اللّهُمَّ عافِني فِيْ بَصَري لَا إِلَهَ إِلاَّ أَنْتَ اَللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفر وَالفَقْر اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ القَبْر لَا إِلَهَ إِلاَّ أَنْتَ',
  translation:
      'O Allah, protect my body (from illness and from what I do not want). O Allah, protect my hearing (from illness and disobedience or from what I do not want). O Allah, protect my sight, there is no deity worthy of worship except You. O Allah, indeed I seek refuge in You from disbelief and poverty. O Allah, I seek refuge in You from the punishment of the grave, there is no deity worthy of worship except You.',
  transliteration:
      'allahumma \'afini fi badani, allahumma \'afini fi sam\'i, allahumma \'afini fi basari, la ilaha illa anta. allahumma inni a\'udhu bika minal-kufri wal-faqr, allahumma inni a\'udhu bika min \'adhabil-qabr, la ilaha illa anta',
  translationKey: 'afiniFiBadani',
  repeat: 3,
  reference: 'Sunan Abi Dawud 5090. Isnad graded hasan by al-Albani; da\'if by Zubair Ali Zai',
);

const _hasbiyallah = Dhikr(
  id: 'hasbiyallah',
  arabic: 'حَسْبِيَ اللّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ العَظيم',
  translation:
      'Allah is sufficient for me. There is no deity worthy of worship except Him. In Him I have placed my trust, and He is the Lord of the Mighty Throne.',
  transliteration: 'hasbiyallahu la ilaha illa huwa, \'alayhi tawakkaltu wa huwa rabbul-\'arshil-\'azim',
  translationKey: 'hasbiyallah',
  repeat: 7,
  virtueKey: 'hasbiyallah',
  reference:
      'Ibn as-Sunni 71 (from the Prophet ﷺ); Sunan Abi Dawud 5081 (as the saying of Abu ad-Darda\'). Isnad graded sahih by Shu\'ayb and \'Abd al-Qadir al-Arna\'ut; al-Albani graded it mawdu\'',
  appTranslated: true,
);

const _alAfwaWalAfiya = Dhikr(
  id: 'alAfwaWalAfiya',
  arabic:
      'اللَّهُمَّ إِنِّي أسْأَلُكَ العَفْوَ وَالعافِيةَ فِي الدُّنْيا وَالآخِرَة اللّهُمَّ إِنِّي أسْأَلُكَ العَفْوَ وَالعافِيةَ فِي دِيْنِيْ وَدُنْيايَ وَأهْلي وَمالي اللّهُمَّ اسْتُرْ عوْراتي وَآمِنْ رَوْعاتي اللّهُمَّ احْفَظْني مِن بَينِ يَدَيَّ وَمِن خَلْفي وَعَن يَميني وَعَن شِمالي وَمِن فَوْقي وَأَعوذُ بِعَظَمَتِكَ أَن أُغْتالَ مِن تَحْتي',
  translation:
      'O Allah, indeed I ask You for well-being and safety in this world and the Hereafter. O Allah, indeed I ask You for well-being and safety in my religion, my world, my family and my wealth. O Allah, cover my flaws (faults and things that are not appropriate for others to see) and calm me from fear. O Allah, protect me from the front, behind, right, left and above me. I seek refuge in Your greatness, so that I am not snatched from below me (by snakes or swallowed by the earth, etc., which would cause me to fall).',
  transliteration:
      'allahumma inni as\'alukal-\'afwa wal-\'afiyah fid-dunya wal-akhirah. allahumma inni as\'alukal-\'afwa wal-\'afiyah fi dini wa dunyaya wa ahli wa mali. allahummastur \'awrati wa amin raw\'ati. allahummahfadhni min bayni yadayya, wa min khalfi, wa \'an yamini wa \'an shimali, wa min fawqi. wa a\'udhu bi \'adhamatika an ughtala min tahti',
  translationKey: 'alAfwaWalAfiya',
  repeat: 1,
  reference: 'Sunan Abi Dawud 5074; Sunan Ibn Majah 3871 (sahih)',
);

const _alimAlGhayb = Dhikr(
  id: 'alimAlGhayb',
  arabic:
      'اللّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فاطِرَ السّماواتِ وَالأرْضِ رَبَّ كُلِّ شَيْءٍ وَمَليكَه أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ أَعوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ الشَّيْطانِ وَشِرْكِهِ وَأَنْ أَقْتَرِفَ عَلَى نَفْسي سوءاً أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ',
  translation:
      'O Allah, Knower of the unseen and the seen, Creator of the heavens and the earth, Lord of all things and their Sovereign. I bear witness that there is no deity worthy of worship except You. I seek refuge in You from the evil of myself, Satan and his soldiers (temptations to commit shirk against Allah), and I (seek refuge in You) from committing evil against myself or dragging it to a Muslim.',
  transliteration:
      'allahumma \'alimal-ghaybi wash-shahadati, fatiras-samawati wal-ard, rabbakulli shayin wa malikahu. ashhadu alla ilaha illa anta, a\'udhu bika min sharri nafsi, wa min sharri ash-shaytani wa shirkih. wa an aqtarifa \'ala nafsi su\'an aw ajurrahu ila muslim',
  translationKey: 'alimAlGhayb',
  repeat: 1,
  reference: 'Jami\' at-Tirmidhi 3392, 3529; Sunan Abi Dawud 5067 (sahih)',
);

const _bismillahLaYadurr = Dhikr(
  id: 'bismillahLaYadurr',
  arabic: 'بِسْمِ اللهِ الَّذِى لاَ يَضُرُّ مَعَ اسمِهِ شَيءٌ فِى الأرْضِ وَلا فِى السّماءِ وَهوَ السّميعُ العَليم',
  translation:
      'In the name of Allah with Whose name nothing can harm on earth or in heaven, and He is the All-Hearing, All-Knowing.',
  transliteration:
      'bismillahi alladhi la yadurru ma\'asmihi shay\'un fi\'l-ard wa la fi\'s-sama\'i, wa huwa as-sami\'u al-\'aleem',
  translationKey: 'bismillahLaYadurr',
  repeat: 3,
  virtueKey: 'bismillahLaYadurr',
  reference: 'Sunan Abi Dawud 5088; Jami\' at-Tirmidhi 3388; Sunan Ibn Majah 3869 (sahih)',
);

const _raditu = Dhikr(
  id: 'raditu',
  arabic: 'رَضيتُ بِاللهِ رَبَّاً وَبِالإسْلامِ ديناً وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيّاً',
  translation:
      'I am pleased with Allah as my Lord, Islam as my religion and Muhammad sallallahu \'alayhi wa sallam as my Prophet (sent by Allah).',
  transliteration: 'raditu billahi rabba, wa bil-islami dina, wa bi-muhammadin sallallahu \'alayhi wa sallama nabiyya',
  translationKey: 'raditu',
  repeat: 3,
  virtueKey: 'raditu',
  reference: 'Sunan Abi Dawud 5072; Jami\' at-Tirmidhi 3389. Graded hasan by Ibn Baz; da\'if by al-Albani',
);

const _yaHayyuYaQayyum = Dhikr(
  id: 'yaHayyuYaQayyum',
  arabic:
      'يَا حَيُّ يَا قيُّومُ بِرَحْمَتِكَ أسْتَغِيثُ أصْلِحْ لِي شَأنِي كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
  translation:
      'O Ever-Living, O Self-Sustaining, by Your mercy I seek help, rectify all my affairs and do not leave me to myself even for the blink of an eye.',
  transliteration:
      'ya hayyu ya qayyum, bi rahmatika astaghith, aslih li sha\'ni kullahu wa la takilni ila nafsi tarfata \'aynin',
  translationKey: 'yaHayyuYaQayyum',
  repeat: 1,
  reference: 'al-Hakim 1/545 (graded sahih by al-Hakim, agreed by adh-Dhahabi; Sahih at-Targhib 1/273)',
);

const _rabbilAlaminMorning = Dhikr(
  id: 'rabbilAlaminMorning',
  arabic:
      'أَصْبَحْنا وَأَصْبَحَ الْمُلْكُ للهِ رَبِّ العالَمين اللَّهُمَّ إِنِّي أسْأَلُكَ خَيْرَ هَذَا اليَوْم فَتْحَهُ وَنَصْرَهُ وَنورَهُ وَبَرَكَتَهُ وَهُداهُ وَأَعُوذُ بِكَ مِنْ شَرِّ ما فيهِ وَشَرِّ مَا بَعْدَه',
  translation:
      'We have entered the morning and the dominion belongs to Allah, Lord of the worlds. O Allah, I ask You for the good of this day: its opening, its victory, its light, its blessing and its guidance. And I seek refuge in You from the evil in it and the evil of what comes after it.',
  transliteration:
      'asbahna wa asbahal-mulku lillahi rabbil-\'alamin. allahumma inni as\'aluka khayra hadhal-yawm: fathahu, wa nasrahu, wa nurahu, wa barakatahu, wa hudahu, wa a\'udhu bika min sharri ma fihi wa sharri ma ba\'dah',
  translationKey: 'rabbilAlaminMorning',
  repeat: 1,
  reference: 'Sunan Abi Dawud 5084. Isnad graded hasan by the Arna\'uts; da\'if by al-Albani',
  appTranslated: true,
);

const _rabbilAlaminEvening = Dhikr(
  id: 'rabbilAlaminEvening',
  arabic:
      'أَمْسَيْنا وَأَمْسَى الْمُلْكُ للهِ رَبِّ العالَمين اللَّهُمَّ إِنِّي أسْأَلُكَ خَيْرَ هذهِ اللَّيْلَةِ فَتْحَهَا ونَصْرَهَا ونُوْرَهَا وبَرَكَتهَا وَهُدَاهَا وَأَعُوذُ بِكَ مِنْ شَرِّ ما فِيهَا وَشَرِّ مَا بَعْدَهَا',
  translation:
      'We have entered the evening and the dominion belongs to Allah, Lord of the worlds. O Allah, I ask You for the good of this night: its opening, its victory, its light, its blessing and its guidance. And I seek refuge in You from the evil in it and the evil of what comes after it.',
  transliteration:
      'amsayna wa amsal-mulku lillahi rabbil-\'alamin. allahumma inni as\'aluka khayra hadhihil-laylah: fathaha, wa nasraha, wa nuraha, wa barakataha, wa hudaha, wa a\'udhu bika min sharri ma fiha wa sharri ma ba\'daha',
  translationKey: 'rabbilAlaminEvening',
  repeat: 1,
  reference: 'Sunan Abi Dawud 5084. Isnad graded hasan by the Arna\'uts; da\'if by al-Albani',
  appTranslated: true,
);

const _fitratAlIslamMorning = Dhikr(
  id: 'fitratAlIslamMorning',
  arabic:
      'أَصْبَحْنا عَلَى فِطْرَةِ الإسْلاَمِ وَعَلَى كَلِمَةِ الإِخْلاَصِ وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ وَعَلَى مِلَّةِ أَبِينَا إبْرَاهِيمَ حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ المُشْرِكِينَ',
  translation:
      'In the morning we are upon the fitrah of Islam, the word of sincerity (the testimony of faith), the religion of our Prophet Muhammad, sallallahu \'alayhi wa sallam, and the religion of our father Abraham, who stood upon the straight path, a Muslim, and was not among the polytheists.',
  transliteration:
      'asbahna \'ala fitratil-islam wa \'ala kalimatil-ikhlas, wa \'ala dini nabiyyina muhammadin sallallahu \'alayhi wa sallam, wa \'ala millati abina ibrahima hanifan musliman wa ma kana minal-mushrikin',
  translationKey: 'fitratAlIslamMorning',
  repeat: 1,
  reference: 'Musnad Ahmad 3/406-407; Ibn as-Sunni, \'Amal al-Yawm wal-Layla 34 (Sahih al-Jami\' 4/209)',
);

const _fitratAlIslamEvening = Dhikr(
  id: 'fitratAlIslamEvening',
  arabic:
      'أَمْسَيْنَا عَلَى فِطْرَةِ الإسْلاَمِ وَعَلَى كَلِمَةِ الإِخْلاَصِ وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ وَعَلَى مِلَّةِ أَبِينَا إبْرَاهِيمَ حَنِيفاً مُسْلِماً وَمَا كَانَ مِنَ المُشْرِكِينَ',
  translation:
      'In the evening we are upon the fitrah of Islam, the word of sincerity (the testimony of faith), the religion of our Prophet Muhammad, sallallahu \'alayhi wa sallam, and the religion of our father Abraham, who stood upon the straight path, a Muslim, and was not among the polytheists.',
  transliteration:
      'amsayna \'ala fitratil-islam wa \'ala kalimatil-ikhlas, wa \'ala dini nabiyyina muhammadin sallallahu \'alayhi wa sallam, wa \'ala millati abina ibrahima hanifan musliman wa ma kana minal-mushrikin',
  translationKey: 'fitratAlIslamEvening',
  repeat: 1,
  reference: 'Musnad Ahmad 3/406-407; Ibn as-Sunni, \'Amal al-Yawm wal-Layla 34 (Sahih al-Jami\' 4/209)',
);

const _subhanallahWaBihamdihi = Dhikr(
  id: 'subhanallahWaBihamdihi',
  arabic: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
  translation: 'Glory be to Allah, I praise Him.',
  transliteration: 'subhanallah wa bihamdihi',
  translationKey: 'subhanallahWaBihamdihi',
  repeat: 100,
  virtueKey: 'subhanallahWaBihamdihi',
  reference: 'Sahih Muslim 2692',
);

const _tahlilTen = Dhikr(
  id: 'tahlilTen',
  arabic:
      'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  translation:
      'There is no deity worthy of worship except Allah alone, He has no partner. To Him belongs the dominion and all praise. And He is over all things competent.',
  transliteration:
      'la ilaha illa allah wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa \'ala kulli shay\'in qadir',
  translationKey: 'tahlil',
  repeat: 10,
  reference: 'an-Nasa\'i, \'Amal al-Yawm wal-Layla 24 (Sahih at-Targhib 1/272)',
);

const _tahlilHundred = Dhikr(
  id: 'tahlilHundred',
  arabic:
      'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  translation:
      'There is no deity worthy of worship except Allah alone, He has no partner. To Him belongs the dominion and all praise. And He is over all things competent.',
  transliteration:
      'la ilaha illa allah wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa \'ala kulli shay\'in qadir',
  translationKey: 'tahlil',
  repeat: 100,
  virtueKey: 'tahlilHundred',
  reference: 'Sahih al-Bukhari 3293; Sahih Muslim 2691',
);

const _adadaKhalqihi = Dhikr(
  id: 'adadaKhalqihi',
  arabic: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ عَدَدَ خَلْقِه وَرِضا نَفْسِه وَزِنَةَ عَرْشِه وَمِدادَ كَلِماتِه',
  translation:
      'Glory to Allah, I praise Him as many as the number of His creatures, Glory to Allah according to His pleasure, as pure as the weight of His Throne, and as pure as the ink (which writes) His words.',
  transliteration:
      'subhanallahi wa bihamdihi \'adada khalqihi wa rida nafsihi wa zinata \'arshihi wa midada kalimatihi',
  translationKey: 'adadaKhalqihi',
  repeat: 3,
  reference: 'Sahih Muslim 2726',
);

const _ilmanNafian = Dhikr(
  id: 'ilmanNafian',
  arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلاً مُتَقَبَّلًا',
  translation:
      'O Allah, I really ask You for knowledge that is beneficial, sustenance that is lawful, and deeds that are accepted.',
  transliteration: 'allahumma inni as\'aluka \'ilman nafi\'an, wa rizqan tayyiban, wa \'amalan mutaqabbalan',
  translationKey: 'ilmanNafian',
  repeat: 1,
  reference: 'Sunan Ibn Majah 925 (graded sahih by al-Albani)',
);

const _istighfarHundred = Dhikr(
  id: 'istighfarHundred',
  arabic: 'أسْتَغْفِرُ اللهَ وَأَتُوْبُ إلَيهِ',
  translation: 'I seek forgiveness from Allah and repent to Him.',
  transliteration: 'astaghfirullah wa atubu ilayh',
  translationKey: 'istighfarHundred',
  repeat: 100,
  reference: 'Sahih Muslim 2702',
);

const _audhuBiKalimat = Dhikr(
  id: 'audhuBiKalimat',
  arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التّامّاتِ مِنْ شَرِّ مَا خَلَق',
  translation: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
  transliteration: 'a\'udhu bikalimatillahit-tammati min sharri ma khalaq',
  translationKey: 'audhuBiKalimat',
  repeat: 3,
  virtueKey: 'audhuBiKalimat',
  reference: 'Jami\' at-Tirmidhi 3604; Sunan Abi Dawud 3898 (sahih)',
);

const _salawat = Dhikr(
  id: 'salawat',
  arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ على نَبِيِّنَا مُحمَّد',
  translation: 'O Allah, send prayers and peace upon our Prophet Muhammad.',
  transliteration: 'allahumma salli wa sallim \'ala nabiyyina muhammad',
  translationKey: 'salawat',
  repeat: 10,
  virtueKey: 'salawat',
  reference: 'at-Tabarani, with two chains, one of them good (Majma\' az-Zawa\'id 10/120; Sahih at-Targhib 1/273)',
  appTranslated: true,
);

const List<Dhikr> morningAdhkar = [
  _ayatAlKursi,
  _threeQuls,
  _asbahnaMorning,
  _bikaAsbahna,
  _sayyidAlIstighfar,
  _ushhidukaMorning,
  _maAsbahaBi,
  _afiniFiBadani,
  _hasbiyallah,
  _alAfwaWalAfiya,
  _alimAlGhayb,
  _bismillahLaYadurr,
  _raditu,
  _yaHayyuYaQayyum,
  _rabbilAlaminMorning,
  _fitratAlIslamMorning,
  _subhanallahWaBihamdihi,
  _tahlilTen,
  _tahlilHundred,
  _adadaKhalqihi,
  _ilmanNafian,
  _istighfarHundred,
  _salawat,
];

const List<Dhikr> eveningAdhkar = [
  _ayatAlKursi,
  _threeQuls,
  _amsaynaEvening,
  _bikaAmsayna,
  _sayyidAlIstighfar,
  _ushhidukaEvening,
  _maAmsaBi,
  _afiniFiBadani,
  _hasbiyallah,
  _alAfwaWalAfiya,
  _alimAlGhayb,
  _bismillahLaYadurr,
  _raditu,
  _yaHayyuYaQayyum,
  _rabbilAlaminEvening,
  _fitratAlIslamEvening,
  _subhanallahWaBihamdihi,
  _tahlilTen,
  _audhuBiKalimat,
  _salawat,
];

List<Dhikr> adhkarFor(AdhkarTime time) => time == AdhkarTime.morning ? morningAdhkar : eveningAdhkar;

/// Virtues, verbatim from Hisn al-Muslim's footnotes.
const Map<String, String> adhkarVirtuesArabic = {
  'ayatAlKursi': 'من قالها حين يصبح أجير من الجن حتى يمسى ومن قالها حين يمسى أجير من الجن حتى يصبح',
  'threeQuls': 'من قالها ثلاث مرات حين يصبح وحين يمسي كفته من كل شيء',
  'sayyidAlIstighfar': 'من قالها موقناً بها حين يمسي فمات من ليلته دخل الجنة ، وكذلك إذا أصبح',
  'ushhiduka': 'من قالها حين يصبح وحين يمسي أربع مرات أعتقه الله من النار',
  'maAsbahaBi': 'من قالها حين يصبح فقد أدي شكر يومه ، ومن قالها حين يمسى فقد أدى شكر ليلته',
  'hasbiyallah': 'من قالها حين يصبح ويمسي سبع مرات كفاه الله ما أهمه من أمر الدنيا والآخرة',
  'bismillahLaYadurr': 'من قالها ثلاثاً إذا أصبح وثلاثاً إذا أمسى لم يضره شيء',
  'raditu': 'من قالها ثلاثاً حين يصبح وحين يمسي كان حقاً على الله أن يرضيه يوم القيامة',
  'subhanallahWaBihamdihi':
      'من قالها مائة مرة حين يصبح وحين يمسي لم يأت أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد',
  'tahlilHundred':
      'من قالها مائة مرة في يوم كانت له عدل عشر رقاب، وكتب له مائة حسنة ،ومحيت عنه مائة سيئة ، وكانت حرزاً من الشيطان يومه ذلك حتى يمسي ،ولم يأت أحد بأفضل مما جاء به إلا أحد عمل أكثر من ذلك',
  'audhuBiKalimat': 'من قالها حين يمسي ثلاث مرات لم تضره حمة تلك الليلة',
  'salawat': 'من صلى علي حين يُصبح عشراً ، وحين يُمسي عشراً أدركتهُ شفاعتي يوم القيامة',
};

/// English translation of [adhkarVirtuesArabic].
const Map<String, String> _virtuesEnglish = {
  'ayatAlKursi':
      'Whoever says it in the morning is protected from the jinn until the evening, and whoever says it in the evening is protected from them until the morning.',
  'threeQuls':
      'Whoever recites them three times in the morning and in the evening, they will suffice him against everything.',
  'sayyidAlIstighfar':
      'Whoever says it with certainty in the evening and dies that night will enter Paradise, and likewise in the morning.',
  'ushhiduka': 'Whoever says it four times in the morning or in the evening, Allah will free him from the Fire.',
  'maAsbahaBi':
      'Whoever says it in the morning has given thanks for that day, and whoever says it in the evening has given thanks for that night.',
  'hasbiyallah':
      'Whoever says it seven times in the morning and in the evening, Allah will suffice him in whatever concerns him of this world and the Hereafter.',
  'bismillahLaYadurr':
      'Whoever says it three times in the morning and three times in the evening, nothing will harm him.',
  'raditu':
      'Whoever says it three times in the morning and in the evening, it is a right upon Allah to please him on the Day of Resurrection.',
  'subhanallahWaBihamdihi':
      'Whoever says it a hundred times in the morning and in the evening, no one will come on the Day of Resurrection with anything better, except someone who said the same or more.',
  'tahlilHundred':
      'Whoever says it a hundred times in a day has the reward of freeing ten slaves; a hundred good deeds are written for him, a hundred bad deeds are erased, and it protects him from Shaytan that day until evening. No one brings anything better, except someone who did more.',
  'audhuBiKalimat': 'Whoever says it three times in the evening, no poisonous sting will harm him that night.',
  'salawat':
      'Whoever sends blessings upon me ten times in the morning and ten times in the evening will receive my intercession on the Day of Resurrection.',
};

const Map<String, Map<String, String>> _translations = {
  'ur': adhkarTranslationsUr,
  'fr': adhkarTranslationsFr,
  'de': adhkarTranslationsDe,
  'hi': adhkarTranslationsHi,
  'tr': adhkarTranslationsTr,
  'zh': adhkarTranslationsZh,
};

const Map<String, Map<String, String>> _virtues = {
  'ur': adhkarVirtuesUr,
  'fr': adhkarVirtuesFr,
  'de': adhkarVirtuesDe,
  'hi': adhkarVirtuesHi,
  'tr': adhkarVirtuesTr,
  'zh': adhkarVirtuesZh,
};

/// Translation of [dhikr] in [languageCode], falling back to English. Null
/// in Arabic (the Arabic text is shown) and for Quran passages, which are
/// translated from the `quran` package by the screen.
String? dhikrTranslation(Dhikr dhikr, String languageCode) {
  if (languageCode == 'ar' || dhikr.isQuran) return null;
  return _translations[languageCode]?[dhikr.translationKey] ?? dhikr.translation;
}

/// The virtue of [dhikr] in [languageCode] (Arabic verbatim from Hisn
/// al-Muslim), or null if it has none.
String? dhikrVirtue(Dhikr dhikr, String languageCode) {
  final key = dhikr.virtueKey;
  if (key == null) return null;
  if (languageCode == 'ar') return adhkarVirtuesArabic[key];
  return _virtues[languageCode]?[key] ?? _virtuesEnglish[key];
}

/// Total taps to finish [adhkar] (sum of the repeat counts).
int totalRepetitions(List<Dhikr> adhkar) => adhkar.fold(0, (sum, d) => sum + d.repeat);
