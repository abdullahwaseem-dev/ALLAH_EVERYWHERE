/// A reciter (Qari) whose recitation can be streamed for a Surah, via the
/// `ar.<identifier>` audio edition on api.alquran.cloud. Identifiers verified
/// live against `GET /v1/edition?format=audio&language=ar&type=versebyverse`.
class Reciter {
  final String editionId;
  final String name;
  final String arabicName;

  const Reciter({required this.editionId, required this.name, required this.arabicName});
}

const List<Reciter> availableReciters = [
  Reciter(editionId: 'ar.alafasy', name: 'Mishary Alafasy', arabicName: 'مشاري العفاسي'),
  Reciter(editionId: 'ar.abdulsamad', name: 'Abdul Basit Abdul Samad', arabicName: 'عبدالباسط عبدالصمد'),
  Reciter(editionId: 'ar.husary', name: 'Mahmoud Khalil Al-Husary', arabicName: 'محمود خليل الحصري'),
  Reciter(editionId: 'ar.abdurrahmaansudais', name: 'Abdurrahmaan As-Sudais', arabicName: 'عبدالرحمن السديس'),
  Reciter(editionId: 'ar.saoodshuraym', name: 'Saood Ash-Shuraym', arabicName: 'سعود الشريم'),
  Reciter(editionId: 'ar.mahermuaiqly', name: 'Maher Al Muaiqly', arabicName: 'ماهر المعيقلي'),
  Reciter(editionId: 'ar.hudhaify', name: 'Ali Al-Hudhaify', arabicName: 'علي الحذيفي'),
  Reciter(editionId: 'ar.ahmedajamy', name: 'Ahmed Al-Ajamy', arabicName: 'أحمد العجمي'),
];

Reciter reciterFor(String editionId) =>
    availableReciters.firstWhere((r) => r.editionId == editionId, orElse: () => availableReciters.first);
