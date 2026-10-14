import 'dart:io';

/// Modul calendar: akce v notifikacích (Android) a popis oprávnění
/// ke čtení kalendáře (iOS).
bool patchCalendar() {
  var ok = true;
  ok &= _android();
  ok &= _ios();
  return ok;
}

/// Akce „Počítám s tím“ neotevírá aplikaci – na Androidu ji přijímá
/// ActionBroadcastReceiver balíčku flutter_local_notifications.
bool _android() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  final s = file.readAsStringSync();
  if (s.contains('ActionBroadcastReceiver')) {
    stdout.writeln('• ${file.path}: akce notifikací už nastavené.');
    return true;
  }
  final i = s.lastIndexOf('</application>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
    return false;
  }
  const receiver = '    <receiver android:exported="false"\n'
      '            android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />\n    ';
  file.writeAsStringSync(s.replaceRange(i, i, receiver));
  stdout.writeln('✓ ${file.path}: akce notifikací.');
  return true;
}

/// Popis plného přístupu ke kalendáři zmiňuje i čtení událostí (hledání
/// volného času). Anglicky jako ostatní popisy (_plistKeys v
/// tool/setup_platforms.dart). Přepíše jen dřívější výchozí texty,
/// vlastní text zůstane.
const _fullAccessKey = 'NSCalendarsFullAccessUsageDescription';
const _fullAccess = 'The app adds your planned workouts to your calendar '
    'and, if you turn this on, looks for free time and warns you about '
    'conflicts. Your calendar events never leave your phone.';
const _legacyFullAccess = [
  // Základní text z tool/setup_platforms.dart (anglický i dřívější český).
  'The app adds your planned workouts to your calendar and updates them '
      'when your plan changes.',
  'Aplikace přidává naplánované tréninky do kalendáře a při změně plánu je upraví.',
  // Dřívější český text tohoto modulu.
  'Aplikace přidává naplánované tréninky do kalendáře a – pokud to zapneš – '
      'hledá v něm volný čas a upozorní na kolize. Události z telefonu nikam neodesílá.',
];

bool _ios() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  final s = file.readAsStringSync();
  final m = RegExp(
    '(<key>$_fullAccessKey</key>\\s*<string>)([^<]*)(</string>)',
  ).firstMatch(s);
  if (m == null || !_legacyFullAccess.contains(m.group(2)!.trim())) {
    stdout.writeln('• ${file.path}: popis kalendáře už upravený.');
    return true;
  }
  file.writeAsStringSync(
    s.replaceRange(m.start, m.end, '${m.group(1)}$_fullAccess${m.group(3)}'),
  );
  stdout.writeln('✓ ${file.path}: popis čtení kalendáře.');
  return true;
}
