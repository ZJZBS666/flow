import SwiftUI
import UIKit

/// 外观切换时的过渡。
///
/// 为什么不直接用 SwiftUI 的 `preferredColorScheme`：
/// 它是「瞬间」生效的，深色切浅色时整屏颜色在一帧之内全换掉，看着很硬。
///
/// 这里改成直接改 `UIWindow.overrideUserInterfaceStyle`，改之前先把旧画面
/// 截一张快照盖在最上层，改完再把快照淡掉。肉眼看到的就是旧配色渐渐化成新配色。
///
/// 关于流畅度，踩过两个坑：
/// 1. 原来用 `DispatchQueue.main.async` 把「淡出」推迟到下一帧才开始，
///    结果中间空出一帧，观感是「先顿一下再淡」。现在快照贴上去、换色、起动画
///    全在同一个 turn 里完成，Core Animation 会在同一次提交里把动画带上，
///    不会再有那个空档。
/// 2. 大头的卡顿其实不在这里，而在换色瞬间 SwiftUI 整棵树重建
///    （365 个圆点排布 + 日历运算）。那个已经单独优化了：
///    日历实例缓存、圆点排布按「年」缓存、三条 Path 合并绘制。
enum AppearanceTransition {

    /// 正在淡出的那层旧画面，用 tag 标记。连点两下时先把上一张摘掉，避免叠两层。
    private static let snapshotTag = 0x5F0A1

    /// 淡入淡出时长。0.3 秒接近 iOS 系统自己切深色时的节奏。
    private static let duration: TimeInterval = 0.30

    /// 把配色应用到当前所有窗口。
    /// 设置页是弹出来的独立一层，只改主窗口它可能漏掉，所以这里遍历一遍。
    ///
    /// 返回 true 表示确实有窗口被改过（用来判断冷启动时那次同步是否生效了）。
    @discardableResult
    static func apply(_ style: UIUserInterfaceStyle, animated: Bool) -> Bool {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        var changed = false

        for window in windows where window.overrideUserInterfaceStyle != style {

            // 上一张还没淡完的话先摘掉
            window.viewWithTag(snapshotTag)?.removeFromSuperview()

            guard animated, !window.isHidden,
                  let snapshot = window.snapshotView(afterScreenUpdates: false) else {
                // 不需要动画（冷启动、窗口不可见、或截不出快照）：直接换
                window.overrideUserInterfaceStyle = style
                changed = true
                continue
            }

            // 1. 先盖上旧画面
            snapshot.tag = snapshotTag
            snapshot.frame = window.bounds
            snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            snapshot.isUserInteractionEnabled = false
            window.addSubview(snapshot)

            // 2. 底下换配色。被快照挡着，这一下看不见。
            window.overrideUserInterfaceStyle = style
            changed = true

            // 3. 同一个 turn 里起动画，不要 async 推迟，
            //    否则中间会空出一帧，看起来就是「顿一下」。
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
                snapshot.alpha = 0
            } completion: { _ in
                snapshot.removeFromSuperview()
            }
        }

        return changed
    }
}
