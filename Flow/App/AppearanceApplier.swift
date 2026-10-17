import SwiftUI
import UIKit

/// 把「外观」这一项真正写到窗口上，并且切换时做一次交叉淡入淡出。
///
/// 为什么不用 SwiftUI 的 preferredColorScheme：
/// 它是「瞬间」生效的——深色切浅色时整屏颜色在一帧之内全换掉，看着很硬。
/// 这里改成直接改 UIWindow 的 overrideUserInterfaceStyle，并在改之前先把
/// 旧画面截一张快照盖在最上层，改完用 0.32 秒把快照淡出。
/// 肉眼看到的效果就是旧配色渐渐化成新配色。
struct AppearanceApplier: UIViewRepresentable {
    /// .unspecified 表示跟随系统
    let style: UIUserInterfaceStyle

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        // 先试着同步落位（冷启动时不要先闪一下系统配色）。
        // 万一这时窗口还没建好，updateUIView 还会补一次，所以这里不记 lastStyle。
        applyStyleToWindows(style, animated: false)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        let target = style
        let first = context.coordinator.lastStyle == nil
        guard context.coordinator.lastStyle != target else { return }
        context.coordinator.lastStyle = target

        if first {
            applyStyleToWindows(target, animated: false)
            return
        }
        // 等这一帧结束再改，避免和当前这次布局打架
        DispatchQueue.main.async {
            applyStyleToWindows(target, animated: true)
        }
    }

    final class Coordinator {
        var lastStyle: UIUserInterfaceStyle?
    }
}

/// 正在淡出的那层旧画面，用 tag 标记，连点两下时好清掉上一张
private let snapshotTag = 0x5F0A1

/// 把配色应用到当前所有窗口。
/// 设置页是弹出来的独立一层，只改主窗口它可能漏掉，所以这里遍历一遍。
private func applyStyleToWindows(_ style: UIUserInterfaceStyle, animated: Bool) {
    let windows = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }

    for window in windows where window.overrideUserInterfaceStyle != style {
        // 上一张还没淡完的话先摘掉，避免叠两层
        window.viewWithTag(snapshotTag)?.removeFromSuperview()

        guard animated, !window.isHidden,
              let snapshot = window.snapshotView(afterScreenUpdates: false) else {
            // 不需要动画（启动时、或窗口不可见）：直接换
            window.overrideUserInterfaceStyle = style
            continue
        }

        // 1. 先盖上旧画面
        snapshot.tag = snapshotTag
        snapshot.frame = window.bounds
        snapshot.isUserInteractionEnabled = false
        window.addSubview(snapshot)

        // 2. 底下换配色（这一步瞬间完成，但被快照挡住了）
        window.overrideUserInterfaceStyle = style

        // 3. 下一帧开始把旧画面淡掉
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.32,
                           delay: 0,
                           options: [.curveEaseInOut, .beginFromCurrentState]) {
                snapshot.alpha = 0
            } completion: { _ in
                snapshot.removeFromSuperview()
            }
        }
    }
}
