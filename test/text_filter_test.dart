import 'package:fitness_app/core/text_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('containsSevereProfanity', () {
    test('hrubá slova a urážky skupin', () {
      for (final t in [
        'Pičus',
        'PIČA',
        'kunda z Brna',
        'Nigger',
        'n1gg3r',
        'N i g g e r',
        'HitlerFan',
        'Sieg Heil',
        'buzerant',
        'Fotze',
        'p0rn king',
        'PičaMan',
        'Niggggger',
      ]) {
        expect(containsSevereProfanity(t), isTrue, reason: t);
      }
    });

    test('hovorové nadávky a běžná jména projdou', () {
      for (final t in [
        'Kurva Gym',
        'hovno',
        'Do prdele',
        'Shit happens',
        'Mierda',
        'Scunthorpe',
        'Dick',
        'Kike',
        'Fitness Picasso',
        'Nigeria Gym',
        'Pedro',
        'Tomáš',
        'Žebříček Jičín',
        'Kokos',
        'Pico de Orizaba',
        'ČEPEK',
      ]) {
        expect(containsSevereProfanity(t), isFalse, reason: t);
      }
    });

    test('normalizace slov', () {
      expect(profanityTokens('PičaMan 3000!'), ['pica', 'man', 'eooi']);
      expect(profanityTokens('aaaahoj'), ['aahoj']);
    });
  });

  test('publicTextOr', () {
    expect(publicTextOr('Tom', '?'), 'Tom');
    expect(publicTextOr('kunda', '?'), '?');
  });
}
