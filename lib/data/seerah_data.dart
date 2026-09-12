/// One chapter of the Prophet's biography (Seerah), shown as an
/// expandable section. Content is a concise but substantive narrative
/// drawn from the standard early biographical sources (principally Ibn
/// Ishaq's Sirah as preserved by Ibn Hisham) and the two Sahihs, not an
/// exhaustive scholarly work.
class SeerahChapter {
  final String period;
  final String title;
  final List<String> paragraphs;
  final String? reference;

  const SeerahChapter({
    required this.period,
    required this.title,
    required this.paragraphs,
    this.reference,
  });
}

const List<SeerahChapter> seerahChapters = [
  SeerahChapter(
    period: 'Before 570 CE',
    title: 'Arabia Before Islam',
    paragraphs: [
      'Pre-Islamic Arabia (the "Jahiliyyah", or Age of Ignorance) was a land of tribal society, built around clan loyalty and honor rather than settled government. Makkah sat at the crossroads of major trade routes and was home to the Kaaba, a cube-shaped shrine built - according to Islamic tradition - by Ibrahim (Abraham) and his son Ismail as a house of worship for the one God. By the 6th century CE it had come to hold some 360 idols, and pilgrims from across Arabia came to venerate them.',
      'The Quraysh, custodians of the Kaaba, held both religious and commercial prestige. Alongside this, the era was marked by tribal warfare, the practice of female infanticide, gross economic exploitation of the weak, and widespread idolatry - the very conditions the Quran would later describe prayer and revelation as correcting (Quran 29:45).',
    ],
  ),
  SeerahChapter(
    period: '570 CE',
    title: 'Birth and Early Childhood',
    paragraphs: [
      'Muhammad ibn Abdullah (peace be upon him) was born in Makkah in the "Year of the Elephant", named for the year an Abyssinian army with war elephants attempted to destroy the Kaaba and was repelled, an event referenced in Surah Al-Fil (Quran 105). His father, Abdullah, had died before his birth; his mother, Aminah, died when he was six, leaving him an orphan raised first by his grandfather Abdul Muttalib, and after his grandfather\'s death, by his uncle Abu Talib.',
      'Following Arabian custom, the infant Muhammad was sent to be nursed in the desert by Halimah al-Sa\'diyyah of the Banu Sa\'d tribe, where he spent his first years away from the crowding and illness of the city - a period Islamic tradition associates with the purification of his heart in preparation for prophethood.',
    ],
  ),
  SeerahChapter(
    period: '576-595 CE',
    title: 'Youth in Makkah',
    paragraphs: [
      'Raised in his uncle Abu Talib\'s household, the young Muhammad worked as a shepherd and later joined trading caravans to Syria, gaining a reputation across Makkah for honesty and reliability - so much so that he came to be known as "Al-Amin", the Trustworthy. He took no part in the idol worship, drinking, or moral corruption common among his contemporaries, and was known for settling disputes fairly; he was chosen, in his mid-thirties, to arbitrate a dangerous dispute among the Quraysh clans over who would place the Black Stone back in the rebuilt Kaaba - a role he resolved by having representatives of each clan jointly lift the stone on a cloth.',
    ],
  ),
  SeerahChapter(
    period: '595 CE',
    title: 'Marriage to Khadijah',
    paragraphs: [
      'At 25, Muhammad was employed by Khadijah bint Khuwaylid, a respected and successful Makkan businesswoman, to lead a trading caravan to Syria. Impressed by his honesty and the profit he brought her, Khadijah - then 40 - proposed marriage, and he accepted. Their marriage was one of deep partnership: Khadijah was the first person to believe in his prophethood, and he took no other wife during her lifetime. Together they had several children, including their daughter Fatimah, who would become central to later Islamic history.',
    ],
  ),
  SeerahChapter(
    period: '610 CE',
    title: 'The First Revelation',
    paragraphs: [
      'By his fortieth year, Muhammad had taken to retreating for contemplation in the Cave of Hira, on the mountain of Jabal al-Nur near Makkah. During one such retreat in the month of Ramadan, the angel Jibril (Gabriel) appeared to him and commanded, "Read" (Iqra). Muhammad replied that he could not read, and the angel embraced him tightly three times before revealing the first verses of the Quran: "Read in the name of your Lord who created - created man from a clinging substance. Read, and your Lord is the most Generous" (Quran 96:1-3).',
      'Shaken, he returned home to Khadijah, who wrapped him in a cloak and, after hearing his account, reassured him: "Allah would never disgrace you. You keep good relations with kin, help the weak, feed the poor, and assist those in distress." She took him to her cousin Waraqah ibn Nawfal, a Christian scholar, who recognized the encounter as the same revelation received by Musa (Moses), and told him he would be driven from his home for the message he would carry.',
    ],
    reference: 'Sahih al-Bukhari 3, Sahih Muslim 160',
  ),
  SeerahChapter(
    period: '613-619 CE',
    title: 'Early Preaching and Persecution',
    paragraphs: [
      'After a pause in revelation, Muhammad began preaching first privately to family and close friends - Khadijah, his cousin Ali, his freed servant Zayd ibn Harithah, and his close friend Abu Bakr were among the earliest to accept Islam. After three years, he was commanded to preach publicly (Quran 26:214), which brought open hostility from the Quraysh, who saw the message as a threat to their idols, trade, and social order.',
      'Persecution intensified: early Muslims from powerless families, such as Bilal ibn Rabah, were tortured; some Muslims emigrated to Abyssinia (modern Ethiopia) under a Christian king, Negus, who granted them protection after hearing verses of the Quran about Isa (Jesus) and Maryam (Mary). The Quraysh imposed a boycott on Muhammad\'s clan, Banu Hashim, cutting off trade and marriage ties for roughly three years until it collapsed under its own injustice.',
    ],
  ),
  SeerahChapter(
    period: '619-620 CE',
    title: 'The Year of Sorrow and the Night Journey',
    paragraphs: [
      'In the tenth year of prophethood, Muhammad lost both his wife Khadijah and his uncle and protector Abu Talib within a short span, a period known as "Aam al-Huzn", the Year of Sorrow. Without Abu Talib\'s protection, hostility from the Quraysh grew sharper, and an attempt to preach in the nearby city of Ta\'if ended in his being driven out and stoned by its inhabitants.',
      'Shortly after, Islamic tradition holds that Muhammad experienced Al-Isra wal-Mi\'raj, the Night Journey: a miraculous journey from Makkah to Jerusalem, and from there an ascension through the heavens, during which the five daily prayers were established as an obligation upon Muslims (Quran 17:1).',
    ],
  ),
  SeerahChapter(
    period: '620-622 CE',
    title: 'The Pledges of Aqabah and the Hijrah',
    paragraphs: [
      'During the annual pilgrimage season, Muhammad met pilgrims from Yathrib (later renamed Madinah), a city troubled by long-running tribal conflict between the Aws and Khazraj. Over two secret meetings at Aqabah, groups of Yathrib\'s residents accepted Islam and invited Muhammad to their city as an arbitrator and leader, pledging to protect him as they would their own families.',
      'As Quraysh hostility reached the point of an assassination plot, Muhammad instructed his followers to migrate to Madinah in small groups, while he and Abu Bakr departed last, hiding for three days in the Cave of Thawr before making the journey themselves. This migration - the Hijrah, in 622 CE - marks the beginning of the Islamic (Hijri) calendar, and transformed the Muslim community from a persecuted minority into the foundation of a new society.',
    ],
  ),
  SeerahChapter(
    period: '622-624 CE',
    title: 'Building the Community in Madinah',
    paragraphs: [
      'In Madinah, Muhammad established a mosque that also served as a center of community life, formally paired the Meccan emigrants (Muhajirun) with Madinan hosts (Ansar) in bonds of mutual support, and drafted the Constitution of Madinah - an agreement between the Muslims and the city\'s Jewish tribes establishing mutual defense, religious freedom, and legal cooperation, regarded by historians as one of the earliest written constitutions.',
    ],
  ),
  SeerahChapter(
    period: '624 CE',
    title: 'The Battle of Badr',
    paragraphs: [
      'Conflict with Makkah continued as the Quraysh sought to crush the new Muslim community. At Badr in 624 CE, a small, poorly-equipped Muslim force of about 313 met a Meccan army roughly three times its size and won a decisive victory, an outcome the Quran describes as coming with divine aid (Quran 3:123, 8:9). The battle proved the new community\'s resilience and significantly boosted its standing across Arabia.',
    ],
  ),
  SeerahChapter(
    period: '625-627 CE',
    title: 'Uhud and the Battle of the Trench',
    paragraphs: [
      'The Quraysh returned the following year at Uhud, where a tactical error by a group of Muslim archers who left their post turned an early advantage into a costly setback, though the Muslim force was not destroyed; the Prophet himself was wounded. In 627 CE, a coalition of Meccan and allied tribes besieged Madinah itself; on the advice of the Persian companion Salman al-Farisi, the Muslims dug a defensive trench around the city\'s exposed side - an unfamiliar tactic in Arabia - which stalled the siege until the coalition, worn down by weather and disunity, withdrew without a decisive battle.',
    ],
  ),
  SeerahChapter(
    period: '628 CE',
    title: 'The Treaty of Hudaybiyyah',
    paragraphs: [
      'In 628 CE, Muhammad set out with 1,400 companions to perform pilgrimage, unarmed, but was stopped by the Quraysh outside Makkah at Hudaybiyyah. Rather than fight, he negotiated a ten-year truce - on terms that initially appeared unfavorable to the Muslims, including postponing that year\'s pilgrimage. The Quran later described the treaty as "a clear victory" (Quran 48:1): the truce ended years of open warfare and, by allowing free movement and contact, led to more conversions to Islam over the following two years than in the entire previous period of the message.',
    ],
  ),
  SeerahChapter(
    period: '630 CE',
    title: 'The Conquest of Makkah',
    paragraphs: [
      'When the Quraysh\'s allies broke the Hudaybiyyah truce, Muhammad marched on Makkah with some 10,000 men in 630 CE. The city surrendered with almost no bloodshed. Muhammad entered in humility, declared a general amnesty even for those who had persecuted the Muslims for two decades, and personally destroyed the idols surrounding the Kaaba while reciting, "Truth has come, and falsehood has departed; indeed, falsehood is bound to depart" (Quran 17:81). Within two years, most of Arabia had embraced Islam.',
    ],
  ),
  SeerahChapter(
    period: '632 CE',
    title: 'The Farewell Pilgrimage',
    paragraphs: [
      'In the final year of his life, Muhammad led some 100,000 to 120,000 Muslims on what became known as the Farewell Pilgrimage (Hajjat al-Wada). At Arafah, he delivered his Farewell Sermon, articulating principles that remain foundational to Islamic ethics: the sanctity of life and property, the abolition of pre-Islamic blood feuds and usury, the rights of women, the equality of all people regardless of race or tribe ("no Arab has superiority over a non-Arab, nor a white over a black, except by piety"), and the instruction to hold fast to the Quran. It was during this pilgrimage that the verse "This day I have perfected for you your religion" (Quran 5:3) was revealed.',
    ],
  ),
  SeerahChapter(
    period: '632 CE',
    title: 'Passing in Madinah',
    paragraphs: [
      'Muhammad fell ill shortly after returning to Madinah and passed away on 12 Rabi\' al-Awwal, 11 AH (8 June 632 CE), in the apartment of his wife Aisha, with his head resting in her lap. He was buried where he died, in what is now part of Al-Masjid an-Nabawi, the Prophet\'s Mosque in Madinah. He left behind the Quran and his Sunnah (example) as guidance, and the small community he had led grew, within a century, across three continents - a legacy Muslims regard not as the achievement of one man, but as a mercy to all creation (Quran 21:107).',
    ],
  ),
];
