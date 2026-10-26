// Aplikace pro Apple Watch (ios/GymBarWatch) mluví stejným protokolem jako
// Wear OS a má stejné texty – hlídá, že se nerozejdou.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Swift čte všechna pole stavu, která telefon posílá', () {
    final dart = File('lib/modules/wear/wear_protocol.dart').readAsStringSync();
    final swift =
        File('ios/GymBarWatch/WatchProtocol.swift').readAsStringSync();
    // Klíče z toJson() stavu, série a cviku.
    final keys = <String>{};
    for (final cls in ['WearCurrentSet', 'WearExerciseItem', 'WearState']) {
      final start = dart.indexOf('class $cls ');
      final toJson = dart.indexOf('toJson() => {', start);
      final end = dart.indexOf('};', toJson);
      keys.addAll(RegExp(r"'(\w+)':")
          .allMatches(dart.substring(toJson, end))
          .map((m) => m.group(1)!));
    }
    expect(keys, containsAll(['b', 'ex', 'set', 'phase', 'restEnd']));
    for (final k in keys) {
      expect(swift, contains('m["$k"]'), reason: 'pole $k');
    }
    // Příkazy hodinek.
    for (final cmd in RegExp(r"String get name => '(\w+)';")
        .allMatches(dart)
        .map((m) => m.group(1)!)) {
      expect(swift, contains('"$cmd"'), reason: 'příkaz $cmd');
    }
  });

  test('texty Apple Watch odpovídají wear/lib/strings.dart', () async {
    final result =
        await Process.run('python3', ['tool/ios_watch_strings.py', '--check']);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}
