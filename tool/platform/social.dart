import 'dart:io';

/// Nativní nastavení pro modul „social“ (Firebase, přihlášení Google
/// a Apple, push notifikace, skenování QR). Doplňuje to, co neudělá
/// `flutterfire configure`. Bezpečné spustit opakovaně.
///
/// Android: minSdk alespoň 23 (Firebase).
/// iOS: URL schéma a GIDClientID pro Google Sign-In (z
///   GoogleService-Info.plist), popis fotoaparátu, push na pozadí,
///   entitlements (Sign in with Apple, push) a CODE_SIGN_ENTITLEMENTS.
bool patchSocial() {
  var ok = true;
  ok &= _androidMinSdk();
  ok &= _iosInfoPlist();
  ok &= _iosEntitlements();
  ok &= _iosProject();
  return ok;
}

const _minSdk = 23;
const _entitlementsPath = 'ios/Runner/Runner.entitlements';
const _entitlementsSetting = 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;';

// ---------------------------------------------------------------- Android

bool _androidMinSdk() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final file = kts.existsSync() ? kts : groovy;
  if (!file.existsSync()) {
    stderr.writeln('✗ android/app/build.gradle(.kts) nenalezen.');
    return false;
  }
  final kotlin = file == kts;
  var s = file.readAsStringSync();
  // minSdk = … (Kotlin i novější Groovy) nebo minSdkVersion … (starší Groovy).
  final m = RegExp(r'(minSdk(?:Version)?)(\s*=\s*|[ \t]+)([^\n]+)')
      .firstMatch(s);
  if (m == null) {
    stderr.writeln('✗ ${file.path}: minSdk nenalezen – nastav ho ručně '
        'alespoň na $_minSdk.');
    return false;
  }
  final value = m.group(3)!.trim();
  final number = int.tryParse(value);
  if (number != null && number >= _minSdk) {
    stdout.writeln('• ${file.path}: minSdk $number je v pořádku.');
    return true;
  }
  if (value.contains('$_minSdk)')) {
    stdout.writeln('• ${file.path}: minSdk už upraven.');
    return true;
  }
  // flutter.minSdkVersion apod. ponechat, ale aspoň 23.
  final newValue = number != null
      ? '$_minSdk'
      : kotlin
          ? 'maxOf($value, $_minSdk)'
          : 'Math.max($value, $_minSdk)';
  s = s.replaceRange(m.start, m.end, '${m.group(1)}${m.group(2)}$newValue');
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: minSdk alespoň $_minSdk (Firebase).');
  return true;
}

// ---------------------------------------------------------------- iOS

String? _plistString(String plist, String key) {
  final m = RegExp('<key>${RegExp.escape(key)}</key>\\s*<string>([^<]*)</string>')
      .firstMatch(plist);
  return m?.group(1)?.trim();
}

/// Index konce pole, které začíná na [arrayStart] (`<array>`), s ohledem
/// na vnořená pole. Vrací index znaku `<` uzavíracího `</array>`.
int _matchingArrayEnd(String s, int arrayStart) {
  var depth = 0;
  final tag = RegExp(r'<array>|</array>|<array\s*/>');
  for (final m in tag.allMatches(s, arrayStart)) {
    final t = m.group(0)!;
    if (t == '<array>') {
      depth++;
    } else if (t == '</array>') {
      depth--;
      if (depth == 0) return m.start;
    }
  }
  return -1;
}

/// Přidá [item] (XML) na konec pole pod klíčem [key], nebo klíč s polem
/// vytvoří. Vrací upravený text, nebo null, když se pole nedá najít.
String? _appendToArray(String s, String key, String item) {
  final keyTag = '<key>$key</key>';
  final k = s.indexOf(keyTag);
  if (k < 0) {
    final i = s.lastIndexOf('</dict>');
    if (i < 0) return null;
    return s.replaceRange(
        i, i, '\t$keyTag\n\t<array>\n$item\t</array>\n');
  }
  final after = k + keyTag.length;
  final empty = RegExp(r'^\s*<array\s*/>').firstMatch(s.substring(after));
  if (empty != null) {
    return s.replaceRange(
        after, after + empty.end, '\n\t<array>\n$item\t</array>');
  }
  final open = s.indexOf('<array>', after);
  if (open < 0 || s.substring(after, open).trim().isNotEmpty) return null;
  final close = _matchingArrayEnd(s, open);
  if (close < 0) return null;
  // Vložit na začátek řádku s </array> (kvůli odsazení).
  final lineStart = s.lastIndexOf('\n', close) + 1;
  final at = s.substring(lineStart, close).trim().isEmpty ? lineStart : close;
  return s.replaceRange(at, at, item);
}

bool _iosInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final original = s;
  var ok = true;

  // Google Sign-In: CLIENT_ID a REVERSED_CLIENT_ID z GoogleService-Info.plist
  // (vytvoří ho `flutterfire configure`, když je v konzoli zapnutý Google).
  final google = File('ios/Runner/GoogleService-Info.plist');
  final googlePlist = google.existsSync() ? google.readAsStringSync() : '';
  final clientId = _plistString(googlePlist, 'CLIENT_ID');
  final reversed = _plistString(googlePlist, 'REVERSED_CLIENT_ID');
  if (reversed == null || clientId == null) {
    stdout.writeln('! ${google.path}: chybí CLIENT_ID / REVERSED_CLIENT_ID. '
        'Zapni ve Firebase přihlášení přes Google, spusť znovu '
        '`flutterfire configure` a pak tento skript (docs/social.md).');
  } else {
    if (!s.contains('<key>GIDClientID</key>')) {
      final i = s.lastIndexOf('</dict>');
      if (i >= 0) {
        s = s.replaceRange(
            i, i, '\t<key>GIDClientID</key>\n\t<string>$clientId</string>\n');
      }
    }
    if (!s.contains('<string>$reversed</string>')) {
      // Pole CFBundleURLTypes už může obsahovat schéma fitnessapp
      // (tool/platform/links.dart) – přidáme další <dict>.
      final dict = '\t\t<dict>\n'
          '\t\t\t<key>CFBundleTypeRole</key>\n'
          '\t\t\t<string>Editor</string>\n'
          '\t\t\t<key>CFBundleURLSchemes</key>\n'
          '\t\t\t<array>\n'
          '\t\t\t\t<string>$reversed</string>\n'
          '\t\t\t</array>\n'
          '\t\t</dict>\n';
      final updated = _appendToArray(s, 'CFBundleURLTypes', dict);
      if (updated == null) {
        stderr.writeln('✗ ${file.path}: pole CFBundleURLTypes se nepodařilo '
            'upravit – přidej schéma $reversed ručně.');
        ok = false;
      } else {
        s = updated;
      }
    }
  }

  // Skenování QR kódu přítele.
  if (!s.contains('<key>NSCameraUsageDescription</key>')) {
    final i = s.lastIndexOf('</dict>');
    if (i >= 0) {
      s = s.replaceRange(
          i,
          i,
          '\t<key>NSCameraUsageDescription</key>\n'
          '\t<string>Fotoaparát slouží ke skenování QR kódu přítele.</string>\n');
    }
  }

  // Push notifikace na pozadí (firebase_messaging).
  final modesKey = s.indexOf('<key>UIBackgroundModes</key>');
  final hasRemote = modesKey >= 0 &&
      () {
        final open = s.indexOf('<array>', modesKey);
        final close = open < 0 ? -1 : _matchingArrayEnd(s, open);
        return close > 0 &&
            s.substring(open, close).contains('<string>remote-notification</string>');
      }();
  if (!hasRemote) {
    final updated = _appendToArray(
        s, 'UIBackgroundModes', '\t\t<string>remote-notification</string>\n');
    if (updated == null) {
      stderr.writeln('✗ ${file.path}: UIBackgroundModes se nepodařilo upravit '
          '– přidej remote-notification ručně.');
      ok = false;
    } else {
      s = updated;
    }
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: Google Sign-In, fotoaparát, push.');
  } else {
    stdout.writeln('• ${file.path}: přátelé už nastavení.');
  }
  return ok;
}

/// Sign in with Apple a push (APNs). Soubor může už existovat (HealthKit
/// z modulu health) – klíče se doplní, nic se nepřepisuje.
bool _iosEntitlements() {
  if (!Directory('ios/Runner').existsSync()) return true;
  final file = File(_entitlementsPath);
  const keys = {
    'com.apple.developer.applesignin':
        '\t<key>com.apple.developer.applesignin</key>\n'
            '\t<array>\n\t\t<string>Default</string>\n\t</array>\n',
    // Při exportu pro App Store se hodnota změní na production podle
    // provisioning profilu.
    'aps-environment':
        '\t<key>aps-environment</key>\n\t<string>development</string>\n',
  };
  if (!file.existsSync()) {
    file.writeAsStringSync('<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n<dict>\n'
        '${keys.values.join()}'
        '</dict>\n</plist>\n');
    stdout.writeln('✓ ${file.path}: vytvořen (Sign in with Apple, push).');
    return true;
  }
  var s = file.readAsStringSync();
  final add = StringBuffer();
  keys.forEach((k, v) {
    if (!s.contains('<key>$k</key>')) add.write(v);
  });
  if (add.isEmpty) {
    stdout.writeln('• ${file.path}: už upraveno.');
    return true;
  }
  var i = s.lastIndexOf('</dict>');
  if (i < 0) {
    // Prázdný slovník <dict/>.
    final empty = s.indexOf('<dict/>');
    if (empty < 0) {
      stderr.writeln('✗ ${file.path}: neznámý formát – doplň klíče ručně.');
      return false;
    }
    s = s.replaceRange(empty, empty + '<dict/>'.length, '<dict>\n</dict>');
    i = s.lastIndexOf('</dict>');
  }
  s = s.replaceRange(i, i, add.toString());
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: doplněno Sign in with Apple a push.');
  return true;
}

/// CODE_SIGN_ENTITLEMENTS do konfigurací cíle Runner (Debug/Release/Profile).
/// Konfigurace Runneru poznáme podle INFOPLIST_FILE = Runner/Info.plist.
bool _iosProject() {
  final file = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!file.existsSync()) {
    stdout.writeln('• ${file.path} nenalezen – iOS přeskočeno.');
    return true;
  }
  var s = file.readAsStringSync();
  final blocks = RegExp(r'buildSettings = \{').allMatches(s).toList();
  var changed = 0;
  // Odzadu, ať se indexy předchozích bloků neposunou.
  for (final b in blocks.reversed) {
    final end = s.indexOf('\n\t\t\t};', b.end);
    if (end < 0) continue;
    final body = s.substring(b.end, end);
    if (!body.contains('INFOPLIST_FILE = Runner/Info.plist;')) continue;
    if (body.contains('CODE_SIGN_ENTITLEMENTS')) continue;
    s = s.replaceRange(b.end, b.end, '\n\t\t\t\t$_entitlementsSetting');
    changed++;
  }
  if (changed == 0) {
    stdout.writeln('• ${file.path}: entitlements už nastavené.');
    return true;
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: CODE_SIGN_ENTITLEMENTS ($changed×).');
  return true;
}
