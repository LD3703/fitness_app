import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show md5;

/// Požadavky App Store na iOS projekt (docs/app_store.md). Bezpečné spustit
/// opakovaně – co už v souborech je, znovu nepřidá.
///
///  1. ios/Runner/PrivacyInfo.xcprivacy – privacy manifest (bez trackingu,
///     sbíraná data stejně jako štítky „App Privacy“ v App Store Connect),
///     zapsaný i do Xcode projektu (Resources cíle Runner),
///  2. jen iPhone (TARGETED_DEVICE_FAMILY = 1) – na iPadu běží
///     v režimu pro iPhone a App Store nechce screenshoty z iPadu,
///  3. Universal Links: entitlement applinks:gymbar.app (odkazy
///     https://gymbar.app/challenge|friend|gym otevřou rovnou aplikaci;
///     web je potvrdí souborem apple-app-site-association, který vytvoří
///     `dart run tool/assetlinks.dart --apple-team <Team ID>`).
///
/// Volá se po patchSocial (ten založí Runner.entitlements
/// a CODE_SIGN_ENTITLEMENTS).
bool patchIosStore() {
  if (!Directory('ios/Runner').existsSync()) {
    stdout.writeln('• ios/Runner nenalezen – iOS (App Store) přeskočeno.');
    return true;
  }
  var ok = true;
  ok &= _privacyManifest();
  ok &= _iphoneOnly();
  ok &= _associatedDomains();
  return ok;
}

/// Musí odpovídat kWebBaseUrl (lib/modules/links/deep_links.dart).
const _webHost = 'gymbar.app';
const _manifestName = 'PrivacyInfo.xcprivacy';
const _pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';
const _entitlementsPath = 'ios/Runner/Runner.entitlements';

// ---------------------------------------------------------------- 1. manifest

/// Sbíraná data (stejně jako docs/app_store.md, „App Privacy“): vše jen
/// pro funkce aplikace, propojené s účtem, bez trackingu. Pády
/// (Crashlytics) bez vazby na účet.
const _collected = [
  ('NSPrivacyCollectedDataTypeName', true),
  ('NSPrivacyCollectedDataTypeEmailAddress', true),
  ('NSPrivacyCollectedDataTypeHealth', true),
  ('NSPrivacyCollectedDataTypeFitness', true),
  ('NSPrivacyCollectedDataTypeOtherUserContent', true),
  ('NSPrivacyCollectedDataTypeUserID', true),
  ('NSPrivacyCollectedDataTypeDeviceID', true),
  ('NSPrivacyCollectedDataTypeCrashData', false),
];

String _manifest() {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">')
    ..writeln('<plist version="1.0">')
    ..writeln('<dict>')
    ..writeln('\t<key>NSPrivacyTracking</key>')
    ..writeln('\t<false/>')
    ..writeln('\t<key>NSPrivacyTrackingDomains</key>')
    ..writeln('\t<array/>')
    ..writeln('\t<key>NSPrivacyCollectedDataTypes</key>')
    ..writeln('\t<array>');
  for (final (type, linked) in _collected) {
    b
      ..writeln('\t\t<dict>')
      ..writeln('\t\t\t<key>NSPrivacyCollectedDataType</key>')
      ..writeln('\t\t\t<string>$type</string>')
      ..writeln('\t\t\t<key>NSPrivacyCollectedDataTypeLinked</key>')
      ..writeln('\t\t\t<${linked ? 'true' : 'false'}/>')
      ..writeln('\t\t\t<key>NSPrivacyCollectedDataTypeTracking</key>')
      ..writeln('\t\t\t<false/>')
      ..writeln('\t\t\t<key>NSPrivacyCollectedDataTypePurposes</key>')
      ..writeln('\t\t\t<array>')
      ..writeln('\t\t\t\t<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>')
      ..writeln('\t\t\t</array>')
      ..writeln('\t\t</dict>');
  }
  b
    ..writeln('\t</array>')
    // Vlastní nativní kód (AppDelegate, widget) čte a zapisuje jen
    // UserDefaults aplikace; pluginy (Firebase, path_provider…) mají
    // vlastní manifesty.
    ..writeln('\t<key>NSPrivacyAccessedAPITypes</key>')
    ..writeln('\t<array>')
    ..writeln('\t\t<dict>')
    ..writeln('\t\t\t<key>NSPrivacyAccessedAPIType</key>')
    ..writeln('\t\t\t<string>NSPrivacyAccessedAPICategoryUserDefaults</string>')
    ..writeln('\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>')
    ..writeln('\t\t\t<array>')
    ..writeln('\t\t\t\t<string>CA92.1</string>')
    ..writeln('\t\t\t</array>')
    ..writeln('\t\t</dict>')
    ..writeln('\t</array>')
    ..writeln('</dict>')
    ..writeln('</plist>');
  return b.toString();
}

bool _privacyManifest() {
  final file = File('ios/Runner/$_manifestName');
  if (!file.existsSync()) {
    file.writeAsStringSync(_manifest());
    stdout.writeln('✓ ${file.path}: vytvořen.');
  } else {
    stdout.writeln('• ${file.path}: už existuje (nepřepisuji).');
  }
  return _addResourceToProject(_manifestName);
}

/// ID objektu v project.pbxproj: 24 hex znaků, stabilní podle [seed]
/// a jiné než všechna ID v projektu.
String _newId(String project, String seed) {
  for (var i = 0;; i++) {
    final id = md5
        .convert(utf8.encode('gymbar:$seed:$i'))
        .toString()
        .substring(0, 24)
        .toUpperCase();
    if (!project.contains(id)) return id;
  }
}

/// Zapíše soubor ze složky ios/Runner do skupiny Runner a do fáze
/// Resources cíle Runner (jako přetažení do Xcode s „Copy items“).
bool _addResourceToProject(String name) {
  final file = File(_pbxproj);
  if (!file.existsSync()) {
    stdout.writeln('• $_pbxproj nenalezen – $name přidej do Xcode ručně.');
    return true;
  }
  var s = file.readAsStringSync();
  if (s.contains('/* $name in Resources */')) {
    stdout.writeln('• $_pbxproj: $name už v projektu.');
    return true;
  }
  void fail(String what) => stderr.writeln('✗ $_pbxproj: $what nenalezeno – '
      'přidej $name do cíle Runner ručně v Xcode (File → Add Files…).');

  final fileRef = _newId(s, 'ref:$name');
  final buildFile = _newId('$s$fileRef', 'build:$name');

  // Skupina Runner a fáze Resources (ta, kde je Assets.xcassets).
  final group = RegExp(
    r'[0-9A-F]{24} /\* Runner \*/ = \{\s*isa = PBXGroup;\s*children = \(',
  ).firstMatch(s);
  if (group == null) {
    fail('skupina Runner');
    return false;
  }
  int? resourcesAt;
  for (final m in RegExp(r'isa = PBXResourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \(')
      .allMatches(s)) {
    final end = s.indexOf(');', m.end);
    if (end > 0 && s.substring(m.end, end).contains('Assets.xcassets in Resources')) {
      resourcesAt = m.end;
      break;
    }
  }
  if (resourcesAt == null) {
    fail('fáze Resources cíle Runner');
    return false;
  }
  final buildEnd = s.indexOf('/* End PBXBuildFile section */');
  final refEnd = s.indexOf('/* End PBXFileReference section */');
  if (buildEnd < 0 || refEnd < 0) {
    fail('sekce PBXBuildFile / PBXFileReference');
    return false;
  }

  // Vkládá se odzadu, ať se dřívější pozice neposunou.
  final inserts = <(int, String)>[
    (buildEnd, '\t\t$buildFile /* $name in Resources */ = {isa = PBXBuildFile; '
        'fileRef = $fileRef /* $name */; };\n'),
    (refEnd, '\t\t$fileRef /* $name */ = {isa = PBXFileReference; '
        'lastKnownFileType = text.xml; path = $name; '
        'sourceTree = "<group>"; };\n'),
    (group.end, '\n\t\t\t\t$fileRef /* $name */,'),
    (resourcesAt, '\n\t\t\t\t$buildFile /* $name in Resources */,'),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  for (final (at, text) in inserts) {
    s = s.replaceRange(at, at, text);
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ $_pbxproj: $name přidán do cíle Runner.');
  return true;
}

// ---------------------------------------------------------------- 2. iPhone

bool _iphoneOnly() {
  final file = File(_pbxproj);
  if (!file.existsSync()) return true;
  var s = file.readAsStringSync();
  final original = s;
  s = s.replaceAll(
    RegExp(r'TARGETED_DEVICE_FAMILY = "?1,2"?;'),
    'TARGETED_DEVICE_FAMILY = 1;',
  );
  // Šablona Flutteru má nastavení v konfiguracích projektu; když tam
  // chybí, doplní se do konfigurací cíle Runner.
  if (!s.contains('TARGETED_DEVICE_FAMILY')) {
    final blocks = RegExp(r'buildSettings = \{').allMatches(s).toList();
    for (final b in blocks.reversed) {
      final end = s.indexOf('\n\t\t\t};', b.end);
      if (end < 0) continue;
      if (!s.substring(b.end, end).contains('INFOPLIST_FILE = Runner/Info.plist;')) {
        continue;
      }
      s = s.replaceRange(b.end, b.end, '\n\t\t\t\tTARGETED_DEVICE_FAMILY = 1;');
    }
  }
  if (s == original) {
    stdout.writeln('• $_pbxproj: jen iPhone už nastaveno.');
    return true;
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ $_pbxproj: jen iPhone (TARGETED_DEVICE_FAMILY = 1).');
  return true;
}

// ---------------------------------------------------------------- 3. odkazy

bool _associatedDomains() {
  final file = File(_entitlementsPath);
  const key = 'com.apple.developer.associated-domains';
  const entry = '\t<key>$key</key>\n'
      '\t<array>\n\t\t<string>applinks:$_webHost</string>\n\t</array>\n';
  if (!file.existsSync()) {
    file.writeAsStringSync('<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n<dict>\n$entry</dict>\n</plist>\n');
    stdout.writeln('✓ ${file.path}: vytvořen (Universal Links).');
    return true;
  }
  var s = file.readAsStringSync();
  if (s.contains('<key>$key</key>')) {
    if (!s.contains('applinks:$_webHost')) {
      stderr.writeln('✗ ${file.path}: $key existuje bez applinks:$_webHost '
          '– doplň ho ručně.');
      return false;
    }
    stdout.writeln('• ${file.path}: Universal Links už nastavené.');
    return true;
  }
  final i = s.lastIndexOf('</dict>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: neznámý formát – doplň $key ručně.');
    return false;
  }
  s = s.replaceRange(i, i, entry);
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: Universal Links (applinks:$_webHost).');
  return true;
}
