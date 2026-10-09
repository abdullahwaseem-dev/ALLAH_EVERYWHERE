package com.allaheverywhere.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import com.allaheverywhere.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Today's Hijri date (with the user's moon-sighting adjustment), the
 *  Gregorian date and today's Islamic occasion, if any. */
class HijriDateWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val data = WidgetData.from(widgetData)
    val day = data.hijriOn(WidgetData.today())
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_hijri_date)
      WidgetData.applyDirection(views, R.id.widget_root, data.isRtl)
      views.setOnClickPendingIntent(R.id.widget_root, WidgetData.launch(context, "calendar"))
      if (day == null) {
        views.setTextViewText(R.id.hijri_day, "")
        views.setTextViewText(R.id.hijri_month, data.label("openApp", context.getString(R.string.widget_open_app_fallback)))
        views.setTextViewText(R.id.hijri_year, "")
        views.setTextViewText(R.id.gregorian, "")
        views.setViewVisibility(R.id.event, View.GONE)
      } else {
        views.setTextViewText(R.id.hijri_day, day.optString("d"))
        views.setTextViewText(R.id.hijri_month, day.optString("m"))
        views.setTextViewText(R.id.hijri_year, day.optString("y"))
        views.setTextViewText(R.id.gregorian, day.optString("g"))
        val event = day.optString("e")
        views.setViewVisibility(R.id.event, if (event.isEmpty()) View.GONE else View.VISIBLE)
        views.setTextViewText(R.id.event, event)
      }
      appWidgetManager.updateAppWidget(id, views)
    }
    WidgetData.scheduleRefresh(context, javaClass, WidgetData.nextMidnight())
  }
}
