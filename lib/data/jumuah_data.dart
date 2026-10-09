// CONTENT REVIEW REQUIRED: verify against source before release

// Sources behind the Friday (Jumu'ah) reminders. Only references are kept
// here - the notification text itself is a short localized paraphrase in
// lib/l10n/*.arb, never a quoted hadith.

/// Surah Al-Kahf, opened from the Friday notification and the Home card.
const int jumuahSurahNumber = 18;

/// Reading Surah Al-Kahf on Friday.
const String jumuahKahfReference = "al-Hakim, al-Mustadrak 2/399; al-Bayhaqi, as-Sunan al-Kubra 3/249";

/// Sending abundant salawat (Durood) upon the Prophet ﷺ on Friday.
const String jumuahDuroodReference = 'Sunan Abi Dawud 1047';

/// The hour on Friday in which duas are answered. Scholars differ on when it
/// is: one narration places it in the last hour after Asr (before Maghrib),
/// another between the imam sitting on the minbar and the end of the prayer.
/// The notification states the first and notes the difference of opinion.
const String jumuahAcceptedHourReference = 'Sahih al-Bukhari 935; Sunan Abi Dawud 1048; Sahih Muslim 853';
