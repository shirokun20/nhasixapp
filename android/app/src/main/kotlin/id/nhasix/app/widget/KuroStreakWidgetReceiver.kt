package id.nhasix.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import HomeWidgetGlanceWidgetReceiver

class KuroStreakWidgetReceiver : HomeWidgetGlanceWidgetReceiver<KuroStreakGlanceWidget>() {

    override val glanceAppWidget = KuroStreakGlanceWidget()
    override fun onEnabled(context: Context) {
        StreakWidgetWorker.enqueuePeriodic(context)
        KuroStreakGlanceWidget.updateAllWidgets(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        StreakWidgetWorker.enqueuePeriodic(context)
        for (id in appWidgetIds) {
            KuroStreakGlanceWidget.updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        KuroStreakGlanceWidget.updateWidget(
            context = context,
            manager = appWidgetManager,
            appWidgetId = appWidgetId,
            options = newOptions,
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        val manager = AppWidgetManager.getInstance(context)
        when (intent.action) {
            AppWidgetManager.ACTION_APPWIDGET_ENABLED -> onEnabled(context)
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val ids = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)
                if (ids != null && ids.isNotEmpty()) {
                    onUpdate(context, manager, ids)
                } else {
                    KuroStreakGlanceWidget.updateAllWidgets(context)
                }
            }
            AppWidgetManager.ACTION_APPWIDGET_OPTIONS_CHANGED -> {
                val id = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                val options = intent.getBundleExtra(AppWidgetManager.EXTRA_APPWIDGET_OPTIONS)
                if (id != AppWidgetManager.INVALID_APPWIDGET_ID && options != null) {
                    onAppWidgetOptionsChanged(context, manager, id, options)
                } else {
                    KuroStreakGlanceWidget.updateAllWidgets(context)
                }
            }
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED -> {
                StreakWidgetWorker.enqueuePeriodic(context)
                KuroStreakGlanceWidget.updateAllWidgets(context)
            }
            else -> super.onReceive(context, intent)
        }
    }
}
