import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show md5;

/// Aplikace pro Apple Watch (docs/apple_watch.md).
///
/// SwiftUI kód je v ios/GymBarWatch/. Tenhle skript ho zapojí: přidá do
/// Xcode projektu cíl GymBarWatch (aplikace pro watchOS 9+, vložená do
/// Runner.app/Watch) – Flutter ji pak sestaví spolu s aplikací v telefonu
/// (pozná ji podle WKCompanionAppBundleIdentifier v Info.plist).
///
/// Cíl potřebuje App ID cz.dedina.fitnessApp.watchkitapp (s HealthKit)
/// v Apple Developer účtu – bez něj podepsaný build (Codemagic, TestFlight)
/// selže. Proto se zapíná jen na vyžádání ([enable],
/// `dart run tool/ios_watch.dart`); jakmile je cíl v projektu, další
/// spuštění ho jen udržují. Bezpečné spustit opakovaně.
bool patchIosWatch({required bool enable}) {
  if (!Directory('ios/Runner').existsSync()) {
    stdout.writeln('• ios/Runner nenalezen – Apple Watch přeskočeno.');
    return true;
  }
  final project = File(_pbxproj);
  if (!project.existsSync()) {
    stdout.writeln('• $_pbxproj nenalezen – Apple Watch přeskočeno.');
    return true;
  }
  final present = project.readAsStringSync().contains('/* $_product */');
  if (!enable && !present) {
    stdout.writeln('• Apple Watch: vypnuté (zapnutí: '
        'dart run tool/ios_watch.dart, docs/apple_watch.md).');
    return true;
  }
  for (final f in _watchFiles.map((f) => 'ios/$_target/$f')) {
    if (FileSystemEntity.typeSync(f) == FileSystemEntityType.notFound) {
      stderr.writeln('✗ $f chybí – Apple Watch nejde zapnout.');
      return false;
    }
  }
  return _patchProject();
}

const _pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';
const _target = 'GymBarWatch';
const _product = '$_target.app';
const _embedPhase = 'Embed Watch Content';
const _bundleId = 'cz.dedina.fitnessApp';
const _assets = 'Assets.xcassets';

/// Soubory ve složce ios/GymBarWatch (pořadí = pořadí v Xcode).
const _swiftFiles = [
  'WatchViews.swift',
  'WatchController.swift',
  'WatchProtocol.swift',
  'HeartRateMonitor.swift',
  'WatchStrings.swift',
];
const _watchFiles = [
  ..._swiftFiles,
  _assets,
  'Info.plist',
  '$_target.entitlements',
  '$_target.xcconfig',
];

// ---------------------------------------------------------------- projekt

/// ID objektu v project.pbxproj: 24 hex znaků, stabilní podle [seed]
/// a jiné než všechna ID v projektu (stejně jako ios_store.dart).
String _newId(String project, String seed) {
  for (var i = 0;; i++) {
    final id = md5
        .convert(utf8.encode('gymbar-watch:$seed:$i'))
        .toString()
        .substring(0, 24)
        .toUpperCase();
    if (!project.contains(id)) return id;
  }
}

String _fileType(String name) => switch (name.split('.').last) {
      'swift' => 'sourcecode.swift',
      'plist' => 'text.plist.xml',
      'entitlements' => 'text.plist.entitlements',
      'xcconfig' => 'text.xcconfig',
      'xcassets' => 'folder.assetcatalog',
      _ => 'text',
    };

bool _patchProject() {
  final file = File(_pbxproj);
  var s = file.readAsStringSync();
  if (s.contains('/* $_product */')) {
    stdout.writeln('• $_pbxproj: cíl $_target už v projektu.');
    return true;
  }
  void fail(String what) => stderr.writeln('✗ $_pbxproj: $what nenalezeno – '
      'cíl $_target nepřidán (docs/apple_watch.md).');

  // Existující objekty: projekt, cíl Runner, skupiny.
  final projectId =
      RegExp(r'rootObject = ([0-9A-F]{24})').firstMatch(s)?.group(1);
  final runnerTarget = RegExp(
    r'[0-9A-F]{24} /\* Runner \*/ = \{\s*isa = PBXNativeTarget;',
  ).firstMatch(s);
  final mainGroupId =
      RegExp(r'mainGroup = ([0-9A-F]{24});').firstMatch(s)?.group(1);
  final productsId =
      RegExp(r'productRefGroup = ([0-9A-F]{24})').firstMatch(s)?.group(1);
  final runnerGroup = RegExp(
    r'[0-9A-F]{24} /\* Runner \*/ = \{\s*isa = PBXGroup;\s*children = \(',
  ).firstMatch(s);
  if (projectId == null ||
      runnerTarget == null ||
      mainGroupId == null ||
      productsId == null ||
      runnerGroup == null) {
    fail('projekt, cíl nebo skupina Runner');
    return false;
  }
  // Nová ID (každé jiné než všechna dosavadní i už vydaná).
  var taken = s;
  String id(String seed) {
    final v = _newId(taken, seed);
    taken += v;
    return v;
  }

  final refs = {for (final f in _watchFiles) f: id('ref:$f')};
  final appRef = id('ref:$_product');
  final group = id('group');
  final watchBuild = {for (final f in _swiftFiles) f: id('build:$f')};
  final assetsBuild = id('build:$_assets');
  final appBuild = id('build:embed:$_product');
  final target = id('target');
  final sources = id('phase:sources');
  final frameworks = id('phase:frameworks');
  final resources = id('phase:resources');
  final embed = id('phase:embed');
  final proxy = id('proxy');
  final dependency = id('dependency');
  final configList = id('configlist');
  final configs = {
    for (final c in ['Debug', 'Release', 'Profile']) c: id('config:$c'),
  };

  // --- obsah nových sekcí
  final buildFiles = StringBuffer();
  for (final f in _swiftFiles) {
    buildFiles.writeln('\t\t${watchBuild[f]} /* $f in Sources */ = '
        '{isa = PBXBuildFile; fileRef = ${refs[f]} /* $f */; };');
  }
  buildFiles
    ..writeln('\t\t$assetsBuild /* $_assets in Resources */ = '
        '{isa = PBXBuildFile; fileRef = ${refs[_assets]} /* $_assets */; };')
    ..writeln('\t\t$appBuild /* $_product in $_embedPhase */ = '
        '{isa = PBXBuildFile; fileRef = $appRef /* $_product */; '
        'settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };');

  final fileRefs = StringBuffer();
  for (final f in _watchFiles) {
    fileRefs.writeln('\t\t${refs[f]} /* $f */ = {isa = PBXFileReference; '
        'lastKnownFileType = ${_fileType(f)}; path = $f; sourceTree = "<group>"; };');
  }
  fileRefs.writeln('\t\t$appRef /* $_product */ = {isa = PBXFileReference; '
      'explicitFileType = wrapper.application; includeInIndex = 0; '
      'path = $_product; sourceTree = BUILT_PRODUCTS_DIR; };');

  String list(Iterable<String> items) =>
      items.map((i) => '\t\t\t\t$i,\n').join();

  final groupText = '\t\t$group /* $_target */ = {\n'
      '\t\t\tisa = PBXGroup;\n'
      '\t\t\tchildren = (\n'
      '${list(_watchFiles.map((f) => '${refs[f]} /* $f */'))}'
      '\t\t\t);\n'
      '\t\t\tpath = $_target;\n'
      '\t\t\tsourceTree = "<group>";\n'
      '\t\t};\n';

  final targetText = '\t\t$target /* $_target */ = {\n'
      '\t\t\tisa = PBXNativeTarget;\n'
      '\t\t\tbuildConfigurationList = $configList /* Build configuration list '
      'for PBXNativeTarget "$_target" */;\n'
      '\t\t\tbuildPhases = (\n'
      '${list([
        '$sources /* Sources */',
        '$frameworks /* Frameworks */',
        '$resources /* Resources */'
      ])}'
      '\t\t\t);\n'
      '\t\t\tbuildRules = (\n\t\t\t);\n'
      '\t\t\tdependencies = (\n\t\t\t);\n'
      '\t\t\tname = $_target;\n'
      '\t\t\tproductName = $_target;\n'
      '\t\t\tproductReference = $appRef /* $_product */;\n'
      '\t\t\tproductType = "com.apple.product-type.application";\n'
      '\t\t};\n';

  String phase(
          String phaseId, String name, String isa, Iterable<String> files) =>
      '\t\t$phaseId /* $name */ = {\n'
      '\t\t\tisa = $isa;\n'
      '\t\t\tbuildActionMask = 2147483647;\n'
      '\t\t\tfiles = (\n${list(files)}\t\t\t);\n'
      '\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
      '\t\t};\n';

  // Aplikace pro hodinky se vkládá do Runner.app/Watch (dstSubfolderSpec
  // 16 = Products Directory).
  final embedText = '\t\t$embed /* $_embedPhase */ = {\n'
      '\t\t\tisa = PBXCopyFilesBuildPhase;\n'
      '\t\t\tbuildActionMask = 2147483647;\n'
      '\t\t\tdstPath = "\$(CONTENTS_FOLDER_PATH)/Watch";\n'
      '\t\t\tdstSubfolderSpec = 16;\n'
      '\t\t\tfiles = (\n'
      '\t\t\t\t$appBuild /* $_product in $_embedPhase */,\n'
      '\t\t\t);\n'
      '\t\t\tname = "$_embedPhase";\n'
      '\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
      '\t\t};\n';

  final proxyText = '\t\t$proxy /* PBXContainerItemProxy */ = {\n'
      '\t\t\tisa = PBXContainerItemProxy;\n'
      '\t\t\tcontainerPortal = $projectId /* Project object */;\n'
      '\t\t\tproxyType = 1;\n'
      '\t\t\tremoteGlobalIDString = $target;\n'
      '\t\t\tremoteInfo = $_target;\n'
      '\t\t};\n';

  final dependencyText = '\t\t$dependency /* PBXTargetDependency */ = {\n'
      '\t\t\tisa = PBXTargetDependency;\n'
      '\t\t\ttarget = $target /* $_target */;\n'
      '\t\t\ttargetProxy = $proxy /* PBXContainerItemProxy */;\n'
      '\t\t};\n';

  String config(String name) {
    final debug = name == 'Debug';
    return '\t\t${configs[name]} /* $name */ = {\n'
        '\t\t\tisa = XCBuildConfiguration;\n'
        '\t\t\tbaseConfigurationReference = ${refs['$_target.xcconfig']} '
        '/* $_target.xcconfig */;\n'
        '\t\t\tbuildSettings = {\n'
        '\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n'
        '\t\t\t\tCLANG_ENABLE_MODULES = YES;\n'
        '\t\t\t\tCODE_SIGN_ENTITLEMENTS = $_target/$_target.entitlements;\n'
        '\t\t\t\tCURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";\n'
        '\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n'
        '\t\t\t\tINFOPLIST_FILE = $_target/Info.plist;\n'
        '\t\t\t\tINFOPLIST_KEY_WKCompanionAppBundleIdentifier = $_bundleId;\n'
        '\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n'
        '\t\t\t\t\t"\$(inherited)",\n'
        '\t\t\t\t\t"@executable_path/Frameworks",\n'
        '\t\t\t\t);\n'
        '\t\t\t\tMARKETING_VERSION = "\$(FLUTTER_BUILD_NAME)";\n'
        '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = $_bundleId.watchkitapp;\n'
        '\t\t\t\tPRODUCT_NAME = "\$(TARGET_NAME)";\n'
        '\t\t\t\tSDKROOT = watchos;\n'
        '\t\t\t\tSKIP_INSTALL = YES;\n'
        '\t\t\t\tSUPPORTED_PLATFORMS = "watchos watchsimulator";\n'
        '${debug ? '\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n' : ''}'
        '${debug ? '\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n' : ''}'
        '\t\t\t\tSWIFT_VERSION = 5.0;\n'
        '\t\t\t\tTARGETED_DEVICE_FAMILY = 4;\n'
        '\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 9.0;\n'
        '\t\t\t};\n'
        '\t\t\tname = $name;\n'
        '\t\t};\n';
  }

  final configListText = '\t\t$configList /* Build configuration list for '
      'PBXNativeTarget "$_target" */ = {\n'
      '\t\t\tisa = XCConfigurationList;\n'
      '\t\t\tbuildConfigurations = (\n'
      '${list(configs.entries.map((e) => '${e.value} /* ${e.key} */'))}'
      '\t\t\t);\n'
      '\t\t\tdefaultConfigurationIsVisible = 0;\n'
      '\t\t\tdefaultConfigurationName = Release;\n'
      '\t\t};\n';

  // --- vložení do sekcí (sekci, která chybí, založí)
  final inserts = <(int, String)>[];
  void section(String name, String text) {
    final end = s.indexOf('/* End $name section */');
    if (end >= 0) {
      inserts.add((end, text));
    } else {
      final at = s.indexOf('/* Begin PBXBuildFile section */');
      inserts.add(
          (at, '/* Begin $name section */\n$text/* End $name section */\n\n'));
    }
  }

  section('PBXBuildFile', buildFiles.toString());
  section('PBXContainerItemProxy', proxyText);
  section('PBXCopyFilesBuildPhase', embedText);
  section('PBXFileReference', fileRefs.toString());
  section('PBXFrameworksBuildPhase',
      phase(frameworks, 'Frameworks', 'PBXFrameworksBuildPhase', const []));
  section('PBXGroup', groupText);
  section('PBXNativeTarget', targetText);
  section(
      'PBXResourcesBuildPhase',
      phase(resources, 'Resources', 'PBXResourcesBuildPhase',
          ['$assetsBuild /* $_assets in Resources */']));
  section(
    'PBXSourcesBuildPhase',
    phase(sources, 'Sources', 'PBXSourcesBuildPhase',
        _swiftFiles.map((f) => '${watchBuild[f]} /* $f in Sources */')),
  );
  section('PBXTargetDependency', dependencyText);
  section('XCBuildConfiguration',
      ['Debug', 'Release', 'Profile'].map(config).join());
  section('XCConfigurationList', configListText);

  // --- úpravy existujících objektů
  int? listEnd(int from, String key) {
    final open = s.indexOf('$key = (', from);
    if (open < 0) return null;
    final close = s.indexOf(');', open);
    return close < 0 ? null : close;
  }

  // Hlavní skupina a Products.
  final mainGroup = RegExp(
          '$mainGroupId(?: /\\* [^*]* \\*/)? = \\{\\s*isa = PBXGroup;\\s*children = \\(')
      .firstMatch(s);
  final productsGroup = RegExp(
          '$productsId /\\* Products \\*/ = \\{\\s*isa = PBXGroup;\\s*children = \\(')
      .firstMatch(s);
  if (mainGroup == null || productsGroup == null) {
    fail('hlavní skupina nebo Products');
    return false;
  }
  inserts
    ..add((mainGroup.end, '\n\t\t\t\t$group /* $_target */,'))
    ..add((productsGroup.end, '\n\t\t\t\t$appRef /* $_product */,'));

  // Cíl Runner: vložení aplikace pro hodinky (před „Thin Binary“, jinak
  // Xcode hlásí cyklus závislostí) a závislost na jejím cíli.
  final runnerPhasesEnd = listEnd(runnerTarget.end, 'buildPhases');
  final runnerDepsEnd = listEnd(runnerTarget.end, 'dependencies');
  if (runnerPhasesEnd == null || runnerDepsEnd == null) {
    fail('fáze cíle Runner');
    return false;
  }
  final phasesText = s.substring(runnerTarget.end, runnerPhasesEnd);
  final thin = phasesText.indexOf(RegExp(r'[0-9A-F]{24} /\* Thin Binary \*/'));
  final embedAt = thin >= 0
      ? s.lastIndexOf('\n', runnerTarget.end + thin) + 1
      : s.lastIndexOf('\n', runnerPhasesEnd) + 1;
  inserts
    ..add((embedAt, '\t\t\t\t$embed /* $_embedPhase */,\n'))
    ..add((
      s.lastIndexOf('\n', runnerDepsEnd) + 1,
      '\t\t\t\t$dependency /* PBXTargetDependency */,\n'
    ));

  // Projekt: seznam cílů a jejich atributy.
  final targetsEnd = listEnd(s.indexOf('isa = PBXProject;'), 'targets');
  final attributes = s.indexOf('TargetAttributes = {');
  if (targetsEnd == null || attributes < 0) {
    fail('seznam cílů projektu');
    return false;
  }
  inserts
    ..add((
      s.lastIndexOf('\n', targetsEnd) + 1,
      '\t\t\t\t$target /* $_target */,\n'
    ))
    ..add((
      attributes + 'TargetAttributes = {'.length,
      '\n\t\t\t\t\t$target = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n\t\t\t\t\t};'
    ));

  // Vkládá se odzadu, ať se dřívější pozice neposunou.
  inserts.sort((a, b) => b.$1.compareTo(a.$1));
  for (final (at, text) in inserts) {
    s = s.replaceRange(at, at, text);
  }
  file.writeAsStringSync(s);
  stdout
      .writeln('✓ $_pbxproj: cíl $_target (aplikace pro Apple Watch) přidán.');
  return true;
}
