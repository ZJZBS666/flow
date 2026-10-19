package com.zjzbs.flow.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

abstract class FlowWidgetProviderBase : AppWidgetProvider() {

    abstract val size: WidgetSize

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            WidgetBridge.update(context, appWidgetManager, id, size)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        WidgetBridge.update(context, appWidgetManager, appWidgetId, size)
    }

    override fun onEnabled(context: Context) {
        WidgetBridge.refreshAll(context)
    }
}

class FlowWidgetSmall : FlowWidgetProviderBase() {
    override val size = WidgetSize.Small
}

class FlowWidgetMedium : FlowWidgetProviderBase() {
    override val size = WidgetSize.Medium
}

class FlowWidgetLarge : FlowWidgetProviderBase() {
    override val size = WidgetSize.Large
}
