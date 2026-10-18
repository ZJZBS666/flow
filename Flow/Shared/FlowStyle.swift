import SwiftUI

/// 圆角、间距这类「设计常量」集中放这里。
///
/// 之所以单独抽一层，是因为之前每个 View 各写一个数字（16、20 混着来），
/// 改起来要满工程找。现在统一成 iOS 系统那套规矩：
///
/// - 一律用 `style: .continuous`。这是 iOS 系统控件的圆角曲线
///   （Apple 官方叫 continuous corner / squircle / 超椭圆），和 `.circular`
///   那种正圆角比，它从直边到弧线是逐渐加速弯曲的，转折处更顺，
///   没有生硬的「直角感」。iPhone 设置页、系统弹层、系统卡片全是这个。
/// - 半径按「层级」分档，不按心情随手写。
/// - 嵌套的时候外面半径 = 里面半径 + 两者间距，这样两个圆角的弧线才是同心的
///   （Apple 叫 concentric radii）。否则里外弧度对不齐，看着会「别扭」但说不出哪不对。
public enum FlowRadius {

    /// 页面级大卡片：主界面那块 365 圆点卡。
    ///
    /// 16 这一档是 Apple 自家大卡片的常用值（健康 App 的卡片、钱包里的券卡都在
    /// 这个量级）。设置页那种一行行的分组列表用的是 10，但那是「行」的尺寸；
    /// 同样的 10 放到 342×300 的方块上会显得太方，所以大卡片取 16。
    public static let card: CGFloat = 16

    /// 卡片内部元素（设置页里的排列预览小块）。
    /// 比外层卡片的 16 再收一档，避让出层级感。
    public static let tile: CGFloat = 12

    /// 小组件外框。WidgetKit 自己会裁圆角，这个只在预览/占位时用。
    public static let widget: CGFloat = 22

    /// 同心圆角：外层容器里嵌一个子视图时，子视图该用的半径。
    /// - Parameters:
    ///   - outer: 外层容器的圆角半径
    ///   - inset: 子视图到外层的间距
    public static func nested(inside outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(0, outer - inset)
    }
}
