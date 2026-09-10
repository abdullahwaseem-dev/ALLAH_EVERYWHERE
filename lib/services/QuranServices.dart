import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class QuranService {
  Future<List<Map<String, dynamic>>> fetchSurahs() async {
    final url = 'https://quranapi.pages.dev/api/surah.json';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((surah) {
          return {
            'surahName': surah['surahName'],
            'surahNameArabic': surah['surahNameArabic'],
            'surahNameTranslation': surah['surahNameTranslation'],
            'totalAyah': surah['totalAyah'],
          };
        }).toList();
      } else {
        throw Exception('Failed to load surahs: HTTP ${response.statusCode}');
      }
    } catch (e) {
      VoidLogger.error('Failed to fetch Surah list', e);
      throw Exception('Failed to load surahs: $e');
    }
  }
}
