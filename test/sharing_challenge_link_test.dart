import 'package:fitness_app/modules/sharing/challenge_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChallengeLink', () {
    test('sestaví webový odkaz se zakódovaným jménem', () {
      final link = ChallengeLink(
        exercise: 'bench_press',
        value: 116.67,
        fromName: 'Lukáš N.',
        deadline: DateTime(2026, 10, 30),
      );
      final url = link.toWebUrl('https://example.com/');
      expect(url, startsWith('https://example.com/challenge?'));
      final uri = Uri.parse(url);
      expect(uri.queryParameters['e'], 'bench_press');
      expect(uri.queryParameters['v'], '116.5');
      expect(uri.queryParameters['n'], 'Lukáš N.');
      expect(uri.queryParameters['d'], '2026-10-30');
      expect(uri.queryParameters.containsKey('x'), isFalse);
    });

    test('celé číslo bez desetinné části', () {
      expect(ChallengeLink.formatValue(100), '100');
      expect(ChallengeLink.formatValue(100.24), '100');
      expect(ChallengeLink.formatValue(100.3), '100.5');
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
  });
}
