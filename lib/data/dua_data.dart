/// A single dua with its Arabic text, transliteration, translation and source.
class DuaItem {
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String reference;

  const DuaItem({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
  });
}

class DuaCategory {
  final String title;
  final List<DuaItem> duas;

  const DuaCategory({required this.title, required this.duas});
}

/// Static, authentic dua content. Replaces the old hardcoded/dead-ended
/// screens where most category cards led nowhere and the detail screen
/// always showed the same "new clothes" text regardless of what was tapped.
const List<DuaCategory> duaCategories = [
  DuaCategory(
    title: 'Ablution',
    duas: [
      DuaItem(
        title: 'Before Wudu',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah',
        translation: 'In the name of Allah.',
        reference: 'Sunan Abu Dawood 101',
      ),
      DuaItem(
        title: 'After Wudu',
        arabic:
            'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
        transliteration:
            "Ash-hadu an la ilaha illallahu wahdahu la sharika lah, wa ash-hadu anna Muhammadan 'abduhu wa rasuluh",
        translation:
            'I bear witness that there is no god but Allah alone, without partner, and I bear witness that Muhammad is His servant and Messenger.',
        reference: 'Sahih Muslim 234',
      ),
      DuaItem(
        title: 'Extended dua after Wudu',
        arabic:
            'اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ',
        transliteration:
            "Allahumma-j'alni minat-tawwabina waj'alni minal-mutatahhirin",
        translation:
            'O Allah, make me among those who repent and make me among those who purify themselves.',
        reference: "Jami' at-Tirmidhi 55",
      ),
    ],
  ),
  DuaCategory(
    title: 'Clothes',
    duas: [
      DuaItem(
        title: 'Before removing clothes',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah',
        translation: 'In the name of Allah.',
        reference: 'General Islamic etiquette (Adab)',
      ),
      DuaItem(
        title: 'When wearing new clothes',
        arabic:
            'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ كَسَوْتَنِيهِ، أَسْأَلُكَ مِنْ خَيْرِهِ وَخَيْرِ مَا صُنِعَ لَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّهِ وَشَرِّ مَا صُنِعَ لَهُ',
        transliteration:
            "Allahumma laka-l-hamdu Anta kasawtanih, as'aluka min khayrihi wa khayri ma suni'a lah, wa a'udhu bika min sharrihi wa sharri ma suni'a lah.",
        translation:
            'O Allah, all praise is for You alone - You have clothed me with it. I ask You for its good and the good of that for which it was made; and I seek Your protection from its evil and the evil of that for which it was made.',
        reference: "Sunan Abu Dawood 4020, Jami' at-Tirmidhi 1767",
      ),
      DuaItem(
        title: 'After wearing clothes',
        arabic:
            'الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
        transliteration:
            "Alhamdu lillahil-ladhi kasani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah",
        translation:
            'Praise be to Allah who has clothed me with this and provided it for me, with no power or might from myself.',
        reference: "Sunan Abu Dawood 4023, Jami' at-Tirmidhi 3560",
      ),
      DuaItem(
        title: 'To someone wearing new clothes',
        arabic: 'تُبْلِي وَيُخْلِفُ اللَّهُ تَعَالَى',
        transliteration: "Tubli wa yukhliful-Lahu ta'ala",
        translation: 'May you wear it out and may Allah replace it with a new one.',
        reference: 'Sunan Abu Dawood 4020',
      ),
    ],
  ),
  DuaCategory(
    title: 'Ramadan',
    duas: [
      DuaItem(
        title: 'On sighting the Ramadan crescent',
        arabic:
            'اللَّهُ أَكْبَرُ، اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْأَمْنِ وَالْإِيمَانِ، وَالسَّلَامَةِ وَالْإِسْلَامِ، رَبِّي وَرَبُّكَ اللَّهُ',
        transliteration:
            "Allahu Akbar, Allahumma ahillahu 'alayna bil-amni wal-iman, was-salamati wal-Islam, rabbi wa rabbuk Allah",
        translation:
            'Allah is the Greatest. O Allah, let this crescent moon pass by us with security and faith, safety and Islam. My Lord and your Lord is Allah.',
        reference: "Jami' at-Tirmidhi 3451",
      ),
      DuaItem(
        title: 'Intention to fast (before Suhoor)',
        arabic: 'وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَان',
        transliteration: 'Wa bisawmi ghadin nawaitu min shahri Ramadan',
        translation: 'I intend to keep the fast for tomorrow in the month of Ramadan.',
        reference: 'Common practice recorded by early scholars',
      ),
      DuaItem(
        title: 'Breaking the fast (Iftar)',
        arabic:
            'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
        transliteration:
            "Dhahaba adh-dhama'u wabtallatil-'uruqu wa thabatal-ajru in sha Allah",
        translation:
            'The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills.',
        reference: 'Sunan Abu Dawood 2357',
      ),
      DuaItem(
        title: 'General Iftar dua',
        arabic: 'اللَّهُمَّ لَكَ صُمْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
        transliteration: "Allahumma laka sumtu wa 'ala rizqika aftartu",
        translation: 'O Allah, I fasted for You and I break my fast with Your provision.',
        reference: 'Sunan Abu Dawood 2358',
      ),
    ],
  ),
];
