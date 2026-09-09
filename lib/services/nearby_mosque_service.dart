import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class NearbyMosque {
  final String name;
  final double distanceKm;

  NearbyMosque({required this.name, required this.distanceKm});
}

/// Looks up real nearby mosques via the public OpenStreetMap Overpass API.
/// No API key required. Replaces the two hardcoded "Faisal Mosque"/"Lal
/// Masjid" cards that used to show regardless of the user's actual location.
class NearbyMosqueService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<NearbyMosque>> fetchNearby(
    double latitude,
    double longitude, {
    int radiusMeters = 5000,
    int limit = 10,
  }) async {
    final query = '''
      [out:json][timeout:15];
      node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
      out body $limit;
    ''';

    try {
      final response = await http
          .post(Uri.parse(_endpoint), body: {'data': query})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Overpass API returned ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List<dynamic>? ?? []);

      final mosques = elements
          .map((e) {
            final tags = e['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name'] as String? ?? 'Unnamed Mosque';
            final lat = (e['lat'] as num).toDouble();
            final lon = (e['lon'] as num).toDouble();
            final distance = _haversineKm(latitude, longitude, lat, lon);
            return NearbyMosque(name: name, distanceKm: distance);
          })
          .toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return mosques;
    } catch (e) {
      VoidLogger.error('Failed to fetch nearby mosques', e);
      return [];
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}
