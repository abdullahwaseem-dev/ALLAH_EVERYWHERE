package com.allaheverywhere.app.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.allaheverywhere.app.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Reads the payload the app writes (lib/services/home_widget_service.dart):
 * several days of prayer times, Hijri dates and daily reminders, already in
 * the app language. The widgets only pick today's entry.
 */
class WidgetData(private val json: JSONObject?) {

  data class Prayer(val name: String, val time: Long, val label: String)

  val isRtl: Boolean get() = json?.optBoolean("rtl") ?: false

  fun label(key: String, fallback: String): String =
      json?.optJSONObject("labels")?.optString(key)?.takeIf { it.isNotEmpty() } ?: fallback

  private fun dayEntry(array: String, day: String): JSONObject? {
    val list = json?.optJSONArray(array) ?: return null
    for (i in 0 until list.length()) {
      val e = list.optJSONObject(i) ?: continue
      if (e.optString("day") == day) return e
    }
    return null
  }

  /** All saved prayers from now on, in time order (today's and later days). */
  fun upcomingPrayers(now: Long): List<Prayer> {
    val list = json?.optJSONArray("prayers") ?: return emptyList()
    val out = mutableListOf<Prayer>()
    for (i in 0 until list.length()) {
      val items = list.optJSONObject(i)?.optJSONArray("items") ?: continue
      for (j in 0 until items.length()) {
        val p = items.optJSONObject(j) ?: continue
        val t = p.optLong("t")
        if (t > now) out.add(Prayer(p.optString("n"), t, p.optString("s")))
      }
    }
    return out.sortedBy { it.time }
  }

  /** The five prayers of [day] ("yyyy-MM-dd"), or empty. */
  fun prayersOn(day: String): List<Prayer> {
    val items = dayEntry("prayers", day)?.optJSONArray("items") ?: return emptyList()
    return (0 until items.length()).mapNotNull { items.optJSONObject(it) }
        .map { Prayer(it.optString("n"), it.optLong("t"), it.optString("s")) }
  }

  fun hijriOn(day: String): JSONObject? = dayEntry("hijri", day)

  fun reminderOn(day: String): JSONObject? = dayEntry("reminders", day)

  companion object {
    private const val KEY = "widget_data"

    fun from(prefs: SharedPreferences): WidgetData =
        WidgetData(prefs.getString(KEY, null)?.let { runCatching { JSONObject(it) }.getOrNull() })

    fun today(now: Long = System.currentTimeMillis()): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))

    /** Opens the app at [route] (allaheverywhere://route), via home_widget. */
    fun launch(context: Context, route: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("allaheverywhere://$route?homeWidget"))

    /** Mirrors the app language's direction (it can differ from the phone's). */
    fun applyDirection(views: RemoteViews, rootId: Int, rtl: Boolean) {
      views.setInt(rootId, "setLayoutDirection",
          if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
    }

    fun nextMidnight(now: Long = System.currentTimeMillis()): Long =
        Calendar.getInstance().apply {
          timeInMillis = now
          add(Calendar.DAY_OF_YEAR, 1)
          set(Calendar.HOUR_OF_DAY, 0)
          set(Calendar.MINUTE, 0)
          set(Calendar.SECOND, 5)
          set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    /**
     * Asks for one refresh of [provider]'s widgets at [at] (inexact - the
     * system may batch it by a few minutes, which is fine for a date or a
     * "next prayer" switch; the countdown itself is a live Chronometer).
     */
    fun scheduleRefresh(context: Context, provider: Class<*>, at: Long) {
      val manager = AppWidgetManager.getInstance(context)
      val ids = manager.getAppWidgetIds(ComponentName(context, provider))
      val intent = Intent(context, provider).apply {
        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
      }
      val pending = PendingIntent.getBroadcast(
          context, provider.name.hashCode(), intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
      val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
      alarms.set(AlarmManager.RTC, at, pending)
    }
  }
}
