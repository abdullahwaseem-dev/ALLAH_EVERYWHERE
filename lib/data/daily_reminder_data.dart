/// A single "verse/hadith of the day" entry shown in the Home screen banner.
class DailyReminder {
  final bool isHadith;
  final String arabic;
  final String translation;
  final String reference;

  const DailyReminder({
    required this.isHadith,
    required this.arabic,
    required this.translation,
    required this.reference,
  });
}

/// A broad, mixed pool of authentic ayat and ahadith covering everyday
/// themes (mercy, patience, gratitude, character, knowledge) - not limited
/// to prayer, which already has its own reminder pool for the Adhan dialog.
/// [reminderForDay] picks one deterministically per calendar day so the
/// banner shows the same message all day and rotates the next day, rather
/// than changing every time the app is reopened.
const List<DailyReminder> dailyReminders = [
  DailyReminder(
    isHadith: false,
    arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translation: 'For indeed, with hardship [will be] ease.',
    reference: 'Quran 94:5',
  ),
  DailyReminder(
    isHadith: true,
    arabic:
        'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
    translation: 'Whoever believes in Allah and the Last Day should speak good or remain silent.',
    reference: 'Sahih al-Bukhari 6018, Sahih Muslim 47',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    translation: 'Indeed, Allah is with the patient.',
    reference: 'Quran 2:153',
  ),
  DailyReminder(
    isHadith: true,
    arabic:
        'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
    translation: 'None of you truly believes until he loves for his brother what he loves for himself.',
    reference: 'Sahih al-Bukhari 13, Sahih Muslim 45',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    translation: 'Allah does not burden a soul beyond that it can bear.',
    reference: 'Quran 2:286',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    translation: 'And whoever relies upon Allah - then He is sufficient for him.',
    reference: 'Quran 65:3',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ',
    translation:
        'The strong person is not the one who overcomes people by his strength, but the one who controls himself while in anger.',
    reference: 'Sahih al-Bukhari 6114, Sahih Muslim 2609',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
    translation:
        'O My servants who have transgressed against themselves - do not despair of the mercy of Allah. Indeed, Allah forgives all sins.',
    reference: 'Quran 39:53',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا نَفَّسَ اللَّهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ الْقِيَامَةِ',
    translation:
        'Whoever relieves a believer of a hardship of this world, Allah will relieve him of a hardship on the Day of Judgment.',
    reference: 'Sahih Muslim 2699',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'إِنَّ أَكْرَمَكُمْ عِندَ اللَّهِ أَتْقَاكُمْ',
    translation: 'Indeed, the most noble of you in the sight of Allah is the most righteous of you.',
    reference: 'Quran 49:13',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'خَيْرُكُمْ خَيْرُكُمْ لِأَهْلِهِ، وَأَنَا خَيْرُكُمْ لِأَهْلِي',
    translation: 'The best of you is the one who is best to his family, and I am the best of you to my family.',
    reference: "Sunan Ibn Majah 1977, Jami' at-Tirmidhi 3895",
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    translation: 'Verily, in the remembrance of Allah do hearts find rest.',
    reference: 'Quran 13:28',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'لَيْسَ مِنَّا مَنْ لَمْ يَرْحَمْ صَغِيرَنَا وَيُوَقِّرْ كَبِيرَنَا',
    translation: 'He is not one of us who does not show mercy to our young and does not respect our elders.',
    reference: "Sunan Abu Dawood 4943, Jami' at-Tirmidhi 1919",
  ),
  DailyReminder(
    isHadith: false,
    arabic:
        'وَقَضَىٰ رَبُّكَ أَلَّا تَعْبُدُوا إِلَّا إِيَّاهُ وَبِالْوَالِدَيْنِ إِحْسَانًا',
    translation:
        'Your Lord has decreed that you worship none but Him, and that you be dutiful to your parents.',
    reference: 'Quran 17:23',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ',
    translation: 'Be mindful of Allah wherever you are.',
    reference: "Jami' at-Tirmidhi 1987",
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ',
    translation: 'Do not weaken and do not grieve, and you will be superior if you are [true] believers.',
    reference: 'Quran 3:139',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
    translation: 'The best among you are those who learn the Quran and teach it.',
    reference: 'Sahih al-Bukhari 5027',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'وَاعْبُدُوا اللَّهَ وَلَا تُشْرِكُوا بِهِ شَيْئًا وَبِالْوَالِدَيْنِ إِحْسَانًا وَبِذِي الْقُرْبَىٰ',
    translation:
        'Worship Allah and associate nothing with Him, and to parents do good, and to relatives, orphans, the needy, and the neighbour.',
    reference: 'Quran 4:36',
  ),
  DailyReminder(
    isHadith: true,
    arabic: 'الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ، وَفِي كُلٍّ خَيْرٌ',
    translation:
        'The strong believer is better and more beloved to Allah than the weak believer, though there is good in both.',
    reference: 'Sahih Muslim 2664',
  ),
  DailyReminder(
    isHadith: false,
    arabic: 'وَبَشِّرِ الصَّابِرِينَ',
    translation: 'And give good tidings to the patient.',
    reference: 'Quran 2:155',
  ),
];

DailyReminder reminderForDay(DateTime date) {
  final dayOfYear = int.parse(
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
  );
  final index = dayOfYear % dailyReminders.length;
  return dailyReminders[index];
}
