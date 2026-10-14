import 'dart:io';

/// Nativní nastavení pro hlášení o pádech (Firebase Crashlytics).
/// Bezpečné spustit opakovaně.
///
/// Android: Gradle plugin `com.google.firebase.crashlytics` – nové verze
/// `flutterfire configure` ho přidají samy, tady se jen doplní, když
/// chybí. Potřebuje plugin `com.google.gms.google-services`, který
/// přidá `flutterfire configure` (docs/social.md, krok 5); bez něj se
/// nic nemění (aplikace funguje dál, jen bez hlášení o pádech).
///
/// iOS: Crashlytics běží bez úprav projektu. Nahrávání symbolů
/// (dSYM) pro čitelné nativní pády přidá `flutterfire configure` na Macu
/// (na Windows to neumí); pády v Dartu jsou čitelné i bez nich.
///
/// Obě platformy: sběr je ve výchozím stavu vypnutý (manifest
/// `firebase_crashlytics_collection_enabled`, Info.plist
/// `FirebaseCrashlyticsCollectionEnabled` = false). Zapne ho až
/// CrashReporting.init podle volby uživatele (Profil → Soukromí), takže
/// se neodešle nic, co se stane před ní nebo s vypnutým odesíláním.
bool patchCrash() {
  // Vypnutý výchozí sběr je neškodný i bez Firebase – nastaví se vždy.
  final ok = _manifest() & _infoPlist();
  return _gradle() & ok;
}

const _manifestKey = 'firebase_crashlytics_collection_enabled';
const _plistKey = 'FirebaseCrashlyticsCollectionEnabled';

/// AndroidManifest.xml: `<meta-data … collection_enabled="false" />`
/// v bloku `<application>`.
bool _manifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  final s = file.readAsStringSync();
  if (s.contains(_manifestKey)) {
    stdout.writeln('• ${file.path}: výchozí sběr Crashlytics už nastavený.');
    return true;
  }
  final i = s.lastIndexOf('</application>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
    return false;
  }
  const meta = '    <meta-data\n'
      '            android:name="$_manifestKey"\n'
      '            android:value="false" />\n    ';
  file.writeAsStringSync(s.replaceRange(i, i, meta));
  stdout.writeln('✓ ${file.path}: Crashlytics bez souhlasu nesbírá.');
  return true;
}

/// Info.plist: `<key>FirebaseCrashlyticsCollectionEnabled</key><false/>`.
bool _infoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stdout.writeln('• ios/Runner/Info.plist nenalezen – iOS přeskočeno.');
    return true;
  }
  final s = file.readAsStringSync();
  if (s.contains('<key>$_plistKey</key>')) {
    stdout.writeln('• ${file.path}: výchozí sběr Crashlytics už nastavený.');
    return true;
  }
  // Poslední </dict> = konec kořenového slovníku.
  final i = s.lastIndexOf('</dict>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
    return false;
  }
  file.writeAsStringSync(
      s.replaceRange(i, i, '\t<key>$_plistKey</key>\n\t<false/>\n'));
  stdout.writeln('✓ ${file.path}: Crashlytics bez souhlasu nesbírá.');
  return true;
}

/// Gradle plugin Crashlytics (jen s Firebase / google-services).
bool _gradle() {
  final settings = _firstExisting([
    'android/settings.gradle.kts',
    'android/settings.gradle',
  ]);
  final app = _firstExisting([
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]);
  if (settings == null || app == null) {
    stderr.writeln('✗ crash: Gradle soubory Androidu nenalezeny.');
    return false;
  }
  if (!app.readAsStringSync().contains('com.google.gms.google-services')) {
    stdout.writeln('• crash: chybí Firebase (google-services) – nejdřív '
        '`flutterfire configure`, pak tento skript znovu. Přeskakuji.');
    return true;
  }
  return _settings(settings) & _app(app);
}

const _pluginId = 'com.google.firebase.crashlytics';
const _pluginVersion = '3.0.6';

File? _firstExisting(List<String> paths) {
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) return f;
  }
  return null;
}

/// settings.gradle(.kts): `id(...) version "…" apply false` vedle
/// google-services.
bool _settings(File file) {
  var s = file.readAsStringSync();
  if (s.contains(_pluginId)) {
    stdout.writeln('• ${file.path}: Crashlytics plugin už je.');
    return true;
  }
  final kotlin = file.path.endsWith('.kts');
  final line = RegExp(r"""^([ \t]*)id[ (]+['"]com\.google\.gms\.google-services['"][^\n]*$""",
          multiLine: true)
      .firstMatch(s);
  if (line == null) {
    stderr.writeln('✗ ${file.path}: nenalezen řádek google-services – '
        'přidej do bloku plugins ručně: '
        '${_settingsLine(kotlin)}');
    return false;
  }
  final indent = line.group(1)!;
  s = s.replaceRange(
      line.end, line.end, '\n$indent${_settingsLine(kotlin)}');
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: Crashlytics plugin $_pluginVersion.');
  return true;
}

String _settingsLine(bool kotlin) => kotlin
    ? 'id("$_pluginId") version "$_pluginVersion" apply false'
    : 'id "$_pluginId" version "$_pluginVersion" apply false';

/// app/build.gradle(.kts): `id(...)` v bloku plugins za google-services.
bool _app(File file) {
  var s = file.readAsStringSync();
  if (s.contains(_pluginId)) {
    stdout.writeln('• ${file.path}: Crashlytics plugin už je.');
    return true;
  }
  final kotlin = file.path.endsWith('.kts');
  final pluginLine = kotlin ? 'id("$_pluginId")' : 'id "$_pluginId"';
  final line = RegExp(r"""^([ \t]*)id[ (]+['"]com\.google\.gms\.google-services['"][^\n]*$""",
          multiLine: true)
      .firstMatch(s);
  if (line == null) {
    // Starší zápis: apply plugin: 'com.google.gms.google-services'
    final apply = RegExp(
            r"""^apply plugin:\s*['"]com\.google\.gms\.google-services['"][^\n]*$""",
            multiLine: true)
        .firstMatch(s);
    if (apply == null) {
      stderr.writeln('✗ ${file.path}: nenalezen google-services – přidej '
          'do bloku plugins ručně: $pluginLine');
      return false;
    }
    s = s.replaceRange(
        apply.end, apply.end, "\napply plugin: '$_pluginId'");
  } else {
    s = s.replaceRange(line.end, line.end, '\n${line.group(1)}$pluginLine');
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: Crashlytics plugin.');
  return true;
}
