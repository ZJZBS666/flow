import SwiftUI

@main
struct FlowApp: App {
    @StateObject private var store = FlowStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                // 外观三档：浅色 / 深色 / 跟随系统（.unspecified 就是跟随系统）
                //
                // 这里不用 preferredColorScheme，因为它切换时是硬跳的。
                // AppearanceApplier 会直接改窗口的 overrideUserInterfaceStyle，
                // 并配一次 0.32 秒的交叉淡入，切换过程是平滑的。
                .background(
                    AppearanceApplier(style: store.appearance.userInterfaceStyle)
                        .frame(width: 0, height: 0)
                )
        }
    }
}
