import 'package:get/get.dart';


import '../services/HadithDetailService.dart';

class HadithDetailController extends GetxController {
  var isLoading = true.obs;
  var hadithData = [].obs;
  var chapterName = ''.obs;
  var errorMessage = ''.obs;

  final HadithDetailService _service = HadithDetailService();

  Future<void> fetchHadiths(String chapterId) async {
    try {
      isLoading(true);
      errorMessage.value = '';
      hadithData.value = [];
      chapterName.value = '';
      var data = await _service.fetchHadithDetails(chapterId);
      if (data != null) {
        // Ensure hadiths data is a list
        if (data['hadiths'] != null && data['hadiths']['data'] is List) {
          hadithData.value = data['hadiths']['data'];  // Assign the list to the observable variable
          chapterName.value = data['hadiths']['data'][0]['chapter']['chapterEnglish'] ?? 'Unknown Chapter';
        } else {
          errorMessage.value = 'No Hadiths found for this chapter.';
        }
      } else {
        errorMessage.value = 'Failed to load Hadith details.';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading(false);
    }
  }
}

