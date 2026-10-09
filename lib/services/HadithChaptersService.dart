import 'package:allah_everywhere/services/hadith_api_client.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithChaptersService {
  Future<List<dynamic>> fetchChapters(String bookSlug) async {
    try {
      final data = await HadithApiClient().getJson('$bookSlug/chapters');
      return data['chapters'] as List<dynamic>;
    } catch (e) {
      VoidLogger.error('Error fetching Hadith chapters', e);
      throw Exception('Error fetching chapters: $e');
    }
  }
}
