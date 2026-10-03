package cz.dedina.fitness_app

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
import java.util.Locale

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
