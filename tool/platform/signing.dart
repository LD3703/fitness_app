import 'dart:io';

/// Podpis release buildu Androidu (README, kapitola „Vydání pro Android“).
/// Bezpečné spustit opakovaně.
///
/// Do `<androidDir>/app/build.gradle(.kts)` doplní načtení klíče:
///  1. ze souboru `key.properties` ve složce `<androidDir>` (na tvém PC;
///     soubor i klíč jsou v .gitignore a do gitu NEPATŘÍ),
///  2. s [phoneKeyFallback] (jen hodinky, `wear/tool/setup_wear.dart`)
///     i z `../../android/key.properties` = key.properties aplikace
///     v telefonu (stejný klíč, nemusíš ho kopírovat). U telefonu by ta
///     cesta mířila mimo projekt, proto se tam nepřidává,
///  3. jinak z proměnných CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD,
///     CM_KEY_ALIAS a CM_KEY_PASSWORD, které nastaví Codemagic
///     (codemagic.yaml, workflow android-release).
/// Bez klíče se release podepíše ladicím klíčem jako dosud – jde
/// nainstalovat do telefonu, ale do Google Play ne.
///
/// `storeFile` v key.properties musí být absolutní cesta – relativní
/// by Gradle hledal ve složce app/ toho projektu, který se zrovna sestavuje.
bool patchSigning({
  String androidDir = 'android',
  bool phoneKeyFallback = false,
}) {
  final kts = File('$androidDir/app/build.gradle.kts');
  final groovy = File('$androidDir/app/build.gradle');
  if (kts.existsSync()) {
    return _patch(kts, kotlin: true, phoneKeyFallback: phoneKeyFallback);
  }
  if (groovy.existsSync()) {
    return _patch(groovy, kotlin: false, phoneKeyFallback: phoneKeyFallback);
  }
  stderr.writeln('✗ signing: $androidDir/app/build.gradle(.kts) nenalezen.');
  return false;
}

const _marker = 'releaseStoreFile';

/// Řádek s key.properties telefonu v seznamu kandidátů (Kotlin i Groovy).
final _phoneKeyLine = RegExp(
  r"""^[ \t]*rootProject\.file\(["']\.\./\.\./android/key\.properties["']\),[ \t]*\r?\n""",
  multiLine: true,
);

bool _patch(
  File file, {
  required bool kotlin,
  required bool phoneKeyFallback,
}) {
  var s = file.readAsStringSync();
  if (s.contains(_marker)) {
    // Starší verze skriptu přidávala ../../android/key.properties
    // i telefonu (mimo projekt) – tam ten řádek odebrat.
    if (!phoneKeyFallback && _phoneKeyLine.hasMatch(s)) {
      file.writeAsStringSync(s.replaceAll(_phoneKeyLine, ''));
      stdout.writeln('✓ ${file.path}: odebráno hledání key.properties '
          'mimo projekt.');
      return true;
    }
    stdout.writeln('• ${file.path}: podpis release už nastavený.');
    return true;
  }
  // Podpis nastavený ručně (např. podle návodu Flutteru) – nic neměnit,
  // jinak by vznikl druhý keystoreProperties / signingConfig release.
  if (s.contains('keystoreProperties') ||
      s.contains('create("release")') ||
      RegExp(r'signingConfigs\s*\{[^}]*\brelease\s*\{').hasMatch(s)) {
    stdout.writeln('• ${file.path}: vlastní podpis release už existuje – '
        'nechávám beze změny (Codemagic pak potřebuje proměnné '
        'CM_KEYSTORE_* doplnit ručně, README „Vydání pro Android“).');
    return true;
  }

  // 1) Release v buildTypes: ladicí klíč → release klíč, když existuje.
  final debugSigning = kotlin
      ? RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)')
      : RegExp(r'signingConfig\s*=?\s*signingConfigs\.debug');
  final release = RegExp(r'buildTypes\s*\{\s*release\s*\{').firstMatch(s);
  if (release == null) {
    stderr.writeln('✗ ${file.path}: blok buildTypes { release { … } } '
        'nenalezen – podpis nastav ručně podle README.');
    return false;
  }
  final releaseLine = kotlin
      ? 'signingConfig = if (releaseStoreFile != null) '
          'signingConfigs.getByName("release") '
          'else signingConfigs.getByName("debug")'
      : 'signingConfig releaseStoreFile ? signingConfigs.release '
          ': signingConfigs.debug';
  final debugMatch = debugSigning.firstMatch(s.substring(release.end));
  if (debugMatch != null) {
    final start = release.end + debugMatch.start;
    s = s.replaceRange(start, release.end + debugMatch.end, releaseLine);
  } else {
    s = s.replaceRange(release.end, release.end, '\n            $releaseLine');
  }

  // 2) signingConfigs na začátek bloku android { }.
  final android = RegExp(r'^android\s*\{', multiLine: true).firstMatch(s);
  if (android == null) {
    stderr.writeln('✗ ${file.path}: blok android { } nenalezen.');
    return false;
  }
  s = s.replaceRange(android.end, android.end,
      kotlin ? _kotlinSigningConfigs : _groovySigningConfigs);

  // 3) Načtení key.properties před blok android { }.
  s = s.replaceRange(android.start, android.start,
      kotlin ? _kotlinLoad(phoneKeyFallback) : _groovyLoad(phoneKeyFallback));

  // 4) Importy (Kotlin skript je potřebuje úplně nahoře).
  if (kotlin) {
    const imports = 'import java.io.FileInputStream\n'
        'import java.util.Properties\n';
    final missing = [
      if (!s.contains('import java.io.FileInputStream'))
        'import java.io.FileInputStream',
      if (!s.contains('import java.util.Properties'))
        'import java.util.Properties',
    ];
    if (missing.length == 2) {
      s = '$imports\n$s';
    } else if (missing.isNotEmpty) {
      s = '${missing.join('\n')}\n$s';
    }
  }

  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: podpis release z key.properties '
      'nebo z Codemagicu.');
  return true;
}

/// Načtení key.properties (Kotlin). [phoneKeyFallback]: i key.properties
/// aplikace v telefonu (hodinky ve složce wear/).
String _kotlinLoad(bool phoneKeyFallback) => '''
// Podpis release buildu (tool/platform/signing.dart, README „Vydání pro
// Android“): key.properties na tvém PC, nebo proměnné CM_KEYSTORE_*
// v Codemagicu. Bez nich se release podepíše ladicím klíčem.
val keystoreProperties = Properties().apply {
    val candidates = listOf(
        rootProject.file("key.properties"),
${phoneKeyFallback ? '        rootProject.file("../../android/key.properties"),\n' : ''}    )
    candidates.firstOrNull { it.exists() }?.let { file ->
        FileInputStream(file).use { load(it) }
    }
}
val releaseStoreFile: String? =
    keystoreProperties.getProperty("storeFile") ?: System.getenv("CM_KEYSTORE_PATH")

''';

const _kotlinSigningConfigs = '''

    signingConfigs {
        create("release") {
            releaseStoreFile?.let { path ->
                storeFile = file(path)
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: System.getenv("CM_KEY_ALIAS")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: System.getenv("CM_KEY_PASSWORD")
            }
        }
    }
''';

/// Načtení key.properties (Groovy). [phoneKeyFallback] jako u Kotlinu.
String _groovyLoad(bool phoneKeyFallback) => '''
// Podpis release buildu (tool/platform/signing.dart, README „Vydání pro
// Android“): key.properties na tvém PC, nebo proměnné CM_KEYSTORE_*
// v Codemagicu. Bez nich se release podepíše ladicím klíčem.
def keystoreProperties = new Properties()
def keystorePropertiesFile = [
    rootProject.file('key.properties'),
${phoneKeyFallback ? "    rootProject.file('../../android/key.properties'),\n" : ''}].find { it.exists() }
if (keystorePropertiesFile != null) {
    keystorePropertiesFile.withInputStream { keystoreProperties.load(it) }
}
def releaseStoreFile = keystoreProperties['storeFile'] ?: System.getenv('CM_KEYSTORE_PATH')

''';

const _groovySigningConfigs = '''

    signingConfigs {
        release {
            if (releaseStoreFile) {
                storeFile file(releaseStoreFile)
                storePassword keystoreProperties['storePassword'] ?: System.getenv('CM_KEYSTORE_PASSWORD')
                keyAlias keystoreProperties['keyAlias'] ?: System.getenv('CM_KEY_ALIAS')
                keyPassword keystoreProperties['keyPassword'] ?: System.getenv('CM_KEY_PASSWORD')
            }
        }
    }
''';
