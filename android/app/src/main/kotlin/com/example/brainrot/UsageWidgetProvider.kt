package com.example.brainrot

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin


class UsageWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widget instances
        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val score = widgetData.getInt("widget_score", 100)
            val moodImage = widgetData.getString("widget_mood_image", "vui")
            val views = RemoteViews(context.packageName, R.layout.usage_widget)
            val iconResId = getMoodIconResource(context, moodImage ?: "vui")
            if (iconResId != 0) {
                views.setImageViewResource(R.id.widget_mood_icon, iconResId)
            }

            views.setTextViewText(R.id.widget_score_text, score.toString())

            views.setProgressBar(R.id.widget_progress_bar, 100, score, false)


            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.score_container, pendingIntent)

            // Update widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getMoodIconResource(context: Context, moodImage: String): Int {
            return when {
                moodImage.contains("vui") -> {
                    context.resources.getIdentifier("vui", "drawable", context.packageName)
                }
                moodImage.contains("suynghi") -> {
                    context.resources.getIdentifier("suynghi", "drawable", context.packageName)
                }
                moodImage.contains("cangthang") -> {
                    context.resources.getIdentifier("cangthang", "drawable", context.packageName)
                }
                moodImage.contains("buonngu") -> {
                    context.resources.getIdentifier("buonngu", "drawable", context.packageName)
                }
                else -> {
                    context.resources.getIdentifier("vui", "drawable", context.packageName)
                }
            }
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, UsageWidgetProvider::class.java)
            )

            appWidgetIds.forEach { widgetId ->
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
