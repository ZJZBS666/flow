import SwiftUI

@main
struct FlowApp: App {
    @StateObject private var store = FlowStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                // 外观三档：浅色 / 深色 / 跟随系统
                // preferredColorScheme(nil) 就是跟随系统，这是 SwiftUI 的约定
                .preferredColorScheme(store.appearance.colorScheme)
        }
    }
}
