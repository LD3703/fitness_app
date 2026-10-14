// Geohash pro hledání posiloven v okolí (čistý Dart, testy:
// test/social_gym_geo_test.dart). Stejný algoritmus jako
// tool/gyms_import/lib.mjs (import z OpenStreetMap).
//
// Posilovna má ve Firestore pole `geohash` (9 znaků) a buňky `g5`, `g6`
// (prvních 5 / 6 znaků). Hledání v okolí = dotaz `g6 in [buňky]` (do 30
// hodnot), v řídce osídlených oblastech pak `g5 in [buňky]`.
import 'dart:math';

const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Přesnost uloženého geohashe (cca 5 × 5 m).
const gymGeohashPrecision = 9;

String geohashEncode(double lat, double lng, [int precision = gymGeohashPrecision]) {
  var latMin = -90.0, latMax = 90.0, lngMin = -180.0, lngMax = 180.0;
  final b = StringBuffer();
  var bit = 0, ch = 0, even = true, length = 0;
  while (length < precision) {
    if (even) {
      final mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch = (ch << 1) | 1;
        lngMin = mid;
      } else {
        ch <<= 1;
        lngMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch = (ch << 1) | 1;
        latMin = mid;
      } else {
        ch <<= 1;
        latMax = mid;
      }
    }
    even = !even;
    if (++bit == 5) {
      b.write(_base32[ch]);
      length++;
      bit = 0;
      ch = 0;
    }
  }
  return b.toString();
}

/// Velikost buňky geohashe ve stupních (zeměpisná šířka, délka).
({double lat, double lng}) geohashCellDegrees(int precision) {
  final bits = 5 * precision;
  final lngBits = (bits + 1) ~/ 2;
  final latBits = bits ~/ 2;
  return (lat: 180 / pow(2, latBits), lng: 360 / pow(2, lngBits));
}

/// Buňky geohashe dané přesnosti, které pokrývají čtverec ±[radiusKm]
/// kolem bodu (seřazené, bez opakování).
List<String> geohashCellsCovering(
  double lat,
  double lng,
  double radiusKm,
  int precision,
) {
  final dLat = radiusKm / 111.32;
  final cosLat = max(0.01, cos(lat * pi / 180).abs());
  final dLng = radiusKm / (111.32 * cosLat);
  final cell = geohashCellDegrees(precision);
  final cells = <String>{};
  // Krok poloviny buňky + krajní body → žádná buňka nevypadne.
  final latStep = cell.lat / 2, lngStep = cell.lng / 2;
  for (var y = lat - dLat;; y += latStep) {
    final yy = max(-89.999999, min(min(y, lat + dLat), 89.999999));
    for (var x = lng - dLng;; x += lngStep) {
      final xx = min(x, lng + dLng);
      final wrapped = ((xx + 180) % 360 + 360) % 360 - 180;
      cells.add(geohashEncode(yy, wrapped, precision));
      if (x >= lng + dLng) break;
    }
    if (y >= lat + dLat) break;
  }
  return cells.toList()..sort();
}

/// Vzdálenost dvou bodů v km (haversine).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0088;
  const rad = pi / 180;
  final dLat = (lat2 - lat1) * rad;
  final dLng = (lng2 - lng1) * rad;
  final a = pow(sin(dLat / 2), 2) +
      cos(lat1 * rad) * cos(lat2 * rad) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(min(1.0, sqrt(a)));
}

/// Pole polohy posilovny ve Firestore (stejně jako geoFields v importu).
Map<String, Object> gymGeoFields(double lat, double lng) {
  final hash = geohashEncode(lat, lng);
  return {
    'lat': lat,
    'lng': lng,
    'geohash': hash,
    'g5': hash.substring(0, 5),
    'g6': hash.substring(0, 6),
  };
}

/// Rozdělí seznam na části po [size] (Firestore whereIn: nejvýš 30).
List<List<T>> chunked<T>(List<T> items, [int size = 30]) => [
      for (var i = 0; i < items.length; i += size)
        items.sublist(i, min(i + size, items.length)),
    ];
