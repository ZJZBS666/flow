import WidgetKit
import SwiftUI
import UIKit

/// 小组件数据源。
///
/// 关键点：圆点网格一天只变一次（跨过 0 点，"今天"那个橙点才往前挪一格），
/// 所以不需要频繁刷新 —— 只要把下一次刷新定在明天 0 点后一点点就行。
/// 这比"每 15 分钟刷一次"更准，也更省电（iOS 本来就常把高频刷新往后推）。
struct FlowEntry: TimelineEntry {
    let date: Date
}

struct FlowProvider: TimelineProvider {

    func placeholder(in context: Context) -> FlowEntry {
        FlowEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (FlowEntry) -> Void) {
        completion(FlowEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlowEntry>) -> Void) {
        let calendar = FlowMath.calendar
        let now = Date()

        // 明天 0 点
        let startOfToday = calendar.startOfDay(for: now)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)

        // 再往后加 1 分钟，确保刷新时日期已经翻过去了
        let refreshAt = nextMidnight.addingTimeInterval(60)

        // 顺便给几个整点各生成一条，万一系统延后刷新，界面上也不会差一天
        var entries: [FlowEntry] = [FlowEntry(date: now)]
        for hour in 1...6 {
            if let t = calendar.date(byAdding: .hour, value: hour * 4, to: now), t < nextMidnight {
                entries.append(FlowEntry(date: t))
            }
        }

        completion(Timeline(entries: entries, policy: .after(refreshAt)))
    }
}

// MARK: - 锁屏专用的三个尺寸

/// 锁屏圆形：一个环 + 百分比。
///
/// 这里**故意不放圆点网格**：锁屏圆形大概只有 50pt 宽，365 个点塞进去就是一团灰，
/// 和当初 App 图标犯的错是同一个。宁可只给一个数字。
private struct AccessoryCircularView: View {
    let now: Date
    let accent: Color

    private var progress: Double { FlowMath.yearProgress(now: now) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.20), lineWidth: 5)

            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .widgetAccentable()
        }
        .padding(3)
    }
}

/// 锁屏长方形：标题 + 一条细进度 + 剩余天数。
private struct AccessoryRectangularView: View {
    let now: Date
    let accent: Color

    private var progress: Double { FlowMath.yearProgress(now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(FlowMath.yearLabel(now: now))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(FlowMath.percent(progress))
                    .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                    .widgetAccentable()
                Spacer(minLength: 0)
            }

            // 细进度条：锁屏上主色会被系统压成单色，所以这里只用主色 + 半透明底
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.20))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(3, geo.size.width * min(1, max(0, progress))))
                        .widgetAccentable()
                }
            }
            .frame(height: 4)

            Text("还剩 \(FlowMath.daysRemaining(now: now)) 天")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }
}

/// 锁屏单行：时间旁边的一行字。
private struct AccessoryInlineView: View {
    let now: Date

    var body: some View {
        Text("今年 \(FlowMath.percent(FlowMath.yearProgress(now: now)))　还剩 \(FlowMath.daysRemaining(now: now)) 天")
    }
}

// MARK: - 入口视图

struct FlowWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: FlowEntry

    private var store: FlowStore { FlowStore.shared }

    /// 锁屏三种尺寸
    private var isAccessory: Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            return true
        default:
            return false
        }
    }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if family == .accessoryCircular {
                    // 圆形那个有底色圆盘，用系统的半透明材质才和锁屏一致
                    AccessoryWidgetBackground()
                } else if isAccessory {
                    Color.clear
                } else {
                    Color(.secondarySystemGroupedBackground)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {

        // ---------------- 锁屏 ----------------
        case .accessoryCircular:
            AccessoryCircularView(now: entry.date, accent: store.accentColor)

        case .accessoryRectangular:
            AccessoryRectangularView(now: entry.date, accent: store.accentColor)

        case .accessoryInline:
            AccessoryInlineView(now: entry.date)

        // ---------------- 桌面 ----------------
        case .systemSmall:
            DotGrid(layout: store.gridLayout,
                    accent: store.accentColor,
                    colorPastDots: store.colorPastDots,
                    now: entry.date,
                    sequentialColumns: 20,
                    monthsPerRow: 4)
                .padding(14)

        case .systemMedium:
            // 中号是横长条，列数要多一些才铺得开
            VStack(spacing: 10) {
                HStack {
                    Text(FlowMath.yearLabel(now: entry.date))
                    Spacer()
                    Text(FlowMath.dayCounterLabel(now: entry.date))
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                DotGrid(layout: store.gridLayout,
                        accent: store.accentColor,
                        colorPastDots: store.colorPastDots,
                        now: entry.date,
                        sequentialColumns: 30,
                        monthsPerRow: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

        default:   // .systemLarge 以及其它尺寸都走这个
            VStack(spacing: 14) {
                HStack {
                    Text(FlowMath.yearLabel(now: entry.date))
                    Spacer()
                    Text(FlowMath.dayCounterLabel(now: entry.date))
                }
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)

                DotGrid(layout: store.gridLayout,
                        accent: store.accentColor,
                        colorPastDots: store.colorPastDots,
                        now: entry.date,
                        sequentialColumns: 20,
                        monthsPerRow: 4)
            }
            .padding(18)
        }
    }
}

@main
struct FlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FlowWidget()
        FlowCalendarWidget()
    }
}

struct FlowWidget: Widget {
    let kind = "FlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowProvider()) { entry in
            FlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flow")
        .description("用圆点看这一年过去了多少。支持桌面与锁屏。")
        .supportedFamilies([
            // 桌面
            .systemSmall, .systemMedium, .systemLarge,
            // 锁屏
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Flow 日历（第二种锁屏组件）

/// 三周滚动窗口：上周 / 这周 / 下周，过一周就往前滚一周。
///
/// 和 `FlowMath.calendar` 不同：这里**周日排第一列**（日一二三四五六），
/// 跟 iPhone 自带日历锁屏组件一致。`FlowMath.calendar` 是周一开头，
/// 那是给「年度日历排列」用的，两处需求不一样，别混。
private struct ThreeWeekGrid {
    struct Cell {
        let day: Int
        /// 是否属于当前月份。跨月的日子照常显示，只是淡化，不然月初/月末那行会空一片。
        let inMonth: Bool
    }

    let headers = ["日", "一", "二", "三", "四", "五", "六"]
    let rows: [[Cell]]
    let today: Int
    let year: Int
    let month: Int

    init(now: Date) {
        let cal = FlowMath.calendar
        let startOfToday = cal.startOfDay(for: now)
        // Calendar.component(.weekday) 不受 firstWeekday 影响：1 = 周日 … 7 = 周六
        let weekday = cal.component(.weekday, from: now)
        let thisWeekSunday = cal.date(byAdding: .day, value: -(weekday - 1), to: startOfToday) ?? startOfToday
        let thisMonth = cal.component(.month, from: now)

        var built: [[Cell]] = []
        for weekOffset in -1...1 {
            let weekStart = cal.date(byAdding: .day, value: weekOffset * 7, to: thisWeekSunday) ?? thisWeekSunday
            var row: [Cell] = []
            for dayOffset in 0..<7 {
                let date = cal.date(byAdding: .day, value: dayOffset, to: weekStart) ?? weekStart
                let day = cal.component(.day, from: date)
                let monthOfDay = cal.component(.month, from: date)
                row.append(Cell(day: day, inMonth: monthOfDay == thisMonth))
            }
            built.append(row)
        }

        rows = built
        today = cal.component(.day, from: now)
        year = cal.component(.year, from: now)
        month = thisMonth
    }
}

/// 锁屏长方形 · 日历版：左上角年份，左下月份 + 大号日号，右边只铺上周/这周/下周。
private struct AccessoryCalendarRectangularView: View {
    let now: Date
    let accent: Color

    var body: some View {
        let g = ThreeWeekGrid(now: now)

        HStack(alignment: .top, spacing: 9) {
            // 左边：年份在最上面，月份紧贴日号上方，日号靠 Spacer 压到下面
            VStack(alignment: .leading, spacing: 0) {
                Text("\(g.year)")
                    .font(.system(size: 7).monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer(minLength: 1)

                Text("\(g.month)月")
                    .font(.system(size: 7).monospacedDigit())
                    .foregroundStyle(.secondary)

                Text("\(g.today)")
                    .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .widgetAccentable()
            }
            .frame(width: 32, alignment: .leading)

            // 右边：三周，今天用实心圆盖住、数字反白为黑
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(g.headers, id: \.self) { h in
                        Text(h)
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 11)

                ForEach(g.rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { colIndex in
                            let cell = g.rows[rowIndex][colIndex]
                            let isToday = cell.inMonth && cell.day == g.today
                            ZStack {
                                if isToday {
                                    Circle()
                                        .fill(accent)
                                        .frame(width: 12, height: 12)
                                        .widgetAccentable()
                                }
                                Text("\(cell.day)")
                                    .font(.system(size: 8.5, weight: isToday ? .bold : .regular)
                                        .monospacedDigit())
                                    .foregroundStyle(isToday
                                                     ? Color.black
                                                     : (cell.inMonth ? Color.primary : Color.secondary.opacity(0.5)))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 13)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// 锁屏圆形 · 日历版：就一个大号日号。
private struct AccessoryCalendarCircularView: View {
    let now: Date

    var body: some View {
        let cal = FlowMath.calendar
        let day = cal.component(.day, from: now)
        let month = cal.component(.month, from: now)

        VStack(spacing: -1) {
            Text("\(day)")
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .widgetAccentable()
            Text("\(month)月")
                .font(.system(size: 7))
                .foregroundStyle(.secondary)
        }
    }
}

struct FlowCalendarEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: FlowEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if family == .accessoryCircular {
                    AccessoryWidgetBackground()
                } else if family == .accessoryRectangular {
                    Color.clear
                } else {
                    Color(.secondarySystemGroupedBackground)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            AccessoryCalendarRectangularView(now: entry.date, accent: FlowStore.shared.accentColor)
        case .accessoryCircular:
            AccessoryCalendarCircularView(now: entry.date)
        default:
            AccessoryCalendarRectangularView(now: entry.date, accent: FlowStore.shared.accentColor)
        }
    }
}

/// 第二种锁屏组件：日历样式。和上面的 Flow 并列出现在组件库里。
struct FlowCalendarWidget: Widget {
    let kind = "FlowCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowProvider()) { entry in
            FlowCalendarEntryView(entry: entry)
        }
        .configurationDisplayName("Flow 日历")
        .description("只显示上周、这周、下周三周，今天用底色标出。")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}
