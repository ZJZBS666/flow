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
    ) {
        if (width <= 0f || height <= 0f) return
        if (cells.unitColumns <= 0 || cells.unitRows <= 0) return

        val unit = minOf(width / cells.unitColumns, height / cells.unitRows)
        if (unit <= 0f) return

        val gridW = unit * cells.unitColumns
        val gridH = unit * cells.unitRows
        val originX = (width - gridW) / 2f
        val originY = (height - gridH) / 2f
        val radius = maxOf(0.4f, unit * dotScale / 2f)

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 按颜色分三遍画。365 颗点分三组，比逐颗切换画笔状态快得多。
        drawPass(canvas, paint, cells, originX, originY, unit, radius, pastColor) { it < todayIdx }
        drawPass(canvas, paint, cells, originX, originY, unit, radius, futureColor) { it > todayIdx }
        drawPass(canvas, paint, cells, originX, originY, unit, radius, todayColor) { it == todayIdx }
    }

    private inline fun drawPass(
        canvas: Canvas,
        paint: Paint,
        cells: GridCells,
        originX: Float,
        originY: Float,
        unit: Float,
        radius: Float,
        color: Int,
        crossinline predicate: (Int) -> Boolean,
    ) {
        paint.color = color
        for (dot in cells.dots) {
            if (!predicate(dot.day)) continue
            val cx = originX + (dot.col + 0.5f) * unit
            val cy = originY + (dot.row + 0.5f) * unit
            canvas.drawCircle(cx, cy, radius, paint)
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

    Canvas(
        modifier.semantics {
            contentDescription =
                "${FlowMath.dayCounterLabel(now)}，今年进度 ${FlowMath.percent(FlowMath.yearProgress(now))}"
        }
    ) {
        drawIntoCanvas { canvas ->
            val cells = DotGridLayout.cells(
                layout = layout,
                year = now.year,
                sequentialColumns = sequentialColumns,
                monthsPerRow = monthsPerRow,
            )
            DotRenderer.draw(
                canvas = canvas.nativeCanvas,
                width = size.width,
                height = size.height,
                cells = cells,
                todayIdx = FlowMath.todayIndex(now),
                pastColor = past.toArgb(),
                futureColor = future.toArgb(),
                todayColor = accent.toArgb(),
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
