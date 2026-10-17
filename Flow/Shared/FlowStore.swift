import SwiftUI
import UIKit
import WidgetKit

/// 设置存储。
///
/// 说明：为了让签名一次成功，这个工程**没有**启用 App Group 权限。
/// 带来的结果是：App 里的设置只影响 App 自己，桌面小组件始终使用
/// 默认样式（橙色、顺序排列、只有今天亮橙色）。
/// 小组件进程读不到 App 的 UserDefaults，于是自动落到下面的默认值上。
public final class FlowStore: ObservableObject {

    public static let shared = FlowStore()

    private let defaults: UserDefaults

    // MARK: - 键名
    private enum Key {
        static let accent = "accentHex"
        static let colorPast = "colorPastDots"
        static let layout = "gridLayout"
        static let showRing = "showRing"
        static let showRows = "showRows"
        static let showGrid = "showGrid"
        static let appearance = "appearance"
    }

    // MARK: - 设置项

    /// 外观：浅色 / 深色 / 跟随系统
    @Published public var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    /// 主题色，十六进制字符串，如 "#FC8E03"
    @Published public var accentHex: String {
        didSet { defaults.set(accentHex, forKey: Key.accent); reloadWidgets() }
    }

    /// true = 已过去的圆点全部用主题色；false = 只有今天用主题色
    @Published public var colorPastDots: Bool {
        didSet { defaults.set(colorPastDots, forKey: Key.colorPast); reloadWidgets() }
    }

    /// 网格排列方式
    @Published public var gridLayout: GridLayout {
        didSet { defaults.set(gridLayout.rawValue, forKey: Key.layout); reloadWidgets() }
    }

    @Published public var showRing: Bool {
        didSet { defaults.set(showRing, forKey: Key.showRing) }
    }

    @Published public var showRows: Bool {
        didSet { defaults.set(showRows, forKey: Key.showRows) }
    }

    @Published public var showGrid: Bool {
        didSet { defaults.set(showGrid, forKey: Key.showGrid) }
    }

    // MARK: - 初始化

    private init() {
        defaults = .standard

        accentHex = defaults.string(forKey: Key.accent) ?? "#FC8E03"
        colorPastDots = defaults.object(forKey: Key.colorPast) as? Bool ?? false
        gridLayout = GridLayout(rawValue: defaults.string(forKey: Key.layout) ?? "") ?? .sequential
        showRing = defaults.object(forKey: Key.showRing) as? Bool ?? true
        showRows = defaults.object(forKey: Key.showRows) as? Bool ?? true
        showGrid = defaults.object(forKey: Key.showGrid) as? Bool ?? true
        appearance = Appearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
    }

    /// 通知小组件刷新
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 派生

    public var accentColor: Color {
        Color(hex: accentHex) ?? Color(red: 252/255, green: 142/255, blue: 3/255)
    }
}

// MARK: - 外观

/// 外观模式。存的是字符串，方便 UserDefaults 持久化。
public enum Appearance: String, CaseIterable, Identifiable {
    case system     // 跟随系统
    case light      // 浅色
    case dark       // 深色

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light:  return "浅色"
        case .dark:   return "深色"
        }
    }

    /// 交给 SwiftUI 的 preferredColorScheme；nil 表示跟随系统
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// 交给 UIKit 的 overrideUserInterfaceStyle，用于小组件预览等场景
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - 网格排列

public enum GridLayout: String, CaseIterable, Identifiable {
    case sequential     // 顺序排列：1 月 1 日从左上角铺满
    case calendar       // 日历排列：12 个月块，每块周一至周日成列

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .sequential: return "顺序排列"
        case .calendar:   return "日历排列"
        }
    }

    public var subtitle: String {
        switch self {
        case .sequential: return "从 1 月 1 日铺满"
        case .calendar:   return "12 个月块"
        }
    }
}

// MARK: - 颜色工具

public extension Color {
    /// 从 "#RRGGBB" 创建颜色，失败返回 nil
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }

    /// 转成 "#RRGGBB"
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}
