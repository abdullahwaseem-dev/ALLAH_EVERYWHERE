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
  DuaCategory(
    title: 'Morning & Evening Adhkar',
    duas: [
      DuaItem(
        title: 'Morning remembrance (Ayat al-Kursi)',
        arabic:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
        transliteration: "Allahu la ilaha illa huwal-Hayyul-Qayyum, la ta'khudhuhu sinatuw-wa la nawm",
        translation:
            'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. (Ayat al-Kursi, recited morning and evening for protection.)',
        reference: "Quran 2:255; Sunan an-Nasa'i (Al-Kubra) 9928",
      ),
      DuaItem(
        title: 'In the morning (Asbahna)',
        arabic:
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        transliteration:
            "Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah",
        translation:
            'We have entered the morning and with it all dominion belongs to Allah, and praise is for Allah. There is no deity but Allah alone, without partner.',
        reference: 'Sahih Muslim 2723',
      ),
      DuaItem(
        title: 'In the evening (Amsayna)',
        arabic:
            'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        transliteration:
            "Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah",
        translation:
            'We have entered the evening and with it all dominion belongs to Allah, and praise is for Allah. There is no deity but Allah alone, without partner.',
        reference: 'Sahih Muslim 2723',
      ),
      DuaItem(
        title: 'Seeking well-being (Sayyid al-Istighfar)',
        arabic:
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
        transliteration:
            "Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana 'abduk, wa ana 'ala 'ahdika wa wa'dika mas-tata't",
        translation:
            'O Allah, You are my Lord, there is no deity but You. You created me and I am Your servant, and I am upon Your covenant and promise as much as I am able. (The best supplication for forgiveness - whoever says it in the morning or evening with certainty and dies that day/night enters Paradise.)',
        reference: 'Sahih al-Bukhari 6306',
      ),
    ],
  ),
  DuaCategory(
    title: 'Travel',
    duas: [
      DuaItem(
        title: 'When setting out on a journey',
        arabic:
            'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
        transliteration:
            "Allahu Akbar, Allahu Akbar, Allahu Akbar. Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila Rabbina lamunqalibun",
        translation:
            'Allah is the Greatest, Allah is the Greatest, Allah is the Greatest. Glory to Him who has subjected this to us, and we could not have done it ourselves. And indeed, to our Lord we will return.',
        reference: 'Sahih Muslim 1342',
      ),
      DuaItem(
        title: 'Dua for the traveler',
        arabic:
            'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى',
        transliteration:
            "Allahumma inna nas'aluka fi safarina hadhal-birra wat-taqwa, wa minal-'amali ma tarda",
        translation:
            'O Allah, we ask You on this journey of ours for righteousness and piety, and for deeds that please You.',
        reference: 'Sahih Muslim 1342',
      ),
      DuaItem(
        title: 'For one staying behind, to the traveler',
        arabic: 'أَسْتَوْدِعُ اللَّهَ دِينَكَ وَأَمَانَتَكَ وَخَوَاتِيمَ عَمَلِكَ',
        transliteration: "Astawdi'ullaha dinaka, wa amanataka, wa khawatima 'amalik",
        translation:
            'I entrust to Allah your religion, your trust, and the last of your deeds.',
        reference: "Jami' at-Tirmidhi 3443",
      ),
      DuaItem(
        title: 'Entering a town or city',
        arabic:
            'اللَّهُمَّ رَبَّ السَّمَاوَاتِ السَّبْعِ وَمَا أَظْلَلْنَ، وَرَبَّ الْأَرَضِينَ وَمَا أَقْلَلْنَ، أَسْأَلُكَ خَيْرَ هَذِهِ الْقَرْيَةِ',
        transliteration:
            "Allahumma Rabbas-samawatis-sab'i wa ma azlalna, wa Rabbal-aradina wa ma aqlalna, as'aluka khayra hadhihil-qaryah",
        translation:
            'O Allah, Lord of the seven heavens and all that they shade, and Lord of the earths and all that they carry, I ask You for the good of this town.',
        reference: "Sunan an-Nasa'i (Al-Kubra) 10406",
      ),
    ],
  ),
  DuaCategory(
    title: 'Illness & Health',
    duas: [
      DuaItem(
        title: 'Visiting the sick',
        arabic: 'لَا بَأْسَ، طَهُورٌ إِنْ شَاءَ اللَّهُ',
        transliteration: "La ba'sa, tahurun in sha Allah",
        translation: 'No harm, it will be a purification, if Allah wills.',
        reference: 'Sahih al-Bukhari 3616',
      ),
      DuaItem(
        title: 'Dua for the sick (seeking cure)',
        arabic:
            'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَاسَ اشْفِ أَنْتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
        transliteration:
            "Allahumma Rabban-nas, adhhibil-ba's, ishfi Antash-Shafi, la shifa'a illa shifa'uk, shifa'an la yughadiru saqama",
        translation:
            'O Allah, Lord of mankind, remove the affliction and heal - You are the Healer, there is no healing but Your healing, a healing that leaves no illness behind.',
        reference: 'Sahih al-Bukhari 5675, Sahih Muslim 2191',
      ),
      DuaItem(
        title: 'When in pain (placing hand on the area)',
        arabic: 'بِسْمِ اللَّهِ (×٣) أَعُوذُ بِعِزَّةِ اللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ',
        transliteration:
            "Bismillah (three times), a'udhu bi'izzatillahi wa qudratihi min sharri ma ajidu wa uhadhir",
        translation:
            'In the name of Allah (three times). I seek refuge in the might and power of Allah from the evil of what I feel and am wary of.',
        reference: 'Sahih Muslim 2202',
      ),
      DuaItem(
        title: "Reciting Ruqyah for oneself (Al-Mu'awwidhatayn)",
        arabic: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ... قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
        transliteration: "Qul a'udhu bi Rabbil-Falaq... Qul a'udhu bi Rabbin-nas",
        translation:
            'Say: I seek refuge in the Lord of daybreak... Say: I seek refuge in the Lord of mankind. (Surahs 113 and 114, recited and blown onto the body, as the Prophet did during his final illness.)',
        reference: 'Quran 113-114; Sahih al-Bukhari 5735, Sahih Muslim 2192',
      ),
    ],
  ),
  DuaCategory(
    title: 'Entering & Leaving Home',
    duas: [
      DuaItem(
        title: 'Entering the home',
        arabic:
            'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
        transliteration: "Bismillahi walajna, wa bismillahi kharajna, wa 'ala Rabbina tawakkalna",
        translation:
            'In the name of Allah we enter, in the name of Allah we leave, and upon our Lord we place our trust.',
        reference: 'Sunan Abu Dawood 5096',
      ),
      DuaItem(
        title: 'Leaving the home',
        arabic:
            'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        transliteration: "Bismillahi, tawakkaltu 'alallah, wa la hawla wa la quwwata illa billah",
        translation:
            'In the name of Allah, I place my trust in Allah, and there is no power nor might except with Allah.',
        reference: 'Sunan Abu Dawood 5095, Jami\' at-Tirmidhi 3426',
      ),
      DuaItem(
        title: 'Entering the masjid',
        arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        transliteration: 'Allahummaf-tah li abwaba rahmatik',
        translation: 'O Allah, open the gates of Your mercy for me.',
        reference: 'Sahih Muslim 713',
      ),
      DuaItem(
        title: 'Leaving the masjid',
        arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
        transliteration: 'Allahumma inni as\'aluka min fadlik',
        translation: 'O Allah, I ask You from Your bounty.',
        reference: 'Sahih Muslim 713',
      ),
    ],
  ),
  DuaCategory(
    title: 'Eating & Drinking',
    duas: [
      DuaItem(
        title: 'Before eating',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah',
        translation: 'In the name of Allah.',
        reference: 'Sunan Abu Dawood 3767; if one forgets, add "Bismillahi fi awwalihi wa akhirih"',
      ),
      DuaItem(
        title: 'After eating',
        arabic:
            'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
        transliteration:
            "Alhamdu lillahil-ladhi at'amani hadha, wa razaqanihi min ghayri hawlin minni wa la quwwah",
        translation:
            'Praise be to Allah who fed me this and provided it for me without any power or might from myself.',
        reference: "Sunan Abu Dawood 4023, Jami' at-Tirmidhi 3458",
      ),
      DuaItem(
        title: 'When served a meal as a guest',
        arabic:
            'اللَّهُمَّ بَارِكْ لَهُمْ فِيمَا رَزَقْتَهُمْ، وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ',
        transliteration: "Allahumma barik lahum fima razaqtahum, waghfir lahum warhamhum",
        translation: 'O Allah, bless what You have provided them, and forgive them and have mercy on them.',
        reference: 'Sahih Muslim 2042',
      ),
    ],
  ),
  DuaCategory(
    title: 'Sleep & Waking',
    duas: [
      DuaItem(
        title: 'Before sleeping',
        arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        transliteration: 'Bismika Allahumma amutu wa ahya',
        translation: 'In Your name, O Allah, I die and I live.',
        reference: 'Sahih al-Bukhari 6324',
      ),
      DuaItem(
        title: 'Upon waking',
        arabic:
            'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
        translation:
            'Praise be to Allah who gave us life after having caused us to die, and to Him is the resurrection.',
        reference: 'Sahih al-Bukhari 6312',
      ),
      DuaItem(
        title: 'Ayat al-Kursi before sleeping',
        arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
        transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum...",
        translation:
            'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence... Whoever recites it before sleeping will have a protector from Allah, and no devil will come near him until morning.',
        reference: 'Quran 2:255; Sahih al-Bukhari 2311',
      ),
    ],
  ),
  DuaCategory(
    title: 'Distress & Anxiety',
    duas: [
      DuaItem(
        title: 'In times of distress',
        arabic:
            'لَا إِلَٰهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَٰهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ',
        transliteration:
            "La ilaha illallahul-'Azimul-Halim, la ilaha illallahu Rabbul-'Arshil-'Azim",
        translation:
            'There is no deity but Allah, the Mighty, the Forbearing. There is no deity but Allah, Lord of the Magnificent Throne.',
        reference: 'Sahih al-Bukhari 6345, Sahih Muslim 2730',
      ),
      DuaItem(
        title: 'Against grief and anxiety',
        arabic:
            'اللَّهُمَّ إِنِّي عَبْدُكَ ابْنُ عَبْدِكَ ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ',
        transliteration:
            "Allahumma inni 'abduka ibnu 'abdika ibnu amatik, nasiyati biyadik, madin fiyya hukmuk, 'adlun fiyya qada'uk",
        translation:
            'O Allah, I am Your servant, son of Your servant, son of Your maidservant. My forelock is in Your hand, Your judgment upon me is assured, and Your decree over me is just.',
        reference: "Musnad Ahmad 3712 (hasan/sahih)",
      ),
      DuaItem(
        title: 'Relief from worry and debt',
        arabic:
            'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
        transliteration:
            "Allahumma inni a'udhu bika minal-hammi wal-hazan, wal-'ajzi wal-kasal, wal-bukhli wal-jubn, wa dala'id-dayni wa ghalabatir-rijal",
        translation:
            'O Allah, I seek refuge in You from worry and grief, from incapacity and laziness, from miserliness and cowardice, from being overcome by debt and overpowered by men.',
        reference: 'Sahih al-Bukhari 6369',
      ),
    ],
  ),
  DuaCategory(
    title: 'Marriage & Family',
    duas: [
      DuaItem(
        title: 'For the newly married couple',
        arabic: 'بَارَكَ اللَّهُ لَكَ، وَبَارَكَ عَلَيْكَ، وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ',
        transliteration: "Barakallahu laka, wa baraka 'alayka, wa jama'a baynakuma fi khayr",
        translation:
            'May Allah bless you, and shower His blessings upon you, and unite you both in goodness.',
        reference: "Sunan Abu Dawood 2130, Jami' at-Tirmidhi 1091",
      ),
      DuaItem(
        title: 'On the wedding night',
        arabic:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَخَيْرَ مَا جَبَلْتَهَا عَلَيْهِ، وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَشَرِّ مَا جَبَلْتَهَا عَلَيْهِ',
        transliteration:
            "Allahumma inni as'aluka khayraha wa khayra ma jabaltaha 'alayh, wa a'udhu bika min sharriha wa sharri ma jabaltaha 'alayh",
        translation:
            'O Allah, I ask You for her good and the good that You have instilled in her, and I seek refuge in You from her evil and the evil that You have instilled in her.',
        reference: 'Sunan Abu Dawood 2160',
      ),
      DuaItem(
        title: 'For righteous offspring',
        arabic:
            'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
        transliteration:
            "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yuniw-waj'alna lil-muttaqina imama",
        translation:
            'Our Lord, grant us from among our spouses and offspring comfort to our eyes, and make us an example for the righteous.',
        reference: 'Quran 25:74',
      ),
    ],
  ),
  DuaCategory(
    title: 'Children',
    duas: [
      DuaItem(
        title: 'For a newborn (Tahnik blessing)',
        arabic: 'أُعِيذُهُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ، وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ',
        transliteration:
            "U'idhuhu bikalimatillahit-tammati min kulli shaytaniw-wa hammah, wa min kulli 'aynil-lammah",
        translation:
            'I seek protection for him/her with the perfect words of Allah, from every devil and every poisonous creature, and from every evil, harmful eye. (Said for Ismail and Ishaq by their forefather Ibrahim, and by the Prophet for his grandsons Hasan and Husayn.)',
        reference: 'Sahih al-Bukhari 3371',
      ),
      DuaItem(
        title: 'For a child\'s wellbeing',
        arabic: 'رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ',
        transliteration: 'Rabbi hab li minas-salihin',
        translation: 'My Lord, grant me [a child] from among the righteous.',
        reference: 'Quran 37:100',
      ),
      DuaItem(
        title: 'Blessing a child (as the Prophet did for Ibn Abbas)',
        arabic: 'اللَّهُمَّ فَقِّهْهُ فِي الدِّينِ وَعَلِّمْهُ التَّأْوِيلَ',
        transliteration: "Allahumma faqqihhu fid-dini wa 'allimhut-ta'wil",
        translation: 'O Allah, grant him deep understanding of the religion and teach him the true interpretation.',
        reference: 'Sahih al-Bukhari 143',
      ),
    ],
  ),
  DuaCategory(
    title: 'Forgiveness & Repentance',
    duas: [
      DuaItem(
        title: 'Seeking forgiveness',
        arabic: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
        transliteration: "Rabbighfir li wa tub 'alayya innaka Antat-Tawwabur-Rahim",
        translation: 'My Lord, forgive me and accept my repentance; indeed, You are the Accepting of repentance, the Merciful.',
        reference: 'Sunan Abu Dawood 1516',
      ),
      DuaItem(
        title: "Our Lord, we have wronged ourselves",
        arabic:
            'رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
        transliteration:
            "Rabbana zalamna anfusana, wa illam taghfir lana wa tarhamna lanakunanna minal-khasirin",
        translation:
            'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
        reference: 'Quran 7:23',
      ),
      DuaItem(
        title: 'General istighfar',
        arabic: 'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
        transliteration: "Astaghfirullahal-ladhi la ilaha illa Huwal-Hayyal-Qayyuma wa atubu ilayh",
        translation: 'I seek the forgiveness of Allah, besides whom there is no deity, the Ever-Living, the Sustainer, and I repent to Him.',
        reference: "Sunan Abu Dawood 1517, Jami' at-Tirmidhi 3577",
      ),
    ],
  ),
  DuaCategory(
    title: 'Protection from Evil',
    duas: [
      DuaItem(
        title: 'Seeking refuge in the complete words of Allah',
        arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
        translation: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
        reference: 'Sahih Muslim 2708',
      ),
      DuaItem(
        title: 'Protection morning and evening',
        arabic:
            'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        transliteration:
            "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim",
        translation:
            'In the name of Allah, with whose name nothing on earth or in the heaven can cause harm, and He is the All-Hearing, the All-Knowing. (Said three times morning and evening.)',
        reference: "Sunan Abu Dawood 5088, Jami' at-Tirmidhi 3388",
      ),
      DuaItem(
        title: 'Against the evil eye and envy',
        arabic: 'اللَّهُمَّ بَارِكْ فِيهِ وَلَا تَضُرَّهُ',
        transliteration: "Allahumma barik fihi wa la tadurrahu",
        translation:
            'O Allah, bless him/it and do not let it cause harm. (Said when admiring something to guard against the evil eye, per the Prophet\'s guidance.)',
        reference: "Muwatta Imam Malik; Musnad Ahmad",
      ),
    ],
  ),
  DuaCategory(
    title: 'Hajj & Umrah',
    duas: [
      DuaItem(
        title: 'The Talbiyah',
        arabic:
            'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
        transliteration:
            "Labbayka Allahumma labbayk, labbayka la sharika laka labbayk, innal-hamda wan-ni'mata laka wal-mulk, la sharika lak",
        translation:
            'Here I am, O Allah, here I am. Here I am, You have no partner, here I am. Indeed all praise, grace, and dominion are Yours - You have no partner.',
        reference: 'Sahih al-Bukhari 1549, Sahih Muslim 1184',
      ),
      DuaItem(
        title: 'Between the Yemeni Corner and the Black Stone',
        arabic:
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
        translation: 'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
        reference: 'Quran 2:201; Sunan Abu Dawood 1892',
      ),
      DuaItem(
        title: 'At Mount Safa and Marwah',
        arabic: 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ',
        transliteration: 'Innas-Safa wal-Marwata min sha\'a\'irillah',
        translation: 'Indeed, Safa and Marwah are among the symbols of Allah. (Recited on beginning Sa\'i, as the Prophet did.)',
        reference: 'Quran 2:158; Sahih Muslim 1218',
      ),
    ],
  ),
];
