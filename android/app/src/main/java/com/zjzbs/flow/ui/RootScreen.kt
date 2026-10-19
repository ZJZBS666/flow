package com.zjzbs.flow.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zjzbs.flow.data.FlowStore
import com.zjzbs.flow.domain.FlowMath
import kotlinx.coroutines.delay
import java.time.ZonedDateTime
import kotlin.math.abs

@Composable
fun RootScreen(onOpenSettings: () -> Unit) {
    val c = LocalFlowColors.current
    val settings = FlowStore.settings
    val accent = parseHex(settings.accentHex)

    // 每分钟对齐到整分刷新一次。
    // 界面上最小的时间刻度是「今天」那行的整数百分比（1% ≈ 14.4 分钟），
    // 每秒重算纯属白烧电，对齐到整分观感又完全一样。
    var now by remember { mutableStateOf(ZonedDateTime.now()) }
    LaunchedEffect(Unit) {
        while (true) {
            val ms = System.currentTimeMillis()
            delay(60_000L - (ms % 60_000L))
            now = ZonedDateTime.now()
        }
    }

    val year = FlowMath.yearProgress(now)
    val rows = listOf(
        "今年" to year,
        "本月" to FlowMath.monthProgress(now),
        "本周" to FlowMath.weekProgress(now),
        "今天" to FlowMath.dayProgress(now),
    )

    Column(
        Modifier
            .fillMaxSize()
            .background(c.background)
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        // 顶栏
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 30.dp)
                .padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "FLOW",
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 3.4.sp,
                color = c.textSecondary,
            )
            Spacer(Modifier.weight(1f))
            IconButton(onClick = onOpenSettings) {
                Icon(
                    imageVector = Icons.Filled.Settings,
                    contentDescription = "设置",
                    tint = c.textSecondary,
                    modifier = Modifier.size(22.dp),
                )
            }
        }

        Spacer(Modifier.height(28.dp))

        // 大圆环
        if (settings.showRing) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                RingWithLabel(
                    progress = year,
                    accent = accent,
                    yearLabel = FlowMath.yearLabel(now),
                )
            }
            Spacer(Modifier.height(24.dp))
        } else {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = FlowMath.percent(year),
                    fontSize = 74.sp,
                    fontWeight = FontWeight.Bold,
                    color = c.textPrimary,
                )
            }
            Spacer(Modifier.height(6.dp))
        }

        // 剩余天数
        Text(
            text = FlowMath.remainingLabel(now),
            fontSize = 15.sp,
            color = c.textSecondary,
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 30.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )

        // 四条进度
        if (settings.showRows) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 30.dp)
                    .padding(bottom = 32.dp)
            ) {
                rows.forEach { (label, value) ->
                    ProgressRowView(label = label, progress = value, accent = accent)
                }
            }
        }

        // 圆点卡片
        if (settings.showGrid) {
            DotCard(
                layout = settings.gridLayout,
                accent = accent,
                colorPastDots = settings.colorPastDots,
                now = now,
                height = 188.dp,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .padding(bottom = 40.dp),
            )
        }
    }
}
