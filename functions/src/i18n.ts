// Notification texts in the app's 8 languages. The wording matches the
// in-app feed (lib/l10n/app_*.arb, "challengesFeed*" keys). Each receiver
// gets the language stored on their users/{uid} doc (`language`).

export type Lang = 'en' | 'ar' | 'ur' | 'fr' | 'de' | 'hi' | 'tr' | 'zh';

export const languages: Lang[] = ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh'];

export interface Strings {
  joined: string;
  juz: string;
  pages: string;
  ayahs: string;
  amount: string;
  progressed: string;
  completed: string;
  message: string;
  nudge: string;
  behind: string;
  lastDay: string;
  duaOne: string;
  duaMany: string;
  duaAll: string;
  units: Record<string, string>;
}

const strings: Record<Lang, Strings> = {
  en: {
    joined: '{name} joined',
    juz: '{name} finished Juz {items}',
    pages: '{name} read pages {items}',
    ayahs: '{name} memorized ayahs {items}',
    amount: '{name}: +{amount} {unit}',
    progressed: '{name} made progress',
    completed: '{name} completed the challenge! MashaAllah',
    message: '{name}: {text}',
    nudge: '{name} reminded you to log today',
    behind: "You're {n} {unit} behind. You can still make it!",
    lastDay: '1 day left. Finish strong, in sha Allah!',
    duaOne: '{name} made a dua for you',
    duaMany: 'Your family made {n} duas for you',
    duaAll: '{name} made a dua for everyone',
    units: { juz: 'Juz', pages: 'pages', ayahs: 'ayahs', ahadith: 'ahadith', count: 'times', days: 'days' },
  },
  ar: {
    joined: 'انضم {name}',
    juz: 'أتمّ {name} الجزء {items}',
    pages: 'قرأ {name} الصفحات {items}',
    ayahs: 'حفظ {name} الآيات {items}',
    amount: '{name}: +{amount} {unit}',
    progressed: 'تقدّم {name}',
    completed: 'أتمّ {name} التحدي! ما شاء الله',
    message: '{name}: {text}',
    nudge: 'ذكّرك {name} بتسجيل تقدمك اليوم',
    behind: 'أنت متأخر بمقدار {n} {unit}. ما زال بإمكانك اللحاق!',
    lastDay: 'بقي يوم واحد. أتمّه بقوة إن شاء الله!',
    duaOne: 'دعا لك {name}',
    duaMany: 'دعا لك أهلك {n} دعوات',
    duaAll: 'دعا {name} للجميع',
    units: { juz: 'جزء', pages: 'صفحات', ayahs: 'آيات', ahadith: 'أحاديث', count: 'مرات', days: 'أيام' },
  },
  ur: {
    joined: '{name} شامل ہوئے',
    juz: '{name} نے پارہ {items} مکمل کیا',
    pages: '{name} نے صفحات {items} پڑھے',
    ayahs: '{name} نے آیات {items} یاد کیں',
    amount: '{name}: +{amount} {unit}',
    progressed: '{name} نے پیش رفت کی',
    completed: '{name} نے چیلنج مکمل کر لیا! ماشاءاللہ',
    message: '{name}: {text}',
    nudge: '{name} نے آپ کو آج درج کرنے کی یاد دلائی',
    behind: 'آپ {n} {unit} پیچھے ہیں۔ آپ اب بھی کر سکتے ہیں!',
    lastDay: 'ایک دن باقی ہے۔ ان شاءاللہ مکمل کریں!',
    duaOne: '{name} نے آپ کے لیے دعا کی',
    duaMany: 'آپ کے اپنوں نے آپ کے لیے {n} دعائیں کیں',
    duaAll: '{name} نے سب کے لیے دعا کی',
    units: { juz: 'پارے', pages: 'صفحات', ayahs: 'آیات', ahadith: 'احادیث', count: 'بار', days: 'دن' },
  },
  fr: {
    joined: '{name} a rejoint le défi',
    juz: '{name} a terminé le juz {items}',
    pages: '{name} a lu les pages {items}',
    ayahs: '{name} a mémorisé les versets {items}',
    amount: '{name} : +{amount} {unit}',
    progressed: '{name} a progressé',
    completed: '{name} a terminé le défi ! MashaAllah',
    message: '{name} : {text}',
    nudge: '{name} vous rappelle de noter votre progression aujourd’hui',
    behind: 'Vous avez {n} {unit} de retard. Vous pouvez encore y arriver !',
    lastDay: 'Plus qu’un jour. Terminez en beauté, in sha Allah !',
    duaOne: '{name} a fait une dou\'a pour vous',
    duaMany: 'Votre famille a fait {n} dou\'as pour vous',
    duaAll: '{name} a fait une dou\'a pour tout le monde',
    units: { juz: 'juz', pages: 'pages', ayahs: 'versets', ahadith: 'hadiths', count: 'fois', days: 'jours' },
  },
  de: {
    joined: '{name} ist beigetreten',
    juz: '{name} hat Juz {items} beendet',
    pages: '{name} hat die Seiten {items} gelesen',
    ayahs: '{name} hat die Verse {items} auswendig gelernt',
    amount: '{name}: +{amount} {unit}',
    progressed: '{name} ist vorangekommen',
    completed: '{name} hat die Challenge geschafft! MashaAllah',
    message: '{name}: {text}',
    nudge: '{name} erinnert dich, heute einzutragen',
    behind: 'Du liegst {n} {unit} zurück. Du schaffst es noch!',
    lastDay: 'Noch 1 Tag. Bring es zu Ende, in sha Allah!',
    duaOne: '{name} hat ein Bittgebet für dich gesprochen',
    duaMany: 'Deine Familie hat {n} Bittgebete für dich gesprochen',
    duaAll: '{name} hat ein Bittgebet für alle gesprochen',
    units: { juz: 'Juz', pages: 'Seiten', ayahs: 'Verse', ahadith: 'Hadithe', count: 'Mal', days: 'Tage' },
  },
  hi: {
    joined: '{name} शामिल हुए',
    juz: '{name} ने पारा {items} पूरा किया',
    pages: '{name} ने पृष्ठ {items} पढ़े',
    ayahs: '{name} ने आयतें {items} याद कीं',
    amount: '{name}: +{amount} {unit}',
    progressed: '{name} ने प्रगति की',
    completed: '{name} ने चैलेंज पूरा कर लिया! माशाअल्लाह',
    message: '{name}: {text}',
    nudge: '{name} ने आपको आज दर्ज करने की याद दिलाई',
    behind: 'आप {n} {unit} पीछे हैं। आप अब भी कर सकते हैं!',
    lastDay: 'एक दिन बाकी है। इन शा अल्लाह पूरा करें!',
    duaOne: '{name} ने आपके लिए दुआ की',
    duaMany: 'आपके अपनों ने आपके लिए {n} दुआएँ कीं',
    duaAll: '{name} ने सबके लिए दुआ की',
    units: { juz: 'पारे', pages: 'पृष्ठ', ayahs: 'आयतें', ahadith: 'हदीसें', count: 'बार', days: 'दिन' },
  },
  tr: {
    joined: '{name} katıldı',
    juz: '{name} {items}. cüzü bitirdi',
    pages: '{name} {items}. sayfaları okudu',
    ayahs: '{name} {items}. ayetleri ezberledi',
    amount: '{name}: +{amount} {unit}',
    progressed: '{name} ilerleme kaydetti',
    completed: '{name} meydan okumayı tamamladı! Maşallah',
    message: '{name}: {text}',
    nudge: '{name} bugün kayıt yapmanızı hatırlattı',
    behind: '{n} {unit} geridesiniz. Hâlâ yetişebilirsiniz!',
    lastDay: 'Son 1 gün. İnşallah güçlü bitirin!',
    duaOne: '{name} sizin için dua etti',
    duaMany: 'Aileniz sizin için {n} dua etti',
    duaAll: '{name} herkes için dua etti',
    units: { juz: 'cüz', pages: 'sayfa', ayahs: 'ayet', ahadith: 'hadis', count: 'kez', days: 'gün' },
  },
  zh: {
    joined: '{name} 加入了',
    juz: '{name} 读完了第 {items} 卷',
    pages: '{name} 读了第 {items} 页',
    ayahs: '{name} 背会了第 {items} 节',
    amount: '{name}：+{amount} {unit}',
    progressed: '{name} 有了新进度',
    completed: '{name} 完成了挑战！玛莎安拉',
    message: '{name}：{text}',
    nudge: '{name} 提醒你今天记录进度',
    behind: '你落后了 {n} {unit}。现在追还来得及！',
    lastDay: '只剩 1 天了。因沙安拉，坚持到底！',
    duaOne: '{name} 为你做了杜阿',
    duaMany: '你的家人为你做了 {n} 次杜阿',
    duaAll: '{name} 为大家做了杜阿',
    units: { juz: '卷', pages: '页', ayahs: '节', ahadith: '段圣训', count: '次', days: '天' },
  },
};

export function langOf(code: unknown): Lang {
  return typeof code === 'string' && (languages as string[]).includes(code) ? (code as Lang) : 'en';
}

export function stringsFor(lang: Lang): Strings {
  return strings[lang];
}

/// Fills `{key}` placeholders.
export function fill(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (m, key: string) => (key in values ? String(values[key]) : m));
}

/// A unit's label in [lang]; units typed by the creator stay as they are.
export function unitLabel(unit: string, lang: Lang): string {
  return strings[lang].units[unit] ?? unit;
}
