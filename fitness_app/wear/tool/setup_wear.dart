// Úprava nativních souborů aplikace pro HODINKY (Wear OS).
//
// Spouští se ve složce wear/ po `flutter create`:
//   flutter create . --platforms android --org cz.dedina --project-name fitness_wear
//   dart run tool/setup_wear.dart
//
// Co udělá (bezpečné spustit opakovaně):
// - build.gradle(.kts): applicationId STEJNÉ jako aplikace v telefonu
//   (přečte ho z ../android/app/build.gradle.kts, jinak cz.dedina.fitness_app;
//   jde zadat i parametrem: dart run tool/setup_wear.dart cz.neco.fitness_app),
//   minSdk 30 (Wear OS 3+).
// - AndroidManifest.xml: uses-feature android.hardware.type.watch,
//   oprávnění VIBRATE a WAKE_LOCK, knihovna com.google.android.wearable
//   (nepovinná), meta-data com.google.android.wearable.standalone = false
//   (aplikace bez telefonu nefunguje), název aplikace jako v telefonu.
// - MainActivity.kt: vibrace, displej zapnutý během pauzy a otočná
//   korunka (kanály fitness_wear/native a fitness_wear/rotary, viz
//   lib/native.dart). Soubor se celý přepíše.
// - Černé pozadí při startu (místo bílého záblesku).
// - Smaže výchozí test/widget_test.dart z `flutter create` (odkazuje na
//   neexistující MyApp).
import 'dart:io';

const _defaultApplicationId = 'cz.dedina.fitness_app';

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync() ||
      !File('pubspec.yaml').readAsStringSync().contains('name: fitness_wear')) {
    stderr.writeln('✗ Spusť skript ve složce wear/ (cd wear).');
    exitCode = 1;
    return;
  }
  if (!Directory('android').existsSync()) {
    stderr.writeln('✗ Složka android/ chybí. Nejdřív spusť:\n'
        '  flutter create . --platforms android --org cz.dedina '
        '--project-name fitness_wear');
    exitCode = 1;
    return;
  }
  final applicationId =
      args.isNotEmpty ? args.first : (_phoneApplicationId() ?? _defaultApplicationId);
  stdout.writeln('ID aplikace (stejné jako v telefonu): $applicationId');

  var ok = true;
  ok &= _patchGradle(applicationId);
  ok &= _patchManifest();
  ok &= _writeMainActivity();
  _blackLaunchBackground();
  _removeDefaultTest();

  stdout.writeln(ok
      ? '\nHotovo. Teď spusť: flutter pub get && flutter run -d <hodinky>'
      : '\nNěkteré soubory se nepodařilo upravit – viz výpis výše.');
  if (!ok) exitCode = 1;
}

// ---------------------------------------------------------------- Telefon

String? _phoneApplicationId() {
  for (final path in [
    '../android/app/build.gradle.kts',
    '../android/app/build.gradle',
  ]) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final m = RegExp(r'''applicationId\s*=?\s*["']([\w.]+)["']''')
        .firstMatch(f.readAsStringSync());
    if (m != null) return m.group(1);
  }
  return null;
}

String? _phoneLabel() {
  final f = File('../android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) return null;
  final m = RegExp(r'<application[^>]*android:label="([^"]*)"')
      .firstMatch(f.readAsStringSync());
  return m?.group(1);
}

// ---------------------------------------------------------------- Gradle

bool _patchGradle(String applicationId) {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final file = kts.existsSync() ? kts : (groovy.existsSync() ? groovy : null);
  if (file == null) {
    stderr.writeln('✗ android/app/build.gradle(.kts) nenalezen.');
    return false;
  }
  final kotlin = file == kts;
  var s = file.readAsStringSync();
  final original = s;

  final idRe = RegExp(r'''applicationId\s*=?\s*["'][\w.]+["']''');
  if (!idRe.hasMatch(s)) {
    stderr.writeln('✗ ${file.path}: řádek applicationId nenalezen.');
    return false;
  }
  s = s.replaceFirst(
    idRe,
    kotlin ? 'applicationId = "$applicationId"' : 'applicationId "$applicationId"',
  );

  final minRe = kotlin
      ? RegExp(r'minSdk\s*=\s*[^\n]+')
      : RegExp(r'minSdk(Version)?\s+[^\n]+');
  if (minRe.hasMatch(s)) {
    s = s.replaceFirst(minRe, kotlin ? 'minSdk = 30' : 'minSdkVersion 30');
  } else {
    final m = RegExp(r'defaultConfig\s*\{').firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: blok defaultConfig nenalezen.');
      return false;
    }
    s = s.replaceRange(m.end, m.end,
        kotlin ? '\n        minSdk = 30' : '\n        minSdkVersion 30');
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: applicationId $applicationId, minSdk 30.');
  } else {
    stdout.writeln('• ${file.path}: už upraveno.');
  }
  return true;
}

// ---------------------------------------------------------------- Manifest

bool _patchManifest() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;

  final top = <String>[
    if (!s.contains('android.hardware.type.watch'))
      '    <uses-feature android:name="android.hardware.type.watch" />',
    for (final p in ['android.permission.VIBRATE', 'android.permission.WAKE_LOCK'])
      if (!s.contains('"$p"')) '    <uses-permission android:name="$p" />',
  ];
  if (top.isNotEmpty) {
    final m = RegExp(r'<manifest[^>]*>').firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: značka <manifest> nenalezena.');
      return false;
    }
    s = s.replaceRange(m.end, m.end, '\n${top.join('\n')}');
  }

  final inApp = <String>[
    if (!s.contains('com.google.android.wearable.standalone'))
      '''        <!-- Aplikace potřebuje aplikaci v telefonu (zápis jde přes ni). -->
        <meta-data
            android:name="com.google.android.wearable.standalone"
            android:value="false" />''',
    if (!s.contains('android:name="com.google.android.wearable"'))
      '''        <uses-library
            android:name="com.google.android.wearable"
            android:required="false" />''',
  ];
  if (inApp.isNotEmpty) {
    final m = RegExp(r'<application[^>]*>').firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: značka <application> nenalezena.');
      return false;
    }
    s = s.replaceRange(m.end, m.end, '\n${inApp.join('\n')}');
  }

  // Stejný název jako aplikace v telefonu (flutter create dá „fitness_wear“).
  final label = _phoneLabel() ?? 'Fitness App';
  s = s.replaceFirst(
    RegExp(r'android:label="fitness_wear"'),
    'android:label="$label"',
  );

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: nastaveno pro hodinky.');
  } else {
    stdout.writeln('• ${file.path}: už upraveno.');
  }
  return true;
}

// ---------------------------------------------------------------- Kotlin

File? _findMainActivity() {
  for (final root in [
    'android/app/src/main/kotlin',
    'android/app/src/main/java',
  ]) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name == 'MainActivity.kt' || name == 'MainActivity.java') return f;
    }
  }
  return null;
}

bool _writeMainActivity() {
  final existing = _findMainActivity();
  if (existing == null) {
    stderr.writeln('✗ MainActivity nenalezena v android/app/src/main.');
    return false;
  }
  final pkg = RegExp(r'^\s*package\s+([\w.]+)', multiLine: true)
      .firstMatch(existing.readAsStringSync())
      ?.group(1);
  if (pkg == null) {
    stderr.writeln('✗ ${existing.path}: řádek „package“ nenalezen.');
    return false;
  }
  final target = File('${existing.parent.path}/MainActivity.kt');
  final content = _mainActivity.replaceAll('__PACKAGE__', pkg);
  if (existing.path.endsWith('.java')) existing.deleteSync();
  if (target.existsSync() && target.readAsStringSync() == content) {
    stdout.writeln('• ${target.path}: aktuální.');
    return true;
  }
  target.writeAsStringSync(content);
  stdout.writeln('✓ ${target.path}: vibrace, displej a korunka.');
  return true;
}

const _mainActivity = r'''package __PACKAGE__

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.InputDevice
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Aplikace pro hodinky. Soubor zapisuje wear/tool/setup_wear.dart –
 * ruční úpravy se při dalším spuštění přepíšou.
 *
 * - fitness_wear/native: vibrate (konec pauzy), keepScreenOn(Boolean)
 * - fitness_wear/rotary: posun z otočné korunky / lunety v pixelech
 */
class MainActivity : FlutterActivity() {
    private var rotarySink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "fitness_wear/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    vibrate()
                    result.success(null)
                }
                "keepScreenOn" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "fitness_wear/rotary").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    rotarySink = events
                }

                override fun onCancel(arguments: Any?) {
                    rotarySink = null
                }
            },
        )
    }

    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        val sink = rotarySink
        if (sink != null &&
            event.action == MotionEvent.ACTION_SCROLL &&
            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
        ) {
            val delta = -event.getAxisValue(MotionEvent.AXIS_SCROLL) *
                ViewConfiguration.get(this).scaledVerticalScrollFactor
            sink.success(delta.toDouble())
            return true
        }
        return super.onGenericMotionEvent(event)
    }

    private fun vibrate() {
        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }
        if (vibrator == null || !vibrator.hasVibrator()) return
        vibrator.vibrate(
            VibrationEffect.createWaveform(longArrayOf(0, 400, 200, 400, 200, 700), -1),
        )
    }
}
''';

// ---------------------------------------------------------------- Ostatní

void _blackLaunchBackground() {
  for (final path in [
    'android/app/src/main/res/drawable/launch_background.xml',
    'android/app/src/main/res/drawable-v21/launch_background.xml',
  ]) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final s = f.readAsStringSync();
    final patched = s
        .replaceAll('@android:color/white', '@android:color/black')
        .replaceAll('?android:colorBackground', '@android:color/black');
    if (patched != s) {
      f.writeAsStringSync(patched);
      stdout.writeln('✓ $path: černé pozadí při startu.');
    }
  }
}

void _removeDefaultTest() {
  final f = File('test/widget_test.dart');
  if (f.existsSync() && f.readAsStringSync().contains('MyApp')) {
    f.deleteSync();
    stdout.writeln('✓ test/widget_test.dart: smazán výchozí test z flutter create.');
  }
}
