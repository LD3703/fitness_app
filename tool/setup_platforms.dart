// Jednorázová úprava nativních souborů Androidu a iOS pro pluginy
// upozornění a kalendáře. Skript je bezpečné spustit opakovaně –
// co už v souboru je, znovu nepřidá.
//
// Spuštění z kořene projektu:  dart run tool/setup_platforms.dart
// (s volbou --ios-widget zapne i iOS widget a Live Activity,
// docs/ios_widget.md; s --ios-watch aplikaci pro Apple Watch,
// docs/apple_watch.md).
import 'dart:io';

import 'platform/branding.dart';
import 'platform/ios_store.dart';
import 'platform/ios_watch.dart';
import 'platform/ios_widget.dart';
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
// [platform-imports:wear]
import 'platform/wear.dart';
//
// [platform-imports:crash]
import 'platform/crash.dart';
//
// [platform-imports:signing]
import 'platform/signing.dart';
//

void main(List<String> args) {
  var ok = true;
  ok &= _patchGradle();
  ok &= _patchManifest();
  ok &= _patchInfoPlist();
  ok &= _patchAppDelegate();
  ok &= patchLinks();
  ok &= patchBranding();
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
  // App Store: PrivacyInfo.xcprivacy, jen iPhone, Universal Links
  // (po patchSocial – ten založí Runner.entitlements).
  ok &= patchIosStore();
  // iOS widget a Live Activity: jen s --ios-widget (potřebuje App Group
  // v Apple Developer účtu); když už je v projektu, jen ho udrží.
  ok &= patchIosWidget(enable: args.contains('--ios-widget'));
  // Apple Watch: jen s --ios-watch (potřebuje App ID …watchkitapp v Apple
  // Developer účtu, docs/apple_watch.md); jakmile je v projektu, udržuje se.
  ok &= patchIosWatch(enable: args.contains('--ios-watch'));
  //
  // [platform:wear]
  ok &= patchWear();
  //
  // [platform:crash]
  ok &= patchCrash();
  //
  // [platform:signing]
  ok &= patchSigning();
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
  // Posilovny v okolí (jen když aplikace běží; Android 12+ nabídne
  // i přibližnou polohu).
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.ACCESS_FINE_LOCATION',
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

/// Popisy oprávnění v Info.plist. Anglicky: aplikace je pro celý svět
/// (10 jazyků) a texty čte i kontrola Applu. Překlad by šel přidat
/// soubory InfoPlist.strings v Xcode (README, kapitola 2c).
const _plistKeys = {
  'NSCalendarsUsageDescription':
      'The app adds your planned workouts to your calendar.',
  // Modul calendar (tool/platform/calendar.dart) text pak rozšíří
  // o hledání volného času.
  'NSCalendarsFullAccessUsageDescription':
      'The app adds your planned workouts to your calendar and updates them '
          'when your plan changes.',
  'NSCalendarsWriteOnlyAccessUsageDescription':
      'The app adds your planned workouts to your calendar.',
  // Sdílení obrázků (karta tréninku, plakát s QR kódem) přes systémovou
  // nabídku: bez tohoto klíče aplikace při „Uložit obrázek“ spadne.
  'NSPhotoLibraryAddUsageDescription':
      'The app saves the workout cards and images you share to your photo '
          'library when you choose Save Image.',
  // Posilovny v okolí (geolocator). Aplikace žádá jen „při používání“;
  // klíč Always vyžaduje knihovna, i když se nepoužívá.
  'NSLocationWhenInUseUsageDescription':
      'Your location is used to show gyms near you and, if you choose, to '
          'save the location of a gym you add. It is not stored otherwise.',
  'NSLocationAlwaysAndWhenInUseUsageDescription':
      'Your location is used to show gyms near you while you use the app. '
          'GymBar does not track your location in the background.',
};

/// Dřívější české výchozí texty. Má-li je Info.plist beze změny, nahradí
/// se anglickými z [_plistKeys]; vlastní text (cokoli jiného) zůstane.
const _legacyPlistValues = <String, List<String>>{
  'NSCalendarsUsageDescription': [
    'Aplikace přidává naplánované tréninky do kalendáře.',
  ],
  'NSCalendarsFullAccessUsageDescription': [
    'Aplikace přidává naplánované tréninky do kalendáře a při změně plánu je upraví.',
  ],
  'NSCalendarsWriteOnlyAccessUsageDescription': [
    'Aplikace přidává naplánované tréninky do kalendáře.',
  ],
};

const _languages = [
  'en', 'cs', 'de', 'es', 'fr', 'pl', 'pt', 'it', 'sk', 'nl',
];

/// Nahradí text pod klíčem [key], je-li jedním z [legacy]. Když klíč chybí
/// nebo má vlastní text, vrátí [plist] beze změny.
String _replaceLegacyString(
  String plist,
  String key,
  List<String> legacy,
  String value,
) {
  final m = RegExp(
    '(<key>${RegExp.escape(key)}</key>\\s*<string>)([^<]*)(</string>)',
  ).firstMatch(plist);
  if (m == null || !legacy.contains(m.group(2)!.trim())) return plist;
  return plist.replaceRange(
      m.start, m.end, '${m.group(1)}$value${m.group(3)}');
}

bool _patchInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final original = s;
  final done = <String>[];

  // 1) Dřívější české výchozí popisy → anglické.
  final beforeLegacy = s;
  for (final e in _legacyPlistValues.entries) {
    s = _replaceLegacyString(s, e.key, e.value, _plistKeys[e.key]!);
  }
  if (s != beforeLegacy) done.add('popisy oprávnění anglicky');

  // 2) Chybějící klíče.
  final add = StringBuffer();
  final added = <String>[];
  _plistKeys.forEach((k, v) {
    if (!s.contains('<key>$k</key>')) {
      add.write('\t<key>$k</key>\n\t<string>$v</string>\n');
      added.add(k);
    }
  });
  // Aplikace používá jen standardní šifrování (HTTPS), které je z exportních
  // pravidel vyjmuté – App Store Connect se pak u každého buildu neptá.
  if (!s.contains('<key>ITSAppUsesNonExemptEncryption</key>')) {
    add.write('\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n');
    added.add('ITSAppUsesNonExemptEncryption');
  }
  if (added.isNotEmpty) done.add('přidáno ${added.join(', ')}');

  // 3) Jazyky aplikace – iOS podle nich ukáže systémové texty ve správném
  //    jazyce a v Nastavení nabídne volbu jazyka aplikace.
  final locKey = s.indexOf('<key>CFBundleLocalizations</key>');
  if (locKey >= 0) {
    // Doplnění nových jazyků do už existujícího seznamu.
    final arrEnd = s.indexOf('</array>', locKey);
    if (arrEnd > 0) {
      final existing = s.substring(locKey, arrEnd);
      final missing = [
        for (final lang in _languages)
          if (!existing.contains('<string>$lang</string>')) lang,
      ];
      if (missing.isNotEmpty) {
        s = s.replaceRange(arrEnd, arrEnd,
            missing.map((l) => '\t<string>$l</string>\n\t').join());
        done.add('doplněny jazyky ${missing.join(', ')}');
      }
    }
  } else {
    add.write('\t<key>CFBundleLocalizations</key>\n\t<array>\n');
    for (final lang in _languages) {
      add.write('\t\t<string>$lang</string>\n');
    }
    add.write('\t</array>\n');
    done.add('jazyky');
  }

  if (add.isNotEmpty) {
    final i = s.lastIndexOf('</dict>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, add.toString());
  }
  if (s == original) {
    stdout.writeln('• ${file.path}: už upraveno.');
    return true;
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: ${done.join('; ')}.');
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
  s = s.replaceRange(brace + 1, brace + 1, '''

    UNUserNotificationCenter.current().delegate =
      self as? UNUserNotificationCenterDelegate''');
  if (!s.contains('import UserNotifications')) {
    s = s.replaceFirst('import UIKit', 'import UIKit\nimport UserNotifications');
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: upozornění i při otevřené aplikaci.');
  return true;
}
