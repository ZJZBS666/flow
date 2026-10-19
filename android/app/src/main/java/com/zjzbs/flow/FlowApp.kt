package com.zjzbs.flow

import android.app.Activity
import android.graphics.Color
import androidx.activity.compose.BackHandler
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.zjzbs.flow.data.Appearance
import com.zjzbs.flow.data.FlowStore
import com.zjzbs.flow.ui.FlowTheme
import com.zjzbs.flow.ui.LocalFlowColors
import com.zjzbs.flow.ui.RootScreen
import com.zjzbs.flow.ui.SettingsScreen

@Composable
fun FlowApp() {
    val systemDark = isSystemInDarkTheme()
    val dark = when (FlowStore.appearance) {
        Appearance.System -> systemDark
        Appearance.Light -> false
        Appearance.Dark -> true
    }

    var showSettings by rememberSaveable { mutableStateOf(false) }

    // 让状态栏图标跟着主题反色
    val view = LocalView.current
    val activity = LocalContext.current as? Activity
    LaunchedEffect(dark) {
        val window = activity?.window ?: return@LaunchedEffect
        runCatching {
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !dark
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !dark
        }
    }

    BackHandler(enabled = showSettings) { showSettings = false }

    // 0.28 秒交叉淡入淡出，和 iOS 那边的观感对齐
    Crossfade(
        targetState = dark,
        animationSpec = tween(durationMillis = 280),
        label = "theme",
    ) { isDark ->
        FlowTheme(dark = isDark) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(LocalFlowColors.current.background)
            ) {
                if (showSettings) {
                    SettingsScreen(onClose = { showSettings = false })
                } else {
                    RootScreen(onOpenSettings = { showSettings = true })
                }
            }
        }
    }
}
