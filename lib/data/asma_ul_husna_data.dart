// CONTENT REVIEW REQUIRED: verify against source before release

import 'i18n/asma_ul_husna_de.dart';
import 'i18n/asma_ul_husna_fr.dart';
import 'i18n/asma_ul_husna_hi.dart';
import 'i18n/asma_ul_husna_tr.dart';
import 'i18n/asma_ul_husna_ur.dart';
import 'i18n/asma_ul_husna_zh.dart';

/// One of the 99 Names of Allah (Asma-ul-Husna).
class DivineName {
  /// 1-99, in the order of the Tirmidhi narration.
  final int number;

  /// Taken verbatim from the Arabic text of [asmaUlHusnaReference].
  final String arabic;
  final String transliteration;

  /// English meaning; see [divineNameMeaning] for other languages.
  final String meaning;

  /// A short English explanation of the Name.
  final String explanation;

  const DivineName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.explanation,
  });
}

/// The source of the list and its order. The hadith that Allah has 99 Names
/// is in Sahih al-Bukhari 2736 and Sahih Muslim 2677, but neither lists
/// them. at-Tirmidhi calls this narration gharib, and many scholars
/// (including al-Albani) grade the list itself weak, holding it was added
/// by a narrator - so other lists exist that differ in a few Names. This
/// edition counts "Allah" as the first Name and does not include al-Ahad.
const String asmaUlHusnaReference = "Jami' at-Tirmidhi 3507";
const String asmaUlHusnaCountReference = 'Sahih al-Bukhari 2736; Sahih Muslim 2677';

const List<DivineName> asmaUlHusna = [
  DivineName(
    number: 1,
    arabic: 'اللَّهُ',
    transliteration: 'Allāh',
    meaning: 'Allah, the One True God',
    explanation: 'The proper name of God, gathering all His perfect attributes; every other Name describes Him.',
  ),
  DivineName(
    number: 2,
    arabic: 'الرَّحْمَنُ',
    transliteration: 'Ar-Raḥmān',
    meaning: 'The Most Merciful',
    explanation: 'His mercy is vast and embraces all of creation.',
  ),
  DivineName(
    number: 3,
    arabic: 'الرَّحِيمُ',
    transliteration: 'Ar-Raḥīm',
    meaning: 'The Especially Merciful',
    explanation: 'He shows special, lasting mercy to the believers.',
  ),
  DivineName(
    number: 4,
    arabic: 'الْمَلِكُ',
    transliteration: 'Al-Malik',
    meaning: 'The King',
    explanation: 'The absolute Sovereign who owns and rules over everything.',
  ),
  DivineName(
    number: 5,
    arabic: 'الْقُدُّوسُ',
    transliteration: 'Al-Quddūs',
    meaning: 'The Most Holy',
    explanation: 'Pure and free of every flaw and imperfection.',
  ),
  DivineName(
    number: 6,
    arabic: 'السَّلاَمُ',
    transliteration: 'As-Salām',
    meaning: 'The Source of Peace',
    explanation: 'Free of all defects, He grants peace and safety.',
  ),
  DivineName(
    number: 7,
    arabic: 'الْمُؤْمِنُ',
    transliteration: 'Al-Muʾmin',
    meaning: 'The Granter of Security',
    explanation: 'He grants safety and confirms the truth of His messengers.',
  ),
  DivineName(
    number: 8,
    arabic: 'الْمُهَيْمِنُ',
    transliteration: 'Al-Muhaymin',
    meaning: 'The Guardian',
    explanation: 'He watches over and preserves all of His creation.',
  ),
  DivineName(
    number: 9,
    arabic: 'الْعَزِيزُ',
    transliteration: 'Al-ʿAzīz',
    meaning: 'The Almighty',
    explanation: 'Mighty beyond measure; He is never overcome.',
  ),
  DivineName(
    number: 10,
    arabic: 'الْجَبَّارُ',
    transliteration: 'Al-Jabbār',
    meaning: 'The Compeller',
    explanation: 'His will prevails over all, and He mends what is broken.',
  ),
  DivineName(
    number: 11,
    arabic: 'الْمُتَكَبِّرُ',
    transliteration: 'Al-Mutakabbir',
    meaning: 'The Supreme in Greatness',
    explanation: 'True greatness belongs to Him alone.',
  ),
  DivineName(
    number: 12,
    arabic: 'الْخَالِقُ',
    transliteration: 'Al-Khāliq',
    meaning: 'The Creator',
    explanation: 'He brings everything into existence by His decree.',
  ),
  DivineName(
    number: 13,
    arabic: 'الْبَارِئُ',
    transliteration: 'Al-Bāriʾ',
    meaning: 'The Maker',
    explanation: 'He brings creation into being, free of any flaw.',
  ),
  DivineName(
    number: 14,
    arabic: 'الْمُصَوِّرُ',
    transliteration: 'Al-Muṣawwir',
    meaning: 'The Fashioner',
    explanation: 'He gives every created thing its form and appearance.',
  ),
  DivineName(
    number: 15,
    arabic: 'الْغَفَّارُ',
    transliteration: 'Al-Ghaffār',
    meaning: 'The Ever-Forgiving',
    explanation: 'He forgives again and again those who turn back to Him.',
  ),
  DivineName(
    number: 16,
    arabic: 'الْقَهَّارُ',
    transliteration: 'Al-Qahhār',
    meaning: 'The Subduer',
    explanation: 'Everything submits to His power; nothing can resist Him.',
  ),
  DivineName(
    number: 17,
    arabic: 'الْوَهَّابُ',
    transliteration: 'Al-Wahhāb',
    meaning: 'The Bestower',
    explanation: 'He gives freely and abundantly, expecting nothing in return.',
  ),
  DivineName(
    number: 18,
    arabic: 'الرَّزَّاقُ',
    transliteration: 'Ar-Razzāq',
    meaning: 'The Provider',
    explanation: 'He provides sustenance for every living thing.',
  ),
  DivineName(
    number: 19,
    arabic: 'الْفَتَّاحُ',
    transliteration: 'Al-Fattāḥ',
    meaning: 'The Opener',
    explanation: 'He opens the doors of mercy and provision and judges with truth.',
  ),
  DivineName(
    number: 20,
    arabic: 'الْعَلِيمُ',
    transliteration: 'Al-ʿAlīm',
    meaning: 'The All-Knowing',
    explanation: 'His knowledge encompasses everything, hidden and apparent.',
  ),
  DivineName(
    number: 21,
    arabic: 'الْقَابِضُ',
    transliteration: 'Al-Qābiḍ',
    meaning: 'The Withholder',
    explanation: 'He withholds and restricts provision according to His wisdom.',
  ),
  DivineName(
    number: 22,
    arabic: 'الْبَاسِطُ',
    transliteration: 'Al-Bāsiṭ',
    meaning: 'The Extender',
    explanation: 'He extends provision and mercy as He wills.',
  ),
  DivineName(
    number: 23,
    arabic: 'الْخَافِضُ',
    transliteration: 'Al-Khāfiḍ',
    meaning: 'The Abaser',
    explanation: 'He lowers whom He wills, with perfect justice.',
  ),
  DivineName(
    number: 24,
    arabic: 'الرَّافِعُ',
    transliteration: 'Ar-Rāfiʿ',
    meaning: 'The Exalter',
    explanation: 'He raises whom He wills in rank and honour.',
  ),
  DivineName(
    number: 25,
    arabic: 'الْمُعِزُّ',
    transliteration: 'Al-Muʿizz',
    meaning: 'The Giver of Honour',
    explanation: 'He grants honour and strength to whom He wills.',
  ),
  DivineName(
    number: 26,
    arabic: 'الْمُذِلُّ',
    transliteration: 'Al-Mudhill',
    meaning: 'The Giver of Disgrace',
    explanation: 'He humbles whom He wills, with perfect justice.',
  ),
  DivineName(
    number: 27,
    arabic: 'السَّمِيعُ',
    transliteration: 'As-Samīʿ',
    meaning: 'The All-Hearing',
    explanation: 'He hears every sound and every call made to Him.',
  ),
  DivineName(
    number: 28,
    arabic: 'الْبَصِيرُ',
    transliteration: 'Al-Baṣīr',
    meaning: 'The All-Seeing',
    explanation: 'He sees all things, however small or hidden.',
  ),
  DivineName(
    number: 29,
    arabic: 'الْحَكَمُ',
    transliteration: 'Al-Ḥakam',
    meaning: 'The Judge',
    explanation: 'He judges between His creation with complete justice.',
  ),
  DivineName(
    number: 30,
    arabic: 'الْعَدْلُ',
    transliteration: 'Al-ʿAdl',
    meaning: 'The Just',
    explanation: 'Perfectly just, He wrongs no one in the least.',
  ),
  DivineName(
    number: 31,
    arabic: 'اللَّطِيفُ',
    transliteration: 'Al-Laṭīf',
    meaning: 'The Subtle, the Kind',
    explanation: 'He knows the finest details and is gentle with His servants.',
  ),
  DivineName(
    number: 32,
    arabic: 'الْخَبِيرُ',
    transliteration: 'Al-Khabīr',
    meaning: 'The All-Aware',
    explanation: 'He knows the inner reality of every matter.',
  ),
  DivineName(
    number: 33,
    arabic: 'الْحَلِيمُ',
    transliteration: 'Al-Ḥalīm',
    meaning: 'The Forbearing',
    explanation: 'He does not hasten punishment, giving time to repent.',
  ),
  DivineName(
    number: 34,
    arabic: 'الْعَظِيمُ',
    transliteration: 'Al-ʿAẓīm',
    meaning: 'The Magnificent',
    explanation: 'Supreme in greatness and majesty.',
  ),
  DivineName(
    number: 35,
    arabic: 'الْغَفُورُ',
    transliteration: 'Al-Ghafūr',
    meaning: 'The All-Forgiving',
    explanation: 'His forgiveness covers even great sins.',
  ),
  DivineName(
    number: 36,
    arabic: 'الشَّكُورُ',
    transliteration: 'Ash-Shakūr',
    meaning: 'The Most Appreciative',
    explanation: 'He rewards even small good deeds abundantly.',
  ),
  DivineName(
    number: 37,
    arabic: 'الْعَلِيُّ',
    transliteration: 'Al-ʿAliyy',
    meaning: 'The Most High',
    explanation: 'Exalted above all of creation.',
  ),
  DivineName(
    number: 38,
    arabic: 'الْكَبِيرُ',
    transliteration: 'Al-Kabīr',
    meaning: 'The Most Great',
    explanation: 'Greater than everything that exists.',
  ),
  DivineName(
    number: 39,
    arabic: 'الْحَفِيظُ',
    transliteration: 'Al-Ḥafīẓ',
    meaning: 'The Preserver',
    explanation: 'He guards and preserves all things.',
  ),
  DivineName(
    number: 40,
    arabic: 'الْمُقِيتُ',
    transliteration: 'Al-Muqīt',
    meaning: 'The Sustainer',
    explanation: 'He gives every creature its nourishment and has power over all.',
  ),
  DivineName(
    number: 41,
    arabic: 'الْحَسِيبُ',
    transliteration: 'Al-Ḥasīb',
    meaning: 'The Reckoner',
    explanation: 'He takes account of all deeds and suffices whoever relies on Him.',
  ),
  DivineName(
    number: 42,
    arabic: 'الْجَلِيلُ',
    transliteration: 'Al-Jalīl',
    meaning: 'The Majestic',
    explanation: 'Possessor of majesty and splendour.',
  ),
  DivineName(
    number: 43,
    arabic: 'الْكَرِيمُ',
    transliteration: 'Al-Karīm',
    meaning: 'The Generous',
    explanation: 'Noble and abundant in His giving.',
  ),
  DivineName(
    number: 44,
    arabic: 'الرَّقِيبُ',
    transliteration: 'Ar-Raqīb',
    meaning: 'The Watchful',
    explanation: 'Nothing escapes His watch.',
  ),
  DivineName(
    number: 45,
    arabic: 'الْمُجِيبُ',
    transliteration: 'Al-Mujīb',
    meaning: 'The Responder',
    explanation: 'He answers those who call upon Him.',
  ),
  DivineName(
    number: 46,
    arabic: 'الْوَاسِعُ',
    transliteration: 'Al-Wāsiʿ',
    meaning: 'The All-Encompassing',
    explanation: 'Vast in mercy, knowledge and generosity.',
  ),
  DivineName(
    number: 47,
    arabic: 'الْحَكِيمُ',
    transliteration: 'Al-Ḥakīm',
    meaning: 'The All-Wise',
    explanation: 'All that He commands and decrees is full of wisdom.',
  ),
  DivineName(
    number: 48,
    arabic: 'الْوَدُودُ',
    transliteration: 'Al-Wadūd',
    meaning: 'The Loving',
    explanation: 'He loves His righteous servants and is loved by them.',
  ),
  DivineName(
    number: 49,
    arabic: 'الْمَجِيدُ',
    transliteration: 'Al-Majīd',
    meaning: 'The Most Glorious',
    explanation: 'Glorious in His essence, attributes and deeds.',
  ),
  DivineName(
    number: 50,
    arabic: 'الْبَاعِثُ',
    transliteration: 'Al-Bāʿith',
    meaning: 'The Resurrector',
    explanation: 'He will raise all creatures on the Day of Judgement.',
  ),
  DivineName(
    number: 51,
    arabic: 'الشَّهِيدُ',
    transliteration: 'Ash-Shahīd',
    meaning: 'The Witness',
    explanation: 'He witnesses everything; nothing is hidden from Him.',
  ),
  DivineName(
    number: 52,
    arabic: 'الْحَقُّ',
    transliteration: 'Al-Ḥaqq',
    meaning: 'The Truth',
    explanation: 'His existence is the ultimate truth, and His word is true.',
  ),
  DivineName(
    number: 53,
    arabic: 'الْوَكِيلُ',
    transliteration: 'Al-Wakīl',
    meaning: 'The Trustee',
    explanation: 'He is sufficient as the One to rely upon.',
  ),
  DivineName(
    number: 54,
    arabic: 'الْقَوِيُّ',
    transliteration: 'Al-Qawiyy',
    meaning: 'The All-Strong',
    explanation: 'His strength is perfect and never weakens.',
  ),
  DivineName(
    number: 55,
    arabic: 'الْمَتِينُ',
    transliteration: 'Al-Matīn',
    meaning: 'The Firm',
    explanation: 'Unshakeable in His strength.',
  ),
  DivineName(
    number: 56,
    arabic: 'الْوَلِيُّ',
    transliteration: 'Al-Waliyy',
    meaning: 'The Protecting Friend',
    explanation: 'He supports and protects the believers.',
  ),
  DivineName(
    number: 57,
    arabic: 'الْحَمِيدُ',
    transliteration: 'Al-Ḥamīd',
    meaning: 'The Praiseworthy',
    explanation: 'Worthy of all praise in every circumstance.',
  ),
  DivineName(
    number: 58,
    arabic: 'الْمُحْصِي',
    transliteration: 'Al-Muḥṣī',
    meaning: 'The Accounter',
    explanation: 'He has counted and recorded everything.',
  ),
  DivineName(
    number: 59,
    arabic: 'الْمُبْدِئُ',
    transliteration: 'Al-Mubdiʾ',
    meaning: 'The Originator',
    explanation: 'He begins creation from nothing.',
  ),
  DivineName(
    number: 60,
    arabic: 'الْمُعِيدُ',
    transliteration: 'Al-Muʿīd',
    meaning: 'The Restorer',
    explanation: 'He will bring creation back after death.',
  ),
  DivineName(
    number: 61,
    arabic: 'الْمُحْيِي',
    transliteration: 'Al-Muḥyī',
    meaning: 'The Giver of Life',
    explanation: 'He gives life to whom He wills.',
  ),
  DivineName(
    number: 62,
    arabic: 'الْمُمِيتُ',
    transliteration: 'Al-Mumīt',
    meaning: 'The Bringer of Death',
    explanation: 'He causes death when the appointed term arrives.',
  ),
  DivineName(
    number: 63,
    arabic: 'الْحَيُّ',
    transliteration: 'Al-Ḥayy',
    meaning: 'The Ever-Living',
    explanation: 'He lives eternally, without beginning or end.',
  ),
  DivineName(
    number: 64,
    arabic: 'الْقَيُّومُ',
    transliteration: 'Al-Qayyūm',
    meaning: 'The Self-Sustaining',
    explanation: 'He sustains Himself and everything that exists.',
  ),
  DivineName(
    number: 65,
    arabic: 'الْوَاجِدُ',
    transliteration: 'Al-Wājid',
    meaning: 'The Perceiver',
    explanation: 'He lacks nothing; whatever He wills, He finds.',
  ),
  DivineName(
    number: 66,
    arabic: 'الْمَاجِدُ',
    transliteration: 'Al-Mājid',
    meaning: 'The Illustrious',
    explanation: 'Noble and glorious in His generosity.',
  ),
  DivineName(
    number: 67,
    arabic: 'الْوَاحِدُ',
    transliteration: 'Al-Wāḥid',
    meaning: 'The One',
    explanation: 'One in His essence and attributes, without partner.',
  ),
  DivineName(
    number: 68,
    arabic: 'الصَّمَدُ',
    transliteration: 'Aṣ-Ṣamad',
    meaning: 'The Eternal Refuge',
    explanation: 'All depend on Him, and He depends on none.',
  ),
  DivineName(
    number: 69,
    arabic: 'الْقَادِرُ',
    transliteration: 'Al-Qādir',
    meaning: 'The All-Able',
    explanation: 'He is able to do all things.',
  ),
  DivineName(
    number: 70,
    arabic: 'الْمُقْتَدِرُ',
    transliteration: 'Al-Muqtadir',
    meaning: 'The All-Powerful',
    explanation: 'His power over everything is complete.',
  ),
  DivineName(
    number: 71,
    arabic: 'الْمُقَدِّمُ',
    transliteration: 'Al-Muqaddim',
    meaning: 'The Expediter',
    explanation: 'He brings forward whom and what He wills.',
  ),
  DivineName(
    number: 72,
    arabic: 'الْمُؤَخِّرُ',
    transliteration: 'Al-Muʾakhkhir',
    meaning: 'The Delayer',
    explanation: 'He holds back whom and what He wills, by His wisdom.',
  ),
  DivineName(
    number: 73,
    arabic: 'الأَوَّلُ',
    transliteration: 'Al-Awwal',
    meaning: 'The First',
    explanation: 'Nothing existed before Him.',
  ),
  DivineName(
    number: 74,
    arabic: 'الآخِرُ',
    transliteration: 'Al-Ākhir',
    meaning: 'The Last',
    explanation: 'Nothing will remain after Him.',
  ),
  DivineName(
    number: 75,
    arabic: 'الظَّاهِرُ',
    transliteration: 'Aẓ-Ẓāhir',
    meaning: 'The Manifest',
    explanation: 'Above all things, with His signs evident everywhere.',
  ),
  DivineName(
    number: 76,
    arabic: 'الْبَاطِنُ',
    transliteration: 'Al-Bāṭin',
    meaning: 'The Hidden',
    explanation: 'Nearer than all things, yet beyond full perception.',
  ),
  DivineName(
    number: 77,
    arabic: 'الْوَالِي',
    transliteration: 'Al-Wālī',
    meaning: 'The Governor',
    explanation: 'He manages and governs all affairs.',
  ),
  DivineName(
    number: 78,
    arabic: 'الْمُتَعَالِي',
    transliteration: 'Al-Mutaʿālī',
    meaning: 'The Most Exalted',
    explanation: 'Far above anything that does not befit Him.',
  ),
  DivineName(
    number: 79,
    arabic: 'الْبَرُّ',
    transliteration: 'Al-Barr',
    meaning: 'The Source of Goodness',
    explanation: 'Kind and good to all of His creation.',
  ),
  DivineName(
    number: 80,
    arabic: 'التَّوَّابُ',
    transliteration: 'At-Tawwāb',
    meaning: 'The Acceptor of Repentance',
    explanation: 'He turns to those who repent, again and again.',
  ),
  DivineName(
    number: 81,
    arabic: 'الْمُنْتَقِمُ',
    transliteration: 'Al-Muntaqim',
    meaning: 'The Avenger',
    explanation: 'He brings to justice those who persist in wrongdoing.',
  ),
  DivineName(
    number: 82,
    arabic: 'الْعَفُوُّ',
    transliteration: 'Al-ʿAfuww',
    meaning: 'The Pardoner',
    explanation: 'He erases sins completely.',
  ),
  DivineName(
    number: 83,
    arabic: 'الرَّءُوفُ',
    transliteration: 'Ar-Raʾūf',
    meaning: 'The Most Kind',
    explanation: 'His compassion is tender and deep.',
  ),
  DivineName(
    number: 84,
    arabic: 'مَالِكُ الْمُلْكِ',
    transliteration: 'Mālik al-Mulk',
    meaning: 'Owner of All Sovereignty',
    explanation: 'All dominion belongs to Him alone.',
  ),
  DivineName(
    number: 85,
    arabic: 'ذُو الْجَلاَلِ وَالإِكْرَامِ',
    transliteration: 'Dhū al-Jalāl wa al-Ikrām',
    meaning: 'Lord of Majesty and Generosity',
    explanation: 'Possessor of majesty, and of honour and generosity.',
  ),
  DivineName(
    number: 86,
    arabic: 'الْمُقْسِطُ',
    transliteration: 'Al-Muqsiṭ',
    meaning: 'The Equitable',
    explanation: 'He acts with perfect fairness.',
  ),
  DivineName(
    number: 87,
    arabic: 'الْجَامِعُ',
    transliteration: 'Al-Jāmiʿ',
    meaning: 'The Gatherer',
    explanation: 'He will gather all creation on the Day of Judgement.',
  ),
  DivineName(
    number: 88,
    arabic: 'الْغَنِيُّ',
    transliteration: 'Al-Ghaniyy',
    meaning: 'The Self-Sufficient',
    explanation: 'He needs nothing, while all are in need of Him.',
  ),
  DivineName(
    number: 89,
    arabic: 'الْمُغْنِي',
    transliteration: 'Al-Mughnī',
    meaning: 'The Enricher',
    explanation: 'He enriches whom He wills.',
  ),
  DivineName(
    number: 90,
    arabic: 'الْمَانِعُ',
    transliteration: 'Al-Māniʿ',
    meaning: 'The Preventer',
    explanation: 'He withholds what He wills, by His wisdom.',
  ),
  DivineName(
    number: 91,
    arabic: 'الضَّارُّ',
    transliteration: 'Aḍ-Ḍārr',
    meaning: 'The Distresser',
    explanation: 'Harm happens only by His decree, through His wisdom.',
  ),
  DivineName(
    number: 92,
    arabic: 'النَّافِعُ',
    transliteration: 'An-Nāfiʿ',
    meaning: 'The Benefactor',
    explanation: 'All benefit comes from Him.',
  ),
  DivineName(
    number: 93,
    arabic: 'النُّورُ',
    transliteration: 'An-Nūr',
    meaning: 'The Light',
    explanation: 'He illuminates the heavens, the earth and the hearts of the believers.',
  ),
  DivineName(
    number: 94,
    arabic: 'الْهَادِي',
    transliteration: 'Al-Hādī',
    meaning: 'The Guide',
    explanation: 'He guides whom He wills to the truth.',
  ),
  DivineName(
    number: 95,
    arabic: 'الْبَدِيعُ',
    transliteration: 'Al-Badīʿ',
    meaning: 'The Incomparable Originator',
    explanation: 'He creates without any precedent.',
  ),
  DivineName(
    number: 96,
    arabic: 'الْبَاقِي',
    transliteration: 'Al-Bāqī',
    meaning: 'The Everlasting',
    explanation: 'He remains forever.',
  ),
  DivineName(
    number: 97,
    arabic: 'الْوَارِثُ',
    transliteration: 'Al-Wārith',
    meaning: 'The Inheritor',
    explanation: 'He remains after all creation passes away.',
  ),
  DivineName(
    number: 98,
    arabic: 'الرَّشِيدُ',
    transliteration: 'Ar-Rashīd',
    meaning: 'The Guide to the Right Path',
    explanation: 'All His decrees are rightly directed.',
  ),
  DivineName(
    number: 99,
    arabic: 'الصَّبُورُ',
    transliteration: 'Aṣ-Ṣabūr',
    meaning: 'The Patient',
    explanation: 'He does not hasten to punish.',
  ),
];

/// Meanings in the other app languages, index-aligned with [asmaUlHusna].
/// Arabic has none (a gloss in Arabic is commentary that needs a sourced
/// tafsir), so it falls back to English like every missing language.
const Map<String, List<String>> _meaningsByLanguage = {
  'ur': asmaMeaningsUr,
  'fr': asmaMeaningsFr,
  'de': asmaMeaningsDe,
  'hi': asmaMeaningsHi,
  'tr': asmaMeaningsTr,
  'zh': asmaMeaningsZh,
};

String divineNameMeaning(DivineName name, String languageCode) {
  final meanings = _meaningsByLanguage[languageCode];
  if (meanings == null || meanings.length != asmaUlHusna.length) return name.meaning;
  return meanings[name.number - 1];
}

/// Rotates through the 99 Names, one per day (day-of-year % 99).
DivineName nameOfTheDay(DateTime date) {
  final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(date.year)).inDays;
  return asmaUlHusna[dayOfYear % asmaUlHusna.length];
}

/// Folds accents and apostrophes so "rahman" matches "Ar-Raḥmān".
String foldForSearch(String s) {
  const from = 'āīūḥṣḍṭẓĀĪŪḤṢḌṬẒàâäéèêëîïôöùûüçğışÀÂÄÉÈÊËÎÏÔÖÙÛÜÇĞİŞ';
  const to = 'aiuhsdtzAIUHSDTZaaaeeeeiioouuucgisAAAEEEEIIOOUUUCGIS';
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    if (i >= 0) {
      buffer.write(to[i]);
    } else if (!'ʿʾ’\'`-'.contains(ch)) {
      buffer.write(ch);
    }
  }
  return buffer.toString().toLowerCase();
}
