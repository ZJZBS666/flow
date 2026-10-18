import SwiftUI
import UIKit

/// 一行进度的数据
private struct ProgressItem: Identifiable {
    let id: String
    let label: String
    let value: Double
}

struct RootView: View {
    @EnvironmentObject private var store: FlowStore
    @State private var showSettings = false

    var body: some View {
        // 每分钟整点刷新一次。
        //
        // 原来是一秒一次。但界面上最小的时间刻度是「今天」那行的整数百分比
        // —— 一天 1440 分钟，1% 就是 14.4 分钟；大圆环的弧长一秒只挪 0.0000032 圈，
        // 肉眼完全看不见。也就是说每秒重算一次纯属白烧，
        // 而切深色/浅色那一下正好可能撞上一次重算。改成每分钟既能省掉 60 倍的开销，
        // 显示上又没有任何区别。
        TimelineView(.everyMinute) { timeline in
            content(now: timeline.date)
        }
        .sheet(isPresented: $showSettings) {
            // 外观不用 preferredColorScheme：那是「瞬间切换」的。
            // 现在由 AppearanceTransition 改整个窗口的 overrideUserInterfaceStyle，
            // 设置页也在这个窗口里，所以会跟着一起平滑过渡。
            SettingsView()
                .environmentObject(store)
        }
    }

    private func content(now: Date) -> some View {
        let accent = store.accentColor
        let year = FlowMath.yearProgress(now: now)
        let rows: [ProgressItem] = [
            ProgressItem(id: "year", label: "今年", value: year),
            ProgressItem(id: "month", label: "本月", value: FlowMath.monthProgress(now: now)),
            ProgressItem(id: "week", label: "本周", value: FlowMath.weekProgress(now: now)),
            ProgressItem(id: "day", label: "今天", value: FlowMath.dayProgress(now: now))
        ]

        return ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // 顶栏
                    HStack {
                        Text("FLOW")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(3.4)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 19))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("设置")
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 8)

                    Spacer(minLength: 28)

                    // 大圆环
                    if store.showRing {
                        ZStack {
                            RingProgress(progress: year, accent: accent, lineWidth: 15)
                            VStack(spacing: 2) {
                                Text(FlowMath.percent(year))
                                    .font(.system(size: 50, weight: .bold).monospacedDigit())
                                    .minimumScaleFactor(0.6)
                                    .lineLimit(1)
                                Text("\(FlowMath.yearLabel(now: now))年")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 40)
                        }
                        .frame(width: 191, height: 191)
                        .padding(.bottom, 24)
                    } else {
                        Text(FlowMath.percent(year))
                            .font(.system(size: 74, weight: .bold).monospacedDigit())
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .padding(.bottom, 6)
                    }

                    // 剩余天数
                    Text(FlowMath.remainingLabel(now: now))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 30)

                    // 四条进度
                    if store.showRows {
                        VStack(spacing: 0) {
                            ForEach(rows) { row in
                                ProgressRow(label: row.label, progress: row.value, accent: accent)
                                    .frame(height: 36)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 32)
                    }

                    // 圆点卡片
                    if store.showGrid {
                        DotCard(layout: store.gridLayout,
                                accent: accent,
                                colorPastDots: store.colorPastDots,
                                now: now,
                                height: 188,
                                columns: 24,
                                monthsPerRow: 4)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    RootView().environmentObject(FlowStore.shared)
}
