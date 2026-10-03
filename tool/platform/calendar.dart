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

/// Popis plného přístupu ke kalendáři teď zmiňuje i čtení událostí
/// (hledání volného času). Přepíše jen původní výchozí text.
const _oldFullAccess =
    'Aplikace přidává naplánované tréninky do kalendáře a při změně plánu je upraví.';
const _newFullAccess =
    'Aplikace přidává naplánované tréninky do kalendáře a – pokud to zapneš – '
    'hledá v něm volný čas a upozorní na kolize. Události z telefonu nikam neodesílá.';

bool _ios() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  final s = file.readAsStringSync();
  if (!s.contains(_oldFullAccess)) {
    stdout.writeln('• ${file.path}: popis kalendáře už upravený.');
    return true;
  }
  file.writeAsStringSync(s.replaceAll(_oldFullAccess, _newFullAccess));
  stdout.writeln('✓ ${file.path}: popis čtení kalendáře.');
  return true;
}
