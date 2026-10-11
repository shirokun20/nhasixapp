package id.nhasix.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import androidx.annotation.LayoutRes
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
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
 * Kuro streak launcher widget supporting 3 dedicated fixed-size variants:
 * - 4x2 Full Design A (`R.layout.kuro_streak_widget`)
 * - 4x1 Compact Strip (`R.layout.kuro_streak_widget_strip`)
 * - 2x2 Mini Square (`R.layout.kuro_streak_widget_small`)
 *
 * Privacy-safe by construction: renders streak count, the Sn-Mn weekly checklist and the
 * mood mascot only. No content title, cover, tag or source name is ever read or shown.
 */
class KuroStreakGlanceWidget(
    @LayoutRes private val layoutRes: Int = R.layout.kuro_streak_widget,
) : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            AndroidRemoteViews(
                remoteViews = buildRemoteViewsForLayout(context, layoutRes),
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

        private val DAY_LABEL_IDS = intArrayOf(
            R.id.day_label_1,
            R.id.day_label_2,
            R.id.day_label_3,
            R.id.day_label_4,
            R.id.day_label_5,
            R.id.day_label_6,
            R.id.day_label_7,
        )

        private val DAY_STRING_RES = intArrayOf(
            R.string.streak_day_1,
            R.string.streak_day_2,
            R.string.streak_day_3,
            R.string.streak_day_4,
            R.string.streak_day_5,
            R.string.streak_day_6,
            R.string.streak_day_7,
        )

        private val CORAL_COLOR = Color.parseColor("#F1958E")
        private val TEAR_COLOR = Color.parseColor("#7DD3FC")
        private val CHECK_COLOR = Color.parseColor("#1A1A1F")
        private val UNCHECK_COLOR = Color.parseColor("#9E948C")

        private val VARIANT_RECEIVERS: List<Pair<Class<*>, Int>> = listOf(
            KuroStreakWidgetReceiver::class.java to R.layout.kuro_streak_widget,
            KuroStreakStripWidgetReceiver::class.java to R.layout.kuro_streak_widget_strip,
            KuroStreakSmallWidgetReceiver::class.java to R.layout.kuro_streak_widget_small,
        )

        fun buildRemoteViews(context: Context): RemoteViews =
            buildRemoteViewsForLayout(context, R.layout.kuro_streak_widget)

        fun buildRemoteViewsForLayout(
            context: Context,
            @LayoutRes layoutRes: Int,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, layoutRes)
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
            val isCry: Boolean
            when {
                diffDays != null && diffDays <= 0L -> {
                    moodRes = R.drawable.kuro_happy
                    effectiveStreak = maxOf(storedStreak, 1)
                    subtitle = context.getString(R.string.streak_mood_happy)
                    isCry = false
                }
                diffDays != null && diffDays in 1L..7L -> {
                    moodRes = R.drawable.kuro_frozen_cry
                    effectiveStreak = if (diffDays == 1L) storedStreak else 0
                    subtitle = context.getString(R.string.streak_mood_cry)
                    isCry = true
                }
                else -> {
                    moodRes = R.drawable.kuro_tsundere
                    effectiveStreak = 0
                    subtitle = context.getString(R.string.streak_mood_tsundere)
                    isCry = false
                }
            }

            val accentColor = if (isCry) TEAR_COLOR else CORAL_COLOR
            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                if (isCry) R.drawable.kuro_widget_cry_bg else R.drawable.kuro_widget_bg,
            )
            if (layoutRes == R.layout.kuro_streak_widget) {
                views.setInt(R.id.widget_flame_icon, "setColorFilter", accentColor)
            }
            views.setTextColor(R.id.widget_streak_count, accentColor)
            views.setTextViewText(
                R.id.widget_streak_label,
                context.getString(R.string.streak_days_unit).trim(),
            )
            views.setTextViewText(R.id.widget_streak_count, effectiveStreak.toString())
            views.setTextViewText(R.id.widget_mood_subtitle, subtitle)
            views.setImageViewResource(R.id.widget_kuro_mood, moodRes)

            val readDays = parseReadDays(readDaysRaw)
            val checkedCount = applyWeek(context, views, layoutRes, readDays, today, accentColor)
            views.setTextViewText(
                R.id.widget_week_summary,
                context.getString(R.string.streak_week_progress, checkedCount),
            )

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

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for ((receiverClass, layoutRes) in VARIANT_RECEIVERS) {
                val ids = manager.getAppWidgetIds(ComponentName(context, receiverClass))
                if (ids.isNotEmpty()) {
                    manager.updateAppWidget(ids, buildRemoteViewsForLayout(context, layoutRes))
                }
            }
        }

        /** Monday..Sunday of the current week, oldest first. */
        private fun applyWeek(
            context: Context,
            views: RemoteViews,
            @LayoutRes layoutRes: Int,
            readDays: Set<LocalDate>,
            today: LocalDate,
            accentColor: Int,
        ): Int {
            val todayIndex = today.dayOfWeek.value - 1
            val monday = today.minusDays(todayIndex.toLong())
            var checkedCount = 0
            for (index in 0 until WEEKDAYS) {
                val date = monday.plusDays(index.toLong())
                val isRead = date in readDays
                if (isRead) checkedCount++

                if (layoutRes == R.layout.kuro_streak_widget_small) {
                    // 2x2 Bento Hero Tile has no 7-day dot strip (matches HTML prototype w2x2).
                    continue
                }

                val dotId = DAY_DOT_IDS[index]
                if (layoutRes == R.layout.kuro_streak_widget_strip) {
                    // 4x1 Strip: each chip holds the day name (Mo..Su / Sn..Mn) inside the pill.
                    views.setTextViewText(dotId, context.getString(DAY_STRING_RES[index]))
                    if (isRead) {
                        views.setInt(dotId, "setBackgroundResource", R.drawable.kuro_chip_checked_bg)
                        views.setTextColor(dotId, CHECK_COLOR)
                    } else {
                        views.setInt(dotId, "setBackgroundResource", R.drawable.kuro_chip_unchecked_bg)
                        views.setTextColor(
                            dotId,
                            if (index == todayIndex) accentColor else UNCHECK_COLOR,
                        )
                    }
                } else {
                    // 4x2 Full Design A: label above circle dot.
                    val labelId = DAY_LABEL_IDS[index]
                    views.setTextColor(
                        labelId,
                        if (index == todayIndex) accentColor else UNCHECK_COLOR,
                    )
                    if (isRead) {
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
            return checkedCount
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
