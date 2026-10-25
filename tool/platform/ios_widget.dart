import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show md5;

/// iOS widget „Dnes“ a Live Activity odpočtu pauzy (docs/ios_widget.md).
///
/// Swift soubory jsou v ios/GymBarWidget/ a ios/Runner/RestLiveActivity.swift.
/// Tenhle skript je zapojí: přidá do Xcode projektu cíl GymBarWidget
/// (rozšíření WidgetKitu, vložené do aplikace), App Group do entitlements,
/// Live Activity do Info.plist a registraci kanálu do AppDelegate.swift.
///
/// Cíl potřebuje App Group zaregistrovanou v Apple Developer účtu – bez ní
/// podepsaný build (Codemagic, TestFlight) selže. Proto se zapíná jen na
/// vyžádání ([enable], `dart run tool/ios_widget.dart`); jakmile je cíl
/// v projektu, další spuštění ho jen udržují. Bezpečné spustit opakovaně.
bool patchIosWidget({required bool enable}) {
  if (!Directory('ios/Runner').existsSync()) {
    stdout.writeln('• ios/Runner nenalezen – iOS widget přeskočen.');
    return true;
  }
  final project = File(_pbxproj);
  if (!project.existsSync()) {
    stdout.writeln('• $_pbxproj nenalezen – iOS widget přeskočen.');
    return true;
  }
  final present = project.readAsStringSync().contains('/* $_product */');
  if (!enable && !present) {
    stdout.writeln('• iOS widget a Live Activity: vypnuté (zapnutí: '
        'dart run tool/ios_widget.dart, docs/ios_widget.md).');
    return true;
  }
  for (final f in [
    ..._widgetFiles.map((f) => 'ios/$_target/$f'),
    _runnerSwift
  ]) {
    if (!File(f).existsSync()) {
      stderr.writeln('✗ $f chybí – iOS widget nejde zapnout.');
      return false;
    }
  }
  var ok = true;
  ok &= _checkBundleId();
  ok &= _patchProject();
  ok &= _patchEntitlements();
  ok &= _patchInfoPlist();
  ok &= _patchAppDelegate();
  return ok;
}

const _pbxproj = 'ios/Runner.xcodeproj/project.pbxproj';
const _target = 'GymBarWidget';
const _product = '$_target.appex';
const _runnerSwift = 'ios/Runner/RestLiveActivity.swift';
const _sharedSwift = 'RestTimerAttributes.swift';

/// Musí odpovídat kIosAppGroup (lib/modules/widgets/widget_content.dart),
/// kAppGroup (ios/GymBarWidget/WidgetShared.swift) a
/// GymBarWidget.entitlements.
const _bundleId = 'cz.dedina.fitnessApp';
const _appGroup = 'group.$_bundleId';

/// Soubory ve složce ios/GymBarWidget (pořadí = pořadí v Xcode).
const _swiftFiles = [
  'GymBarWidgetBundle.swift',
  'TodayWidget.swift',
  'TodayContent.swift',
  'TodayViews.swift',
  'WidgetShared.swift',
  'RestActivityWidget.swift',
  'RestActivityViews.swift',
  _sharedSwift,
];
const _otherFiles = [
  'Info.plist',
  '$_target.entitlements',
  '$_target.xcconfig',
];
const _widgetFiles = [..._swiftFiles, ..._otherFiles];

// ---------------------------------------------------------------- bundle ID

bool _checkBundleId() {
  final s = File(_pbxproj).readAsStringSync();
  final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
      .allMatches(s)
      .map((m) => m.group(1)!.replaceAll('"', ''))
      .where((id) => !id.contains('.RunnerTests') && !id.endsWith('.$_target'))
      .toSet();
  if (ids.isNotEmpty && !ids.contains(_bundleId)) {
    stdout.writeln('! Bundle ID aplikace je ${ids.join(', ')}, widget počítá '
        's $_bundleId – uprav App Group v ios/$_target/WidgetShared.swift, '
        'obou .entitlements, kIosAppGroup a _bundleId v '
        'tool/platform/ios_widget.dart.');
  }
  return true;
}

// ---------------------------------------------------------------- projekt

/// ID objektu v project.pbxproj: 24 hex znaků, stabilní podle [seed]
/// a jiné než všechna ID v projektu (stejně jako ios_store.dart).
String _newId(String project, String seed) {
  for (var i = 0;; i++) {
    final id = md5
        .convert(utf8.encode('gymbar-widget:$seed:$i'))
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
      'cíl $_target nepřidán (docs/ios_widget.md, ruční postup v Xcode).');

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

  final refs = {for (final f in _widgetFiles) f: id('ref:$f')};
  final runnerRef = id('ref:RestLiveActivity.swift');
  final appexRef = id('ref:$_product');
  final group = id('group');
  final widgetBuild = {for (final f in _swiftFiles) f: id('build:$f')};
  final runnerBuild = id('build:runner:RestLiveActivity.swift');
  final sharedRunnerBuild = id('build:runner:$_sharedSwift');
  final appexBuild = id('build:embed:$_product');
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
    buildFiles.writeln('\t\t${widgetBuild[f]} /* $f in Sources */ = '
        '{isa = PBXBuildFile; fileRef = ${refs[f]} /* $f */; };');
  }
  buildFiles
    ..writeln('\t\t$runnerBuild /* RestLiveActivity.swift in Sources */ = '
        '{isa = PBXBuildFile; fileRef = $runnerRef /* RestLiveActivity.swift */; };')
    ..writeln('\t\t$sharedRunnerBuild /* $_sharedSwift in Sources */ = '
        '{isa = PBXBuildFile; fileRef = ${refs[_sharedSwift]} /* $_sharedSwift */; };')
    ..writeln(
        '\t\t$appexBuild /* $_product in Embed Foundation Extensions */ = '
        '{isa = PBXBuildFile; fileRef = $appexRef /* $_product */; '
        'settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };');

  final fileRefs = StringBuffer();
  for (final f in _widgetFiles) {
    fileRefs.writeln('\t\t${refs[f]} /* $f */ = {isa = PBXFileReference; '
        'lastKnownFileType = ${_fileType(f)}; path = $f; sourceTree = "<group>"; };');
  }
  fileRefs
    ..writeln(
        '\t\t$runnerRef /* RestLiveActivity.swift */ = {isa = PBXFileReference; '
        'lastKnownFileType = sourcecode.swift; path = RestLiveActivity.swift; '
        'sourceTree = "<group>"; };')
    ..writeln('\t\t$appexRef /* $_product */ = {isa = PBXFileReference; '
        'explicitFileType = "wrapper.app-extension"; includeInIndex = 0; '
        'path = $_product; sourceTree = BUILT_PRODUCTS_DIR; };');

  String list(Iterable<String> items) =>
      items.map((i) => '\t\t\t\t$i,\n').join();

  final groupText = '\t\t$group /* $_target */ = {\n'
      '\t\t\tisa = PBXGroup;\n'
      '\t\t\tchildren = (\n'
      '${list(_widgetFiles.map((f) => '${refs[f]} /* $f */'))}'
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
      '\t\t\tproductReference = $appexRef /* $_product */;\n'
      '\t\t\tproductType = "com.apple.product-type.app-extension";\n'
      '\t\t};\n';

  String phase(
          String phaseId, String name, String isa, Iterable<String> files) =>
      '\t\t$phaseId /* $name */ = {\n'
      '\t\t\tisa = $isa;\n'
      '\t\t\tbuildActionMask = 2147483647;\n'
      '\t\t\tfiles = (\n${list(files)}\t\t\t);\n'
      '\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
      '\t\t};\n';

  final embedText = '\t\t$embed /* Embed Foundation Extensions */ = {\n'
      '\t\t\tisa = PBXCopyFilesBuildPhase;\n'
      '\t\t\tbuildActionMask = 2147483647;\n'
      '\t\t\tdstPath = "";\n'
      '\t\t\tdstSubfolderSpec = 13;\n'
      '\t\t\tfiles = (\n'
      '\t\t\t\t$appexBuild /* $_product in Embed Foundation Extensions */,\n'
      '\t\t\t);\n'
      '\t\t\tname = "Embed Foundation Extensions";\n'
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
        '\t\t\t\tCLANG_ENABLE_MODULES = YES;\n'
        '\t\t\t\tCODE_SIGN_ENTITLEMENTS = $_target/$_target.entitlements;\n'
        '\t\t\t\tCURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";\n'
        '\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n'
        '\t\t\t\tINFOPLIST_FILE = $_target/Info.plist;\n'
        '\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.2;\n'
        '\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n'
        '\t\t\t\t\t"\$(inherited)",\n'
        '\t\t\t\t\t"@executable_path/Frameworks",\n'
        '\t\t\t\t\t"@executable_path/../../Frameworks",\n'
        '\t\t\t\t);\n'
        '\t\t\t\tMARKETING_VERSION = "\$(FLUTTER_BUILD_NAME)";\n'
        '\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = $_bundleId.$_target;\n'
        '\t\t\t\tPRODUCT_NAME = "\$(TARGET_NAME)";\n'
        '\t\t\t\tSKIP_INSTALL = YES;\n'
        '${debug ? '\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n' : ''}'
        '${debug ? '\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";\n' : ''}'
        '\t\t\t\tSWIFT_VERSION = 5.0;\n'
        '\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n'
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
  section('PBXResourcesBuildPhase',
      phase(resources, 'Resources', 'PBXResourcesBuildPhase', const []));
  section(
    'PBXSourcesBuildPhase',
    phase(sources, 'Sources', 'PBXSourcesBuildPhase',
        _swiftFiles.map((f) => '${widgetBuild[f]} /* $f in Sources */')),
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
    ..add((productsGroup.end, '\n\t\t\t\t$appexRef /* $_product */,'))
    ..add((
      runnerGroup.end,
      '\n\t\t\t\t$runnerRef /* RestLiveActivity.swift */,'
    ));

  // Cíl Runner: vložení rozšíření (před „Thin Binary“, jinak Xcode hlásí
  // cyklus závislostí) a závislost na cíli widgetu.
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
    ..add((embedAt, '\t\t\t\t$embed /* Embed Foundation Extensions */,\n'))
    ..add((
      s.lastIndexOf('\n', runnerDepsEnd) + 1,
      '\t\t\t\t$dependency /* PBXTargetDependency */,\n'
    ));

  // Zdrojáky cíle Runner (fáze Sources, kde je AppDelegate.swift).
  int? runnerSourcesAt;
  for (final m in RegExp(
          r'isa = PBXSourcesBuildPhase;\s*buildActionMask = \d+;\s*files = \(')
      .allMatches(s)) {
    final end = s.indexOf(');', m.end);
    if (end > 0 &&
        s.substring(m.end, end).contains('AppDelegate.swift in Sources')) {
      runnerSourcesAt = m.end;
      break;
    }
  }
  if (runnerSourcesAt == null) {
    fail('fáze Sources cíle Runner');
    return false;
  }
  inserts.add((
    runnerSourcesAt,
    '\n\t\t\t\t$runnerBuild /* RestLiveActivity.swift in Sources */,'
        '\n\t\t\t\t$sharedRunnerBuild /* $_sharedSwift in Sources */,'
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
  stdout.writeln('✓ $_pbxproj: cíl $_target (widget a Live Activity) přidán.');
  return true;
}

// ---------------------------------------------------------------- App Group

bool _patchEntitlements() {
  final file = File('ios/Runner/Runner.entitlements');
  const key = 'com.apple.security.application-groups';
  const entry = '\t<key>$key</key>\n'
      '\t<array>\n\t\t<string>$_appGroup</string>\n\t</array>\n';
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} chybí – nejdřív spusť '
        'dart run tool/setup_platforms.dart.');
    return false;
  }
  var s = file.readAsStringSync();
  if (s.contains('<key>$key</key>')) {
    if (!s.contains('<string>$_appGroup</string>')) {
      stderr.writeln(
          '✗ ${file.path}: $key existuje bez $_appGroup – doplň ho ručně.');
      return false;
    }
    stdout.writeln('• ${file.path}: App Group už nastavená.');
    return true;
  }
  final i = s.lastIndexOf('</dict>');
  if (i < 0) {
    stderr.writeln('✗ ${file.path}: neznámý formát – doplň $key ručně.');
    return false;
  }
  s = s.replaceRange(i, i, entry);
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: App Group $_appGroup.');
  return true;
}

// ---------------------------------------------------------------- Info.plist

bool _patchInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;
  // Live Activity (odpočet pauzy na zamykací obrazovce a v Dynamic Islandu).
  if (!s.contains('<key>NSSupportsLiveActivities</key>')) {
    final i = s.lastIndexOf('</dict>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: neznámý formát – doplň '
          'NSSupportsLiveActivities ručně.');
      return false;
    }
    s = s.replaceRange(
        i, i, '\t<key>NSSupportsLiveActivities</key>\n\t<true/>\n');
  }
  // Odkazy z widgetu (homewidget://…, kWidgetUriScheme) otevírají aplikaci.
  if (!s.contains('<string>homewidget</string>')) {
    final gymbar = RegExp(r'([ \t]*)<string>gymbar</string>\n').firstMatch(s);
    if (gymbar == null) {
      stderr.writeln('! ${file.path}: schéma gymbar v CFBundleURLSchemes '
          'nenalezeno – schéma homewidget doplň ručně.');
    } else {
      s = s.replaceRange(gymbar.end, gymbar.end,
          '${gymbar.group(1)}<string>homewidget</string>\n');
    }
  }
  if (s == original) {
    stdout.writeln(
        '• ${file.path}: Live Activity a odkazy widgetu už nastavené.');
    return true;
  }
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: Live Activity a odkazy widgetu.');
  return true;
}

// ---------------------------------------------------------------- AppDelegate

bool _patchAppDelegate() {
  final file = File('ios/Runner/AppDelegate.swift');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  if (s.contains('RestLiveActivityPlugin.register')) {
    stdout.writeln('• ${file.path}: Live Activity už registrovaná.');
    return true;
  }
  // Nová šablona Flutteru (implicitní engine) i starší AppDelegate.
  // Soubor z Windows může mít konce řádků \r\n – zachovají se.
  final implicit = RegExp(
    r'([ \t]*)GeneratedPluginRegistrant\.register\(with: engineBridge\.pluginRegistry\)(\r?\n)',
  ).firstMatch(s);
  final classic = RegExp(
    r'([ \t]*)GeneratedPluginRegistrant\.register\(with: self\)(\r?\n)',
  ).firstMatch(s);
  final m = implicit ?? classic;
  if (m == null) {
    stderr.writeln('✗ ${file.path}: GeneratedPluginRegistrant.register '
        'nenalezen – registraci RestLiveActivityPlugin doplň ručně '
        '(docs/ios_widget.md).');
    return false;
  }
  final indent = m.group(1)!;
  final eol = m.group(2)!;
  final registry = implicit != null ? 'engineBridge.pluginRegistry' : 'self';
  final code =
      '$indent// Live Activity odpočtu pauzy (tool/platform/ios_widget.dart).$eol'
      '${indent}if let registrar = $registry.registrar(forPlugin: "RestLiveActivityPlugin") {$eol'
      '$indent  RestLiveActivityPlugin.register(with: registrar)$eol'
      '$indent}$eol';
  s = s.replaceRange(m.end, m.end, code);
  file.writeAsStringSync(s);
  stdout.writeln('✓ ${file.path}: Live Activity registrovaná.');
  return true;
}
