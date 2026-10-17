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

struct FlowWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: FlowEntry

    private var store: FlowStore { FlowStore.shared }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                Color(.secondarySystemGroupedBackground)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
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
    }
}

struct FlowWidget: Widget {
    let kind = "FlowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlowProvider()) { entry in
            FlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flow")
        .description("用圆点看这一年过去了多少。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
