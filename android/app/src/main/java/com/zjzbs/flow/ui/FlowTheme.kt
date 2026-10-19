package com.zjzbs.flow.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale
import kotlin.math.roundToInt

/** 全 App 的色板。深色/浅色两套，都是照 iOS 版的效果图取的。 */
data class FlowColors(
    val background: Color,
    val card: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val track: Color,
    val separator: Color,
    val controlTrack: Color,
    val controlThumb: Color,
    val isDark: Boolean,
)

val LightFlowColors = FlowColors(
    background = Color(0xFFF3F3F3),
    card = Color(0xFFFFFFFF),
    textPrimary = Color(0xFF000000),
    textSecondary = Color(0x99000000),
    textTertiary = Color(0x4D000000),
    track = Color(0x14000000),
    separator = Color(0x1F000000),
    controlTrack = Color(0xFFE9E9EB),
    controlThumb = Color(0xFFFFFFFF),
    isDark = false,
)

val DarkFlowColors = FlowColors(
    background = Color(0xFF000000),
    card = Color(0xFF1C1C1E),
    textPrimary = Color(0xFFFFFFFF),
    textSecondary = Color(0x99FFFFFF),
    textTertiary = Color(0x4DFFFFFF),
    track = Color(0x1AFFFFFF),
    separator = Color(0x26FFFFFF),
    controlTrack = Color(0xFF2C2C2E),
    controlThumb = Color(0xFF636366),
    isDark = true,
)

val LocalFlowColors = staticCompositionLocalOf { LightFlowColors }

@Composable
fun FlowTheme(dark: Boolean, content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalFlowColors provides if (dark) DarkFlowColors else LightFlowColors,
        content = content,
    )
}

/** 圆角半径。和 iOS 版对齐：大卡片 16，卡片内小块 12。 */
object FlowRadius {
    val card: Dp = 16.dp
    val tile: Dp = 12.dp
    val group: Dp = 12.dp
}

// ---------------- 颜色工具 ----------------

fun parseHex(hex: String, fallback: Color = Color(0xFFFC8E03)): Color =
    runCatching { Color(android.graphics.Color.parseColor(hex.trim())) }.getOrDefault(fallback)

fun Color.toHexString(): String = String.format(
    Locale.US,
    "#%02X%02X%02X",
    (red * 255f).roundToInt(),
    (green * 255f).roundToInt(),
    (blue * 255f).roundToInt(),
)

// ---------------- 设置页用的通用小部件 ----------------

/** 分组小标题 */
@Composable
fun SectionHeader(text: String, modifier: Modifier = Modifier) {
    val c = LocalFlowColors.current
    Text(
        text = text,
        fontSize = 12.5.sp,
        color = c.textSecondary,
        modifier = modifier.padding(start = 16.dp, top = 18.dp, bottom = 7.dp),
    )
}

/** 圆角卡片容器（对应 iOS 的分组列表） */
@Composable
fun SettingsGroup(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val c = LocalFlowColors.current
    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(FlowRadius.group))
            .background(c.card),
        content = { content() },
    )
}

/** 一行（左标签 + 右侧内容）。content 带 RowScope，这样里面能用 weight。 */
@Composable
fun SettingsRow(
    modifier: Modifier = Modifier,
    content: @Composable RowScope.() -> Unit,
) {
    Row(
        modifier
            .fillMaxWidth()
            .height(50.dp)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

@Composable
fun SettingsDivider(startIndent: Dp = 16.dp) {
    val c = LocalFlowColors.current
    Box(
        Modifier
            .fillMaxWidth()
            .padding(start = startIndent)
            .height(0.7.dp)
            .background(c.separator)
    )
}

/** 分段控件（对应 iOS 的 segmented picker） */
@Composable
fun <T> SegmentedControl(
    options: List<Pair<T, String>>,
    selected: T,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    val c = LocalFlowColors.current
    Row(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(9.dp))
            .background(c.controlTrack)
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        options.forEach { (value, label) ->
            val active = value == selected
            Box(
                Modifier
                    .weight(1f)
                    .height(30.dp)
                    .clip(RoundedCornerShape(7.dp))
                    .background(if (active) c.controlThumb else Color.Transparent)
                    .clickable { onSelect(value) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = label,
                    fontSize = 13.sp,
                    fontWeight = if (active) FontWeight.Medium else FontWeight.Normal,
                    color = if (active) c.textPrimary else c.textSecondary,
                )
            }
        }
    }
}

/**
 * 主题色圆点。
 * 选中时外面套一圈描边 —— 对应 iOS 版 `padding(-4.5)` 的做法，
 * 描边在圆的外面，所以整格做成 42dp、圆本身 33dp。
 */
@Composable
fun ColorSwatch(
    hex: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val c = LocalFlowColors.current
    Box(modifier.size(42.dp), contentAlignment = Alignment.Center) {
        if (selected) {
            Box(
                Modifier
                    .matchParentSize()
                    .border(1.5.dp, c.textPrimary, CircleShape)
            )
        }
        Box(
            Modifier
                .size(33.dp)
                .clip(CircleShape)
                .background(parseHex(hex))
                .clickable(onClick = onClick)
        )
    }
}

