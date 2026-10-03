import 'dart:io';

// Widget na ploše pro Android (balíček home_widget, klasický RemoteViews
// widget). Skript zapíše nativní soubory a upraví AndroidManifest.xml.
// Opakované spuštění nic nezdvojí – vlastní soubory jen přepíše aktuální
// verzí. iOS (WidgetKit) potřebuje cíl v Xcode, proto tu není.

/// Musí odpovídat kAndroidWidgetClass v lib/modules/widgets/widget_content.dart.
const _expectedPackage = 'cz.dedina.fitness_app';
const _className = 'FitnessWidgetProvider';
const _launchAction = 'es.antonborri.home_widget.action.LAUNCH';

bool patchWidgets() {
  final main = _findMainActivity();
  if (main == null) {
    stderr.writeln('✗ MainActivity.kt nenalezena v android/app/src/main – '
        'widget na plochu přeskočen.');
    return false;
  }
  final pkg = _packageOf(main);
  if (pkg == null) {
    stderr.writeln('✗ ${main.path}: řádek „package“ nenalezen.');
    return false;
  }
  if (pkg != _expectedPackage) {
    stdout.writeln('! MainActivity je v balíčku $pkg – uprav '
        'kAndroidWidgetClass v lib/modules/widgets/widget_content.dart '
        'na „$pkg.$_className“.');
  }
  final namespace = _namespace();

  var ok = true;
  final dir = main.parent.path;
  final kotlin = _kotlin
      .replaceAll('__PACKAGE__', pkg)
      .replaceAll(
        '__R_IMPORT__',
        namespace != null && namespace != pkg ? '\nimport $namespace.R' : '',
      );
  _write('$dir/$_className.kt', kotlin);

  const res = 'android/app/src/main/res';
  _write('$res/layout/fitness_widget_wide.xml', _layoutWide);
  _write('$res/layout/fitness_widget_small.xml', _layoutSmall);
  _write('$res/drawable/fitness_widget_background.xml', _background);
  _write('$res/drawable/fitness_widget_button.xml', _button);
  _write('$res/drawable/fitness_widget_progress.xml', _progress);
  _write('$res/xml/fitness_widget_info.xml', _info);
  _write('$res/values/fitness_widget_colors.xml', _colorsLight);
  _write('$res/values-night/fitness_widget_colors.xml', _colorsDark);
  _write('$res/values/fitness_widget_strings.xml', _stringsEn);
  _write('$res/values-cs/fitness_widget_strings.xml', _stringsCs);

  ok &= _patchManifest('$pkg.$_className');
  return ok;
}

File? _findMainActivity() {
  for (final root in ['android/app/src/main/kotlin', 'android/app/src/main/java']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name == 'MainActivity.kt' || name == 'MainActivity.java') return f;
    }
  }
  return null;
}

String? _packageOf(File file) => RegExp(r'^\s*package\s+([\w.]+)', multiLine: true)
    .firstMatch(file.readAsStringSync())
    ?.group(1);

/// namespace z build.gradle(.kts) – kvůli importu třídy R.
String? _namespace() {
  for (final path in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final m = RegExp(r'''namespace\s*=?\s*["']([\w.]+)["']''')
        .firstMatch(f.readAsStringSync());
    if (m != null) return m.group(1);
  }
  return null;
}

void _write(String path, String content) {
  final file = File(path);
  if (file.existsSync() && file.readAsStringSync() == content) {
    stdout.writeln('• $path: aktuální.');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  stdout.writeln('✓ $path: zapsáno (widget na plochu).');
}

bool _patchManifest(String receiverClass) {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!file.existsSync()) {
    stderr.writeln('✗ ${file.path} nenalezen.');
    return false;
  }
  var s = file.readAsStringSync();
  final original = s;
  final done = <String>[];

  final activity =
      RegExp(r'<activity[^>]*android:name="\.MainActivity"').firstMatch(s);
  final activityEnd =
      activity == null ? -1 : s.indexOf('</activity>', activity.end);
  if (activityEnd < 0) {
    stderr.writeln('✗ ${file.path}: MainActivity nenalezena.');
    return false;
  }

  // Aplikaci otevírá klepnutí na widget (návod home_widget „Detect Clicks“).
  // Vypnutý vestavěný deep linking Flutteru: odkazy obsluhuje app_links
  // a home_widget, go_router by jinak dostal homewidget://… jako cestu
  // a ukázal chybovou stránku (doporučení balíčku app_links).
  final additions = StringBuffer();
  if (!s.contains(_launchAction)) {
    additions.write('''    <intent-filter>
                <action android:name="$_launchAction" />
            </intent-filter>
        ''');
    done.add('klepnutí na widget');
  }
  if (!s.contains('flutter_deeplinking_enabled')) {
    additions.write('''    <meta-data
                android:name="flutter_deeplinking_enabled"
                android:value="false" />
        ''');
    done.add('flutter_deeplinking_enabled=false');
  }
  if (additions.isNotEmpty) {
    s = s.replaceRange(activityEnd, activityEnd, additions.toString());
  }

  if (!s.contains('$_className"')) {
    final i = s.lastIndexOf('</application>');
    if (i < 0) {
      stderr.writeln('✗ ${file.path}: značka </application> nenalezena.');
      return false;
    }
    s = s.replaceRange(i, i, '''    <receiver
            android:name="$receiverClass"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/fitness_widget_info" />
        </receiver>
    ''');
    done.add('přijímač widgetu');
  }

  if (s != original) {
    file.writeAsStringSync(s);
    stdout.writeln('✓ ${file.path}: ${done.join(', ')}.');
  } else {
    stdout.writeln('• ${file.path}: widget už nastavený.');
  }
  return true;
}

// ------------------------------------------------------------------ Kotlin

const _kotlin = r'''package __PACKAGE__

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale__R_IMPORT__

/**
 * Widget na ploše: pitný režim a dnešní trénink.
 *
 * Texty připravuje Flutter (lib/modules/widgets/home_widget_service.dart)
 * v jazyce telefonu; tady se jen zobrazí. Soubor zapisuje
 * tool/platform/widgets.dart – ruční úpravy se při dalším spuštění přepíšou.
 */
class FitnessWidgetProvider : HomeWidgetProvider() {

    private data class Content(
        val title: String,
        val workout: String,
        val water: String?,
        val percent: Int,
        val glassMl: Int,
        val addLabel: String,
        val addDescription: String,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                widgetId,
                buildViews(context, appWidgetManager, widgetId, widgetData),
            )
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Od Androidu 12 vybírá rozvržení podle velikosti systém sám.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            appWidgetManager.updateAppWidget(
                appWidgetId,
                buildViews(
                    context,
                    appWidgetManager,
                    appWidgetId,
                    HomeWidgetPlugin.getData(context),
                ),
            )
        }
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
    ): RemoteViews {
        val content = readContent(context, data)
        // Čas vykreslení: Flutter podle něj pozná znovu doručený starý intent.
        val nonce = System.currentTimeMillis()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(40f, 40f) to bind(context, R.layout.fitness_widget_wide, content, nonce),
                    SizeF(40f, 110f) to bind(context, R.layout.fitness_widget_small, content, nonce),
                    SizeF(220f, 40f) to bind(context, R.layout.fitness_widget_wide, content, nonce),
                ),
            )
        }
        val options = manager.getAppWidgetOptions(widgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        val layout =
            if (maxHeight >= 110 && minWidth < 220) R.layout.fitness_widget_small
            else R.layout.fitness_widget_wide
        return bind(context, layout, content, nonce)
    }

    private fun readContent(context: Context, data: SharedPreferences): Content {
        val openApp = context.getString(R.string.fitness_widget_open_app)
        val title = data.getString("fw_title", null)
            ?: context.getString(R.string.fitness_widget_title)
        val glass = data.getString("fw_glass_ml", null)?.toIntOrNull() ?: 250
        val addLabel = data.getString("fw_add_label", null) ?: "+$glass ml"
        val addDescription = data.getString("fw_add_desc", null) ?: addLabel

        // Flutter ukládá dnešek i zítřek, aby widget po půlnoci nelhal.
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val suffix = when (today) {
            data.getString("fw_day", null) -> ""
            data.getString("fw_day_next", null) -> "_next"
            else -> null
        } ?: return Content(title, openApp, null, 0, glass, addLabel, addDescription)

        val waterVisible = data.getString("fw_water_visible", "1") == "1"
        return Content(
            title = title,
            workout = data.getString("fw_workout$suffix", null) ?: openApp,
            water = if (waterVisible) data.getString("fw_water$suffix", null) else null,
            percent = data.getString("fw_percent$suffix", null)?.toIntOrNull() ?: 0,
            glassMl = glass,
            addLabel = addLabel,
            addDescription = addDescription,
        )
    }

    private fun bind(context: Context, layoutId: Int, c: Content, nonce: Long): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)
        views.setTextViewText(R.id.fitness_widget_title, c.title)
        views.setTextViewText(R.id.fitness_widget_workout, c.workout)

        val water = c.water
        val visibility = if (water != null) View.VISIBLE else View.GONE
        views.setViewVisibility(R.id.fitness_widget_water, visibility)
        views.setViewVisibility(R.id.fitness_widget_progress, visibility)
        views.setViewVisibility(R.id.fitness_widget_add, visibility)
        if (water != null) {
            views.setTextViewText(R.id.fitness_widget_water, water)
            views.setProgressBar(R.id.fitness_widget_progress, 100, c.percent.coerceIn(0, 100), false)
            views.setTextViewText(R.id.fitness_widget_add, c.addLabel)
            views.setContentDescription(R.id.fitness_widget_add, c.addDescription)
            views.setOnClickPendingIntent(
                R.id.fitness_widget_add,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homewidget://water?ml=${c.glassMl}&n=$nonce"),
                ),
            )
        }

        views.setOnClickPendingIntent(
            R.id.fitness_widget_root,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("homewidget://open"),
            ),
        )
        return views
    }
}
''';

// ------------------------------------------------------------------ Layouts

/// Široký widget (4×1): trénink a voda vlevo, tlačítko vpravo.
const _layoutWide = r'''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/fitness_widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/fitness_widget_background"
    android:gravity="center_vertical"
    android:orientation="horizontal"
    android:paddingStart="16dp"
    android:paddingTop="8dp"
    android:paddingEnd="10dp"
    android:paddingBottom="8dp">

    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical">

        <TextView
            android:id="@+id/fitness_widget_title"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="@string/fitness_widget_title"
            android:visibility="gone" />

        <TextView
            android:id="@+id/fitness_widget_workout"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:ellipsize="end"
            android:maxLines="1"
            android:text="@string/fitness_widget_open_app"
            android:textColor="@color/fitness_widget_text"
            android:textSize="14sp"
            android:textStyle="bold" />

        <TextView
            android:id="@+id/fitness_widget_water"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:layout_marginTop="2dp"
            android:ellipsize="end"
            android:maxLines="1"
            android:textColor="@color/fitness_widget_text_secondary"
            android:textSize="12sp"
            android:visibility="gone" />

        <ProgressBar
            android:id="@+id/fitness_widget_progress"
            style="?android:attr/progressBarStyleHorizontal"
            android:layout_width="match_parent"
            android:layout_height="6dp"
            android:layout_marginTop="4dp"
            android:indeterminate="false"
            android:max="100"
            android:maxHeight="6dp"
            android:minHeight="6dp"
            android:progress="0"
            android:progressDrawable="@drawable/fitness_widget_progress"
            android:visibility="gone" />
    </LinearLayout>

    <TextView
        android:id="@+id/fitness_widget_add"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="10dp"
        android:background="@drawable/fitness_widget_button"
        android:gravity="center"
        android:minHeight="36dp"
        android:paddingStart="12dp"
        android:paddingEnd="12dp"
        android:text="+250 ml"
        android:textColor="@color/fitness_widget_button_text"
        android:textSize="13sp"
        android:textStyle="bold"
        android:visibility="gone" />
</LinearLayout>
''';

/// Čtvercový widget (2×2): pod sebou nadpis, trénink, voda a tlačítko.
const _layoutSmall = r'''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/fitness_widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/fitness_widget_background"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/fitness_widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:ellipsize="end"
        android:maxLines="1"
        android:text="@string/fitness_widget_title"
        android:textColor="@color/fitness_widget_accent"
        android:textSize="11sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/fitness_widget_workout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="2dp"
        android:ellipsize="end"
        android:maxLines="2"
        android:text="@string/fitness_widget_open_app"
        android:textColor="@color/fitness_widget_text"
        android:textSize="14sp"
        android:textStyle="bold" />

    <!-- Mezera (RemoteViews nepovolují obyčejný View). -->
    <FrameLayout
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <TextView
        android:id="@+id/fitness_widget_water"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:ellipsize="end"
        android:maxLines="1"
        android:textColor="@color/fitness_widget_text_secondary"
        android:textSize="12sp"
        android:visibility="gone" />

    <ProgressBar
        android:id="@+id/fitness_widget_progress"
        style="?android:attr/progressBarStyleHorizontal"
        android:layout_width="match_parent"
        android:layout_height="6dp"
        android:layout_marginTop="4dp"
        android:indeterminate="false"
        android:max="100"
        android:maxHeight="6dp"
        android:minHeight="6dp"
        android:progress="0"
        android:progressDrawable="@drawable/fitness_widget_progress"
        android:visibility="gone" />

    <TextView
        android:id="@+id/fitness_widget_add"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:background="@drawable/fitness_widget_button"
        android:gravity="center"
        android:minHeight="32dp"
        android:text="+250 ml"
        android:textColor="@color/fitness_widget_button_text"
        android:textSize="13sp"
        android:textStyle="bold"
        android:visibility="gone" />
</LinearLayout>
''';

const _background = r'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="@color/fitness_widget_background" />
    <corners android:radius="20dp" />
</shape>
''';

const _button = r'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="@color/fitness_widget_button" />
    <corners android:radius="18dp" />
</shape>
''';

const _progress = r'''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@android:id/background">
        <shape android:shape="rectangle">
            <corners android:radius="3dp" />
            <solid android:color="@color/fitness_widget_track" />
        </shape>
    </item>
    <item android:id="@android:id/progress">
        <clip>
            <shape android:shape="rectangle">
                <corners android:radius="3dp" />
                <solid android:color="@color/fitness_widget_accent" />
            </shape>
        </clip>
    </item>
</layer-list>
''';

/// 4×1 výchozí, zmenšit jde na 2×1, zvětšit libovolně (2×2 = čtvercové
/// rozvržení). Překreslení každých 30 min (minimum Androidu) – kvůli půlnoci.
const _info = r'''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:description="@string/fitness_widget_description"
    android:initialLayout="@layout/fitness_widget_wide"
    android:minWidth="250dp"
    android:minHeight="40dp"
    android:minResizeWidth="110dp"
    android:minResizeHeight="40dp"
    android:previewLayout="@layout/fitness_widget_wide"
    android:resizeMode="horizontal|vertical"
    android:targetCellWidth="4"
    android:targetCellHeight="1"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen" />
''';

// ------------------------------------------------------------------ Barvy

// Barvy podle motivu aplikace (seed #2E7D6B).
const _colorsLight = r'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="fitness_widget_background">#FFF4FBF8</color>
    <color name="fitness_widget_text">#FF171D1B</color>
    <color name="fitness_widget_text_secondary">#FF3F4945</color>
    <color name="fitness_widget_accent">#FF2E7D6B</color>
    <color name="fitness_widget_track">#FFD0E8E0</color>
    <color name="fitness_widget_button">#FF2E7D6B</color>
    <color name="fitness_widget_button_text">#FFFFFFFF</color>
</resources>
''';

const _colorsDark = r'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="fitness_widget_background">#FF1A2320</color>
    <color name="fitness_widget_text">#FFDEE4E1</color>
    <color name="fitness_widget_text_secondary">#FFBFC9C4</color>
    <color name="fitness_widget_accent">#FF84D6BF</color>
    <color name="fitness_widget_track">#FF334B44</color>
    <color name="fitness_widget_button">#FF84D6BF</color>
    <color name="fitness_widget_button_text">#FF00382D</color>
</resources>
''';

// ------------------------------------------------------------------ Texty
// Jen texty, které Android ukáže bez aplikace (výběr widgetů, před prvním
// spuštěním). Ostatní texty posílá Flutter v jazyce telefonu.

const _stringsEn = r'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="fitness_widget_title">Today</string>
    <string name="fitness_widget_description">Water intake and today\'s workout</string>
    <string name="fitness_widget_open_app">Open the app to load today</string>
</resources>
''';

const _stringsCs = r'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="fitness_widget_title">Dnes</string>
    <string name="fitness_widget_description">Pitný režim a dnešní trénink</string>
    <string name="fitness_widget_open_app">Otevři aplikaci a načti dnešek</string>
</resources>
''';
