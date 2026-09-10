import 'package:get/get.dart';
import '../services/HadithService.dart';
import '../utils/utils/local_storage/storage.dart';

class HadithController extends GetxController {
  static const _lastReadSlugKey = 'hadith_last_read_slug';
  static const _lastReadNameKey = 'hadith_last_read_name';

  var books = <dynamic>[].obs;
  var filteredBooks = <dynamic>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var lastReadBookSlug = ''.obs;
  var lastReadBookName = ''.obs;

  final HadithService _hadithService = HadithService();

  @override
  void onInit() {
    super.onInit();
    lastReadBookSlug.value = VoidStorage().readData<String>(_lastReadSlugKey) ?? '';
    lastReadBookName.value = VoidStorage().readData<String>(_lastReadNameKey) ?? '';
    fetchBooks();
  }

  void updateLastReadBook(String slug, String name) {
    lastReadBookSlug.value = slug;
    lastReadBookName.value = name;
    VoidStorage().saveData(_lastReadSlugKey, slug);
    VoidStorage().saveData(_lastReadNameKey, name);
  }

  Future<void> fetchBooks() async {
    try {
      isLoading(true);
      errorMessage.value = '';
      var fetchedBooks = await _hadithService.fetchBooks();
      books.assignAll(fetchedBooks);
      filteredBooks.assignAll(fetchedBooks);
    } catch (e) {
      errorMessage.value = 'Error fetching books: $e';
    } finally {
      isLoading(false);
    }
  }

  void searchBooks(String query) {
    if (query.isEmpty) {
      filteredBooks.assignAll(books);
    } else {
      filteredBooks.assignAll(
        books.where((book) {
          String bookName = book['bookName'].toLowerCase();
          String writerName = book['writerName'].toLowerCase();
          return bookName.contains(query.toLowerCase()) || writerName.contains(query.toLowerCase());
        }).toList(),
      );
    }
  }
}
