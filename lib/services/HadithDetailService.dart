import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:allah_everywhere/utils/utils/constraints/api_constants.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithDetailService {
  Future<Map<String, dynamic>?> fetchHadithDetails(String chapterId) async {
    if (ApiConstant.hadithApiKey.isEmpty) {
      VoidLogger.error(
          'HADITH_API_KEY is not configured. Run with --dart-define=HADITH_API_KEY=your_key_here');
      return null;
    }

    final String apiUrl =
        'https://hadithapi.com/api/hadiths/?apiKey=${ApiConstant.hadithApiKey}&chapterId=$chapterId';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load Hadiths: HTTP ${response.statusCode}');
      }
    } catch (e) {
      VoidLogger.error('Error fetching Hadith details', e);
      return null;
    }
  }
}
