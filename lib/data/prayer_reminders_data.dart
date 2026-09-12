/// A single reminder shown in the in-app dialog when a prayer time is
/// reached - either an ayah or a hadith about the importance of Salah.
class PrayerReminder {
  final String arabic;
  final String translation;
  final String reference;

  const PrayerReminder({required this.arabic, required this.translation, required this.reference});
}

/// Curated, authentic reminders about the importance of prayer - rotated
/// through each time a prayer time is reached, so it's not the same message
/// every single time.
const List<PrayerReminder> prayerReminders = [
  PrayerReminder(
    arabic: 'إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ',
    translation:
        'Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater.',
    reference: "Quran 29:45",
  ),
  PrayerReminder(
    arabic: 'حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ',
    translation: 'Maintain with care the [obligatory] prayers, and [in particular] the middle prayer.',
    reference: "Quran 2:238",
  ),
  PrayerReminder(
    arabic: 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
    translation: 'Indeed, prayer has been decreed upon the believers a decree of specified times.',
    reference: "Quran 4:103",
  ),
  PrayerReminder(
    arabic: 'إِنَّنِي أَنَا اللَّهُ لَا إِلَٰهَ إِلَّا أَنَا فَاعْبُدْنِي وَأَقِمِ الصَّلَاةَ لِذِكْرِي',
    translation:
        'Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance.',
    reference: "Quran 20:14",
  ),
  PrayerReminder(
    arabic:
        'أَوَّلُ مَا يُحَاسَبُ بِهِ الْعَبْدُ يَوْمَ الْقِيَامَةِ مِنْ عَمَلِهِ صَلَاتُهُ، فَإِنْ صَلَحَتْ فَقَدْ أَفْلَحَ وَأَنْجَحَ، وَإِنْ فَسَدَتْ فَقَدْ خَابَ وَخَسِرَ',
    translation:
        'The first matter that the slave will be brought to account for on the Day of Judgment is the prayer. If it is sound, the rest of his deeds will be sound; if it is corrupt, the rest of his deeds will be corrupt.',
    reference: "Sunan at-Tirmidhi 413 (hasan)",
  ),
  PrayerReminder(
    arabic: 'بَيْنَ الرَّجُلِ وَبَيْنَ الشِّرْكِ وَالْكُفْرِ تَرْكُ الصَّلَاةِ',
    translation: 'Between a man and disbelief and paganism is the abandonment of prayer.',
    reference: "Sahih Muslim 82",
  ),
  PrayerReminder(
    arabic: 'الْعَهْدُ الَّذِي بَيْنَنَا وَبَيْنَهُمُ الصَّلَاةُ، فَمَنْ تَرَكَهَا فَقَدْ كَفَرَ',
    translation:
        'The covenant that distinguishes between us and them is prayer; whoever abandons it has committed disbelief.',
    reference: "Sunan at-Tirmidhi 2621",
  ),
  PrayerReminder(
    arabic: 'مَنْ صَلَّى الْبَرْدَيْنِ دَخَلَ الْجَنَّةَ',
    translation: 'Whoever prays the two cool prayers (Fajr and Asr) will enter Paradise.',
    reference: "Sahih al-Bukhari 574",
  ),
  PrayerReminder(
    arabic:
        'أَرَأَيْتُمْ لَوْ أَنَّ نَهَرًا بِبَابِ أَحَدِكُمْ يَغْتَسِلُ فِيهِ كُلَّ يَوْمٍ خَمْسَ مَرَّاتٍ، هَلْ يَبْقَى مِنْ دَرَنِهِ شَيْءٌ؟ ... فَذَلِكَ مَثَلُ الصَّلَوَاتِ الْخَمْسِ',
    translation:
        "If there were a river at the door of one of you in which he bathed five times a day, would any dirt remain on him? That is the example of the five daily prayers - Allah erases sins through them.",
    reference: "Sahih al-Bukhari 528, Sahih Muslim 667",
  ),
  PrayerReminder(
    arabic: 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
    translation: 'And seek help through patience and prayer.',
    reference: "Quran 2:45",
  ),
];
