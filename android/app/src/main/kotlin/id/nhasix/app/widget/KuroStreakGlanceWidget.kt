package id.nhasix.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.fillMaxSize
import HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import id.nhasix.app.MainActivity
import id.nhasix.app.R
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import org.json.JSONArray

/**
 * Kuro streak launcher widget.
 *
 * Privacy-safe by construction: renders streak count, the Sn-Mn weekly checklist and the
 * mood mascot only. No content title, cover, tag or source name is ever read or shown.
 */
class KuroStreakGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val size = LocalSize.current
            AndroidRemoteViews(
                remoteViews = buildRemoteViews(
                    context = context,
                    widthDp = size.width.value.toInt(),
                    heightDp = size.height.value.toInt(),
                ),
                modifier = GlanceModifier.fillMaxSize(),
            )
        }
    }
    companion object {

        private const val KEY_STREAK_COUNT = "streak_count"
        private const val KEY_LAST_DATE = "streak_last_date"
        private const val KEY_READ_DAYS = "streak_read_days"

        // Dart mirrors these into SharedPreferences so the widget survives a cold start
        // before Flutter has written HomeWidget data yet.
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val FLUTTER_KEY_STREAK_COUNT = "flutter.reading_streak_count"
        private const val FLUTTER_KEY_LAST_DATE = "flutter.reading_last_date"
        private const val FLUTTER_KEY_READ_DAYS = "flutter.reading_read_days"

        private const val WEEKDAYS = 7

        private val DAY_DOT_IDS = intArrayOf(
            R.id.day_dot_1,
            R.id.day_dot_2,
            R.id.day_dot_3,
            R.id.day_dot_4,
            R.id.day_dot_5,
            R.id.day_dot_6,
            R.id.day_dot_7,
        )

        private val CHECK_COLOR = Color.parseColor("#1A1A1F")
        private val UNCHECK_COLOR = Color.parseColor("#9E948C")

        fun buildRemoteViews(
            context: Context,
            widthDp: Int = 250,
            heightDp: Int = 110,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.kuro_streak_widget)
            val prefs = HomeWidgetPlugin.getData(context)
            val flutterPrefs =
                context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

            val storedStreak = readInt(prefs, KEY_STREAK_COUNT)
                ?: readInt(flutterPrefs, FLUTTER_KEY_STREAK_COUNT)
                ?: 0
            val lastDateStr = readString(prefs, KEY_LAST_DATE)
                ?: readString(flutterPrefs, FLUTTER_KEY_LAST_DATE)
            val readDaysRaw = readString(prefs, KEY_READ_DAYS)
                ?: readString(flutterPrefs, FLUTTER_KEY_READ_DAYS)

            val today = LocalDate.now()
            val lastDate = lastDateStr?.takeIf { it.isNotBlank() }?.let {
                runCatching { LocalDate.parse(it) }.getOrNull()
            }
            val diffDays = lastDate?.let { ChronoUnit.DAYS.between(it, today) }

            // Same rules as the Dart domain layer (resolveKuroMood).
            val moodRes: Int
            val effectiveStreak: Int
            val subtitle: String
            when {
                diffDays != null && diffDays <= 0L -> {
                    moodRes = R.drawable.kuro_happy
                    effectiveStreak = maxOf(storedStreak, 1)
                    subtitle = "Kuro senang kamu baca hari ini!"
                }
                diffDays != null && diffDays in 1L..7L -> {
                    moodRes = R.drawable.kuro_frozen_cry
                    effectiveStreak = if (diffDays == 1L) storedStreak else 0
                    subtitle = "Kuro nangis, yuk lanjut baca!"
                }
                else -> {
                    moodRes = R.drawable.kuro_tsundere
                    effectiveStreak = 0
                    subtitle = "H-hmph, udah lama gak buka Kuron!"
                }
            }

            views.setTextViewText(R.id.widget_streak_count, effectiveStreak.toString())
            views.setTextViewText(R.id.widget_mood_subtitle, subtitle)
            views.setImageViewResource(R.id.widget_kuro_mood, moodRes)

            applyWeek(views, parseReadDays(readDaysRaw), today)
            applyResponsiveSizing(views, widthDp, heightDp)

            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java)
                        .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )

            return views
        }

        private fun applyResponsiveSizing(
            views: RemoteViews,
            widthDp: Int,
            heightDp: Int,
        ) {
            val isNarrow = widthDp in 1..205
            val isShort = heightDp in 1..95
            val isTall = heightDp >= 165

            // Narrow (e.g. 2x1 / 2x2): hide 7-column week strip so text + mascot fit cleanly.
            views.setViewVisibility(
                R.id.widget_week_row,
                if (isNarrow) View.GONE else View.VISIBLE,
            )

            // Short 1-row strip (e.g. 3x1 / 4x1): hide subtitle when week strip is visible.
            views.setViewVisibility(
                R.id.widget_mood_subtitle,
                if (isShort && !isNarrow) View.GONE else View.VISIBLE,
            )

            val countSp = when {
                isShort -> 20f
                isTall -> 30f
                else -> 26f
            }
            val labelSp = when {
                isShort -> 11f
                isTall -> 14f
                else -> 13f
            }
            val subSp = if (isTall) 12f else 11f

            views.setTextViewTextSize(
                R.id.widget_streak_count,
                TypedValue.COMPLEX_UNIT_SP,
                countSp,
            )
            views.setTextViewTextSize(
                R.id.widget_streak_label,
                TypedValue.COMPLEX_UNIT_SP,
                labelSp,
            )
            views.setTextViewTextSize(
                R.id.widget_mood_subtitle,
                TypedValue.COMPLEX_UNIT_SP,
                subSp,
            )
        }

        fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null,
        ) {
            val effectiveOptions = options ?: manager.getAppWidgetOptions(appWidgetId)
            val widthDp = effectiveOptions.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
                250,
            )
            val heightDp = effectiveOptions.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
                110,
            )
            manager.updateAppWidget(
                appWidgetId,
                buildRemoteViews(context, widthDp = widthDp, heightDp = heightDp),
            )
        }

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, KuroStreakWidgetReceiver::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        /** Monday..Sunday of the current week, oldest first. */
        private fun applyWeek(
            views: RemoteViews,
            readDays: Set<LocalDate>,
            today: LocalDate,
        ) {
            val monday = today.minusDays((today.dayOfWeek.value - 1).toLong())
            for (index in 0 until WEEKDAYS) {
                val date = monday.plusDays(index.toLong())
                val dotId = DAY_DOT_IDS[index]
                if (date in readDays) {
                    views.setInt(dotId, "setBackgroundResource", R.drawable.kuro_day_checked_bg)
                    views.setTextViewText(dotId, "✓")
                    views.setTextColor(dotId, CHECK_COLOR)
                } else {
                    views.setInt(
                        dotId,
                        "setBackgroundResource",
                        R.drawable.kuro_day_unchecked_bg
                    )
                    views.setTextViewText(dotId, "")
                    views.setTextColor(dotId, UNCHECK_COLOR)
                }
            }
        }

        private fun parseReadDays(raw: String?): Set<LocalDate> {
            if (raw.isNullOrBlank()) return emptySet()
            val parsed = runCatching {
                val array = JSONArray(raw)
                (0 until array.length()).mapNotNull { index ->
                    runCatching { LocalDate.parse(array.getString(index)) }.getOrNull()
                }
            }.getOrNull() ?: return emptySet()
            return parsed.toSet()
        }

        private fun readInt(prefs: SharedPreferences, key: String): Int? =
            prefs.all[key] as? Int

        private fun readString(prefs: SharedPreferences, key: String): String? =
            prefs.all[key] as? String
    }
}
