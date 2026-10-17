import SwiftUI

@main
struct FlowApp: App {
    @StateObject private var store = FlowStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
