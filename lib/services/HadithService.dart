import 'package:allah_everywhere/services/hadith_api_client.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithService {
  Future<List<dynamic>> fetchBooks() async {
    try {
      final data = await HadithApiClient().getJson('books');
      return data['books'] as List<dynamic>;
    } catch (e) {
      VoidLogger.error('Error fetching Hadith books', e);
      throw Exception('Error: $e');
    }
  }
}
