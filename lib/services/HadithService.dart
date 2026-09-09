import 'dart:convert';
import 'package:http/http.dart' as http;

class HadithService {

  final String apiUrl = 'https://hadithapi.com/api/books?apiKey=\$2y\$10\$gZHaiB1KPJCVmowpqk8zuuYIbzEQCvddX0qPHxf9zY8txPvOjdEm';

  Future<List<dynamic>> fetchBooks() async {
    print('Fetching books...');
    try {
      // Make sure we treat the API URL and API key as strings
      final response = await http.get(Uri.parse(apiUrl));
      print('Response status: ${response.body}');
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming the response has the structure as you provided.
        return data['books'];
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
