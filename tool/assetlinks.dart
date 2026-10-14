// Vytvoří docs/web/.well-known/assetlinks.json pro Android App Links:
// web gymbar.app tím potvrdí, že jeho odkazy (/challenge, /friend, /gym)
// smí otevírat rovnou aplikace. Android ověří, že otisk klíče, kterým je
// nainstalovaná aplikace podepsaná, je v tomhle souboru.
//
//   dart run tool/assetlinks.dart
//   dart run tool/assetlinks.dart --add AB:CD:…   (např. klíč Google Play)
//   firebase deploy --only hosting
//
// Otisky (SHA-256) bere z:
//  1. ladicího klíče (%USERPROFILE%\.android\debug.keystore) – aplikace
//     z `flutter run` a `flutter build apk --debug`,
//  2. release klíče z android/key.properties, pokud existuje,
//  3. --add <otisk> – klíč „App signing key“ z Google Play Console
//     (Test and release → App integrity → App signing). Aplikace stažená
//     z Google Play je podepsaná tímhle klíčem, ne tvým release klíčem,
//  4. otisků, které už v souboru jsou (soubor se doplňuje, nepřepisuje;
//     --reset začne načisto).
//
// iPhone (Universal Links, až po registraci v Apple Developer Programu):
//   dart run tool/assetlinks.dart --apple-team ABCDE12345
// vytvoří i docs/web/.well-known/apple-app-site-association. Team ID je
// v developer.apple.com → Account → Membership details (10 znaků).
//
// Soubory jsou v .gitignore – vznikají na tvém PC a nové verze projektu je
// nepřepíšou. Otisky ani Team ID nejsou tajné (web je ukazuje každému).
import 'dart:convert';
import 'dart:io';

/// Musí odpovídat applicationId (tool/platform/widgets.dart, kPlayStoreUrl).
const _package = 'cz.dedina.fitness_app';
const _outPath = 'docs/web/.well-known/assetlinks.json';

/// iOS: Bundle ID (codemagic.yaml) a cesty, které otevírá aplikace
/// (stejně jako tool/platform/links.dart a ios_store.dart).
const _iosBundleId = 'cz.dedina.fitnessApp';
const _aasaPath = 'docs/web/.well-known/apple-app-site-association';
const _appPaths = ['/challenge', '/friend', '/gym', '/coach', '/plan'];

final _fingerprint = RegExp(r'^([0-9A-F]{2}:){31}[0-9A-F]{2}$');

void main(List<String> args) {
  final appleOnly = _appleSiteAssociation(args);
  final reset = args.contains('--reset');
  final fingerprints = <String>{};
  final out = File(_outPath);

  if (!reset && out.existsSync()) {
    fingerprints.addAll(_existing(out));
  }

  for (var i = 0; i < args.length; i++) {
    if (args[i] != '--add') continue;
    if (i + 1 >= args.length) _fail('Za --add chybí otisk.');
    final fp = args[i + 1].trim().toUpperCase();
    if (!_fingerprint.hasMatch(fp)) {
      _fail('„${args[i + 1]}“ není otisk SHA-256 '
          '(32 dvojic znaků oddělených dvojtečkou).');
    }
    fingerprints.add(fp);
    stdout.writeln('✓ přidán otisk z --add');
  }

  final keytool = _findKeytool();
  if (keytool == null) {
    stderr.writeln('• keytool nenalezen (JAVA_HOME ani Android Studio) – '
        'otisky klíčů z počítače přeskakuji.');
  } else {
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    final debug = File('$home/.android/debug.keystore');
    if (debug.existsSync()) {
      final fp = _sha256(keytool, debug.path, 'androiddebugkey', 'android');
      if (fp != null) {
        fingerprints.add(fp);
        stdout.writeln('✓ ladicí klíč: $fp');
      }
    } else {
      stdout.writeln('• ladicí klíč ${debug.path} nenalezen '
          '(vznikne prvním flutter run).');
    }

    final props = File('android/key.properties');
    if (props.existsSync()) {
      final p = _properties(props);
      final store = p['storeFile'];
      final alias = p['keyAlias'];
      final pass = p['storePassword'];
      if (store != null && alias != null && pass != null) {
        final fp = _sha256(keytool, store, alias, pass);
        if (fp != null) {
          fingerprints.add(fp);
          stdout.writeln('✓ release klíč: $fp');
        }
      } else {
        stderr.writeln('• android/key.properties: chybí storeFile, '
            'keyAlias nebo storePassword – release klíč přeskakuji.');
      }
    }
  }

  if (fingerprints.isEmpty && appleOnly) {
    stdout.writeln('• Android: žádný otisk – assetlinks.json beze změny.');
    return;
  }
  if (fingerprints.isEmpty) {
    _fail('Žádný otisk – soubor nevytvořen. Spusť nejdřív flutter run '
        '(vznikne ladicí klíč), nebo zadej --add <otisk>.');
  }

  final sorted = fingerprints.toList()..sort();
  final json = [
    {
      'relation': ['delegate_permission/common.handle_all_urls'],
      'target': {
        'namespace': 'android_app',
        'package_name': _package,
        'sha256_cert_fingerprints': sorted,
      },
    },
  ];
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('\n✓ $_outPath (${sorted.length} otisk/y). '
      'Nahraj ho: firebase deploy --only hosting');
}

/// S `--apple-team <Team ID>` zapíše apple-app-site-association. Vrací
/// true, když se soubor zapsal (pak chybějící Android otisky nevadí).
bool _appleSiteAssociation(List<String> args) {
  final i = args.indexOf('--apple-team');
  if (i < 0) return false;
  if (i + 1 >= args.length) _fail('Za --apple-team chybí Team ID.');
  final team = args[i + 1].trim().toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(team)) {
    _fail('„${args[i + 1]}“ není Team ID (10 písmen a číslic).');
  }
  final json = {
    'applinks': {
      'details': [
        {
          'appIDs': ['$team.$_iosBundleId'],
          'components': [
            for (final p in _appPaths) {'/': p},
          ],
        },
      ],
    },
  };
  final out = File(_aasaPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('✓ $_aasaPath (Team ID $team).');
  return true;
}

Iterable<String> _existing(File f) {
  try {
    final list = jsonDecode(f.readAsStringSync()) as List;
    return [
      for (final e in list)
        if (e is Map && e['target'] is Map)
          if ((e['target'] as Map)['package_name'] == _package)
            for (final fp in ((e['target'] as Map)['sha256_cert_fingerprints']
                    as List? ??
                const []))
              if (fp is String && _fingerprint.hasMatch(fp)) fp,
    ];
  } catch (e) {
    stderr.writeln('• $_outPath nejde přečíst ($e) – vytvořím nový.');
    return const [];
  }
}

Map<String, String> _properties(File f) {
  final map = <String, String>{};
  for (final line in f.readAsLinesSync()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final i = t.indexOf('=');
    if (i <= 0) continue;
    // key.properties smí mít v cestě zpětná lomítka zdvojená (C:\\keys\\…).
    map[t.substring(0, i).trim()] =
        t.substring(i + 1).trim().replaceAll(r'\\', r'\');
  }
  return map;
}

String? _findKeytool() {
  final exe = Platform.isWindows ? 'keytool.exe' : 'keytool';
  final candidates = <String>[
    if (Platform.environment['JAVA_HOME'] case final j?) '$j/bin/$exe',
    if (Platform.isWindows) ...[
      r'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
      r'C:\Program Files\Android\Android Studio\jre\bin\keytool.exe',
      if (Platform.environment['LOCALAPPDATA'] case final l?)
        '$l\\Programs\\Android Studio\\jbr\\bin\\keytool.exe',
    ],
    if (Platform.isMacOS)
      '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool',
  ];
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  // Na PATH?
  try {
    final r = Process.runSync(exe, ['-help'], runInShell: Platform.isWindows);
    if (r.exitCode == 0 || '${r.stdout}${r.stderr}'.contains('keytool')) {
      return exe;
    }
  } on ProcessException {
    // není
  }
  return null;
}

String? _sha256(String keytool, String store, String alias, String pass) {
  final r = Process.runSync(keytool, [
    '-list',
    '-v',
    '-keystore',
    store,
    '-alias',
    alias,
    '-storepass',
    pass,
  ]);
  final text = '${r.stdout}';
  final m = RegExp(r'SHA256:\s*([0-9A-Fa-f:]{95})').firstMatch(text);
  if (r.exitCode != 0 || m == null) {
    final err = '${r.stderr}${r.stdout}'.trim().split('\n').first;
    stderr.writeln('✗ keytool nepřečetl $store (alias $alias): $err');
    return null;
  }
  return m.group(1)!.toUpperCase();
}

Never _fail(String message) {
  stderr.writeln('✗ $message');
  exit(1);
}
