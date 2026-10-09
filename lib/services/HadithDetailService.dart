import 'package:allah_everywhere/services/hadith_api_client.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class HadithDetailService {
  // The API's largest accepted page size; anything above it silently falls
  // back to 25. At 200, almost every chapter arrives in a single request.
  static const _pageSize = 200;

  /// Fetches every Hadith in [chapterNumber] of [bookSlug]. The API scopes
  /// results by `book` + `chapter` (not `chapterId`, which it silently
  /// ignores). The first page reports `last_page`; any further pages are
  /// then fetched in parallel rather than one after another.
  Future<List<dynamic>> fetchHadithDetails(String bookSlug, int chapterNumber) async {
    Future<Map> page(int n) async {
      final data = await HadithApiClient().getJson('hadiths', {
        'book': bookSlug,
        'chapter': '$chapterNumber',
        'paginate': '$_pageSize',
        'page': '$n',
      });
      final hadiths = data['hadiths'];
      return hadiths is Map ? hadiths : const {};
    }

    try {
      final first = await page(1);
      final lastPage = first['last_page'] as int? ?? 1;
      final rest = await Future.wait([for (int n = 2; n <= lastPage; n++) page(n)]);
      return [
        for (final p in [first, ...rest])
          if (p['data'] is List) ...p['data'] as List,
      ];
    } catch (e) {
      VoidLogger.error('Error fetching Hadith details', e);
      throw Exception('Could not load Hadiths. Check your connection and try again.');
    }
  }
}
