/// Content for the "Share a Reminder" studio: for each feeling, the Quran
/// ayat and authentic Hadith that speak to it.
///
/// Quran entries hold only a reference - the Arabic and translation come from
/// the bundled `quran` package at runtime, so no ayah text is hand-typed.
/// Hadith entries hold the Prophet's words (matn) taken from the
/// hadithapi.com text of that same reference, with the chain of narrators
/// removed and the English lightly edited for grammar only; "…" marks where
/// a longer narration was shortened to its key sentence. Sahih Muslim
/// references use the standard (Abdul Baqi) numbering, which differs from
/// the API's own numbering.
library;

class QuranRef {
  final int surah;
  final int fromAyah;
  final int toAyah;

  const QuranRef(this.surah, this.fromAyah, [int? toAyah]) : toAyah = toAyah ?? fromAyah;
}

class MoodHadith {
  final String arabic;
  final String english;
  final String urdu;
  final String reference;

  const MoodHadith({
    required this.arabic,
    required this.english,
    required this.urdu,
    required this.reference,
  });
}

class Mood {
  final String id;
  final String emoji;

  /// Label per app language code; falls back to English.
  final Map<String, String> label;
  final List<QuranRef> ayat;
  final List<MoodHadith> hadith;

  const Mood({
    required this.id,
    required this.emoji,
    required this.label,
    required this.ayat,
    required this.hadith,
  });

  String labelFor(String code) => label[code] ?? label['en']!;
}

// ---------------------------------------------------------------------------
// Hadith
// ---------------------------------------------------------------------------

const _bukhari5641 = MoodHadith(
  arabic: 'مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلاَ وَصَبٍ وَلاَ هَمٍّ وَلاَ حُزْنٍ وَلاَ أَذًى وَلاَ غَمٍّ حَتَّى الشَّوْكَةِ يُشَاكُهَا، إِلاَّ كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ',
  english: 'No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that.',
  urdu: 'مسلمان جب بھی کسی پریشانی، بیماری، رنج و ملال، تکلیف اور غم میں مبتلا ہو جاتا ہے یہاں تک کہ اگر اسے کوئی کانٹا بھی چبھ جائے تو اللہ تعالیٰ اسے اس کے گناہوں کا کفارہ بنا دیتا ہے۔',
  reference: 'Sahih al-Bukhari 5641',
);

const _bukhari5645 = MoodHadith(
  arabic: 'مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُصِبْ مِنْهُ',
  english: 'If Allah wants to do good to somebody, He afflicts him with trials.',
  urdu: 'اللہ تعالیٰ جس کے ساتھ خیر و بھلائی کرنا چاہتا ہے اسے بیماری کی تکالیف اور دیگر مصیبتوں میں مبتلا کر دیتا ہے۔',
  reference: 'Sahih al-Bukhari 5645',
);

const _bukhari6369 = MoodHadith(
  arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ',
  english: 'O Allah! I seek refuge with You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from being heavily in debt and from being overpowered by (other) men.',
  urdu: 'اے اللہ! میں تیری پناہ مانگتا ہوں غم و الم سے، عاجزی سے، سستی سے، بزدلی سے، بخل سے، قرض چڑھ جانے اور لوگوں کے غلبہ سے۔',
  reference: 'Sahih al-Bukhari 6369',
);

const _bukhari6114 = MoodHadith(
  arabic: 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الْغَضَبِ',
  english: 'The strong is not the one who overcomes the people by his strength, but the strong is the one who controls himself while in anger.',
  urdu: 'پہلوان وہ نہیں ہے جو کشتی لڑنے میں غالب ہو جائے بلکہ اصلی پہلوان تو وہ ہے جو غصہ کی حالت میں اپنے آپ پر قابو پائے۔',
  reference: 'Sahih al-Bukhari 6114',
);

const _bukhari6116 = MoodHadith(
  arabic: 'أَوْصِنِي. قَالَ: «لاَ تَغْضَبْ». فَرَدَّدَ مِرَارًا، قَالَ: «لاَ تَغْضَبْ»',
  english: 'A man said to the Prophet (ﷺ), "Advise me!" The Prophet (ﷺ) said, "Do not become angry." The man asked (the same) again and again, and the Prophet (ﷺ) said in each case, "Do not become angry."',
  urdu: 'ایک شخص نے نبی کریم ﷺ سے عرض کیا کہ مجھے کوئی نصیحت فرما دیجئے۔ آپ ﷺ نے فرمایا کہ غصہ نہ ہوا کر۔ انہوں نے کئی مرتبہ یہ سوال کیا اور آپ ﷺ نے فرمایا کہ غصہ نہ ہوا کر۔',
  reference: 'Sahih al-Bukhari 6116',
);

const _abuDawood4782 = MoodHadith(
  arabic: 'إِذَا غَضِبَ أَحَدُكُمْ وَهُوَ قَائِمٌ فَلْيَجْلِسْ، فَإِنْ ذَهَبَ عَنْهُ الْغَضَبُ وَإِلَّا فَلْيَضْطَجِعْ',
  english: 'When one of you becomes angry while standing, he should sit down. If the anger leaves him, well and good; otherwise he should lie down.',
  urdu: 'جب تم میں سے کسی کو غصہ آئے اور وہ کھڑا ہو تو چاہیئے کہ بیٹھ جائے، اب اگر اس کا غصہ رفع ہو جائے (تو بہتر ہے) ورنہ پھر لیٹ جائے۔',
  reference: 'Sunan Abi Dawud 4782',
);

const _bukhari5678 = MoodHadith(
  arabic: 'مَا أَنْزَلَ اللَّهُ دَاءً إِلاَّ أَنْزَلَ لَهُ شِفَاءً',
  english: 'There is no disease that Allah has created, except that He also has created its treatment.',
  urdu: 'اللہ تعالیٰ نے کوئی ایسی بیماری نہیں اتاری جس کی دوا بھی نازل نہ کی ہو۔',
  reference: 'Sahih al-Bukhari 5678',
);

const _bukhari5660 = MoodHadith(
  arabic: 'مَا مِنْ مُسْلِمٍ يُصِيبُهُ أَذًى مَرَضٌ فَمَا سِوَاهُ إِلاَّ حَطَّ اللَّهُ لَهُ سَيِّئَاتِهِ كَمَا تَحُطُّ الشَّجَرَةُ وَرَقَهَا',
  english: 'No Muslim is afflicted with harm because of sickness or some other inconvenience, but that Allah will remove his sins for him as a tree sheds its leaves.',
  urdu: 'کسی بھی مسلمان کو مرض کی تکلیف یا کوئی اور تکلیف ہوتی ہے تو اللہ تعالیٰ اس کے گناہوں کو اس طرح گراتا ہے جیسے درخت اپنے پتوں کو گرا دیتا ہے۔',
  reference: 'Sahih al-Bukhari 5660',
);

const _bukhari1283 = MoodHadith(
  arabic: 'إِنَّمَا الصَّبْرُ عِنْدَ الصَّدْمَةِ الأُولَى',
  english: 'Verily, patience is at the first stroke of a calamity.',
  urdu: 'صبر تو جب صدمہ شروع ہو اس وقت کرنا چاہیے۔',
  reference: 'Sahih al-Bukhari 1283',
);

const _bukhari1303 = MoodHadith(
  arabic: 'إِنَّ الْعَيْنَ تَدْمَعُ، وَالْقَلْبَ يَحْزَنُ، وَلاَ نَقُولُ إِلاَّ مَا يَرْضَى رَبُّنَا',
  english: 'The eyes are shedding tears and the heart is grieved, and we will not say except what pleases our Lord.',
  urdu: 'آنکھوں سے آنسو جاری ہیں اور دل غم سے نڈھال ہے پر زبان سے ہم کہیں گے وہی جو ہمارے پروردگار کو پسند ہے۔',
  reference: 'Sahih al-Bukhari 1303',
);

const _muslim918 = MoodHadith(
  arabic: 'مَا مِنْ مُسْلِمٍ تُصِيبُهُ مُصِيبَةٌ فَيَقُولُ مَا أَمَرَهُ اللَّهُ إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا إِلَّا أَخْلَفَ اللَّهُ لَهُ خَيْرًا مِنْهَا',
  english: 'If any Muslim who suffers some calamity says what Allah has commanded him - "We belong to Allah and to Him shall we return; O Allah, reward me for my affliction and give me something better than it in exchange for it" - Allah will give him something better than it in exchange.',
  urdu: 'کوئی مسلمان نہیں جسے مصیبت پہنچے اور وہ (وہی کچھ) کہے جس کا اللہ نے اسے حکم دیا ہے: ”یقیناً ہم اللہ کے ہیں اور اسی کی طرف لوٹنے والے ہیں، اے اللہ! مجھے میری مصیبت پر اجر دے اور مجھے اس سے بہتر بدل عطا فرما“ مگر اللہ تعالیٰ اسے اس کا بہتر بدل عطا فرما دیتا ہے۔',
  reference: 'Sahih Muslim 918',
);

const _muslim2999 = MoodHadith(
  arabic: 'عَجَبًا لِأَمْرِ الْمُؤْمِنِ إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ وَلَيْسَ ذَاكَ لِأَحَدٍ إِلَّا لِلْمُؤْمِنِ إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ',
  english: 'Strange are the ways of a believer, for there is good in every affair of his - and this is not the case with anyone except a believer. If he has an occasion to feel delight, he thanks (Allah), and there is good for him in it; and if he gets into trouble and endures it patiently, there is good for him in it.',
  urdu: 'مومن کا معاملہ عجیب ہے۔ اس کا ہر معاملہ اس کے لیے بھلائی کا ہے۔ اور یہ بات مومن کے سوا کسی اور کو میسر نہیں۔ اسے خوشی اور خوشحالی ملے تو شکر کرتا ہے، اور یہ اس کے لیے اچھا ہوتا ہے، اور اگر اسے کوئی نقصان پہنچے تو صبر کرتا ہے، یہ بھی اس کے لیے بھلائی ہوتی ہے۔',
  reference: 'Sahih Muslim 2999',
);

const _muslim2749 = MoodHadith(
  arabic: 'وَالَّذِي نَفْسِي بِيَدِهِ لَوْ لَمْ تُذْنِبُوا لَذَهَبَ اللَّهُ بِكُمْ وَلَجَاءَ بِقَوْمٍ يُذْنِبُونَ فَيَسْتَغْفِرُونَ اللَّهَ فَيَغْفِرُ لَهُمْ',
  english: 'By Him in Whose Hand is my life, if you were not to commit sin, Allah would sweep you out of existence and replace you with people who would commit sin and seek forgiveness from Allah, and He would pardon them.',
  urdu: 'اس ذات کی قسم جس کے ہاتھ میں میری جان ہے! اگر تم گناہ نہ کرو تو اللہ تعالیٰ تم کو (اس دنیا سے) لے جائے اور ایسی قوم کو لے آئے جو گناہ کریں اور اللہ تعالیٰ سے مغفرت مانگیں تو وہ ان کی مغفرت فرمائے۔',
  reference: 'Sahih Muslim 2749',
);

const _muslim2664 = MoodHadith(
  arabic: 'الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللَّهِ مِنْ الْمُؤْمِنِ الضَّعِيفِ وَفِي كُلٍّ خَيْرٌ احْرِصْ عَلَى مَا يَنْفَعُكَ وَاسْتَعِنْ بِاللَّهِ وَلَا تَعْجَزْ',
  english: 'A strong believer is better and more lovable to Allah than a weak believer, and there is good in everyone. Cherish that which benefits you, seek help from Allah, and do not lose heart…',
  urdu: 'طاقت ور مومن اللہ کے نزدیک کمزور مومن کی نسبت بہتر اور زیادہ محبوب ہے، جبکہ خیر دونوں میں موجود ہے۔ جس چیز سے تمہیں (حقیقی) نفع پہنچے اس میں حرص کرو اور اللہ سے مدد مانگو اور کمزور نہ پڑو…',
  reference: 'Sahih Muslim 2664',
);

const _muslim2564 = MoodHadith(
  arabic: 'إِنَّ اللهَ لَا يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ، وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ',
  english: 'Verily Allah does not look to your faces and your wealth, but He looks to your hearts and to your deeds.',
  urdu: 'اللہ تعالیٰ تمہاری صورتوں اور تمہارے اموال کی طرف نہیں دیکھتا، لیکن وہ تمہارے دلوں اور اعمال کی طرف دیکھتا ہے۔',
  reference: 'Sahih Muslim 2564',
);

const _tirmidhi2344 = MoodHadith(
  arabic: 'لَوْ أَنَّكُمْ كُنْتُمْ تَوَكَّلُونَ عَلَى اللَّهِ حَقَّ تَوَكُّلِهِ، لَرُزِقْتُمْ كَمَا تُرْزَقُ الطَّيْرُ تَغْدُو خِمَاصًا وَتَرُوحُ بِطَانًا',
  english: 'If you were to rely upon Allah with the required reliance, then He would provide for you just as a bird is provided for: it goes out in the morning empty, and returns full.',
  urdu: 'اگر تم لوگ اللہ پر توکل (بھروسہ) کرو جیسا کہ اس پر توکل کرنے کا حق ہے تو تمہیں اسی طرح رزق ملے گا جیسا کہ پرندوں کو ملتا ہے کہ صبح کو وہ بھوکے نکلتے ہیں اور شام کو آسودہ واپس آتے ہیں۔',
  reference: "Jami' at-Tirmidhi 2344",
);

const _tirmidhi2516 = MoodHadith(
  arabic: 'احْفَظْ اللَّهَ يَحْفَظْكَ احْفَظْ اللَّهَ تَجِدْهُ تُجَاهَكَ إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ',
  english: 'Be mindful of Allah and He will protect you. Be mindful of Allah and you will find Him before you. When you ask, ask Allah, and when you seek aid, seek Allah\'s aid…',
  urdu: 'تم اللہ کے احکام کی حفاظت کرو، وہ تمہاری حفاظت فرمائے گا، تم اللہ کے حقوق کا خیال رکھو اسے تم اپنے سامنے پاؤ گے، جب تم کوئی چیز مانگو تو صرف اللہ سے مانگو، جب تم مدد چاہو تو صرف اللہ سے مدد طلب کرو…',
  reference: "Jami' at-Tirmidhi 2516",
);

const _tirmidhi2499 = MoodHadith(
  arabic: 'كُلُّ ابْنِ آدَمَ خَطَّاءٌ وَخَيْرُ الْخَطَّائِينَ التَّوَّابُونَ',
  english: 'Every son of Adam sins, and the best of the sinners are those who repent.',
  urdu: 'سارے انسان خطاکار ہیں اور خطاکاروں میں سب سے بہتر وہ ہیں جو توبہ کرنے والے ہیں۔',
  reference: "Jami' at-Tirmidhi 2499",
);

const _tirmidhi3540 = MoodHadith(
  arabic: 'يَا ابْنَ آدَمَ إِنَّكَ مَا دَعَوْتَنِي وَرَجَوْتَنِي غَفَرْتُ لَكَ عَلَى مَا كَانَ فِيكَ وَلَا أُبَالِي، يَا ابْنَ آدَمَ لَوْ بَلَغَتْ ذُنُوبُكَ عَنَانَ السَّمَاءِ ثُمَّ اسْتَغْفَرْتَنِي غَفَرْتُ لَكَ وَلَا أُبَالِي',
  english: 'Allah said: "O son of Adam! As long as you call upon Me and hope in Me, I forgive you, despite whatever may have occurred from you, and I do not mind. O son of Adam! Were your sins to reach the clouds of the sky, then you sought forgiveness from Me, I would forgive you, and I would not mind…"',
  urdu: 'اللہ کہتا ہے: اے آدم کے بیٹے! جب تک تو مجھ سے دعائیں کرتا رہے گا اور مجھ سے اپنی امیدیں وابستہ رکھے گا میں تجھے بخشتا رہوں گا، چاہے تیرے گناہ کسی بھی درجے پر پہنچے ہوئے ہوں، مجھے کسی بات کی پرواہ نہیں، اے آدم کے بیٹے! اگر تیرے گناہ آسمان کو چھونے لگیں پھر تو مجھ سے مغفرت طلب کرے تو میں تجھے بخش دوں گا اور مجھے کسی بات کی پرواہ نہ ہو گی…',
  reference: "Jami' at-Tirmidhi 3540",
);

const _tirmidhi2398 = MoodHadith(
  arabic: 'فَمَا يَبْرَحُ الْبَلَاءُ بِالْعَبْدِ حَتَّى يَتْرُكَهُ يَمْشِي عَلَى الْأَرْضِ مَا عَلَيْهِ خَطِيئَةٌ',
  english: '…The servant shall continue to be tried until he is left walking upon the earth without any sins.',
  urdu: '…پھر مصیبت بندے کے ساتھ ہمیشہ رہتی ہے، یہاں تک کہ بندہ روئے زمین پر اس حال میں چلتا ہے کہ اس پر کوئی گناہ نہیں ہوتا۔',
  reference: "Jami' at-Tirmidhi 2398",
);

const _tirmidhi1954 = MoodHadith(
  arabic: 'مَنْ لَا يَشْكُرُ النَّاسَ لَا يَشْكُرُ اللَّهَ',
  english: 'Whoever is not grateful to the people, he is not grateful to Allah.',
  urdu: 'جو لوگوں کا شکریہ ادا نہ کرے وہ اللہ کا شکر ادا نہیں کرے گا۔',
  reference: "Jami' at-Tirmidhi 1954",
);

const _bukhari1469 = MoodHadith(
  arabic: 'وَمَنْ يَتَصَبَّرْ يُصَبِّرْهُ اللَّهُ، وَمَا أُعْطِيَ أَحَدٌ عَطَاءً خَيْرًا وَأَوْسَعَ مِنَ الصَّبْرِ',
  english: '…Whoever remains patient, Allah will make him patient. Nobody can be given a blessing better and greater than patience.',
  urdu: '…جو شخص اپنے اوپر زور ڈال کر بھی صبر کرتا ہے تو اللہ تعالیٰ بھی اسے صبر و استقلال دے دیتا ہے، اور کسی کو بھی صبر سے زیادہ بہتر اور اس سے زیادہ بے پایاں خیر نہیں ملی۔',
  reference: 'Sahih al-Bukhari 1469',
);

const _bukhari6446 = MoodHadith(
  arabic: 'لَيْسَ الْغِنَى عَنْ كَثْرَةِ الْعَرَضِ، وَلَكِنَّ الْغِنَى غِنَى النَّفْسِ',
  english: 'Riches does not mean having a great amount of property, but riches is self-contentment.',
  urdu: 'تونگری یہ نہیں ہے کہ سامان زیادہ ہو، بلکہ امیری یہ ہے کہ دل غنی ہو۔',
  reference: 'Sahih al-Bukhari 6446',
);

const _bukhari6469 = MoodHadith(
  arabic: 'إِنَّ اللَّهَ خَلَقَ الرَّحْمَةَ يَوْمَ خَلَقَهَا مِائَةَ رَحْمَةٍ، فَأَمْسَكَ عِنْدَهُ تِسْعًا وَتِسْعِينَ رَحْمَةً، وَأَرْسَلَ فِي خَلْقِهِ كُلِّهِمْ رَحْمَةً وَاحِدَةً',
  english: 'Verily Allah created Mercy. The day He created it, He made it into one hundred parts. He withheld with Him ninety-nine parts, and sent its one part to all His creatures…',
  urdu: 'اللہ تعالیٰ نے رحمت کو جس دن بنایا تو اس کے سو حصے کئے اور اپنے پاس ان میں سے ننانوے رکھے۔ اس کے بعد تمام مخلوق کے لئے صرف ایک حصہ رحمت کا بھیجا…',
  reference: 'Sahih al-Bukhari 6469',
);

const _bukhari7405 = MoodHadith(
  arabic: 'يَقُولُ اللَّهُ تَعَالَى أَنَا عِنْدَ ظَنِّ عَبْدِي بِي، وَأَنَا مَعَهُ إِذَا ذَكَرَنِي، فَإِنْ ذَكَرَنِي فِي نَفْسِهِ ذَكَرْتُهُ فِي نَفْسِي',
  english: 'Allah says: "I am just as My slave thinks I am, and I am with him if he remembers Me. If he remembers Me in himself, I too remember him in Myself…"',
  urdu: 'اللہ تعالیٰ فرماتا ہے کہ میں اپنے بندے کے گمان کے ساتھ ہوں اور جب وہ مجھے اپنے دل میں یاد کرتا ہے تو میں بھی اسے اپنے دل میں یاد کرتا ہوں…',
  reference: 'Sahih al-Bukhari 7405',
);

// ---------------------------------------------------------------------------
// Moods
// ---------------------------------------------------------------------------

const List<Mood> moods = [
  Mood(
    id: 'sad',
    emoji: '😔',
    label: {
      'en': 'Sad / Depressed',
      'ar': 'حزين',
      'ur': 'اداس / افسردہ',
      'hi': 'उदास',
      'zh': '难过',
      'fr': 'Triste',
      'tr': 'Üzgün',
      'de': 'Traurig',
    },
    ayat: [QuranRef(94, 5, 6), QuranRef(3, 139), QuranRef(93, 3), QuranRef(12, 86), QuranRef(13, 28)],
    hadith: [_bukhari5641, _muslim2999, _bukhari6369],
  ),
  Mood(
    id: 'anxious',
    emoji: '😟',
    label: {
      'en': 'Anxious / Worried',
      'ar': 'قلق',
      'ur': 'پریشان / فکرمند',
      'hi': 'चिंतित',
      'zh': '焦虑',
      'fr': 'Anxieux',
      'tr': 'Endişeli',
      'de': 'Ängstlich',
    },
    ayat: [QuranRef(13, 28), QuranRef(65, 3), QuranRef(9, 51), QuranRef(94, 5, 6), QuranRef(2, 153)],
    hadith: [_tirmidhi2344, _tirmidhi2516, _bukhari6369],
  ),
  Mood(
    id: 'lonely',
    emoji: '🥀',
    label: {
      'en': 'Lonely',
      'ar': 'وحيد',
      'ur': 'تنہا',
      'hi': 'अकेला',
      'zh': '孤独',
      'fr': 'Seul',
      'tr': 'Yalnız',
      'de': 'Einsam',
    },
    ayat: [QuranRef(2, 186), QuranRef(50, 16), QuranRef(20, 46), QuranRef(2, 152)],
    hadith: [_bukhari7405, _tirmidhi2516],
  ),
  Mood(
    id: 'angry',
    emoji: '😠',
    label: {
      'en': 'Angry',
      'ar': 'غاضب',
      'ur': 'غصے میں',
      'hi': 'गुस्से में',
      'zh': '生气',
      'fr': 'En colère',
      'tr': 'Öfkeli',
      'de': 'Wütend',
    },
    ayat: [QuranRef(3, 134), QuranRef(41, 34), QuranRef(42, 37), QuranRef(7, 199)],
    hadith: [_bukhari6114, _bukhari6116, _abuDawood4782],
  ),
  Mood(
    id: 'guilty',
    emoji: '🤲',
    label: {
      'en': 'Guilty / Seeking Forgiveness',
      'ar': 'نادم / أطلب المغفرة',
      'ur': 'شرمندہ / معافی کا طلبگار',
      'hi': 'पछतावा / माफ़ी चाहिए',
      'zh': '内疚 / 求饶恕',
      'fr': 'Coupable / En quête de pardon',
      'tr': 'Pişman / Af dileyen',
      'de': 'Schuldig / Suche Vergebung',
    },
    ayat: [QuranRef(39, 53), QuranRef(4, 110), QuranRef(25, 70), QuranRef(15, 49)],
    hadith: [_muslim2749, _tirmidhi2499, _tirmidhi3540],
  ),
  Mood(
    id: 'hopeless',
    emoji: '🌧️',
    label: {
      'en': 'Hopeless',
      'ar': 'يائس',
      'ur': 'مایوس',
      'hi': 'निराश',
      'zh': '绝望',
      'fr': 'Désespéré',
      'tr': 'Umutsuz',
      'de': 'Hoffnungslos',
    },
    ayat: [QuranRef(39, 53), QuranRef(12, 87), QuranRef(15, 56), QuranRef(94, 5, 6), QuranRef(65, 3)],
    hadith: [_bukhari6469, _bukhari7405, _muslim2664],
  ),
  Mood(
    id: 'sick',
    emoji: '🤒',
    label: {
      'en': 'Sick / In Pain',
      'ar': 'مريض',
      'ur': 'بیمار / تکلیف میں',
      'hi': 'बीमार',
      'zh': '生病',
      'fr': 'Malade',
      'tr': 'Hasta',
      'de': 'Krank',
    },
    ayat: [QuranRef(26, 80), QuranRef(17, 82), QuranRef(21, 83), QuranRef(2, 153)],
    hadith: [_bukhari5678, _bukhari5660, _bukhari5641],
  ),
  Mood(
    id: 'grieving',
    emoji: '🕊️',
    label: {
      'en': 'Grieving a Loss',
      'ar': 'في حداد',
      'ur': 'غمزدہ',
      'hi': 'शोक में',
      'zh': '悲痛',
      'fr': 'En deuil',
      'tr': 'Yaslı',
      'de': 'In Trauer',
    },
    ayat: [QuranRef(2, 155, 157), QuranRef(3, 185), QuranRef(94, 5, 6)],
    hadith: [_muslim918, _bukhari1283, _bukhari1303],
  ),
  Mood(
    id: 'tested',
    emoji: '⛰️',
    label: {
      'en': 'Being Tested / Need Patience',
      'ar': 'في ابتلاء / أحتاج الصبر',
      'ur': 'آزمائش میں / صبر چاہیے',
      'hi': 'परीक्षा में / सब्र चाहिए',
      'zh': '经受考验 / 需要忍耐',
      'fr': 'Éprouvé / Besoin de patience',
      'tr': 'İmtihanda / Sabır lazım',
      'de': 'Geprüft / Brauche Geduld',
    },
    ayat: [QuranRef(2, 153), QuranRef(29, 2), QuranRef(3, 200), QuranRef(39, 10), QuranRef(94, 5, 6)],
    hadith: [_bukhari5645, _tirmidhi2398, _bukhari1469, _muslim2999],
  ),
  Mood(
    id: 'confused',
    emoji: '🧭',
    label: {
      'en': 'Confused / Need Guidance',
      'ar': 'حائر / أحتاج الهداية',
      'ur': 'الجھن میں / رہنمائی چاہیے',
      'hi': 'उलझन में / रहनुमाई चाहिए',
      'zh': '迷茫 / 寻求指引',
      'fr': 'Confus / Besoin de guidance',
      'tr': 'Kararsız / Rehberlik lazım',
      'de': 'Verwirrt / Brauche Rechtleitung',
    },
    ayat: [QuranRef(1, 6), QuranRef(29, 69), QuranRef(3, 8), QuranRef(2, 186)],
    hadith: [_muslim2664, _tirmidhi2516],
  ),
  Mood(
    id: 'provision',
    emoji: '💼',
    label: {
      'en': 'Worried About Money / Rizq',
      'ar': 'قلق على الرزق',
      'ur': 'رزق کی فکر',
      'hi': 'रोज़ी की चिंता',
      'zh': '为生计担忧',
      'fr': 'Inquiet pour ma subsistance',
      'tr': 'Rızık endişesi',
      'de': 'Sorge um den Lebensunterhalt',
    },
    ayat: [QuranRef(65, 3), QuranRef(11, 6), QuranRef(51, 22), QuranRef(29, 60), QuranRef(14, 7)],
    hadith: [_tirmidhi2344, _bukhari6446],
  ),
  Mood(
    id: 'grateful',
    emoji: '😊',
    label: {
      'en': 'Happy / Grateful',
      'ar': 'سعيد / شاكر',
      'ur': 'خوش / شکرگزار',
      'hi': 'खुश / शुक्रगुज़ार',
      'zh': '开心 / 感恩',
      'fr': 'Heureux / Reconnaissant',
      'tr': 'Mutlu / Şükreden',
      'de': 'Glücklich / Dankbar',
    },
    ayat: [QuranRef(14, 7), QuranRef(2, 152), QuranRef(16, 18), QuranRef(55, 13), QuranRef(93, 11)],
    hadith: [_muslim2999, _tirmidhi1954, _bukhari6446, _muslim2564],
  ),
];
