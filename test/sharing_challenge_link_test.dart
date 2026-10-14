import 'package:fitness_app/core/formulas.dart';
import 'package:fitness_app/modules/sharing/challenge_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChallengeLink', () {
    test('sestaví webový odkaz se zakódovaným jménem', () {
      final link = ChallengeLink(
        exercise: 'bench_press',
        value: 102.058,
        reps: 5,
        fromName: 'Lukáš N.',
        deadline: DateTime(2026, 10, 30),
      );
      final url = link.toWebUrl('https://gymbar.app/');
      expect(url, startsWith('https://gymbar.app/challenge?'));
      final uri = Uri.parse(url);
      expect(uri.queryParameters['e'], 'bench_press');
      expect(uri.queryParameters['v'], '102.06');
      expect(uri.queryParameters['r'], '5');
      expect(uri.queryParameters['n'], 'Lukáš N.');
      expect(uri.queryParameters['d'], '2026-10-30');
      expect(uri.queryParameters.containsKey('x'), isFalse);
    });

    test('váha na setiny, celé číslo bez desetinné části', () {
      expect(ChallengeLink.formatValue(100), '100');
      expect(ChallengeLink.formatValue(100.24), '100.24');
      expect(ChallengeLink.formatValue(102.058), '102.06');
    });

    test('cíl: víc kg, nebo stejně kg na víc opakování', () {
      const link = ChallengeLink(exercise: 'bench_press', value: 100, reps: 5);
      final parsed = ChallengeLink.fromQuery(
          Uri.parse('x://y?${link.toQuery()}').queryParameters)!;
      expect(parsed.value, 100);
      expect(parsed.reps, 5);
      // 100 × 6 překoná, 100 × 5 ne, 102,5 × 1 ano.
      expect(recordValue(100, 6)! > parsed.target, isTrue);
      expect(recordValue(100, 5)! > parsed.target, isFalse);
      expect(recordValue(102.5, 1)! > parsed.target, isTrue);
    });

    test('bez opakování (nebo s neplatnými) je cílem jen váha', () {
      final l = ChallengeLink.fromQuery(
          {'e': 'squat', 'v': '120', 'r': '0'})!;
      expect(l.reps, isNull);
      expect(l.target, 120);
    });

    test('tam a zpět', () {
      const link = ChallengeLink(
        exercise: '42',
        exerciseName: 'Můj cvik',
        value: 80,
      );
      final parsed =
          ChallengeLink.fromQuery(Uri.parse('x://y?${link.toQuery()}')
              .queryParameters)!;
      expect(parsed.exerciseId, 42);
      expect(parsed.exerciseSlug, isNull);
      expect(parsed.exerciseName, 'Můj cvik');
      expect(parsed.value, 80);
      expect(parsed.fromName, isNull);
      expect(parsed.deadline, isNull);
    });

    test('neplatné odkazy', () {
      expect(ChallengeLink.fromQuery({}), isNull);
      expect(ChallengeLink.fromQuery({'e': 'bench_press'}), isNull);
      expect(ChallengeLink.fromQuery({'e': 'bench_press', 'v': 'abc'}), isNull);
      expect(ChallengeLink.fromQuery({'e': 'bench_press', 'v': '-5'}), isNull);
      expect(ChallengeLink.fromQuery({'e': 'bench_press', 'v': '5000'}), isNull);
    });

    test('špatné datum se ignoruje, dlouhé jméno se zkrátí', () {
      final l = ChallengeLink.fromQuery({
        'e': 'squat',
        'v': '140,5',
        'd': '2026-02-30',
        'n': 'x' * 100,
      })!;
      expect(l.value, 140.5);
      expect(l.deadline, isNull);
      expect(l.fromName!.length, ChallengeLink.maxNameLength);
      expect(ChallengeLink.parseDate('2026-10-05'), DateTime(2026, 10, 5));
    });

    test('název vlastního cviku z editoru (60 znaků) projde celý', () {
      final name = 'Bench ${'x' * 54}';
      expect(name.length, 60);
      final link = ChallengeLink(exercise: '7', exerciseName: name, value: 50);
      final parsed = ChallengeLink.fromQuery(
          Uri.parse('x://y?${link.toQuery()}').queryParameters)!;
      expect(parsed.exerciseName, name);
    });

    test('sestavení i čtení zkracují stejně (64 / 40)', () {
      final link = ChallengeLink(
        exercise: '7',
        exerciseName: 'c' * 70,
        fromName: 'n' * 50,
        value: 50,
      );
      final q = Uri.parse('x://y?${link.toQuery()}').queryParameters;
      expect(q['x']!.length, ChallengeLink.maxExerciseNameLength);
      expect(q['n']!.length, ChallengeLink.maxNameLength);
      final parsed = ChallengeLink.fromQuery({...q, 'x': 'c' * 70})!;
      expect(parsed.exerciseName!.length, ChallengeLink.maxExerciseNameLength);
    });

    test('zkrácení nerozpůlí emoji', () {
      final name = '${'a' * 63}💪';
      final parsed =
          ChallengeLink.fromQuery({'e': '7', 'v': '50', 'x': name})!;
      expect(parsed.exerciseName, 'a' * 63);
    });
  });
}
