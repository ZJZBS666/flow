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
        TimelineView(.everyMinute) { timeline in
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
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FLOW")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(verbatim: FlowMath.yearLabel(now: now))
                                .font(.system(size: 12).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("设置")
                    }
                    .padding(.top, 12)

                    YearOverview(
                        progress: year,
                        accent: accent,
                        now: now,
                        showsRing: store.showRing
                    )
                    .padding(.top, 24)

                    if store.showRows {
                        ProgressRowsCard(rows: rows, accent: accent)
                            .padding(.top, 20)
                    }

                    if store.showGrid {
                        DotCard(
                            layout: store.gridLayout,
                            accent: accent,
                            colorPastDots: store.colorPastDots,
                            now: now,
                            height: 188,
                            columns: 24,
                            monthsPerRow: 4
                        )
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct YearOverview: View {
    let progress: Double
    let accent: Color
    let now: Date
    let showsRing: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if showsRing {
                    RingProgress(progress: progress, accent: accent, lineWidth: 12)
                }

                VStack(spacing: 2) {
                    Text(verbatim: FlowMath.percent(progress))
                        .font(.system(size: showsRing ? 31 : 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    if showsRing {
                        Text("今年")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text("年度进度")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(FlowMath.remainingLabel(now: now))
                    .font(.system(size: 17, weight: .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(FlowMath.dayCounterLabel(now: now))
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FlowRadius.card, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProgressRowsCard: View {
    let rows: [ProgressItem]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间尺度")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    ProgressRow(label: row.label, progress: row.value, accent: accent)
                        .frame(height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: FlowRadius.card, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

#Preview {
    RootView().environmentObject(FlowStore.shared)
}
