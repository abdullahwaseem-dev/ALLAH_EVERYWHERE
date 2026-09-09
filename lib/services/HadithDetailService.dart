import 'package:http/http.dart' as http;
import 'dart:convert';

class HadithDetailService {
  final String apiUrl = 'https://hadithapi.com/api/hadiths/?apiKey=\$2y\$10\$gZHaiB1KPJCVmowpqk8zuuYIbzEQCvddX0qPHxf9zY8txPvOjdEm';


  Future<Map<String, dynamic>?> fetchHadithDetails(String chapterId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl&chapterId=$chapterId'));
      print('Fetching Hadiths: ${response.statusCode}');
      print('Fetching Hadiths: ${response.body}');
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load Hadiths');
      }
    } catch (e) {
      print('Error fetching Hadiths: $e');
      return null;
    }
  }
}

