import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class NearbyMosque {
  final String name;
  final double distanceKm;
  final double latitude;
  final double longitude;

  NearbyMosque({
    required this.name,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
  });
}

/// Result of a nearby-mosque lookup. Distinguishes "the server told us
/// there are genuinely none nearby" from "we couldn't reach/finish the
/// query" so the UI doesn't show a misleading "no mosques found" when the
/// public Overpass server is just overloaded (observed in practice: dense
/// areas like Makkah/Madinah can make this specific free endpoint time
/// out even though it works fine everywhere else).
class NearbyMosqueResult {
  final List<NearbyMosque> mosques;
  final bool hadError;

  const NearbyMosqueResult({required this.mosques, required this.hadError});
}

/// Looks up real nearby mosques via the public OpenStreetMap Overpass API.
/// No API key required. Replaces the two hardcoded "Faisal Mosque"/"Lal
/// Masjid" cards that used to show regardless of the user's actual location.
class NearbyMosqueService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<NearbyMosqueResult> fetchNearby(
    double latitude,
    double longitude, {
    int radiusMeters = 5000,
    int limit = 16,
  }) async {
    try {
      final mosques = await _query(latitude, longitude, radiusMeters, limit);
      return NearbyMosqueResult(mosques: mosques, hadError: false);
    } catch (e) {
      VoidLogger.error('Nearby mosque query failed at ${radiusMeters}m, retrying with a smaller radius', e);
      // Very dense areas (e.g. around the Grand Mosque in Makkah) can time
      // out the free public Overpass server at a 5km radius. A tighter
      // radius is a much cheaper query and still useful in exactly the
      // areas where this happens.
      if (radiusMeters > 1500) {
        try {
          final mosques = await _query(latitude, longitude, 1500, limit);
          return NearbyMosqueResult(mosques: mosques, hadError: false);
        } catch (e2) {
          VoidLogger.error('Nearby mosque retry also failed', e2);
        }
      }
      return const NearbyMosqueResult(mosques: [], hadError: true);
    }
  }

  Future<List<NearbyMosque>> _query(
    double latitude,
    double longitude,
    int radiusMeters,
    int limit,
  ) async {
    // `nwr` (not just `node`) because most mapped mosques are the building
    // outline (a way) or a multipolygon (a relation) with the name tag on
    // that feature - a node-only query mostly hits unnamed minor points
    // (entrances, minarets) and misses the named building entirely.
    // `out center` gives a representative lat/lon for those way/relation
    // results (they have no lat/lon of their own).
    final query = '''
      [out:json][timeout:20];
      nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
      out center $limit;
    ''';

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'User-Agent': 'AllahEverywhereApp/1.0 (Flutter; Islamic prayer app)'},
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Overpass API returned HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>? ?? []);

    final mosques = elements
        .map((e) {
          final tags = e['tags'] as Map<String, dynamic>? ?? {};
          final name = (tags['name'] ?? tags['name:en'] ?? tags['alt_name'] ?? tags['official_name'])
                  as String? ??
              'Unnamed Mosque';

          // Nodes carry lat/lon directly; ways and relations only get a
          // `center` from `out center`.
          double lat, lon;
          if (e['type'] == 'node') {
            lat = (e['lat'] as num).toDouble();
            lon = (e['lon'] as num).toDouble();
          } else {
            final center = e['center'] as Map<String, dynamic>?;
            if (center == null) return null;
            lat = (center['lat'] as num).toDouble();
            lon = (center['lon'] as num).toDouble();
          }

          final distance = _haversineKm(latitude, longitude, lat, lon);
          return NearbyMosque(name: name, distanceKm: distance, latitude: lat, longitude: lon);
        })
        .whereType<NearbyMosque>()
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return _dedupe(mosques);
  }

  /// Querying both points and building outlines (see `_query`) means the
  /// same physical mosque can come back twice - e.g. an unnamed entrance
  /// node plus the named building way. Collapses anything within ~40m of
  /// an already-accepted mosque into a single entry, preferring whichever
  /// one actually has a name.
  List<NearbyMosque> _dedupe(List<NearbyMosque> sorted) {
    final accepted = <NearbyMosque>[];
    for (final candidate in sorted) {
      final duplicateIndex = accepted.indexWhere(
        (m) => _haversineKm(m.latitude, m.longitude, candidate.latitude, candidate.longitude) < 0.04,
      );
      if (duplicateIndex == -1) {
        accepted.add(candidate);
        continue;
      }
      final existing = accepted[duplicateIndex];
      if (existing.name == 'Unnamed Mosque' && candidate.name != 'Unnamed Mosque') {
        accepted[duplicateIndex] = candidate;
      }
    }
    return accepted;
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
