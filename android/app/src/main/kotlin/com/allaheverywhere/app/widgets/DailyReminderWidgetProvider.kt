package com.allaheverywhere.app.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.allaheverywhere.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** The Verse / Hadith of the Day - the same entry as the Home banner. */
class DailyReminderWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val data = WidgetData.from(widgetData)
    val entry = data.reminderOn(WidgetData.today())
    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_daily_reminder)
      WidgetData.applyDirection(views, R.id.widget_root, data.isRtl)
      views.setOnClickPendingIntent(R.id.widget_root, WidgetData.launch(context, "home"))
      views.setTextViewText(R.id.title,
          entry?.optString("title") ?: context.getString(R.string.widget_reminder_name))
      views.setTextViewText(R.id.arabic, entry?.optString("ar") ?: "")
      views.setTextViewText(R.id.translation,
          entry?.optString("tr") ?: data.label("openApp", context.getString(R.string.widget_open_app_fallback)))
      views.setTextViewText(R.id.reference, entry?.optString("ref") ?: "")
      appWidgetManager.updateAppWidget(id, views)
    }
    WidgetData.scheduleRefresh(context, javaClass, WidgetData.nextMidnight())
  }
}
