package com.zjzbs.flow.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Color
import android.widget.RemoteViews
import androidx.compose.ui.graphics.toArgb
import com.zjzbs.flow.MainActivity
import com.zjzbs.flow.R
import com.zjzbs.flow.data.FlowPrefs
import com.zjzbs.flow.domain.DotGridLayout
import com.zjzbs.flow.domain.FlowMath
import com.zjzbs.flow.domain.GridLayout
import com.zjzbs.flow.ui.DotRenderer
import com.zjzbs.flow.ui.parseHex
import java.time.ZonedDateTime

/** 小组件尺寸三档 */
enum class WidgetSize { Small, Medium, Large }

/**
 * 小组件刷新与渲染。
 *
 * 因为小组件和 App 在同一个进程里，所以这里能直接读 SharedPreferences，
 * 小组件会跟着 App 里选的布局 / 主题色 / 着色方式变化 —— 这点比 iOS 好，
 * iOS 那边要 App Group 才能互通。
 */
object WidgetBridge {

    private val ALL_PROVIDERS: List<Pair<Class<*>, WidgetSize>> = listOf(
        FlowWidgetSmall::class.java to WidgetSize.Small,
        FlowWidgetMedium::class.java to WidgetSize.Medium,
        FlowWidgetLarge::class.java to WidgetSize.Large,
    )

    /** 设置一改就全量刷一遍三个尺寸。 */
    fun refreshAll(context: Context) {
        val app = context.applicationContext
        val mgr = AppWidgetManager.getInstance(app) ?: return
        ALL_PROVIDERS.forEach { (cls, size) ->
            val ids = mgr.getAppWidgetIds(ComponentName(app, cls))
            ids?.forEach { id -> update(app, mgr, id, size) }
        }
    }

    fun update(context: Context, mgr: AppWidgetManager, id: Int, size: WidgetSize) {
        val prefs = FlowPrefs.read(context)
        val now = ZonedDateTime.now()
        val night = isNight(context)

        val (wDp, hDp) = dimensions(context, mgr, id, size)
        val density = context.resources.displayMetrics.density
        val wPx = (wDp * density).toInt().coerceAtLeast(1)
        val hPx = (hDp * density).toInt().coerceAtLeast(1)

        val views = when (size) {
            WidgetSize.Small -> RemoteViews(context.packageName, R.layout.widget_small)
            else -> RemoteViews(context.packageName, R.layout.widget_card)
        }

        // 头部：三种尺寸都有年份和天数（2×2 只是字号小一号）
        views.setTextViewText(R.id.widget_year, FlowMath.yearLabel(now))
        views.setTextViewText(R.id.widget_counter, FlowMath.dayCounterLabel(now))

        // 点阵区域：扣掉内边距和头部高度（数字要和 widget_*.xml 里的 padding 对齐）
        val padH = (if (size == WidgetSize.Small) 11f else 16f) * density
        val padV = (if (size == WidgetSize.Small) 10f else 14f) * density
        // 头部 = 字号行高 + 与点阵之间的 marginTop
        // 小号 9sp 行高约 11dp + 5dp；中/大号 11sp 行高约 14dp + 9dp
        val header = if (size == WidgetSize.Small) 16f * density else 23f * density
        val dotsW = (wPx - padH * 2).coerceAtLeast(8f)
        val dotsH = (hPx - padV * 2 - header).coerceAtLeast(8f)

        val bitmap = renderDots(
            context = context,
            width = dotsW,
            height = dotsH,
            layout = prefs.gridLayout,
            accentHex = prefs.accentHex,
            colorPastDots = prefs.colorPastDots,
            size = size,
            night = night,
            now = now,
        )
        views.setImageViewBitmap(R.id.widget_image, bitmap)

        // 点一下打开 App
        val launch = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_image, launch)

        mgr.updateAppWidget(id, views)
    }

    private fun renderDots(
        context: Context,
        width: Float,
        height: Float,
        layout: GridLayout,
        accentHex: String,
        colorPastDots: Boolean,
        size: WidgetSize,
        night: Boolean,
        now: ZonedDateTime,
    ): Bitmap {
        // 注意：这里统一用 android.graphics.Color 的 Int 值。
        // parseHex 返回的是 Compose 的 Color，要先 toArgb()。
        val accent = parseHex(accentHex).toArgb()
        val primary = if (night) Color.WHITE else Color.BLACK
        val past = if (colorPastDots) accent else primary
        val future = Color.argb(38, Color.red(primary), Color.green(primary), Color.blue(primary))

        // 列数按「点阵区域的宽高比」算出来，这样点阵能真正铺满整块卡片，
        // 不会像固定列数那样在两边留一大条空白。
        // 365 天排成 cols × rows，让 cols/rows ≈ 宽高比即可：cols ≈ sqrt(365 * aspect)。
        val aspect = (width / height.coerceAtLeast(1f)).coerceIn(0.5f, 6f)
        val columns = kotlin.math.ceil(kotlin.math.sqrt(365.0 * aspect))
            .toInt().coerceIn(12, 48)

        val monthsPerRow = when {
            aspect > 3.0f -> 6
            aspect > 1.6f -> 4
            else -> 3
        }

        val year = now.year
        val cells = DotGridLayout.cells(layout, year, columns, monthsPerRow)
        val todayIdx = FlowMath.todayIndex(now)

        val w = width.toInt().coerceAtLeast(1)
        val h = height.toInt().coerceAtLeast(1)
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bmp)
        DotRenderer.draw(
            canvas = canvas,
            width = w.toFloat(),
            height = h.toFloat(),
            cells = cells,
            todayIdx = todayIdx,
            pastColor = past,
            futureColor = future,
            todayColor = accent,
            dotScale = DotGridLayout.DOT_SCALE,
            stretchToFill = true,
        )
        return bmp
    }

    private fun dimensions(
        context: Context,
        mgr: AppWidgetManager,
        id: Int,
        size: WidgetSize,
    ): Pair<Int, Int> {
        val opts = runCatching { mgr.getAppWidgetOptions(id) }.getOrNull()
        val minW = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
        val maxW = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH) ?: 0
        val minH = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
        val maxH = opts?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) ?: 0

        // 竖屏 = MIN_WIDTH × MAX_HEIGHT，横屏 = MAX_WIDTH × MIN_HEIGHT。
        // （以前错用了 MIN_WIDTH × MIN_HEIGHT，竖屏下高度偏小，
        //   位图被 fitXY 横向拉长，圆点就变成椭圆了。）
        val portrait = context.resources.configuration.orientation !=
            Configuration.ORIENTATION_LANDSCAPE
        val w = if (portrait) minW else maxW
        val h = if (portrait) maxH else minH
        if (w > 0 && h > 0) return w to h

        // 四向都拿不到时退回单向组合
        val w2 = minW.takeIf { it > 0 } ?: maxW
        val h2 = maxH.takeIf { it > 0 } ?: minH
        if (w2 > 0 && h2 > 0) return w2 to h2
        // 拿不到就退回设计尺寸
        return when (size) {
            WidgetSize.Small -> 110 to 110
            WidgetSize.Medium -> 250 to 110
            WidgetSize.Large -> 250 to 250
        }
    }

    private fun isNight(context: Context): Boolean {
        val mode = context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK
        return mode == Configuration.UI_MODE_NIGHT_YES
    }
}
