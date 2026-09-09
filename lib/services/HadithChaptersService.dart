import 'dart:convert';
import 'package:http/http.dart' as http;

class HadithChaptersService {
  Future<List<dynamic>> fetchChapters(String bookSlug) async {
    final String apiUrl = 'https://hadithapi.com/api/$bookSlug/chapters?apiKey=\$2y\$10\$gZHaiB1KPJCVmowpqk8zuuYIbzEQCvddX0qPHxf9zY8txPvOjdEm';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chapters'];  // Return the list of chapters
      } else {
        throw Exception('Failed to load chapters');
      }
    } catch (e) {
      throw Exception('Error fetching chapters: $e');
    }
  }
}
