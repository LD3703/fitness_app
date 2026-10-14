import 'dart:io';

/// Musí odpovídat kAppLinkScheme v lib/modules/links/deep_links.dart.
const _scheme = 'gymbar';

/// Web, jehož odkazy otevírají rovnou aplikaci (Android App Links).
/// Musí odpovídat kWebBaseUrl v lib/modules/links/deep_links.dart; ověření
/// zajišťuje docs/web/.well-known/assetlinks.json (tool/assetlinks.dart).
const _webHost = 'gymbar.app';

/// Cesty webu, které obsluhuje aplikace (deep_links.dart, firebase.json).
const _webPaths = ['/challenge', '/friend', '/gym', '/coach', '/plan'];

/// Schéma z doby před názvem GymBar – skript ho v už upravených
/// souborech přepíše na [_scheme], aby aplikace nezůstala na starém.
const _legacyScheme = 'fitnessapp';

/// Odkazy do aplikace (gymbar://… i https://gymbar.app/…) a otevírání
/// webu z aplikace.
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
  s = s.replaceAll(
      'android:scheme="$_legacyScheme"', 'android:scheme="$_scheme"');

  final additions = StringBuffer();
  if (!s.contains('android:scheme="$_scheme"')) {
    additions.write('''    <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="$_scheme" />
            </intent-filter>
        ''');
  }
  // App Links: https://gymbar.app/challenge|friend|gym otevře rovnou
  // aplikaci (bez dotazu „Otevřít v…“), když web vrací assetlinks.json
  // s otiskem klíče, kterým je aplikace podepsaná.
  // Filtr už existuje (dřívější verze) – doplnit chybějící cesty.
  final hostLine = '<data android:host="$_webHost" />';
  final hostAt = s.indexOf(hostLine);
  if (hostAt >= 0) {
    final missing = [
      for (final p in _webPaths)
        if (!s.contains('android:path="$p"')) p,
    ];
    if (missing.isNotEmpty) {
      final at = hostAt + hostLine.length;
      s = s.replaceRange(at, at,
          missing.map((p) => '\n                <data android:path="$p" />').join());
    }
  }
  if (!s.contains('android:host="$_webHost"')) {
    final paths = _webPaths
        .map((p) => '                <data android:path="$p" />\n')
        .join();
    additions.write('''    <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" />
                <data android:host="$_webHost" />
$paths            </intent-filter>
        ''');
  }
  // Odkazy obsluhuje app_links (deep_links.dart). Vestavěný deep linking
  // Flutteru by gymbar://… (i homewidget://… z widgetu) předal
  // go_routeru jako cestu a ukázal chybovou stránku (doporučení balíčku
  // app_links). Dřív to přidával tool/platform/widgets.dart – už
  // existující záznam (s jakoukoli hodnotou) se znovu nepřidá.
  if (!s.contains('flutter_deeplinking_enabled')) {
    additions.write('''    <meta-data
                android:name="flutter_deeplinking_enabled"
                android:value="false" />
        ''');
  }
  if (additions.isNotEmpty) {
    final activity = RegExp(r'<activity[^>]*android:name="\.MainActivity"')
        .firstMatch(s);
    final end = activity == null ? -1 : s.indexOf('</activity>', activity.end);
    if (end < 0) {
      stderr.writeln('✗ ${file.path}: MainActivity nenalezena.');
      return false;
    }
    s = s.replaceRange(end, end, additions.toString());
  }

  // Android 11+: aby šlo z aplikace otevřít web a obchod. Hledá se jen
  // uvnitř <queries> – stejný řádek má i intent-filter App Links výše.
  if (!RegExp(r'<queries>(?:(?!</queries>).)*<data android:scheme="https" />',
          dotAll: true)
      .hasMatch(s)) {
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
    stdout.writeln('✓ ${file.path}: odkazy $_scheme:// a https://$_webHost');
  } else {
    stdout.writeln('• ${file.path}: odkazy už nastavené.');
  }
  return true;
}

bool _ios() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) return true;
  var s = file.readAsStringSync();
  final original = s;
  s = s.replaceAll(
      '<string>$_legacyScheme</string>', '<string>$_scheme</string>');
  // Odkazy obsluhuje app_links (deep_links.dart). Vestavěný deep linking
  // Flutteru (na iOS od 3.27 zapnutý) by gymbar://… předal go_routeru
  // jako cestu a ukázal chybovou stránku. Na Androidu totéž dělá
  // meta-data flutter_deeplinking_enabled v _android() výše.
  if (!s.contains('<key>FlutterDeepLinkingEnabled</key>')) {
    final i = s.lastIndexOf('</dict>');
    if (i < 0) return false;
    s = s.replaceRange(
        i, i, '\t<key>FlutterDeepLinkingEnabled</key>\n\t<false/>\n');
  }
  if (!s.contains('<string>$_scheme</string>')) {
    if (s.contains('<key>CFBundleURLTypes</key>')) {
      if (s != original) file.writeAsStringSync(s);
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
  }
  if (s == original) {
    stdout.writeln('• ${file.path}: odkazy už nastavené.');
    return true;
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: odkazy $_scheme://');
  return true;
}
