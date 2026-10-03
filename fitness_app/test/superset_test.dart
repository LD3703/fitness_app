import 'package:fitness_app/core/superset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeSupersetGroups', () {
    test('samostatná skupina s jedním cvikem se zruší', () {
      expect(normalizeSupersetGroups([1, null, 2, 2]), [null, null, 2, 2]);
    });

    test('oddělené úseky se stejným číslem dostanou různá čísla', () {
      final r = normalizeSupersetGroups([1, 1, null, 1, 1]);
      expect(r[0], 1);
      expect(r[1], 1);
      expect(r[2], isNull);
      expect(r[3], isNot(1));
      expect(r[3], r[4]);
    });

    test('platné skupiny zůstanou beze změny', () {
      expect(normalizeSupersetGroups([null, 3, 3, 5, 5, 5]),
          [null, 3, 3, 5, 5, 5]);
    });
  });

  group('linkSupersetWithNext', () {
    test('propojí dva samostatné cviky', () {
      expect(linkSupersetWithNext([null, null, null], 0), [1, 1, null]);
    });

    test('připojí třetí cvik ke skupině', () {
      expect(linkSupersetWithNext([1, 1, null], 1), [1, 1, 1]);
    });

    test('víc než 3 cviky nejde', () {
      expect(linkSupersetWithNext([1, 1, 1, null], 2), isNull);
      expect(linkSupersetWithNext([1, 1, 2, 2], 1), isNull);
    });

    test('poslední cvik ani už propojené nejde', () {
      expect(linkSupersetWithNext([null, null], 1), isNull);
      expect(linkSupersetWithNext([4, 4], 0), isNull);
    });
  });

  group('unlinkSuperset', () {
    test('vyjmutí ze dvojice zruší celou supersérii', () {
      expect(unlinkSuperset([1, 1, null], 0), [null, null, null]);
    });

    test('vyjmutí krajního ze trojice nechá dvojici', () {
      expect(unlinkSuperset([1, 1, 1], 0), [null, 1, 1]);
    });

    test('vyjmutí prostředního ze trojice rozpojí vše', () {
      expect(unlinkSuperset([1, 1, 1], 1), [null, null, null]);
    });
  });

  group('supersetLabels', () {
    test('písmena podle pořadí supersérií, čísla uvnitř', () {
      expect(supersetLabels([7, 7, null, 2, 2, 2]),
          ['A1', 'A2', null, 'B1', 'B2', 'B3']);
    });

    test('supersetLetter', () {
      expect(supersetLetter(0), 'A');
      expect(supersetLetter(25), 'Z');
      expect(supersetLetter(26), 'AA');
    });
  });
}
