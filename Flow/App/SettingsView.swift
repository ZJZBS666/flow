import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: FlowStore
    @Environment(\.dismiss) private var dismiss

    /// 8 个主题色，和效果图一致
    private let palette: [String] = [
        "#FC8E03", "#FF5C8A", "#FF3B30", "#FFC53D",
        "#34D399", "#38BDF8", "#A78BFA", "#8E8E93"
    ]

    var body: some View {
        NavigationStack {
            List {

                // ---------- 外观 ----------
                Section("外观") {
                    Picker("外观", selection: $store.appearance) {
                        ForEach(Appearance.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // ---------- 主题颜色 ----------
                Section("主题颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8.5), count: 8),
                              spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                store.accentHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .orange)
                                    .frame(height: 33)
                                    .overlay {
                                        if store.accentHex.caseInsensitiveCompare(hex) == .orderedSame {
                                            Circle()
                                                .strokeBorder(Color.primary, lineWidth: 1.5)
                                                .padding(-4.5)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("主题色 \(hex)")
                        }
                    }
                    .padding(.vertical, 4)
                }

                // ---------- 圆点着色 ----------
                Section("圆点着色") {
                    Picker("圆点着色", selection: $store.colorPastDots) {
                        Text("仅今天").tag(false)
                        Text("已过去的全部").tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                // ---------- 网格排列 ----------
                Section("网格排列") {
                    HStack(spacing: 14) {
                        ForEach(GridLayout.allCases) { layout in
                            LayoutCard(layout: layout,
                                       selected: store.gridLayout == layout,
                                       accent: store.accentColor,
                                       colorPastDots: store.colorPastDots)
                                .onTapGesture { store.gridLayout = layout }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // ---------- 显示内容 ----------
                Section("显示内容") {
                    Toggle("圆环总览", isOn: $store.showRing)
                    Toggle("年 / 月 / 周 / 日", isOn: $store.showRows)
                    Toggle("圆点网格", isOn: $store.showGrid)
                }

                // ---------- 关于 ----------
                Section {
                    Link(destination: URL(string: "https://github.com/ZJZBS666/flow")!) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ZJZBS666")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.primary)
                                Text("github.com/ZJZBS666/flow")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("项目")
                } footer: {
                    Text("点击打开 GitHub 仓库")
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Flow 1.0.0")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

/// 设置页里那个小的排列预览卡片
private struct LayoutCard: View {
    let layout: GridLayout
    let selected: Bool
    let accent: Color
    let colorPastDots: Bool

    var body: some View {
        VStack(spacing: 0) {
            DotGrid(layout: layout,
                    accent: accent,
                    colorPastDots: colorPastDots,
                    sequentialColumns: 24,
                    monthsPerRow: 6)
                .frame(height: 58)
                .padding(.horizontal, 14)
                .padding(.top, 14)

            Spacer(minLength: 8)

            Text(layout.title)
                .font(.system(size: 12.5))
            Text(layout.subtitle)
                .font(.system(size: 9.5))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(selected ? accent : .clear, lineWidth: 2)
        }
    }
}

#Preview {
    SettingsView().environmentObject(FlowStore.shared)
}
