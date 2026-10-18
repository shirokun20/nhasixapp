package id.nhasix.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.annotation.LayoutRes
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import id.nhasix.app.R

/**
 * Base receiver for fixed-size Kuro streak launcher widget variants.
 * Each subclass binds one dedicated layout (4x2 Design A, 4x1 Strip, 2x2 Mini)
 * with resizeMode="none" so launcher grids never distort or clip the card.
 */
abstract class BaseKuroStreakWidgetReceiver(
    @LayoutRes private val layoutRes: Int,
) : HomeWidgetGlanceWidgetReceiver<KuroStreakGlanceWidget>() {

    override val glanceAppWidget = KuroStreakGlanceWidget(layoutRes)

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
        val views = KuroStreakGlanceWidget.buildRemoteViewsForLayout(context, layoutRes)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
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

/** 4x2 Full Design A widget receiver. */
class KuroStreakWidgetReceiver :
    BaseKuroStreakWidgetReceiver(R.layout.kuro_streak_widget)

/** 4x1 Compact horizontal strip widget receiver. */
class KuroStreakStripWidgetReceiver :
    BaseKuroStreakWidgetReceiver(R.layout.kuro_streak_widget_strip)

/** 2x2 Mini square tile widget receiver. */
class KuroStreakSmallWidgetReceiver :
    BaseKuroStreakWidgetReceiver(R.layout.kuro_streak_widget_small)
