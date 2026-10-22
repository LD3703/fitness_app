// Odkazy pro fitka (docs/fitka.md): samolepka na stroji /ex?id=<slug>
// a doporučení majiteli gymbar.app/fitka?gym=…&ref=….
import 'package:fitness_app/data/seed/seed_data.dart';
import 'package:fitness_app/modules/links/link_decoding.dart';
import 'package:fitness_app/modules/social/gym/gym_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exerciseLinkSlug', () {
    test('slug z webového odkazu i ze schématu aplikace', () {
      expect(
        exerciseLinkSlug(Uri.parse('https://gymbar.app/ex?id=bench_press&gym=osm-n1')),
        'bench_press',
      );
      expect(exerciseLinkSlug(Uri.parse('gymbar://ex?id=Lat_Pulldown')), 'lat_pulldown');
    });

    test('chybějící nebo nesmyslné id', () {
      expect(exerciseLinkSlug(Uri.parse('https://gymbar.app/ex')), isNull);
      expect(exerciseLinkSlug(Uri.parse('https://gymbar.app/ex?id=')), isNull);
      expect(exerciseLinkSlug(Uri.parse('https://gymbar.app/ex?id=../x')), isNull);
      expect(exerciseLinkSlug(Uri.parse('https://gymbar.app/ex?id=a%20b')), isNull);
    });

    test('všechny vestavěné cviky mají slug, který odkaz projde', () {
      final slugs = seedExercises.map((e) => e.slug).toList();
      expect(slugs.toSet().length, slugs.length);
      for (final s in slugs) {
        expect(exerciseLinkSlug(Uri.parse('https://gymbar.app/ex?id=$s')), s);
      }
    });
  });

  group('doporučení fitku', () {
    test('odkaz na /fitka s posilovnou a kódem', () {
      final url = gymReferralUrl('https://gymbar.app', 'osm-n123', 'abcd1234');
      expect(url, 'https://gymbar.app/fitka?gym=osm-n123&ref=abcd1234');
      final uri = Uri.parse(url);
      expect(uri.queryParameters['gym'], 'osm-n123');
    });

    test('kód doporučení je stabilní, krátký a neprozradí uid', () {
      final a = gymReferralRef('uid-12345');
      expect(a, hasLength(8));
      expect(a, gymReferralRef('uid-12345'));
      expect(a, isNot(gymReferralRef('uid-12346')));
      expect(a.contains('uid'), isFalse);
    });

    test('ID záznamu odpovídá pravidlům ({gymId}_{uid})', () {
      expect(gymReferralDocId('gym1', 'u1'), 'gym1_u1');
    });
  });
}
