package com.zjzbs.flow.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.zjzbs.flow.widget.WidgetBridge

/**
 * App 侧的可观察设置。
 *
 * 每次 set 都写回 SharedPreferences，并顺手通知桌面小组件刷新
 * —— 安卓的 SharedPreferences 是同一个包内共用的，所以小组件能真正跟着设置变，
 * 这一点比 iOS 版更强（iOS 那边没用 App Group，小组件读不到 App 的设置）。
 */
object FlowStore {

    private lateinit var prefs: SharedPreferences
    private lateinit var appContext: Context

    var settings by mutableStateOf(FlowSettings())
        private set

    fun init(context: Context) {
        if (!::prefs.isInitialized) {
            appContext = context.applicationContext
            prefs = FlowPrefs.open(appContext)
        }
        settings = FlowPrefs.read(prefs)
    }

    /** 统一的修改入口：只在真的变了的时候落盘并通知小组件 */
    fun edit(block: (FlowSettings) -> FlowSettings) {
        val next = block(settings)
        if (next == settings) return
        settings = next
        FlowPrefs.write(prefs, next)
        scheduleWidgetRefresh()
    }

    /**
     * 小组件刷新要重新画 3 张位图（每张 365 个点），在主线程做会明显掉帧。
     * 所以丢到后台线程，并且做 150ms 去抖 —— 连续点几个色块只算一次。
     */
    @Synchronized
    private fun scheduleWidgetRefresh() {
        if (!::appContext.isInitialized) return
        pendingRefresh?.cancel(false)
        pendingRefresh = scheduler.schedule({
            runCatching { WidgetBridge.refreshAll(appContext) }
        }, 150, java.util.concurrent.TimeUnit.MILLISECONDS)
    }

    private val scheduler =
        java.util.concurrent.Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "flow-widget-refresh").apply { isDaemon = true }
        }

    private var pendingRefresh: java.util.concurrent.ScheduledFuture<*>? = null

    // ---- 便捷设置项 ----

    var accentHex: String
        get() = settings.accentHex
        set(v) = edit { it.copy(accentHex = v) }

    var colorPastDots: Boolean
        get() = settings.colorPastDots
        set(v) = edit { it.copy(colorPastDots = v) }

    var gridLayout: com.zjzbs.flow.domain.GridLayout
        get() = settings.gridLayout
        set(v) = edit { it.copy(gridLayout = v) }

    var showRing: Boolean
        get() = settings.showRing
        set(v) = edit { it.copy(showRing = v) }

    var showRows: Boolean
        get() = settings.showRows
        set(v) = edit { it.copy(showRows = v) }

    var showGrid: Boolean
        get() = settings.showGrid
        set(v) = edit { it.copy(showGrid = v) }

    var appearance: Appearance
        get() = settings.appearance
        set(v) = edit { it.copy(appearance = v) }
}
