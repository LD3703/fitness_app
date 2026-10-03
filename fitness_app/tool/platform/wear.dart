import 'dart:io';

// Hodinky s Wear OS – úpravy aplikace v TELEFONU.
//
// Spojení s hodinkami (Wearable Data Layer) přidává balíček
// watch_connectivity sám (knihovna play-services-wearable), oprávnění
// ani služby v manifestu nepotřebuje. Doplní se jen viditelnost
// doprovodných aplikací hodinek (Android 11+ jinak instalované aplikace
// skrývá a WatchConnectivity.isPaired by vracelo vždy false).
//
// Aplikace v hodinkách (složka wear/) má vlastní skript
// wear/tool/setup_wear.dart – viz docs/wear_os.md.

/// Doprovodné aplikace hodinek v telefonu: Wear OS by Google, Pixel Watch
/// (nová aplikace Wear OS) a Galaxy Wearable.
const _companionPackages = [
  'com.google.android.wearable.app',
  'com.google.android.apps.wear.companion',
  'com.samsung.android.app.watchmanager',
];

bool patchWear() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen – hodinky přeskočeny.');
    return false;
  }
  var s = file.readAsStringSync();
  final missing = [
    for (final p in _companionPackages)
      if (!s.contains('<package android:name="$p"')) p,
  ];
  if (missing.isEmpty) {
    stdout.writeln('• ${file.path}: hodinky už nastavené.');
    return true;
  }
  final packages =
      missing.map((p) => '        <package android:name="$p" />').join('\n');
  final end = s.lastIndexOf('</manifest>');
  if (end < 0) {
    stderr.writeln('✗ ${file.path}: značka </manifest> nenalezena.');
    return false;
  }
  // Vlastní blok <queries> (Android jich dovoluje víc) – nezávisle na
  // blocích ostatních modulů.
  s = s.replaceRange(end, end, '    <queries>\n$packages\n    </queries>\n');
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: viditelnost aplikací pro hodinky.');
  return true;
}
