import SwiftUI

@main
struct FlowApp: App {
    @StateObject private var store = FlowStore.shared

    init() {
        // 把「设置里改外观」接到窗口上（平滑交叉淡入）。
        AppearanceBridge.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                // 外观三档：浅色 / 深色 / 跟随系统（.unspecified 就是跟随系统）
                //
                // 不用 preferredColorScheme，因为它切换时是硬跳的。
                // 真正的切换在 AppearanceTransition 里：改窗口的
                // overrideUserInterfaceStyle，并把旧画面交叉淡出。
                // 这里挂的这个种子视图只负责冷启动时补一次同步。
                .background(
                    AppearanceSeed()
                        .frame(width: 0, height: 0)
                )
        }
    }
}
