package com.zjzbs.flow

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.zjzbs.flow.data.FlowStore

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FlowStore.init(applicationContext)
        enableEdgeToEdge()
        setContent { FlowApp() }
    }
}
