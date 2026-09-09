import 'package:get/get.dart';
import '../services/HadithService.dart';

class HadithController extends GetxController {
  var books = <dynamic>[].obs;
  var filteredBooks = <dynamic>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  final HadithService _hadithService = HadithService();

  void fetchBooks() async {
    try {
      isLoading(true);
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

  @override
  void onInit() {
    super.onInit();
    fetchBooks();
  }
}
