import 'dart:io';

/// Musí odpovídat kAppLinkScheme v lib/modules/links/deep_links.dart.
const _scheme = 'fitnessapp';

/// Odkazy do aplikace (fitnessapp://…) a otevírání webu z aplikace.
bool patchLinks() {
  var ok = true;
  ok &= _android();
  ok &= _ios();
  return ok;
}

bool _android() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;

  if (!s.contains('android:scheme="$_scheme"')) {
    final activity = RegExp(r'<activity[^>]*android:name="\.MainActivity"')
        .firstMatch(s);
    final end = activity == null ? -1 : s.indexOf('</activity>', activity.end);
    if (end < 0) {
      stderr.writeln('✗ ${file.path}: MainActivity nenalezena.');
      return false;
    }
    s = s.replaceRange(end, end, '''    <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="$_scheme" />
            </intent-filter>
        ''');
  }

  // Android 11+: aby šlo z aplikace otevřít web a obchod.
  if (!s.contains('<data android:scheme="https" />')) {
    const queries = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>''';
    final i = s.lastIndexOf('</manifest>');
    if (i < 0) return false;
    s = s.replaceRange(i, i, '${queries.substring(1)}\n');
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: odkazy $_scheme://');
  } else {
    stdout.writeln('• ${file.path}: odkazy už nastavené.');
  }
  return true;
}

bool _ios() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) return true;
  var s = file.readAsStringSync();
  // Odkazy obsluhuje app_links (deep_links.dart). Vestavěný deep linking
  // Flutteru (na iOS od 3.27 zapnutý) by fitnessapp://… předal go_routeru
  // jako cestu a ukázal chybovou stránku. Na Androidu totéž dělá
  // tool/platform/widgets.dart (flutter_deeplinking_enabled).
  if (!s.contains('<key>FlutterDeepLinkingEnabled</key>')) {
    final i = s.lastIndexOf('</dict>');
    if (i < 0) return false;
    s = s.replaceRange(
        i, i, '\t<key>FlutterDeepLinkingEnabled</key>\n\t<false/>\n');
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: FlutterDeepLinkingEnabled = false');
  }
  if (s.contains('<string>$_scheme</string>')) {
    stdout.writeln('• ${file.path}: odkazy už nastavené.');
    return true;
  }
  if (s.contains('<key>CFBundleURLTypes</key>')) {
    stderr.writeln('✗ ${file.path}: CFBundleURLTypes už existuje – '
        'přidej schéma $_scheme ručně.');
    return false;
  }
  final i = s.lastIndexOf('</dict>');
  if (i < 0) return false;
  s = s.replaceRange(i, i, '''\t<key>CFBundleURLTypes</key>
\t<array>
\t\t<dict>
\t\t\t<key>CFBundleURLName</key>
\t\t\t<string>cz.dedina.fitnessApp</string>
\t\t\t<key>CFBundleURLSchemes</key>
\t\t\t<array>
\t\t\t\t<string>$_scheme</string>
\t\t\t</array>
\t\t</dict>
\t</array>
''');
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: odkazy $_scheme://');
  return true;
}
