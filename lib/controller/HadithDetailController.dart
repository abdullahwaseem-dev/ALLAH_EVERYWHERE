import 'package:get/get.dart';


import '../services/HadithDetailService.dart';

class HadithDetailController extends GetxController {
  var isLoading = true.obs;
  var hadithData = [].obs;
  var chapterName = ''.obs;
  var errorMessage = ''.obs;

  final HadithDetailService _service = HadithDetailService();

  Future<void> fetchHadiths(String bookSlug, int chapterNumber) async {
    try {
      isLoading(true);
      errorMessage.value = '';
      hadithData.value = [];
      chapterName.value = '';
      final list = await _service.fetchHadithDetails(bookSlug, chapterNumber);
      if (list.isNotEmpty) {
        hadithData.value = list;
        final chapter = list[0]['chapter'];
        chapterName.value = (chapter is Map ? chapter['chapterEnglish'] as String? : null) ?? 'Unknown Chapter';
      } else {
        errorMessage.value = 'No Hadiths found for this chapter.';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading(false);
    }
  }
}

