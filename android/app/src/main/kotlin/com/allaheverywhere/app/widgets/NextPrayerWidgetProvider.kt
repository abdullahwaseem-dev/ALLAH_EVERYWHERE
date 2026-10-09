package com.allaheverywhere.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.allaheverywhere.app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Next prayer with a live countdown. The wide size also lists today's five
 * prayers with the next one highlighted. Refreshes itself when that prayer
 * time arrives, from the times the app saved for the week ahead.
 */
class NextPrayerWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val data = WidgetData.from(widgetData)
    for (id in appWidgetIds) {
      appWidgetManager.updateAppWidget(id, build(context, data, appWidgetManager.getAppWidgetOptions(id)))
    }
    val next = data.upcomingPrayers(System.currentTimeMillis()).firstOrNull()
    WidgetData.scheduleRefresh(
        context, javaClass,
        minOf(next?.let { it.time + 1000 } ?: Long.MAX_VALUE, WidgetData.nextMidnight()))
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    val data = WidgetData.from(HomeWidgetPlugin.getData(context))
    appWidgetManager.updateAppWidget(appWidgetId, build(context, data, newOptions))
  }

  private fun build(context: Context, data: WidgetData, options: Bundle?): RemoteViews {
    val small = views(context, data, wide = false)
    val wide = views(context, data, wide = true)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      return RemoteViews(mapOf(SizeF(110f, 110f) to small, SizeF(250f, 110f) to wide))
    }
    val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
    return if (minWidth >= 250) wide else small
  }

  private fun views(context: Context, data: WidgetData, wide: Boolean): RemoteViews {
    val now = System.currentTimeMillis()
    val views = RemoteViews(context.packageName,
        if (wide) R.layout.widget_next_prayer_wide else R.layout.widget_next_prayer)
    WidgetData.applyDirection(views, R.id.widget_root, data.isRtl)
    views.setOnClickPendingIntent(R.id.widget_root, WidgetData.launch(context, "prayer"))
    views.setTextViewText(R.id.next_label,
        data.label("next", context.getString(R.string.widget_next_prayer_fallback)))

    val next = data.upcomingPrayers(now).firstOrNull()
    if (next == null) {
      // No location saved yet (or the saved week has run out).
      views.setTextViewText(R.id.next_name, "")
      views.setTextViewText(R.id.next_time, "")
      views.setViewVisibility(R.id.next_countdown, View.GONE)
      views.setViewVisibility(R.id.empty_message, View.VISIBLE)
      views.setTextViewText(R.id.empty_message,
          data.label("setLocation", context.getString(R.string.widget_set_location_fallback)))
      if (wide) views.setViewVisibility(R.id.prayer_list, View.GONE)
      return views
    }
    views.setViewVisibility(R.id.empty_message, View.GONE)
    views.setTextViewText(R.id.next_name, next.name)
    views.setTextViewText(R.id.next_time, next.label)
    views.setViewVisibility(R.id.next_countdown, View.VISIBLE)
    views.setChronometer(R.id.next_countdown, SystemClock.elapsedRealtime() + (next.time - now), null, true)
    views.setChronometerCountDown(R.id.next_countdown, true)

    if (wide) {
      val today = data.prayersOn(WidgetData.today(now)).ifEmpty { data.prayersOn(WidgetData.today(next.time)) }
      views.setViewVisibility(R.id.prayer_list, if (today.isEmpty()) View.GONE else View.VISIBLE)
      val rows = listOf(
          Triple(R.id.row_0, R.id.name_0, R.id.time_0),
          Triple(R.id.row_1, R.id.name_1, R.id.time_1),
          Triple(R.id.row_2, R.id.name_2, R.id.time_2),
          Triple(R.id.row_3, R.id.name_3, R.id.time_3),
          Triple(R.id.row_4, R.id.name_4, R.id.time_4),
      )
      for ((i, ids) in rows.withIndex()) {
        val p = today.getOrNull(i)
        views.setViewVisibility(ids.first, if (p == null) View.GONE else View.VISIBLE)
        if (p == null) continue
        views.setTextViewText(ids.second, p.name)
        views.setTextViewText(ids.third, p.label)
        val isNext = p.time == next.time
        val color = context.getColor(if (isNext) R.color.widget_accent else R.color.widget_text)
        views.setTextColor(ids.second, color)
        views.setTextColor(ids.third, color)
      }
    }
    return views
  }
}
