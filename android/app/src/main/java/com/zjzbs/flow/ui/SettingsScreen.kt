package com.zjzbs.flow.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zjzbs.flow.data.Appearance
import com.zjzbs.flow.data.FlowSettings
import com.zjzbs.flow.data.FlowStore
import com.zjzbs.flow.domain.GridLayout
import java.time.ZonedDateTime

private const val REPO_URL = "https://github.com/ZJZBS666/flow"

@Composable
fun SettingsScreen(onClose: () -> Unit) {
    val c = LocalFlowColors.current
    val ctx = LocalContext.current
    val settings = FlowStore.settings
    val accent = parseHex(settings.accentHex)

    val version = remember {
        runCatching {
            ctx.packageManager.getPackageInfo(ctx.packageName, 0).versionName
        }.getOrNull() ?: "1.0.3"
    }

    val now = remember { ZonedDateTime.now() }

    Column(
        Modifier
            .fillMaxSize()
            .background(c.background)
            .systemBarsPadding()
    ) {
        // 标题栏
        Row(
            Modifier
                .fillMaxWidth()
                .padding(start = 20.dp, end = 12.dp, top = 12.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "设置",
                fontSize = 34.sp,
                fontWeight = FontWeight.Bold,
                color = c.textPrimary,
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = "完成",
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                color = parseHex("#FC8E03"),
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(onClick = onClose)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            )
        }

        Column(
            Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 28.dp)
        ) {
            // ---------- 外观 ----------
            SectionHeader("外观")
            SettingsGroup {
                Box(Modifier.padding(12.dp)) {
                    SegmentedControl(
                        options = Appearance.entries.map { it to it.title },
                        selected = settings.appearance,
                        onSelect = { FlowStore.appearance = it },
                    )
                }
            }

            // ---------- 主题颜色 ----------
            SectionHeader("主题颜色")
            SettingsGroup {
                // 8 个色块一排放不下时（窄屏），按可用宽度均分，而不是让最后几个被挤扁。
                BoxWithConstraints(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp, vertical = 8.dp)
                ) {
                    val palette = FlowSettings.PALETTE
                    val gap = 4.dp
                    val cell = (maxWidth - gap * (palette.size - 1)) / palette.size
                    val swatch = minOf(42.dp, cell)
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(gap),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        palette.forEach { hex ->
                            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                                ColorSwatch(
                                    hex = hex,
                                    selected = settings.accentHex.equals(hex, ignoreCase = true),
                                    onClick = { FlowStore.accentHex = hex },
                                    size = swatch,
                                )
                            }
                        }
                    }
                }
            }

            // ---------- 圆点着色 ----------
            SectionHeader("圆点着色")
            SettingsGroup {
                Box(Modifier.padding(12.dp)) {
                    SegmentedControl(
                        options = listOf(
                            false to "仅今天",
                            true to "已过去的全部",
                        ),
                        selected = settings.colorPastDots,
                        onSelect = { FlowStore.colorPastDots = it },
                    )
                }
            }

            // ---------- 网格排列 ----------
            SectionHeader("网格排列")
            SettingsGroup {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    GridLayout.entries.forEach { layout ->
                        LayoutCard(
                            layout = layout,
                            selected = settings.gridLayout == layout,
                            accent = accent,
                            colorPastDots = settings.colorPastDots,
                            now = now,
                            modifier = Modifier.weight(1f),
                            onClick = { FlowStore.gridLayout = layout },
                        )
                    }
                }
            }

            // ---------- 显示内容 ----------
            SectionHeader("显示内容")
            SettingsGroup {
                SwitchRow("圆环总览", settings.showRing, accent) { FlowStore.showRing = it }
                SettingsDivider()
                SwitchRow("年 / 月 / 周 / 日", settings.showRows, accent) { FlowStore.showRows = it }
                SettingsDivider()
                SwitchRow("圆点网格", settings.showGrid, accent) { FlowStore.showGrid = it }
            }

            // ---------- 项目 ----------
            SectionHeader("项目")
            SettingsGroup {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable {
                            runCatching {
                                ctx.startActivity(
                                    Intent(Intent.ACTION_VIEW, Uri.parse(REPO_URL))
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                )
                            }
                        }
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "</>",
                        fontSize = 13.sp,
                        color = c.textSecondary,
                        modifier = Modifier.padding(end = 12.dp),
                    )
                    Column(Modifier.weight(1f)) {
                        Text(
                            text = "ZJZBS666",
                            fontSize = 15.sp,
                            color = c.textPrimary,
                        )
                        Text(
                            text = "github.com/ZJZBS666/flow",
                            fontSize = 11.5.sp,
                            color = c.textSecondary,
                        )
                    }
                    Text(
                        text = "↗",
                        fontSize = 14.sp,
                        color = c.textTertiary,
                    )
                }
            }

            Text(
                text = "Flow v$version",
                fontSize = 11.sp,
                color = c.textTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 22.dp),
            )
        }
    }
}

@Composable
private fun SwitchRow(
    label: String,
    checked: Boolean,
    accent: Color,
    onChange: (Boolean) -> Unit,
) {
    val c = LocalFlowColors.current
    SettingsRow {
        Text(
            text = label,
            fontSize = 15.sp,
            color = c.textPrimary,
            modifier = Modifier.weight(1f),
        )
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = accent,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = c.controlTrack,
                uncheckedBorderColor = Color.Transparent,
            ),
        )
    }
}

/** 设置页里那个小的排列预览卡片 */
@Composable
private fun LayoutCard(
    layout: GridLayout,
    selected: Boolean,
    accent: Color,
    colorPastDots: Boolean,
    now: ZonedDateTime,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val c = LocalFlowColors.current
    Column(
        modifier
            .height(116.dp)
            .clip(RoundedCornerShape(FlowRadius.tile))
            .background(c.card)
            .border(
                width = if (selected) 2.dp else 0.dp,
                color = if (selected) accent else Color.Transparent,
                shape = RoundedCornerShape(FlowRadius.tile),
            )
            .clickable(onClick = onClick)
            .padding(top = 14.dp, bottom = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        DotGridCanvas(
            layout = layout,
            accent = accent,
            colorPastDots = colorPastDots,
            now = now,
            sequentialColumns = 24,
            monthsPerRow = 6,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp)
                .height(58.dp),
        )
        Spacer(Modifier.weight(1f))
        Text(
            text = layout.title,
            fontSize = 12.5.sp,
            color = c.textPrimary,
        )
        Text(
            text = layout.subtitle,
            fontSize = 9.5.sp,
            color = c.textTertiary,
        )
    }
}
