import WidgetKit
import SwiftUI
import UIKit

/// 小组件数据源。因为进度是按时间连续变化的，用 .after 让它每 15 分钟自己刷新一次。
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
        let now = Date()
        // 每 15 分钟刷新一次，iOS 允许的最快频率量级
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [FlowEntry(date: now)], policy: .after(next)))
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
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}
