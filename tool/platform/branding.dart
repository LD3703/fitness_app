import 'dart:io';

/// Název aplikace pod ikonou (Android i iOS).
const kAppName = 'GymBar';

/// Barva značky (teal z loga) – akcent upozornění na Androidu.
const _brandColor = '#2E7D6B';

/// Malá ikona upozornění: bílá silueta činky z loga (Android ji sám
/// obarví; barevná ikona aplikace by se v liště ukázala jako šedý čtverec).
/// Je to mírně tučnější silueta loga z assets/branding/logo.svg, aby byla
/// čitelná i ve velikosti 24 dp.
const _notificationIcon = '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="100"
    android:viewportHeight="100">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M10,47.5h80v5h-80z M18,40h10v20h-10z M30,34h10v32h-10z M60,28h10v44h-10z M72,21h10v58h-10z" />
</vector>
''';

const _colors = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="gymbar_teal">$_brandColor</color>
</resources>
''';

/// Název aplikace, ikona upozornění a barva značky v nativních souborech.
/// Ikony aplikace a úvodní obrazovku generují balíčky
/// flutter_launcher_icons a flutter_native_splash (README, kapitola 2e).
bool patchBranding() {
  var ok = true;
  ok &= _android();
  ok &= _ios();
  return ok;
}

bool _android() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('✗ ${manifest.path} nenalezen.');
    return false;
  }
  final done = <String>[];

  if (_writeIfChanged(
      'android/app/src/main/res/drawable/ic_stat_gymbar.xml',
      _notificationIcon)) {
    done.add('ikona upozornění');
  }
  if (_writeIfChanged(
      'android/app/src/main/res/values/gymbar_colors.xml', _colors)) {
    done.add('barva');
  }

  var s = manifest.readAsStringSync();
  final original = s;

  final app = RegExp(r'<application[^>]*>').firstMatch(s);
  if (app == null) {
    stderr.writeln('✗ ${manifest.path}: značka <application> nenalezena.');
    return false;
  }
  final tag = app.group(0)!;
  final labelled = tag.contains('android:label=')
      ? tag.replaceFirst(
          RegExp(r'android:label="[^"]*"'), 'android:label="$kAppName"')
      : tag.replaceFirst(
          '<application', '<application\n        android:label="$kAppName"');
  if (labelled != tag) {
    s = s.replaceRange(app.start, app.end, labelled);
    done.add('název $kAppName');
  }

  // Výchozí ikona a barva pro push upozornění z Firebase (firebase_messaging).
  final meta = <String>[
    if (!s.contains('default_notification_icon'))
      '        <meta-data\n'
          '            android:name="com.google.firebase.messaging.default_notification_icon"\n'
          '            android:resource="@drawable/ic_stat_gymbar" />',
    if (!s.contains('default_notification_color'))
      '        <meta-data\n'
          '            android:name="com.google.firebase.messaging.default_notification_color"\n'
          '            android:resource="@color/gymbar_teal" />',
  ];
  if (meta.isNotEmpty) {
    final m = RegExp(r'<application[^>]*>').firstMatch(s)!;
    s = s.replaceRange(m.end, m.end, '\n${meta.join('\n')}');
    done.add('ikona push upozornění');
  }

  if (s != original) manifest.writeAsStringSync(s);
  stdout.writeln(done.isEmpty
      ? '• Android: název a ikona upozornění už nastavené.'
      : '✓ Android: ${done.join(', ')}.');
  return true;
}

bool _ios() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) return true;
  var s = file.readAsStringSync();
  final original = s;
  for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
    final re = RegExp('<key>$key</key>(\\s*)<string>[^<]*</string>');
    if (re.hasMatch(s)) {
      s = s.replaceFirstMapped(
          re, (m) => '<key>$key</key>${m[1]}<string>$kAppName</string>');
    } else {
      final i = s.lastIndexOf('</dict>');
      if (i < 0) {
        stderr.writeln('✗ ${file.path}: značka </dict> nenalezena.');
        return false;
      }
      s = s.replaceRange(
          i, i, '\t<key>$key</key>\n\t<string>$kAppName</string>\n');
    }
  }
  if (s == original) {
    stdout.writeln('• ${file.path}: název už nastavený.');
  } else {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: název $kAppName.');
  }
  return true;
}

/// Zapíše soubor, jen když chybí nebo má jiný obsah. Vrací true při zápisu.
bool _writeIfChanged(String path, String content) {
  final file = File(path);
  if (file.existsSync() && file.readAsStringSync() == content) return false;
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  return true;
}
