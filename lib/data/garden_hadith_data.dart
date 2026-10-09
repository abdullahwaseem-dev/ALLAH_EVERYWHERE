// CONTENT REVIEW REQUIRED: verify against source before release
//
// The hadith behind the Jannah Garden's palm trees. Checked on 2026-10-09
// against en.tohed.com/hadith/tirmidhi/3464 and hadeethenc.com (no. 4201).
// sunnah.com (tirmidhi:3464) lists it as Book 48, Hadith 95, with
// at-Tirmidhi's own verdict "hasan sahih gharib".
// Note: the wording includes "al-'Azim" ("SubhanAllahil-'Azim wa
// bihamdihi"), not only "SubhanAllahi wa bihamdihi".

class GardenHadith {
  final String arabic;
  final String english;
  final String reference;
  final String grading;

  const GardenHadith({required this.arabic, required this.english, required this.reference, required this.grading});
}

const gardenHadith = GardenHadith(
  arabic: 'مَنْ قَالَ: سُبْحَانَ اللَّهِ الْعَظِيمِ وَبِحَمْدِهِ، غُرِسَتْ لَهُ نَخْلَةٌ فِي الْجَنَّةِ',
  english: "Whoever says: 'Glory is to Allah, the Magnificent, and with His Praise "
      "(Subḥān Allāhil-ʿAẓīm wa biḥamdih)', a date-palm tree is planted for him in Paradise.",
  reference: "Jami' at-Tirmidhi 3464 (narrated by Jabir)",
  grading: 'At-Tirmidhi: hasan sahih gharib; al-Albani: sahih (as-Silsilah as-Sahihah 64)',
);
