import 'dart:convert';
import 'package:http/http.dart' as http;

class SurahService {
  Future<Map<String, dynamic>> fetchSurahDetails(int surahId, int pageNumber) async {
    final url = 'https://quranapi.pages.dev/api/$surahId/$pageNumber.json'; // Dynamically change the page number in the URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Decode the response body with UTF-8 decoding
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        // Return only the relevant fields: arabic1 and english
        return {
          'arabic1': data['arabic1'], // Arabic verse text
          'english': data['english'], // English translation
        };
      } else {
        throw Exception('Failed to load Surah details');
      }
    } catch (e) {
      throw Exception('Failed to load Surah details: $e');
    }
  }
}
