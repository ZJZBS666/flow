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
        // 每秒刷新一次，秒数变化时圆环和百分比会平滑推进
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            content(now: timeline.date)
        }
        .sheet(isPresented: $showSettings) {
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
