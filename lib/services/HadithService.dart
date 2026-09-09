import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/constraints/api_constants.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithService {
  Future<List<dynamic>> fetchBooks() async {
    if (ApiConstant.hadithApiKey.isEmpty) {
      throw Exception(
        'HADITH_API_KEY is not configured. Run with '
        '--dart-define=HADITH_API_KEY=your_key_here',
      );
    }

    final apiUrl =
        'https://hadithapi.com/api/books?apiKey=${ApiConstant.hadithApiKey}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['books'];
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      VoidLogger.error('Error fetching Hadith books', e);
      throw Exception('Error: $e');
    }
  }
}
