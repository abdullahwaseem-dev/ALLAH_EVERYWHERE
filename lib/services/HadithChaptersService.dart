import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/constraints/api_constants.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithChaptersService {
  Future<List<dynamic>> fetchChapters(String bookSlug) async {
    if (ApiConstant.hadithApiKey.isEmpty) {
      throw Exception(
        'HADITH_API_KEY is not configured. Run with '
        '--dart-define=HADITH_API_KEY=your_key_here',
      );
    }

    final String apiUrl =
        'https://hadithapi.com/api/$bookSlug/chapters?apiKey=${ApiConstant.hadithApiKey}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chapters'];
      } else {
        throw Exception('Failed to load chapters');
      }
    } catch (e) {
      VoidLogger.error('Error fetching Hadith chapters', e);
      throw Exception('Error fetching chapters: $e');
    }
  }
}
