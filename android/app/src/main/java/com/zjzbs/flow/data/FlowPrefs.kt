package com.zjzbs.flow.data

import android.content.Context
import android.content.SharedPreferences
import com.zjzbs.flow.domain.GridLayout

/** 外观三档 */
enum class Appearance(val key: String, val title: String) {
    System("system", "跟随系统"),
    Light("light", "浅色"),
    Dark("dark", "深色");

    companion object {
        fun fromKey(k: String?): Appearance =
            entries.firstOrNull { it.key == k } ?: System
    }
}

/** 一份完整的设置快照 */
data class FlowSettings(
    val accentHex: String = DEFAULT_ACCENT,
    val colorPastDots: Boolean = false,
    val gridLayout: GridLayout = GridLayout.Sequential,
    val showRing: Boolean = true,
    val showRows: Boolean = true,
    val showGrid: Boolean = true,
    val appearance: Appearance = Appearance.System,
) {
    companion object {
        const val DEFAULT_ACCENT = "#FC8E03"

        /** 8 个主题色，和效果图一致 */
        val PALETTE = listOf(
            "#FC8E03", "#FF5C8A", "#FF3B30", "#FFC53D",
            "#34D399", "#38BDF8", "#A78BFA", "#8E8E93",
        )
    }
}

/**
 * 设置的读写。App 和桌面小组件共用同一份 SharedPreferences
 * —— 安卓上两者属于同一个包，天然互通，所以小组件能跟着 App 的设置走。
 */
object FlowPrefs {

    const val FILE = "flow"

    private const val K_ACCENT = "accentHex"
    private const val K_COLOR_PAST = "colorPastDots"
    private const val K_LAYOUT = "gridLayout"
    private const val K_SHOW_RING = "showRing"
    private const val K_SHOW_ROWS = "showRows"
    private const val K_SHOW_GRID = "showGrid"
    private const val K_APPEARANCE = "appearance"

    fun open(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun read(prefs: SharedPreferences): FlowSettings = FlowSettings(
        accentHex = prefs.getString(K_ACCENT, FlowSettings.DEFAULT_ACCENT)
            ?: FlowSettings.DEFAULT_ACCENT,
        colorPastDots = prefs.getBoolean(K_COLOR_PAST, false),
        gridLayout = GridLayout.fromKey(prefs.getString(K_LAYOUT, null)),
        showRing = prefs.getBoolean(K_SHOW_RING, true),
        showRows = prefs.getBoolean(K_SHOW_ROWS, true),
        showGrid = prefs.getBoolean(K_SHOW_GRID, true),
        appearance = Appearance.fromKey(prefs.getString(K_APPEARANCE, null)),
    )

    fun read(context: Context): FlowSettings = read(open(context))

    fun write(prefs: SharedPreferences, s: FlowSettings) {
        prefs.edit()
            .putString(K_ACCENT, s.accentHex)
            .putBoolean(K_COLOR_PAST, s.colorPastDots)
            .putString(K_LAYOUT, s.gridLayout.key)
            .putBoolean(K_SHOW_RING, s.showRing)
            .putBoolean(K_SHOW_ROWS, s.showRows)
            .putBoolean(K_SHOW_GRID, s.showGrid)
            .putString(K_APPEARANCE, s.appearance.key)
            .apply()
    }
}
