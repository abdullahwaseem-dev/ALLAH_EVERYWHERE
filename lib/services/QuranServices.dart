import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranService {
  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    final url = 'https://quranapi.pages.dev/api/surah.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));  // Use utf8.decode here
        return data.map((surah) {
          print('surahName: ${surah['surahNameArabic']}');
          return {
            'surahName': surah['surahName'],
            'surahNameArabic': surah['surahNameArabic'],
            'surahNameTranslation': surah['surahNameTranslation'],
            'totalAyah': surah['totalAyah'],

          };

        }).toList();
      } else {
        throw Exception('Failed to load surahs');
      }
    } catch (e) {
      throw Exception('Failed to load surahs: $e');
    }
  }
}
