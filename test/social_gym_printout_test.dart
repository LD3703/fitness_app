import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:fitness_app/modules/social/gym/gym_models.dart';
import 'package:fitness_app/modules/social/gym/gym_printout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const month = '2026-10';
  var n = 0;

  GymEntry entry(
    double best, {
    String gender = 'male',
    double? bestMonth,
    String monthKey = month,
    Map<String, Object?> extra = const {},
    String category = 'bench_press',
  }) {
    final uid = 'u${n++}';
    return GymEntry.fromMap('${uid}_$category', {
      'uid': uid,
      'category': category,
      'nickname': 'N$uid',
      'gender': gender,
      'best': best,
      'bestMonth': bestMonth ?? best,
      'monthKey': monthKey,
      ...extra,
    })!;
  }

  List<double> values(List<({int rank, GymEntry item, double value})> rows) =>
      [for (final r in rows) r.value];

  group('gymPrintRows', () {
    test('bez lidí, kteří tisk vypnuli, a bez skrytých záznamů', () {
      final rows = gymPrintRows(
        [
          entry(100),
          entry(120, extra: {'noPrint': true}),
          entry(130, extra: {'hidden': true, 'hiddenReason': 'implausible:x'}),
          entry(110, extra: {'reportCount': 5}),
          entry(90),
        ],
        gender: GymGenderFilter.men,
        monthly: false,
        month: month,
      );
      expect(values(rows), [100, 90]);
    });

    test('jen dané pohlaví; neuvedené pohlaví se netiskne', () {
      final all = [
        entry(100),
        entry(60, gender: 'female'),
        entry(80, gender: 'unspecified'),
      ];
      expect(
        values(gymPrintRows(all,
            gender: GymGenderFilter.men, monthly: false, month: month)),
        [100],
      );
      expect(
        values(gymPrintRows(all,
            gender: GymGenderFilter.women, monthly: false, month: month)),
        [60],
      );
    });

    test('tento měsíc jen se záznamem z aktuálního měsíce', () {
      final rows = gymPrintRows(
        [
          entry(100, bestMonth: 95),
          entry(150, monthKey: '2026-09'),
        ],
        gender: GymGenderFilter.men,
        monthly: true,
        month: month,
      );
      expect(values(rows), [95]);
    });

    test('prvních 5 míst, shoda na 5. místě se vejde, víc ne', () {
      final rows = gymPrintRows(
        [for (final v in [100, 90, 80, 70, 60, 60, 60, 60, 50]) entry(v.toDouble())],
        gender: GymGenderFilter.men,
        monthly: false,
        month: month,
      );
      expect(rows.length, gymPrintMaxRows);
      expect(rows.map((r) => r.rank).toList(), [1, 2, 3, 4, 5, 5, 5]);
    });
  });

  test('gymPrintBoxes: kategorie × muži a ženy, prázdné bez dat', () {
    final boxes = gymPrintBoxes(
      monthly: {
        GymCategory.benchPress: [entry(100)],
      },
      allTime: {
        GymCategory.benchPress: [entry(110), entry(55, gender: 'female')],
      },
      month: month,
    );
    expect(boxes.length, gymPrintCategories.length * gymPrintGenders.length);
    expect(boxes.first.category, GymCategory.benchPress);
    expect(boxes.first.gender, GymGenderFilter.men);
    expect(values(boxes.first.month), [100]);
    expect(values(boxes[1].allTime), [55]);
    expect(gymPrintHasData(boxes), isTrue);
    expect(
      gymPrintHasData(gymPrintBoxes(monthly: {}, allTime: {}, month: month)),
      isFalse,
    );
  });

  test('GymMembership.printable: bez pole ano', () {
    expect(GymMembership.fromMap({'gymId': 'g'}).printable, isTrue);
    expect(
      GymMembership.fromMap({'gymId': 'g', 'printable': false}).printable,
      isFalse,
    );
  });
}
