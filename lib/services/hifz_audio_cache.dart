import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';

/// Downloads a Hifz range's verse-by-verse recitation to the device before a
/// session. Repeats then play from disk: no re-download per repeat, and
/// nothing for the network to interrupt while the screen is locked. Files are
/// kept (per reciter) so practising the same ayahs again works offline.
class HifzAudioCache {
  static const _timeout = Duration(seconds: 20);

  static Future<Directory> _dir(String reciterId) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/hifz_audio/$reciterId');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Local file for every ayah from [from] to [to] of [surahId], downloading
  /// the missing ones. [onProgress] gets (done, total). Throws if the audio
  /// list or a file can't be fetched (e.g. offline with nothing cached).
  static Future<Map<int, String>> ensure({
    required int surahId,
    required int from,
    required int to,
    required String reciterId,
    void Function(int done, int total)? onProgress,
  }) async {
    final dir = await _dir(reciterId);
    final files = <int, String>{};
    final missing = <int>[];
    for (int ayah = from; ayah <= to; ayah++) {
      final file = File('${dir.path}/${surahId}_$ayah.mp3');
      if (file.existsSync() && file.lengthSync() > 0) {
        files[ayah] = file.path;
      } else {
        missing.add(ayah);
      }
    }
    final total = to - from + 1;
    onProgress?.call(files.length, total);
    if (missing.isEmpty) return files;

    final ayahs = await QuranAudioService.handler.fetchSurahAyahs(surahId, reciterId);
    final client = http.Client();
    try {
      for (final ayah in missing) {
        final url = ayahs.firstWhere((a) => a.numberInSurah == ayah).audioUrl;
        final response = await client.get(Uri.parse(url)).timeout(_timeout);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
        }
        // Write then rename, so an interrupted download never leaves a
        // truncated file that would be reused next time.
        final target = File('${dir.path}/${surahId}_$ayah.mp3');
        final partial = File('${target.path}.part');
        await partial.writeAsBytes(response.bodyBytes, flush: true);
        await partial.rename(target.path);
        files[ayah] = target.path;
        onProgress?.call(files.length, total);
      }
    } finally {
      client.close();
    }
    return files;
  }
}
