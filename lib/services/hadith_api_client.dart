import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:allah_everywhere/utils/utils/constraints/api_constants.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Shared client for hadithapi.com with a two-level cache.
///
/// Hadith text never changes, so every response is kept in memory for the
/// session and on disk for [_maxAge]; reopening a book or chapter is then
/// instant and works offline. A single [http.Client] is reused so requests
/// share one keep-alive connection instead of paying a new TLS handshake
/// each time.
class HadithApiClient {
  static final HadithApiClient _instance = HadithApiClient._internal();
  factory HadithApiClient() => _instance;
  HadithApiClient._internal();

  // No trailing slash on paths: `/api/hadiths/` answers with a 301 to
  // `/public/api/hadiths`, which doubled the latency of every request.
  static const _baseUrl = 'https://hadithapi.com/api';
  static const _maxAge = Duration(days: 30);
  static const _timeout = Duration(seconds: 20);
  static const _memoryLimit = 40;

  final http.Client _http = http.Client();
  final Map<String, dynamic> _memory = {};
  final Map<String, Future<dynamic>> _inFlight = {};
  Directory? _cacheDir;

  /// GETs [path] (relative to the API root) with [query], returning the
  /// decoded JSON. Served from cache when fresh; concurrent calls for the
  /// same URL share one request.
  Future<dynamic> getJson(String path, [Map<String, String> query = const {}]) {
    if (ApiConstant.hadithApiKey.isEmpty) {
      throw Exception(
        'HADITH_API_KEY is not configured. Run with '
        '--dart-define=HADITH_API_KEY=your_key_here',
      );
    }
    final cacheKey = _cacheKey(path, query);
    if (_memory.containsKey(cacheKey)) return Future.value(_memory[cacheKey]);
    return _inFlight.putIfAbsent(cacheKey, () async {
      try {
        final cached = await _readDisk(cacheKey);
        if (cached != null) return _remember(cacheKey, cached);

        final uri = Uri.parse('$_baseUrl/$path').replace(
          queryParameters: {'apiKey': ApiConstant.hadithApiKey, ...query},
        );
        final response = await _http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final decoded = jsonDecode(response.body);
        _writeDisk(cacheKey, response.body);
        return _remember(cacheKey, decoded);
      } finally {
        _inFlight.remove(cacheKey);
      }
    });
  }

  /// Keeps at most [_memoryLimit] responses in memory (oldest evicted
  /// first); the disk cache still holds everything.
  dynamic _remember(String key, dynamic value) {
    _memory.remove(key);
    _memory[key] = value;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
    }
    return value;
  }

  String _cacheKey(String path, Map<String, String> query) {
    final keys = query.keys.toList()..sort();
    final parts = [path, for (final k in keys) '$k=${query[k]}'];
    return parts.join('_').replaceAll(RegExp(r'[^A-Za-z0-9_=-]'), '-');
  }

  Future<Directory?> _dir() async {
    if (_cacheDir != null) return _cacheDir;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/hadith_cache');
      if (!await dir.exists()) await dir.create(recursive: true);
      return _cacheDir = dir;
    } catch (e) {
      VoidLogger.warning('Hadith disk cache unavailable: $e');
      return null;
    }
  }

  Future<dynamic> _readDisk(String key) async {
    try {
      final dir = await _dir();
      if (dir == null) return null;
      final file = File('${dir.path}/$key.json');
      if (!await file.exists()) return null;
      final age = DateTime.now().difference(await file.lastModified());
      if (age > _maxAge) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null; // corrupt or unreadable entry - refetch
    }
  }

  Future<void> _writeDisk(String key, String body) async {
    try {
      final dir = await _dir();
      if (dir == null) return;
      await File('${dir.path}/$key.json').writeAsString(body, flush: true);
    } catch (e) {
      VoidLogger.warning('Could not write Hadith cache entry: $e');
    }
  }
}
