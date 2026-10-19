package com.zjzbs.flow.ui

import android.graphics.Canvas
import android.graphics.Paint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zjzbs.flow.domain.DotGridLayout
import com.zjzbs.flow.domain.FlowMath
import com.zjzbs.flow.domain.GridCells
import com.zjzbs.flow.domain.GridLayout
import java.time.ZonedDateTime

/**
 * 365 颗圆点的绘制。
 *
 * 刻意写在 Compose 之外（直接吃 android.graphics.Canvas），
 * 这样**同一份绘制代码**既给 App 的 Canvas 用，也给桌面小组件的 Bitmap 用，
 * 两边的点径、间距、颜色完全一致，不用维护两套。
 */
object DotRenderer {

    fun draw(
        canvas: Canvas,
        width: Float,
        height: Float,
        cells: GridCells,
        todayIdx: Int,
        pastColor: Int,
        futureColor: Int,
        todayColor: Int,
        dotScale: Float = DotGridLayout.DOT_SCALE,
        stretchToFill: Boolean = false,
    ) {
        if (width <= 0f || height <= 0f) return
        if (cells.unitColumns <= 0 || cells.unitRows <= 0) return

        val pitchX: Float
        val pitchY: Float
        val originX: Float
        val originY: Float

        if (stretchToFill) {
            // 桌面小组件用：横竖各自铺满整张位图，不留边。
            // 位图会被 ImageView 等比缩放到实际卡片上，所以这里先按位图尺寸铺满，
            // 屏幕上就基本是满的；点画成椭圆，用来抵消缩放比例的细微差别。
            pitchX = width / cells.unitColumns
            pitchY = height / cells.unitRows
            originX = 0f
            originY = 0f
        } else {
            // App 里用：正方形格子、整体居中，点必须是正圆。
            val unit = minOf(width / cells.unitColumns, height / cells.unitRows)
            pitchX = unit
            pitchY = unit
            originX = (width - unit * cells.unitColumns) / 2f
            originY = (height - unit * cells.unitRows) / 2f
        }
        if (pitchX <= 0f || pitchY <= 0f) return

        val rx = maxOf(0.4f, pitchX * dotScale / 2f)
        val ry = maxOf(0.4f, pitchY * dotScale / 2f)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 按颜色分三遍画。365 颗点分三组，比逐颗切换画笔状态快得多。
        drawPass(canvas, paint, cells, originX, originY, pitchX, pitchY, rx, ry, pastColor) { it < todayIdx }
        drawPass(canvas, paint, cells, originX, originY, pitchX, pitchY, rx, ry, futureColor) { it > todayIdx }
        drawPass(canvas, paint, cells, originX, originY, pitchX, pitchY, rx, ry, todayColor) { it == todayIdx }
    }

    private inline fun drawPass(
        canvas: Canvas,
        paint: Paint,
        cells: GridCells,
        originX: Float,
        originY: Float,
        pitchX: Float,
        pitchY: Float,
        rx: Float,
        ry: Float,
        color: Int,
        crossinline predicate: (Int) -> Boolean,
    ) {
        paint.color = color
        for (dot in cells.dots) {
            if (!predicate(dot.day)) continue
            val cx = originX + (dot.col + 0.5f) * pitchX
            val cy = originY + (dot.row + 0.5f) * pitchY
            if (rx == ry) {
                canvas.drawCircle(cx, cy, rx, paint)
            } else {
                canvas.drawOval(cx - rx, cy - ry, cx + rx, cy + ry, paint)
            }
        }
    }
}

/** App 里用的圆点画布 */
@Composable
fun DotGridCanvas(
    layout: GridLayout,
    accent: Color,
    colorPastDots: Boolean,
    now: ZonedDateTime,
    sequentialColumns: Int,
    monthsPerRow: Int,
    modifier: Modifier = Modifier,
) {
    val c = LocalFlowColors.current
    val past = if (colorPastDots) accent else c.textPrimary.copy(alpha = 0.92f)
    val future = c.textPrimary.copy(alpha = 0.13f)

    // 点阵排布一年才变一次，不要在每帧绘制里重算（滚动时 Canvas 每帧都会重画）。
    val cells = remember(layout, now.year, sequentialColumns, monthsPerRow) {
        DotGridLayout.cells(
            layout = layout,
            year = now.year,
            sequentialColumns = sequentialColumns,
            monthsPerRow = monthsPerRow,
        )
    }
    val todayIdx = remember(now.year, now.dayOfYear) { FlowMath.todayIndex(now) }
    val pastArgb = past.toArgb()
    val futureArgb = future.toArgb()
    val accentArgb = accent.toArgb()

    Canvas(
        modifier.semantics {
            contentDescription =
                "${FlowMath.dayCounterLabel(now)}，今年进度 ${FlowMath.percent(FlowMath.yearProgress(now))}"
        }
    ) {
        drawIntoCanvas { canvas ->
            DotRenderer.draw(
                canvas = canvas.nativeCanvas,
                width = size.width,
                height = size.height,
                cells = cells,
                todayIdx = todayIdx,
                pastColor = pastArgb,
                futureColor = futureArgb,
                todayColor = accentArgb,
            )
        }
    }
}

/** 带表头的圆点卡片 */
@Composable
fun DotCard(
    layout: GridLayout,
    accent: Color,
    colorPastDots: Boolean,
    now: ZonedDateTime,
    height: Dp,
    modifier: Modifier = Modifier,
    columns: Int = 24,
    monthsPerRow: Int = 4,
) {
    val c = LocalFlowColors.current
    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(FlowRadius.card))
            .background(c.card)
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Row(Modifier.fillMaxWidth()) {
            Text(
                text = FlowMath.yearLabel(now),
                fontSize = 11.5.sp,
                color = c.textSecondary,
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = FlowMath.dayCounterLabel(now),
                fontSize = 11.5.sp,
                color = c.textSecondary,
            )
        }
        Spacer(Modifier.height(12.dp))
        DotGridCanvas(
            layout = layout,
            accent = accent,
            colorPastDots = colorPastDots,
            now = now,
            sequentialColumns = columns,
            monthsPerRow = monthsPerRow,
            modifier = Modifier
                .fillMaxWidth()
                .height(height),
        )
    }
}
