import 'package:fitness_app/core/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('klouzavý průměr za 7 dní', () {
    final pts = [
      (x: DateTime(2026, 10, 1), y: 80.0),
      (x: DateTime(2026, 10, 2), y: 82.0),
      (x: DateTime(2026, 10, 9), y: 78.0),
    ];
    final avg = movingAverage(pts);
    expect(avg[0].y, 80.0);
    expect(avg[1].y, 81.0);
    // 9. 10.: okno 3.–9. 10. obsahuje jen poslední bod
    expect(avg[2].y, 78.0);
  });

  test('počty tréninků po týdnech', () {
    final now = DateTime(2026, 10, 14); // středa
    final counts = weeklyCounts([
      DateTime(2026, 10, 12, 18), // pondělí tohoto týdne
      DateTime(2026, 10, 13, 18),
      DateTime(2026, 10, 5, 18), // minulý týden
      DateTime(2025, 1, 1), // mimo rozsah
    ], now, weeks: 4);
    expect(counts.length, 4);
    expect(counts.last.count, 2);
    expect(counts[2].count, 1);
    expect(counts.last.weekStart, DateTime(2026, 10, 12));
  });
}
