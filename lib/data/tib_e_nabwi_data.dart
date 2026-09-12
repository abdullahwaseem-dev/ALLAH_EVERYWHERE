class TibRemedy {
  final String title;
  final String description;
  final String reference;

  const TibRemedy({required this.title, required this.description, required this.reference});
}

class TibCategory {
  final String title;
  final String intro;
  final List<TibRemedy> items;

  const TibCategory({required this.title, required this.intro, required this.items});
}

const List<TibCategory> tibENabwiCategories = [
  TibCategory(
    title: 'General Principles of Prophetic Medicine',
    intro:
        'The Prophet (ﷺ) taught that seeking treatment does not contradict trust (tawakkul) in Allah - every illness Allah creates, He also creates a cure for, except old age and death itself.',
    items: [
      TibRemedy(
        title: 'Seek treatment',
        description:
            'The Prophet (ﷺ) said: "Make use of medical treatment, for Allah has not made a disease without appointing a remedy for it, with the exception of one disease, namely old age."',
        reference: 'Sunan Abu Dawood 3855',
      ),
      TibRemedy(
        title: 'A cure for every disease',
        description:
            'The Prophet (ﷺ) said: "There is no disease that Allah has created, except that He also has created its treatment."',
        reference: 'Sahih al-Bukhari 5678',
      ),
      TibRemedy(
        title: 'Treatment and reliance on Allah together',
        description:
            'A group of Bedouins asked the Prophet (ﷺ) whether they should seek medical treatment. He said: "Yes, O servants of Allah, seek treatment, for Allah has not created a disease without creating a cure for it, except for one disease - old age."',
        reference: "Jami' at-Tirmidhi 2038",
      ),
    ],
  ),
  TibCategory(
    title: 'Foods & Drinks',
    intro:
        'Several foods are singled out in the Quran and authentic Hadith for their benefit - these are traditional remedies, not a substitute for medical treatment.',
    items: [
      TibRemedy(
        title: 'Honey',
        description:
            'The Quran describes honey as containing healing for people. The Prophet (ﷺ) advised a man whose brother had a stomach ailment to give him honey to drink.',
        reference: 'Quran 16:69, Sahih al-Bukhari 5684',
      ),
      TibRemedy(
        title: 'Black Seed (Habbat al-Sawda / Kalonji)',
        description: 'The Prophet (ﷺ) said black seed is a cure for every disease except death.',
        reference: 'Sahih al-Bukhari 5688, Sahih Muslim 2215',
      ),
      TibRemedy(
        title: 'Dates, especially Ajwa',
        description:
            'The Prophet (ﷺ) said whoever eats seven Ajwa dates every morning will not be harmed that day by poison or magic.',
        reference: 'Sahih al-Bukhari 5445, Sahih Muslim 2047',
      ),
      TibRemedy(
        title: 'Talbina',
        description:
            'A barley-based dish the Prophet (ﷺ) said soothes the heart of the sick and eases grief; he encouraged serving it to a bereaved family.',
        reference: 'Sahih al-Bukhari 5417, Sahih Muslim 2216',
      ),
      TibRemedy(
        title: 'Zamzam Water',
        description: 'The Prophet (ﷺ) said Zamzam water serves the purpose for which it is drunk.',
        reference: 'Sunan Ibn Majah 3062',
      ),
      TibRemedy(
        title: 'Olive Oil',
        description:
            'The Prophet (ﷺ) recommended eating and applying olive oil, describing it as coming from a blessed tree.',
        reference: "Jami' at-Tirmidhi 1851",
      ),
      TibRemedy(
        title: 'Milk',
        description:
            'The Prophet (ﷺ) taught a dua for barakah after drinking milk: "O Allah, bless us in it, and give us more of it."',
        reference: "Jami' at-Tirmidhi 3455, Sunan Abu Dawood 3730",
      ),
      TibRemedy(
        title: 'Vinegar',
        description: 'The Prophet (ﷺ) said: "What an excellent condiment vinegar is."',
        reference: 'Sahih Muslim 2051',
      ),
    ],
  ),
  TibCategory(
    title: 'Cupping (Hijama) & Physical Therapies',
    intro: 'Cupping is one of the most frequently mentioned physical therapies in the Hadith.',
    items: [
      TibRemedy(
        title: 'Cupping as a leading remedy',
        description: 'The Prophet (ﷺ) said: "Indeed the best of remedies you have is cupping (hijama)."',
        reference: 'Sahih al-Bukhari 5696, Sahih Muslim 2205',
      ),
      TibRemedy(
        title: 'The Prophet (ﷺ) was cupped himself',
        description:
            'It is reported that the Prophet (ﷺ) had himself cupped on the back of the neck and between the shoulders, and he paid the person who performed it.',
        reference: 'Sahih al-Bukhari 2277, 5691',
      ),
    ],
  ),
  TibCategory(
    title: 'Preventive Medicine & Hygiene',
    intro: 'A number of teachings focus on preventing illness before it starts.',
    items: [
      TibRemedy(
        title: 'Miswak (tooth-stick)',
        description:
            'The Prophet (ﷺ) said: "Were it not that I might overburden my nation, I would have ordered them to use the miswak (tooth-stick) at every prayer."',
        reference: 'Sahih al-Bukhari 887, Sahih Muslim 252',
      ),
      TibRemedy(
        title: 'Cleanliness',
        description: 'The Prophet (ﷺ) said: "Cleanliness is half of faith."',
        reference: 'Sahih Muslim 223',
      ),
      TibRemedy(
        title: 'Moderation in eating',
        description:
            'The Prophet (ﷺ) said the son of Adam fills no vessel worse than his stomach; a few mouthfuls to keep his back straight suffice him - and if he must eat more, a third for food, a third for drink, and a third for breath.',
        reference: "Jami' at-Tirmidhi 2380, Sunan Ibn Majah 3349",
      ),
      TibRemedy(
        title: 'Covering food and drink',
        description:
            'The Prophet (ﷺ) instructed covering vessels and closing waterskins, especially at night, saying there is a night in the year when a plague descends and does not pass an uncovered vessel without some of it falling into it.',
        reference: 'Sahih Muslim 2012, Sahih al-Bukhari 5624',
      ),
      TibRemedy(
        title: 'The principle of quarantine',
        description:
            'The Prophet (ﷺ) said: "If you hear of an outbreak of plague in a land, do not enter it; but if the plague breaks out in a place while you are in it, do not leave that place."',
        reference: 'Sahih al-Bukhari 5728, Sahih Muslim 2218',
      ),
    ],
  ),
  TibCategory(
    title: 'Ruqyah - Spiritual Healing',
    intro: 'Reciting the Quran and supplicating for the sick is itself part of Prophetic medicine.',
    items: [
      TibRemedy(
        title: 'Al-Fatiha as ruqyah',
        description:
            'A companion recited Surah Al-Fatiha over a man bitten by a scorpion and he was cured; when told, the Prophet (ﷺ) said: "And how did you come to know that it can be used as Ruqyah?"',
        reference: 'Sahih al-Bukhari 5749, Sahih Muslim 2201',
      ),
      TibRemedy(
        title: 'The Mu\'awwidhatayn before sleep',
        description:
            'During his final illness the Prophet (ﷺ) would recite Surah Al-Falaq and An-Nas along with Al-Ikhlas, blow into his hands, and wipe them over his body.',
        reference: 'Sahih al-Bukhari 5017, 5748',
      ),
      TibRemedy(
        title: 'Dua for the sick',
        description:
            'The Prophet (ﷺ) would say over the sick: "Adhhibil-ba\'s Rabban-nas, washfi Antash-Shafi, la shifa\'a illa shifa\'uka, shifa\'an la yughadiru saqama" - "Remove the harm, Lord of mankind, and heal - You are the Healer, there is no healing except Your healing, a healing that leaves no illness behind."',
        reference: 'Sahih al-Bukhari 5675, Sahih Muslim 2191',
      ),
    ],
  ),
  TibCategory(
    title: 'Sleep & Daily Rhythm',
    intro: 'A few simple sleep habits are recommended in the Sunnah.',
    items: [
      TibRemedy(
        title: 'Sleeping on the right side',
        description:
            'The Prophet (ﷺ) used to lie down on his right side when going to sleep, and taught this as part of the bedtime routine.',
        reference: 'Sahih al-Bukhari 247, Sahih Muslim 2710',
      ),
      TibRemedy(
        title: 'Avoid sleeping on the stomach',
        description:
            'The Prophet (ﷺ) saw a man lying on his stomach and said Allah dislikes this posture of lying down.',
        reference: 'Sunan Abu Dawood 5040, Sunan Ibn Majah 3723',
      ),
    ],
  ),
  TibCategory(
    title: 'Illness, Patience & Reward',
    intro: 'The Hadith frame illness itself as something that can bring spiritual benefit when met with patience.',
    items: [
      TibRemedy(
        title: 'Illness expiates sins',
        description:
            'The Prophet (ﷺ) said: "No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that."',
        reference: 'Sahih al-Bukhari 5641, Sahih Muslim 2573',
      ),
      TibRemedy(
        title: 'Visiting the sick',
        description:
            'The Prophet (ﷺ) encouraged visiting the sick as a right owed to fellow Muslims and a source of reward for the one who visits.',
        reference: 'Sahih Muslim 2568',
      ),
    ],
  ),
];
