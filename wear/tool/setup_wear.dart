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
// - MainActivity.kt: vibrace, displej zapnutý během pauzy, otočná
//   korunka a senzor tepu (kanály fitness_wear/native, fitness_wear/rotary
//   a fitness_wear/heart_rate, viz lib/native.dart). Soubor se celý přepíše.
// - Dlaždice „Dnes“ (TodayTileService.kt) a TodayDataListener.kt: dnešní
//   plán z telefonu (Data Layer, application context balíčku
//   watch_connectivity), oprávnění k senzoru tepu (BODY_SENSORS,
//   od Wear OS 6 health.READ_HEART_RATE), závislosti Tiles a ProtoLayout.
// - Černé pozadí při startu (místo bílého záblesku).
// - Podpis release buildu stejným klíčem jako telefon
//   (../../tool/platform/signing.dart, README „Vydání pro Android“):
//   wear/android/key.properties, jinak android/key.properties telefonu
//   (storeFile v něm musí být absolutní cesta).
// - Smaže výchozí test/widget_test.dart z `flutter create` (odkazuje na
//   neexistující MyApp).
import 'dart:io';

// Stejný podpis release jako telefon (key.properties z ../android).
import '../../tool/platform/signing.dart';

/// Název aplikace na hodinkách (stejný jako v telefonu).
const kAppName = 'GymBar';

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
  final applicationId = args.isNotEmpty
      ? args.first
      : (_phoneApplicationId() ?? _defaultApplicationId);
  stdout.writeln('ID aplikace (stejné jako v telefonu): $applicationId');

  var ok = true;
  ok &= _patchGradle(applicationId);
  ok &= _patchManifest();
  ok &= _writeMainActivity();
  // Hodinky hledají klíč i v ../android/key.properties (telefon).
  ok &= patchSigning(phoneKeyFallback: true);
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
    kotlin
        ? 'applicationId = "$applicationId"'
        : 'applicationId "$applicationId"',
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

  // Dlaždice (Tiles + ProtoLayout) a Data Layer pro TodayTileService.kt.
  if (!s.contains('androidx.wear.tiles:tiles')) {
    final deps = kotlin
        ? _tileDependencies.map((d) => '    implementation("$d")').join('\n')
        : _tileDependencies.map((d) => "    implementation '$d'").join('\n');
    final block =
        '\n// Dlaždice „Dnes“ (wear/tool/setup_wear.dart)\ndependencies {\n$deps\n}\n';
    s = '${s.trimRight()}\n$block';
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: applicationId $applicationId, minSdk 30.');
  } else {
    stdout.writeln('• ${file.path}: už upraveno.');
  }
  return true;
}

const _tileDependencies = [
  'androidx.wear.tiles:tiles:1.4.1',
  'androidx.wear.protolayout:protolayout:1.2.1',
  'androidx.wear.protolayout:protolayout-material:1.2.1',
  'androidx.concurrent:concurrent-futures:1.2.0',
  'com.google.android.gms:play-services-wearable:18.2.0',
];

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
    for (final p in [
      'android.permission.VIBRATE',
      'android.permission.WAKE_LOCK'
    ])
      if (!s.contains('"$p"')) '    <uses-permission android:name="$p" />',
    // Senzor tepu během tréninku: do Wear OS 5 BODY_SENSORS, od Wear OS 6
    // (API 36) oprávnění Health Connect READ_HEART_RATE.
    if (!s.contains('"android.permission.BODY_SENSORS"'))
      '    <uses-permission android:name="android.permission.BODY_SENSORS" '
          'android:maxSdkVersion="35" />',
    if (!s.contains('"android.permission.health.READ_HEART_RATE"'))
      '    <uses-permission android:name="android.permission.health.READ_HEART_RATE" />',
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
    if (!s.contains('.TodayTileService'))
      '''        <!-- Dlaždice „Dnes“: dnešní plán z telefonu. -->
        <service
            android:name=".TodayTileService"
            android:exported="true"
            android:label="$kAppName"
            android:permission="com.google.android.wearable.permission.BIND_TILE_PROVIDER">
            <intent-filter>
                <action android:name="androidx.wear.tiles.action.BIND_TILE_PROVIDER" />
            </intent-filter>
        </service>
        <!-- Nová data z telefonu → obnovit dlaždici. -->
        <service
            android:name=".TodayDataListener"
            android:exported="true">
            <intent-filter>
                <action android:name="com.google.android.gms.wearable.DATA_CHANGED" />
                <data
                    android:scheme="wear"
                    android:host="*"
                    android:pathPrefix="/watch_connectivity" />
            </intent-filter>
        </service>''',
  ];
  if (inApp.isNotEmpty) {
    final m = RegExp(r'<application[^>]*>').firstMatch(s);
    if (m == null) {
      stderr.writeln('✗ ${file.path}: značka <application> nenalezena.');
      return false;
    }
    s = s.replaceRange(m.end, m.end, '\n${inApp.join('\n')}');
  }

  // Stejný název jako aplikace v telefonu (flutter create dá „fitness_wear“,
  // starší verze skriptu převzaly „fitness_app“ / „Fitness App“).
  final app = RegExp(r'<application[^>]*>').firstMatch(s);
  if (app != null) {
    final tag = app.group(0)!.replaceFirst(
        RegExp(r'android:label="[^"]*"'), 'android:label="$kAppName"');
    s = s.replaceRange(app.start, app.end, tag);
  }

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
    _writeKotlin(existing.parent, 'TodayTileService.kt', _todayTile, pkg);
    _writeKotlin(existing.parent, 'TodayDataListener.kt', _todayListener, pkg);
    return true;
  }
  target.writeAsStringSync(content);
  stdout.writeln('✓ ${target.path}: vibrace, displej, korunka a tep.');
  _writeKotlin(existing.parent, 'TodayTileService.kt', _todayTile, pkg);
  _writeKotlin(existing.parent, 'TodayDataListener.kt', _todayListener, pkg);
  return true;
}

void _writeKotlin(Directory dir, String name, String template, String pkg) {
  final file = File('${dir.path}/$name');
  final content = template.replaceAll('__PACKAGE__', pkg);
  if (file.existsSync() && file.readAsStringSync() == content) return;
  file.writeAsStringSync(content);
  stdout.writeln('✓ ${file.path}');
}

const _mainActivity = r'''package __PACKAGE__

import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.InputDevice
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.view.WindowManager
import androidx.wear.tiles.TileService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Aplikace pro hodinky. Soubor zapisuje wear/tool/setup_wear.dart –
 * ruční úpravy se při dalším spuštění přepíšou.
 *
 * - fitness_wear/native: vibrate (konec pauzy), keepScreenOn(Boolean),
 *   updateTile (obnovit dlaždici „Dnes“)
 * - fitness_wear/rotary: posun z otočné korunky / lunety v pixelech
 * - fitness_wear/heart_rate: tep ze senzoru (tepy/min) – jen když ho
 *   aplikace poslouchá (během tréninku), jinak je senzor vypnutý
 */
class MainActivity : FlutterActivity() {
    private var rotarySink: EventChannel.EventSink? = null
    private var heartRateSink: EventChannel.EventSink? = null
    private var heartRateRegistered = false

    private val heartRateListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val bpm = event.values.firstOrNull()?.toInt() ?: return
            if (bpm <= 0 || event.accuracy == SensorManager.SENSOR_STATUS_NO_CONTACT ||
                event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE
            ) {
                return
            }
            heartRateSink?.success(bpm)
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

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
                "updateTile" -> {
                    TileService.getUpdater(this).requestUpdate(TodayTileService::class.java)
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

        EventChannel(messenger, "fitness_wear/heart_rate").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    heartRateSink = events
                    startHeartRate()
                }

                override fun onCancel(arguments: Any?) {
                    stopHeartRate()
                    heartRateSink = null
                }
            },
        )
    }

    /** Do Wear OS 5 BODY_SENSORS, od Wear OS 6 (API 36) READ_HEART_RATE. */
    private fun heartRatePermission(): String =
        if (Build.VERSION.SDK_INT >= 36) {
            "android.permission.health.READ_HEART_RATE"
        } else {
            "android.permission.BODY_SENSORS"
        }

    private fun startHeartRate() {
        if (heartRateRegistered) return
        val permission = heartRatePermission()
        if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(permission), HEART_RATE_REQUEST)
            return
        }
        val manager = getSystemService(SensorManager::class.java) ?: return
        val sensor = manager.getDefaultSensor(Sensor.TYPE_HEART_RATE) ?: return
        heartRateRegistered =
            manager.registerListener(heartRateListener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    private fun stopHeartRate() {
        if (!heartRateRegistered) return
        getSystemService(SensorManager::class.java)?.unregisterListener(heartRateListener)
        heartRateRegistered = false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == HEART_RATE_REQUEST &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            heartRateSink != null
        ) {
            startHeartRate()
        }
    }

    override fun onDestroy() {
        stopHeartRate()
        super.onDestroy()
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

    companion object {
        private const val HEART_RATE_REQUEST = 7301
    }
}
''';

/// Dlaždice „Dnes“: dnešní plán, který telefon poslal jako application
/// context balíčku watch_connectivity (DataItem /watch_connectivity, mapa
/// {fitnessWear: JSON}, viz lib/wear_protocol.dart – WearToday). Texty jsou
/// už přeložené v jazyce telefonu.
const _todayTile = r'''package __PACKAGE__

import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material.CompactChip
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.protolayout.material.layouts.PrimaryLayout
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.android.gms.wearable.DataItemBuffer
import com.google.android.gms.wearable.Wearable
import com.google.common.util.concurrent.ListenableFuture
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/** Soubor zapisuje wear/tool/setup_wear.dart. */
class TodayTileService : TileService() {
    private data class Today(
        val title: String,
        val lines: List<String>,
        val action: String,
    )

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> =
        CallbackToFutureAdapter.getFuture { completer ->
            Wearable.getDataClient(this).dataItems.addOnCompleteListener { task ->
                val today = if (task.isSuccessful) readToday(task.result) else null
                completer.set(tile(requestParams.deviceConfiguration, today))
            }
            "today-tile"
        }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        CallbackToFutureAdapter.getFuture { completer ->
            completer.set(
                ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build(),
            )
            "today-resources"
        }

    /** Poslední „today“ z telefonu; null = nic nebo jiný den. */
    private fun readToday(items: DataItemBuffer?): Today? {
        if (items == null) return null
        try {
            val day = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            for (item in items) {
                if (item.uri.path != "/watch_connectivity") continue
                val bytes = item.data ?: continue
                val map = ObjectInputStream(ByteArrayInputStream(bytes)).readObject()
                    as? Map<*, *> ?: continue
                val json = JSONObject(map["fitnessWear"] as? String ?: continue)
                if (json.optString("t") != "today") continue
                val today = json.optJSONObject("today") ?: continue
                val lines = today.optJSONArray("lines")
                return if (today.optString("day") == day) {
                    Today(
                        title = today.optString("title", "GymBar"),
                        lines = List(lines?.length() ?: 0) { lines!!.optString(it) },
                        action = today.optString("action", "GymBar"),
                    )
                } else {
                    Today(
                        title = today.optString("title", "GymBar"),
                        lines = listOf(today.optString("stale")),
                        action = today.optString("action", "GymBar"),
                    )
                }
            }
        } catch (e: Exception) {
            // Poškozená nebo cizí data – dlaždice ukáže jen otevření aplikace.
        } finally {
            items.release()
        }
        return null
    }

    private fun tile(device: DeviceParameters, today: Today?): TileBuilders.Tile {
        val open = ModifiersBuilders.Clickable.Builder()
            .setId("open")
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setPackageName(packageName)
                            .setClassName(MainActivity::class.java.name)
                            .build(),
                    )
                    .build(),
            )
            .build()
        val content = LayoutElementBuilders.Column.Builder()
        val lines = today?.lines?.filter { it.isNotBlank() }.orEmpty()
        for (line in lines.take(3)) {
            content.addContent(
                Text.Builder(this, line)
                    .setTypography(Typography.TYPOGRAPHY_BODY1)
                    .setColor(argb(0xFFFFFFFF.toInt()))
                    .setMaxLines(2)
                    .build(),
            )
        }
        if (lines.isEmpty()) {
            content.addContent(
                Text.Builder(this, "GymBar")
                    .setTypography(Typography.TYPOGRAPHY_TITLE3)
                    .setColor(argb(0xFFFFFFFF.toInt()))
                    .build(),
            )
        }
        val layout = PrimaryLayout.Builder(device)
            .setResponsiveContentInsetEnabled(true)
            .setPrimaryLabelTextContent(
                Text.Builder(this, today?.title ?: "GymBar")
                    .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                    .setColor(argb(ACCENT))
                    .build(),
            )
            .setContent(content.build())
            .setPrimaryChipContent(
                CompactChip.Builder(this, today?.action ?: "GymBar", open, device).build(),
            )
            .build()
        return TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setFreshnessIntervalMillis(30 * 60 * 1000L)
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout))
            .build()
    }

    companion object {
        private const val RESOURCES_VERSION = "1"
        private const val ACCENT = 0xFF84D6BF.toInt()
    }
}
''';

/// Nová data z telefonu (application context) → obnovit dlaždici.
const _todayListener = r'''package __PACKAGE__

import androidx.wear.tiles.TileService
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

/** Soubor zapisuje wear/tool/setup_wear.dart. */
class TodayDataListener : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        TileService.getUpdater(this).requestUpdate(TodayTileService::class.java)
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
    stdout.writeln(
        '✓ test/widget_test.dart: smazán výchozí test z flutter create.');
  }
}
