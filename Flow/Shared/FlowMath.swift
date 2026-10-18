import Foundation

/// 时间进度计算。所有界面和小组件都从这里取数，保证完全一致。
public enum FlowMath {

    // MARK: - 基础

    /// 缓存的日历实例。
    ///
    /// 原来这里是 computed property，每读一次就 `Calendar(identifier:)` 建一个新的
    /// —— 这个构造内部要走 ICU 的初始化，不便宜。而日历排列一次布局要点十几次
    /// （12 个月 × 每月取天数/首日星期/年内偏移），加上圆点卡片每秒重绘，
    /// 累积起来是切外观时肉眼可见的卡顿来源之一。
    ///
    /// 缓存 + 时区变了才重建：跨时区飞行、手动改时区都能正确跟上。
    private static var cachedCalendar: Calendar?
    private static var cachedTimeZoneID: String?
    /// 小组件渲染不保证在主线程上，加把锁避免并发写坏这个缓存
    private static let calendarLock = NSLock()

    public static var calendar: Calendar {
        let zoneID = TimeZone.current.identifier

        calendarLock.lock()
        if let cached = cachedCalendar, cachedTimeZoneID == zoneID {
            calendarLock.unlock()
            return cached
        }
        calendarLock.unlock()

        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2          // 周一为一周开始
        c.timeZone = TimeZone(identifier: zoneID) ?? .current

        calendarLock.lock()
        cachedCalendar = c
        cachedTimeZoneID = zoneID
        calendarLock.unlock()

        return c
    }

    /// 某一年的第一天 0 点
    public static func yearStart(_ year: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    /// 某一年的最后一天 0 点
    public static func yearEnd(_ year: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
    }

    /// 这一年一共有多少天（365 或 366）
    public static func dayCount(_ year: Int) -> Int {
        calendar.range(of: .day, in: .year, for: yearStart(year))!.count
    }

    // MARK: - 年进度

    /// 今年已经过去的比例 0...1（精确到秒，含时分秒）
    public static func yearProgress(now: Date = Date()) -> Double {
        let y = calendar.component(.year, from: now)
        let start = yearStart(y)
        let end = yearStart(y + 1)
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    // MARK: - 月 / 周 / 日进度

    public static func monthProgress(now: Date = Date()) -> Double {
        guard let interval = calendar.dateInterval(of: .month, for: now) else { return 0 }
        let total = interval.duration
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(interval.start) / total))
    }

    public static func weekProgress(now: Date = Date()) -> Double {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let total = interval.duration
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(interval.start) / total))
    }

    public static func dayProgress(now: Date = Date()) -> Double {
        guard let interval = calendar.dateInterval(of: .day, for: now) else { return 0 }
        let total = interval.duration
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(interval.start) / total))
    }

    // MARK: - 天数

    /// 今天是今年的第几天（从 1 开始）
    public static func dayOfYear(now: Date = Date()) -> Int {
        let y = calendar.component(.year, from: now)
        let start = yearStart(y)
        let today = calendar.startOfDay(for: now)
        let d = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return d + 1
    }

    /// 今年还剩多少天（不含今天）
    public static func daysRemaining(now: Date = Date()) -> Int {
        let y = calendar.component(.year, from: now)
        return dayCount(y) - dayOfYear(now: now)
    }

    /// 今天还剩多少小时（向下取整，0...23）
    public static func hoursRemainingToday(now: Date = Date()) -> Int {
        let h = calendar.component(.hour, from: now)
        return max(0, 23 - h)
    }

    // MARK: - 圆点网格

    /// 圆点网格里每一颗点代表的状态
    public enum DotState { case past, today, future }
    /// 生成一整年的圆点状态数组，索引 0 = 1 月 1 日
    public static func dots(now: Date = Date()) -> [DotState] {
        let y = calendar.component(.year, from: now)
        let total = dayCount(y)
        let today = dayOfYear(now: now)
        return (1...total).map { d in
            if d < today { return .past }
            if d == today { return .today }
            return .future
        }
    }

    /// 今天在圆点数组里的下标（0 开始）
    public static func todayIndex(now: Date = Date()) -> Int {
        dayOfYear(now: now) - 1
    }

    // MARK: - 文字

    /// "2026年" 这样的年份标题
    public static func yearLabel(now: Date = Date()) -> String {
        "\(calendar.component(.year, from: now))"
    }

    /// "290/365 天"
    public static func dayCounterLabel(now: Date = Date()) -> String {
        let y = calendar.component(.year, from: now)
        return "\(dayOfYear(now: now))/\(dayCount(y)) 天"
    }

    /// "今年还剩 75 天 14 小时"
    public static func remainingLabel(now: Date = Date()) -> String {
        "今年还剩 \(daysRemaining(now: now)) 天 \(hoursRemainingToday(now: now)) 小时"
    }

    /// 百分比文字，如 "79.3%"
    public static func percent(_ v: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f%%", v * 100)
    }
}
