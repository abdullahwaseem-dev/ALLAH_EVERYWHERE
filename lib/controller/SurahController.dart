import 'package:get/get.dart';


import '../services/SurahService.dart'; // Assuming you have a SurahService

class SurahController extends GetxController {
  var surahDetails = RxMap<String, dynamic>({});
  var isLoading = false.obs;
  var currentPage = 1.obs;  // Track the current page
  var isLastPage = false.obs;  // Flag to track if it's the last page

  // Fetch surah details based on surahId and page number
  void fetchSurahDetails(int surahId) async {
    isLoading.value = true;

    try {
      final data = await SurahService().fetchSurahDetails(surahId, currentPage.value);
      surahDetails.value = data;

      // Update last page flag
      isLastPage.value = data['arabic1'] == null || data['english'] == null; // If no data is returned, assume it's the last page
    } catch (e) {
      print('Error fetching Surah details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Move to the next page
  void nextPage(int surahId) {
    if (!isLastPage.value) {
      currentPage.value++;
      fetchSurahDetails(surahId);
    }
  }

  // Move to the previous page
  void previousPage(int surahId) {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchSurahDetails(surahId);
    }
  }
}

