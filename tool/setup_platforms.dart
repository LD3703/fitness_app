// Jednorázová úprava nativních souborů Androidu a iOS pro pluginy
// upozornění a kalendáře. Skript je bezpečné spustit opakovaně –
// co už v souboru je, znovu nepřidá.
//
// Spuštění z kořene projektu:  dart run tool/setup_platforms.dart
import 'dart:io';

import 'platform/links.dart';

// Úpravy pro jednotlivé moduly verzí 2 a 3 jsou v tool/platform/.
// [platform-imports:stats]
//
// [platform-imports:sharing]
//
// [platform-imports:calendar]
import 'platform/calendar.dart';
//
// [platform-imports:widgets]
import 'platform/widgets.dart';
//
// [platform-imports:health]
import 'platform/health.dart';
//
// [platform-imports:data]
//
// [platform-imports:social]
import 'platform/social.dart';
//

void main() {
  var ok = true;
  ok &= _patchGradle();
  ok &= _patchManifest();
  ok &= _patchInfoPlist();
  ok &= _patchAppDelegate();
  ok &= patchLinks();
  // [platform:stats]
  //
  // [platform:sharing]
  //
  // [platform:calendar]
  ok &= patchCalendar();
  //
  // [platform:widgets]
  ok &= patchWidgets();
  //
  // [platform:health]
  ok &= patchHealth();
  //
  // [platform:data]
  //
  // [platform:social]
  ok &= patchSocial();
  //
  stdout.writeln(ok
      ? '\nHotovo. Teď spusť: flutter clean && flutter run'
      : '\nNěkteré soubory se nepodařilo upravit – viz výpis výše.');
  if (!ok) exitCode = 1;
}

// ---------------------------------------------------------------- Gradle

bool _patchGradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) return _patchGradleFile(kts, kotlin: true);
  if (groovy.existsSync()) return _patchGradleFile(groovy, kotlin: false);
  stderr.writeln('✗ android/app/build.gradle(.kts) nenalezen.');
  return false;
}

bool _patchGradleFile(File file, {required bool kotlin}) {
  var s = file.readAsStringSync();
  final original = s;

  // 1) Desugaring v compileOptions
  if (!s.contains('isCoreLibraryDesugaringEnabled') &&
      !s.contains('coreLibraryDesugaringEnabled')) {
    final line = kotlin
        ? '        isCoreLibraryDesugaringEnabled = true'
        : '        coreLibraryDesugaringEnabled true';
    final re = RegExp(r'compileOptions\s*\{');
    final m = re.firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: blok compileOptions nenalezen.');
      return false;
    }
    s = s.replaceRange(m.end, m.end, '\n$line');
  }

  // 2) Knihovna pro desugaring v dependencies
  if (!s.contains('desugar_jdk_libs')) {
    final dep = kotlin
        ? '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
        : "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'";
    final re = RegExp(r'^dependencies\s*\{', multiLine: true);
    final m = re.firstMatch(s);
    if (m != null) {
      s = s.replaceRange(m.end, m.end, '\n$dep');
    } else {
      s = '${s.trimRight()}\n\ndependencies {\n$dep\n}\n';
    }
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: přidán desugaring.');
  } else {
    stdout.writeln('• ${file.path}: už upraveno.');
  }
  return true;
}

// ---------------------------------------------------------------- Manifest

const _permissions = [
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.RECEIVE_BOOT_COMPLETED',
  'android.permission.SCHEDULE_EXACT_ALARM',
  'android.permission.VIBRATE',
  'android.permission.READ_CALENDAR',
  'android.permission.WRITE_CALENDAR',
];

const _receivers = '''
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>''';

bool _patchManifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;

  final missing = [
    for (final p in _permissions)
      if (!s.contains('"$p"')) '    <uses-permission android:name="$p" />',
  ];
  if (missing.isNotEmpty) {
    final m = RegExp(r'<manifest[^>]*>').firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: značka <manifest> nenalezena.');
      return false;
    }
    s = s.replaceRange(m.end, m.end, '\n${missing.join('\n')}');
  }

  if (!s.contains('ScheduledNotificationReceiver')) {
    final i = s.lastIndexOf('</application>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, '${_receivers.substring(1)}\n    ');
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: přidána oprávnění a přijímače.');
  } else {
    stdout.writeln('• ${file.path}: už upraveno.');
  }
  return true;
}

// ---------------------------------------------------------------- iOS

const _plistKeys = {
  'NSCalendarsUsageDescription':
      'Aplikace přidává naplánované tréninky do kalendáře.',
  'NSCalendarsFullAccessUsageDescription':
      'Aplikace přidává naplánované tréninky do kalendáře a při změně plánu je upraví.',
  'NSCalendarsWriteOnlyAccessUsageDescription':
      'Aplikace přidává naplánované tréninky do kalendáře.',
};

const _languages = ['en', 'cs', 'de', 'es', 'fr', 'pl'];

bool _patchInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final add = StringBuffer();
  _plistKeys.forEach((k, v) {
    if (!s.contains('<key>$k</key>')) {
      add.write('\t<key>$k</key>\n\t<string>$v</string>\n');
    }
  });
  if (!s.contains('<key>CFBundleLocalizations</key>')) {
    // Jazyky aplikace – iOS podle nich ukáže systémové texty ve správném
    // jazyce a v Nastavení nabídne volbu jazyka aplikace.
    add.write('\t<key>CFBundleLocalizations</key>\n\t<array>\n');
    for (final lang in _languages) {
      add.write('\t\t<string>$lang</string>\n');
    }
    add.write('\t</array>\n');
  }
  if (add.isEmpty) {
    stdout.writeln('• ${file.path}: už upraveno.');
    return true;
  }
  final i = s.lastIndexOf('</dict>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
    return false;
  }
  s = s.replaceRange(i, i, add.toString());
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: přidány popisy oprávnění a jazyky.');
  return true;
}

/// Aby se upozornění na iOS ukázala i při otevřené aplikaci
/// (návod balíčku flutter_local_notifications).
bool _patchAppDelegate() {
  final file = File('ios/Runner/AppDelegate.swift');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/AppDelegate.swift nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  if (s.contains('UNUserNotificationCenter.current().delegate')) {
    stdout.writeln('• ${file.path}: už upraveno.');
    return true;
  }
  final launch = s.indexOf('didFinishLaunchingWithOptions');
  final brace = launch < 0 ? -1 : s.indexOf('{', launch);
  if (brace < 0) {
    stderr.writeln('✗ ${file.path}: metoda didFinishLaunchingWithOptions '
        'nenalezena – upozornění na iOS se při otevřené aplikaci neukážou.');
    return true; // Není kritické, build projde.
  }
  s = s.replaceRange(brace + 1, brace + 1, """

    UNUserNotificationCenter.current().delegate =
      self as? UNUserNotificationCenterDelegate""");
  if (!s.contains('import UserNotifications')) {
    s = s.replaceFirst('import UIKit', 'import UIKit\nimport UserNotifications');
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: upozornění i při otevřené aplikaci.');
  return true;
}
