import 'package:get/get.dart';
import '../services/QuranServices.dart';
import '../utils/utils/local_storage/storage.dart';
import '../services/mushaf_service.dart';

class QuranController extends GetxController {
  var surahList = <Map<String, dynamic>>[].obs;
  var filteredSurahList = <Map<String, dynamic>>[].obs; // For the filtered list
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // Variables for last read Surah. Default to Al-Faatiha (Surah 1) rather
  // than 0 - 0 isn't a valid Surah number and crashed the reader the first
  // time a new user (who hasn't read anything yet) tapped "Continue".
  var lastReadSurahName = 'الفاتحة'.obs;
  var lastReadSurahId = 1.obs;
  var lastReadAyah = 1.obs; // Default to Ayah 1

  /// Surah view (false) or Mushaf (page) view (true), remembered.
  final mushafView = MushafService.mushafViewSelected.obs;

  /// Last Mushaf page read, for "Continue from page X"; null if never opened.
  final lastMushafPage = MushafService.lastPage.obs;

  void setMushafView(bool mushaf) {
    mushafView.value = mushaf;
    MushafService.setMushafViewSelected(mushaf);
  }

  void refreshLastMushafPage() => lastMushafPage.value = MushafService.lastPage;

  final QuranService _quranService = QuranService();

  @override
  void onInit() {
    final stored = VoidStorage().readData<Map>(_lastReadKey);
    if (stored != null) {
      final name = stored['surahName'];
      final id = stored['surahId'];
      final ayah = stored['ayah'];
      if (name is String && id is num && id >= 1 && id <= 114 && ayah is num && ayah >= 1) {
        lastReadSurahName.value = name;
        lastReadSurahId.value = id.toInt();
        lastReadAyah.value = ayah.toInt();
      }
    }
    fetchSurahs();
    super.onInit();
  }

  Future<void> fetchSurahs() async {
    try {
      isLoading(true);
      errorMessage.value = '';
      final List<Map<String, dynamic>> data = await _quranService.fetchSurahs();
      surahList.value = data;
      filteredSurahList.value = data; // Initially set filtered list to all surahs
    } catch (e) {
      errorMessage.value = 'Error fetching data: $e';
    } finally {
      isLoading(false);
    }
  }

  // Function to update last read Surah
  void updateLastReadSurah(String surahName, int surahId, int ayah) {
    lastReadSurahName.value = surahName;
    lastReadSurahId.value = surahId;
    lastReadAyah.value = ayah;
    saveLastRead(surahName, surahId, ayah);
  }

  static const _lastReadKey = 'quran_last_read';

  /// Persists "last read" so Continue Reading survives an app restart. Static
  /// so the Surah reader can save it even when this controller isn't alive
  /// (reader opened from search, bookmarks or the Ask AI flow).
  static Future<void> saveLastRead(String surahName, int surahId, int ayah) =>
      VoidStorage().saveData(_lastReadKey, {'surahName': surahName, 'surahId': surahId, 'ayah': ayah});

  // Function to filter surah list based on search query
  void searchSurah(String query) {
    if (query.isEmpty) {
      filteredSurahList.value = surahList; // Show all surahs if query is empty
    } else {
      filteredSurahList.value = surahList.where((surah) {
        // Filter based on surah name or translation
        return surah['surahName'].toLowerCase().contains(query.toLowerCase()) ||
            surah['surahNameTranslation'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}
