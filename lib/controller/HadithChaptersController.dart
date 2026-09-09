import 'package:get/get.dart';
import '../services/HadithChaptersService.dart';

class HadithChaptersController extends GetxController {
  var chapters = <dynamic>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var bookNameArabic = ''.obs;

  final HadithChaptersService _hadithChaptersService = HadithChaptersService();

  void fetchChapters(String bookSlug, String bookNameInArabic) async {
    try {
      isLoading(true);
      bookNameArabic.value = bookNameInArabic;
      var fetchedChapters = await _hadithChaptersService.fetchChapters(bookSlug);
      chapters.assignAll(fetchedChapters);
    } catch (e) {
      errorMessage.value = 'Error fetching chapters: $e';
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
  }
}
