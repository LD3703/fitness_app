import 'dart:math';

import 'package:fitness_app/modules/social/gym/geohash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('geohash odpovídá známým hodnotám (stejně jako import v Node)', () {
    expect(geohashEncode(57.64911, 10.40744, 11), 'u4pruydqqvj');
    expect(geohashEncode(-33.8688, 151.2093, 6), 'r3gx2f');
    expect(geohashEncode(0, 0, 1), 's');
    expect(geohashEncode(50.43015, 15.35025).length, gymGeohashPrecision);
  });

  test('pole polohy posilovny', () {
    final f = gymGeoFields(50.43015, 15.35025);
    final hash = f['geohash']! as String;
    expect(f['g5'], hash.substring(0, 5));
    expect(f['g6'], hash.substring(0, 6));
    expect(f['lat'], 50.43015);
  });

  test('buňky pokrývají celé okolí', () {
    final r = Random(1);
    for (final (lat, lng, km, p) in [
      (50.43, 15.35, 2.0, 6),
      (40.7, -74.0, 15.0, 5),
      (-34.6, -58.4, 2.0, 6),
    ]) {
      final cells = geohashCellsCovering(lat, lng, km, p).toSet();
      expect(cells.length, lessThan(120));
      for (var i = 0; i < 2000; i++) {
        final dy = (r.nextDouble() * 2 - 1) * km / 111.32;
        final dx = (r.nextDouble() * 2 - 1) * km / (111.32 * cos(lat * pi / 180));
        expect(cells, contains(geohashEncode(lat + dy, lng + dx, p)));
      }
    }
  });

  test('vzdálenost a dělení na části', () {
    final d = haversineKm(50.0755, 14.4378, 49.1951, 16.6068); // Praha – Brno
    expect(d, inInclusiveRange(180, 190));
    expect(chunked(List.generate(65, (i) => i)).map((c) => c.length), [30, 30, 5]);
    expect(chunked(<int>[]), isEmpty);
  });
}
