// CONTENT REVIEW REQUIRED: verify against source before release

import 'package:allah_everywhere/share_cards/mood_data.dart';

// Sources for the Zakat calculator's "How Zakat works" section. Only
// references live here; the explanations are short localized paraphrases
// in lib/l10n/*.arb, and the Quran text comes from the `quran` package.

/// No zakat on less than five awaq (200 dirhams) of silver.
const String zakatSilverNisabReference = 'Sahih al-Bukhari 1447; Sahih Muslim 979';

/// 5 dirhams on 200 dirhams, half a dinar on 20 dinars (2.5%), once a year
/// has passed. Graded sahih by al-Albani; Zubair Ali Zai grades it weak.
const String zakatRateReference = 'Sunan Abi Dawud 1573';

/// The eight categories of people who may receive zakat.
const QuranRef zakatRecipientsVerse = QuranRef(9, 60);
