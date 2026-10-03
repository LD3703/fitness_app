import 'dart:io';

// Health Connect (Android) a HealthKit / Apple Zdraví (iOS) pro balíček
// `health` (13.x). Skript je idempotentní – co už v souborech je, znovu
// nepřidá a nic cizího nepřepisuje.

/// Balíček health vyžaduje Android 8.0 (API 26).
const _minSdk = 26;

/// Balíček health 13.3.2+ vyžaduje iOS 15.0.
const _iosTarget = '15.0';

const _entitlementsPath = 'Runner/Runner.entitlements';
const _appBundleId = 'cz.dedina.fitnessApp';

const _healthPermissions = [
  // Zápis tréninku (ExerciseSessionRecord) a jeho energie
  // (TotalCaloriesBurnedRecord).
  'android.permission.health.WRITE_EXERCISE',
  'android.permission.health.WRITE_TOTAL_CALORIES_BURNED',
  // Tělesná váha oběma směry.
  'android.permission.health.READ_WEIGHT',
  'android.permission.health.WRITE_WEIGHT',
  // Import váhy starší než 30 dní před udělením oprávnění.
  'android.permission.health.READ_HEALTH_DATA_HISTORY',
];

const _rationaleAction = 'androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE';
const _healthConnectPackage = 'com.google.android.apps.healthdata';

const _plistKeys = {
  'NSHealthShareUsageDescription':
      'Aplikace čte tvou tělesnou váhu z Apple Zdraví, aby ji měla i v přehledu pokroku.',
  'NSHealthUpdateUsageDescription':
      'Aplikace ukládá tvoje tréninky a tělesnou váhu do Apple Zdraví.',
};

bool patchHealth() {
  var ok = true;
  ok &= _manifest();
  ok &= _mainActivity();
  ok &= _gradleMinSdk();
  ok &= _infoPlist();
  ok &= _entitlements();
  ok &= _xcodeProject();
  ok &= _podfile();
  return ok;
}

// ---------------------------------------------------------------- Android

bool _manifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;

  // 1) Oprávnění Health Connect
  final missing = [
    for (final p in _healthPermissions)
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

  // 2) Vysvětlení oprávnění (Android 13 a starší): intent-filter v MainActivity
  final activity =
      RegExp(r'<activity[^>]*android:name="\.MainActivity"').firstMatch(s);
  final end = activity == null ? -1 : s.indexOf('</activity>', activity.end);
  if (activity == null || end < 0) {
    stderr.writeln('✗ ${file.path}: MainActivity nenalezena.');
    return false;
  }
  if (!s
      .substring(activity.start, end)
      .contains('<action android:name="$_rationaleAction"')) {
    s = s.replaceRange(end, end, '''    <!-- Health Connect: vysvětlení oprávnění (Android 13 a starší) -->
            <intent-filter>
                <action android:name="$_rationaleAction" />
            </intent-filter>
        ''');
  }

  // 3) Vysvětlení oprávnění (Android 14+): activity-alias
  if (!s.contains('android.intent.action.VIEW_PERMISSION_USAGE')) {
    final i = s.lastIndexOf('</application>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, '''    <!-- Health Connect: vysvětlení oprávnění (Android 14+) -->
        <activity-alias
            android:name="ViewPermissionUsageActivity"
            android:exported="true"
            android:targetActivity=".MainActivity"
            android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
            <intent-filter>
                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
            </intent-filter>
        </activity-alias>
    ''');
  }

  // 4) <queries>: zjištění, jestli je Health Connect nainstalovaný.
  final queryItems = <String>[
    if (!s.contains('<package android:name="$_healthConnectPackage"'))
      '        <package android:name="$_healthConnectPackage" />',
    if (!RegExp(r'<queries>([\s\S]*?)</queries>')
        .allMatches(s)
        .any((m) => m.group(1)!.contains('"$_rationaleAction"')))
      '''        <intent>
            <action android:name="$_rationaleAction" />
        </intent>''',
  ];
  if (queryItems.isNotEmpty) {
    final q = s.indexOf('<queries>');
    if (q >= 0) {
      final at = q + '<queries>'.length;
      s = s.replaceRange(at, at, '\n${queryItems.join('\n')}');
    } else {
      final i = s.lastIndexOf('</manifest>');
      if (i < 0) {
        stderr.writeln('✗ ${file.path}: značka </manifest> nenalezena.');
        return false;
      }
      s = s.replaceRange(
          i, i, '    <queries>\n${queryItems.join('\n')}\n    </queries>\n');
    }
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: Health Connect (oprávnění, vysvětlení, queries).');
  } else {
    stdout.writeln('• ${file.path}: Health Connect už nastaven.');
  }
  return true;
}

/// Health Connect žádá o oprávnění přes registerForActivityResult –
/// MainActivity musí dědit z FlutterFragmentActivity.
bool _mainActivity() {
  final root = Directory('android/app/src/main');
  if (!root.existsSync()) {
    stderr.writeln('✗ ${root.path} nenalezen.');
    return false;
  }
  final files = [
    for (final dir in ['kotlin', 'java'])
      if (Directory('${root.path}/$dir').existsSync())
        ...Directory('${root.path}/$dir')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) {
          final name = f.uri.pathSegments.last;
          return name == 'MainActivity.kt' || name == 'MainActivity.java';
        }),
  ];
  if (files.isEmpty) {
    stderr.writeln('✗ MainActivity.kt / .java nenalezena v ${root.path}.');
    return false;
  }
  for (final file in files) {
    final s = file.readAsStringSync();
    final patched = s.replaceAll(
      RegExp(r'\bFlutterActivity\b'),
      'FlutterFragmentActivity',
    );
    if (patched != s) {
      file.writeAsStringSync(patched);
      stdout.writeln('✓ ${file.path}: FlutterFragmentActivity.');
    } else if (s.contains('FlutterFragmentActivity')) {
      stdout.writeln('• ${file.path}: už FlutterFragmentActivity.');
    } else {
      stderr.writeln('✗ ${file.path}: nečekaný obsah – MainActivity musí '
          'dědit z io.flutter.embedding.android.FlutterFragmentActivity.');
      return false;
    }
  }
  return true;
}

bool _gradleMinSdk() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final file = kts.existsSync()
      ? kts
      : groovy.existsSync()
          ? groovy
          : null;
  if (file == null) {
    stderr.writeln('✗ android/app/build.gradle(.kts) nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final re = RegExp(
    r'^([ \t]*minSdk(?:Version)?[ \t]*=?[ \t]*)(flutter\.minSdkVersion|\d+)\b',
    multiLine: true,
  );
  final m = re.firstMatch(s);
  if (m == null) {
    stderr.writeln('✗ ${file.path}: řádek minSdk nenalezen – nastav ručně '
        'minSdk = $_minSdk.');
    return false;
  }
  final current = int.tryParse(m.group(2)!);
  if (current != null && current >= _minSdk) {
    stdout.writeln('• ${file.path}: minSdk $current (stačí).');
    return true;
  }
  s = s.replaceRange(m.start, m.end, '${m.group(1)}$_minSdk');
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: minSdk = $_minSdk (Health Connect).');
  return true;
}

// ---------------------------------------------------------------- iOS

bool _infoPlist() {
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
  if (add.isEmpty) {
    stdout.writeln('• ${file.path}: popisy Apple Zdraví už jsou.');
    return true;
  }
  final i = s.lastIndexOf('</dict>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
    return false;
  }
  s = s.replaceRange(i, i, add.toString());
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: popisy oprávnění Apple Zdraví.');
  return true;
}

/// Vytvoří nebo doplní ios/Runner/Runner.entitlements (jiné klíče,
/// např. Sign in with Apple, zůstanou beze změny).
bool _entitlements() {
  if (!Directory('ios/Runner').existsSync()) return true;
  final file = File('ios/$_entitlementsPath');
  var s = file.existsSync()
      ? file.readAsStringSync()
      : '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
''';
  final original = file.existsSync() ? s : '';
  final add = StringBuffer();
  if (!s.contains('<key>com.apple.developer.healthkit</key>')) {
    add.write('\t<key>com.apple.developer.healthkit</key>\n\t<true/>\n');
  }
  if (!s.contains('<key>com.apple.developer.healthkit.access</key>')) {
    add.write('\t<key>com.apple.developer.healthkit.access</key>\n'
        '\t<array/>\n');
  }
  if (add.isNotEmpty) {
    // Poslední </dict> = konec kořenového slovníku.
    final i = s.lastIndexOf('</dict>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, add.toString());
  }
  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: HealthKit.');
  } else {
    stdout.writeln('• ${file.path}: HealthKit už nastaven.');
  }
  return true;
}

/// CODE_SIGN_ENTITLEMENTS pro konfigurace cíle Runner (ne RunnerTests)
/// a minimální verze iOS 15.0.
bool _xcodeProject() {
  final file = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!file.existsSync()) {
    stdout.writeln('• ${file.path} nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final original = s;

  // 1) Entitlements v konfiguracích aplikace.
  var found = 0;
  var searchFrom = 0;
  while (true) {
    final isa = s.indexOf('isa = XCBuildConfiguration;', searchFrom);
    if (isa < 0) break;
    const open = 'buildSettings = {';
    final start = s.indexOf(open, isa);
    if (start < 0) break;
    final bodyStart = start + open.length;
    final bodyEnd = _matchingBrace(s, bodyStart);
    if (bodyEnd < 0) {
      stderr.writeln('✗ ${file.path}: nečitelný blok buildSettings.');
      return false;
    }
    final body = s.substring(bodyStart, bodyEnd);
    searchFrom = bodyEnd;

    final bundle = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = "?([^";]+)"?;')
        .firstMatch(body)
        ?.group(1);
    final isApp = bundle != null &&
        !bundle.endsWith('Tests') &&
        (bundle == _appBundleId ||
            body.contains('INFOPLIST_FILE = Runner/Info.plist;'));
    if (!isApp) continue;
    found++;

    final existing = RegExp(r'CODE_SIGN_ENTITLEMENTS = "?([^";]+)"?;')
        .firstMatch(body)
        ?.group(1);
    if (existing != null) {
      if (existing != _entitlementsPath) {
        stderr.writeln('✗ ${file.path}: CODE_SIGN_ENTITLEMENTS = $existing '
            '(čekáno $_entitlementsPath) – doplň HealthKit do toho souboru.');
      }
      continue;
    }
    // Odsazení podle prvního řádku nastavení.
    final indent =
        RegExp(r'\n([ \t]+)\S').firstMatch(body)?.group(1) ?? '\t\t\t\t';
    final line = '\n${indent}CODE_SIGN_ENTITLEMENTS = $_entitlementsPath;';
    s = s.replaceRange(bodyStart, bodyStart, line);
    searchFrom = bodyEnd + line.length;
  }
  if (found == 0) {
    stderr.writeln('✗ ${file.path}: konfigurace cíle Runner nenalezeny '
        '(PRODUCT_BUNDLE_IDENTIFIER = $_appBundleId).');
    return false;
  }

  // 2) iOS 15.0 jako minimum (balíček health).
  s = s.replaceAllMapped(
    RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);'),
    (m) => _versionLess(m.group(1)!, _iosTarget)
        ? 'IPHONEOS_DEPLOYMENT_TARGET = $_iosTarget;'
        : m.group(0)!,
  );

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: HealthKit entitlements, iOS $_iosTarget.');
  } else {
    stdout.writeln('• ${file.path}: HealthKit už nastaven.');
  }
  return true;
}

/// Podfile (pokud už existuje): platform :ios aspoň 15.0.
bool _podfile() {
  final file = File('ios/Podfile');
  if (!file.existsSync()) return true; // Flutter ho vytvoří podle projektu.
  final s = file.readAsStringSync();
  final re = RegExp(r"^[ \t]*#?[ \t]*platform :ios, '([0-9.]+)'", multiLine: true);
  final m = re.firstMatch(s);
  if (m == null) {
    final patched = "platform :ios, '$_iosTarget'\n$s";
    file.writeAsStringSync(patched);
    stdout.writeln('✓ ${file.path}: platform :ios, $_iosTarget.');
    return true;
  }
  final commented = m.group(0)!.trimLeft().startsWith('#');
  if (!commented && !_versionLess(m.group(1)!, _iosTarget)) {
    stdout.writeln('• ${file.path}: platform :ios ${m.group(1)} (stačí).');
    return true;
  }
  file.writeAsStringSync(
    s.replaceRange(m.start, m.end, "platform :ios, '$_iosTarget'"),
  );
  stdout.writeln('✓ ${file.path}: platform :ios, $_iosTarget.');
  return true;
}

/// Index uzavírací `}` k bloku, jehož obsah začíná na [from].
int _matchingBrace(String s, int from) {
  var depth = 1;
  for (var i = from; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c == 0x7B) depth++; // {
    if (c == 0x7D) {
      // }
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

bool _versionLess(String a, String b) {
  final pa = a.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  final pb = b.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}
