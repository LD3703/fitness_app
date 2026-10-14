import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymbar_trainer/catalog.dart';
import 'package:gymbar_trainer/strings.dart';

void main() {
  test('obě jazykové mapy mají stejné klíče', () {
    expect(csStrings.keys.toSet(), enStrings.keys.toSet());
  });

  test('každý použitý klíč existuje', () {
    final used = <String>{};
    final re = RegExp(r"\bs\('(\w+)'");
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        used.addAll(re.allMatches(f.readAsStringSync()).map((m) => m[1]!));
      }
    }
    used.remove('klic'); // příklad v komentáři strings.dart
    expect(used.difference(csStrings.keys.toSet()), isEmpty);
  });

  test('partie, vybavení a typy z katalogu mají texty', () {
    final raw = jsonDecode(File('assets/exercises.json').readAsStringSync())
        as List<dynamic>;
    expect(raw, isNotEmpty);
    for (final m in raw.cast<Map<String, dynamic>>()) {
      expect(csStrings, contains('muscle_${m['muscle']}'));
      expect(csStrings, contains('equipment_${m['equipment']}'));
      expect(csStrings, contains('type_${m['type']}'));
    }
    for (final m in [...muscleOrder, ...equipmentOrder, ...typeOrder]) {
      expect(
        csStrings.keys.any((k) => k.endsWith('_$m')),
        isTrue,
        reason: m,
      );
    }
  });

  test('množné číslo', () {
    final cs = S.forLang('cs');
    expect(cs('exercisesCount', {'n': 1}), '1 cvik');
    expect(cs('exercisesCount', {'n': 3}), '3 cviky');
    expect(cs('exercisesCount', {'n': 5}), '5 cviků');
    expect(cs('exercisesCount', {'n': 0}), '0 cviků');
    expect(cs('daysAgo', {'days': 1}), 'před 1 dnem');
    expect(cs('daysAgo', {'days': 12}), 'před 12 dny');
    final en = S.forLang('en');
    expect(en('exercisesCount', {'n': 1}), '1 exercise');
    expect(en('exercisesCount', {'n': 2}), '2 exercises');
    expect(en('weekOf', {'date': '1/2'}), 'Week of 1/2');
  });

  test('vyhledávání bez diakritiky', () {
    expect(foldForSearch('Dřep s činkou'), 'drep s cinkou');
  });
}
