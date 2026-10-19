# 桌面小组件的三个 provider 是系统按 Manifest 里的类名反射实例化的，
# 混淆会改类名 —— 必须原样保留。
-keep class com.zjzbs.flow.widget.** { *; }

# AppWidget 的布局里用到的自定义 View（目前没有，留着兜底）
-keep public class * extends android.appwidget.AppWidgetProvider
