import SwiftUI
import UIKit
import Combine

/// 把「设置里改了外观」这件事接到窗口上。
///
/// 为什么不在 `FlowStore.appearance.didSet` 里直接调？
/// 因为 `FlowStore` 在 Shared 目录，小组件 target 也要编译它，
/// 而小组件进程里 `UIApplication.shared` 是拿不到的（扩展限制）。
/// 所以「改窗口配色」这件事只能待在 App target 里，用这里的转发来做。
///
/// 为什么要绕开 SwiftUI 的更新链：
/// 之前是靠一个 `UIViewRepresentable` 在 `updateUIView` 里被动触发，那条路径会
/// 让同一次切换走两遍整棵视图树：
///   ① @Published 触发 SwiftUI 重算（还是旧配色）
///   ② representable 的 updateUIView 才去换窗口配色
///   ③ 换完 trait collection 变化，SwiftUI 又整体重算一遍（新配色）
/// 现在改成订阅 `$appearance`，跳一轮 runloop 直接做，
/// 不再多经过一次「用旧配色渲染」的中间态。
final class AppearanceBridge {

    private static var cancellable: AnyCancellable?

    /// 在 App 启动时调用一次。
    static func start() {
        guard cancellable == nil else { return }

        // 冷启动：先按用户存的偏好同步一次（不要动画，否则一打开就闪一下）
        AppearanceTransition.apply(FlowStore.shared.appearance.userInterfaceStyle, animated: false)

        cancellable = FlowStore.shared.$appearance
            .dropFirst()                    // 跳过订阅时补发的当前值，上面已经处理过
            .removeDuplicates()
            .sink { appearance in
                // 跳一轮 runloop：避免在「SwiftUI 正在更新视图」的过程中去改窗口
                DispatchQueue.main.async {
                    AppearanceTransition.apply(appearance.userInterfaceStyle, animated: true)
                }
            }
    }
}

/// 冷启动时窗口还没建好，`start()` 里那次同步多半没生效。
/// 这个不可见的小视图在**挂到窗口上的那一刻**再补一次，赶在第一帧画出来之前。
///
/// 它对 SwiftUI 的数据没有任何依赖（自己去读 FlowStore），
/// 所以外观变化不会因为它多触发一次视图刷新。
struct AppearanceSeed: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView { SeedView() }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private final class SeedView: UIView {
        private var applied = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard !applied, window != nil else { return }
            applied = true
            AppearanceTransition.apply(FlowStore.shared.appearance.userInterfaceStyle, animated: false)
        }
    }
}
