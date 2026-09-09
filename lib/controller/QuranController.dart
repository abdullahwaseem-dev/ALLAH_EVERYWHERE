import 'package:get/get.dart';
import '../services/QuranServices.dart';

class QuranController extends GetxController {
  var surahList = <Map<String, dynamic>>[].obs;
  var filteredSurahList = <Map<String, dynamic>>[].obs; // For the filtered list
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // Variables for last read Surah
  var lastReadSurahName = ''.obs;
  var lastReadSurahId = 0.obs;
  var lastReadAyah = 1.obs; // Default to Ayah 1

  final QuranService _quranService = QuranService();

  @override
  void onInit() {
    fetchSurahs();
    super.onInit();
  }

  Future<void> fetchSurahs() async {
    try {
      isLoading(true);
      final List<Map<String, dynamic>> data = await _quranService.fetchSurahs();
      surahList.value = data;
      filteredSurahList.value = data; // Initially set filtered list to all surahs
    } catch (e) {
      errorMessage.value = 'Error fetching data';
    } finally {
      isLoading(false);
    }
  }

  // Function to update last read Surah
  void updateLastReadSurah(String surahName, int surahId, int ayah) {
    lastReadSurahName.value = surahName;
    lastReadSurahId.value = surahId;
    lastReadAyah.value = ayah;
  }

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
