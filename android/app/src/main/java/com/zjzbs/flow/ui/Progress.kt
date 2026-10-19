package com.zjzbs.flow.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zjzbs.flow.domain.FlowMath

/** 环形进度：底环 + 进度弧 + 圆头 */
@Composable
fun RingProgress(
    progress: Double,
    accent: Color,
    modifier: Modifier = Modifier,
    lineWidth: Dp = 15.dp,
) {
    val c = LocalFlowColors.current
    val p by animateFloatAsState(
        targetValue = progress.toFloat().coerceIn(0f, 1f),
        animationSpec = tween(durationMillis = 350),
        label = "ringProgress",
    )

    Canvas(modifier) {
        val stroke = lineWidth.toPx()
        val radius = (minOf(size.width, size.height) - stroke) / 2f
        if (radius <= 0f) return@Canvas
        val center = Offset(size.width / 2f, size.height / 2f)

        drawCircle(
            color = c.textPrimary.copy(alpha = 0.08f),
            radius = radius,
            center = center,
            style = Stroke(width = stroke),
        )

        val sweep = 360f * p.coerceAtLeast(0.0001f)
        drawArc(
            color = accent,
            startAngle = -90f,
            sweepAngle = sweep,
            useCenter = false,
            topLeft = Offset(center.x - radius, center.y - radius),
            size = Size(radius * 2f, radius * 2f),
            style = Stroke(width = stroke, cap = StrokeCap.Round),
        )
    }
}

/** 一条横向进度：标签 + 条 + 百分比 */
@Composable
fun ProgressRowView(
    label: String,
    progress: Double,
    accent: Color,
    modifier: Modifier = Modifier,
) {
    val c = LocalFlowColors.current
    val p by animateFloatAsState(
        targetValue = progress.toFloat().coerceIn(0f, 1f),
        animationSpec = tween(durationMillis = 500),
        label = "rowProgress",
    )

    Row(
        modifier
            .fillMaxWidth()
            .height(36.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = label,
            fontSize = 13.5.sp,
            color = c.textPrimary,
            modifier = Modifier.width(44.dp),
        )

        Box(
            Modifier
                .weight(1f)
                .height(7.5.dp)
        ) {
            Canvas(Modifier.fillMaxWidth().height(7.5.dp)) {
                val r = size.height / 2f
                drawRoundRect(color = c.track, cornerRadius = CornerRadius(r))
                val w = maxOf(size.width * p, minOf(7.5.dp.toPx(), size.width))
                drawRoundRect(
                    color = accent,
                    size = Size(w, size.height),
                    cornerRadius = CornerRadius(r),
                )
            }
        }

        Text(
            text = FlowMath.percent(progress, decimals = 0),
            fontSize = 13.5.sp,
            fontWeight = FontWeight.Normal,
            color = c.textSecondary,
            textAlign = TextAlign.End,
            modifier = Modifier.width(42.dp),
        )
    }
}

/** 环形 + 中间文字的整体块 */
@Composable
fun RingWithLabel(
    progress: Double,
    accent: Color,
    yearLabel: String,
    modifier: Modifier = Modifier,
) {
    val c = LocalFlowColors.current
    Box(modifier.size(191.dp), contentAlignment = Alignment.Center) {
        RingProgress(progress = progress, accent = accent, modifier = Modifier.size(191.dp))
        androidx.compose.foundation.layout.Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = FlowMath.percent(progress),
                fontSize = 50.sp,
                fontWeight = FontWeight.Bold,
                color = c.textPrimary,
                maxLines = 1,
            )
            Text(
                text = "${yearLabel}年",
                fontSize = 14.sp,
                color = c.textSecondary,
            )
        }
    }
}
