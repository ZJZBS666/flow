import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: FlowStore
    @Environment(\.dismiss) private var dismiss

    private let palette: [String] = [
        "#FC8E03", "#FF5C8A", "#FF3B30", "#FFC53D",
        "#34D399", "#38BDF8", "#A78BFA", "#8E8E93"
    ]

    private static var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SettingsGroup("外观") {
                            Picker("外观", selection: $store.appearance) {
                                ForEach(Appearance.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .accessibilityLabel("外观")
                        }

                        SettingsGroup("主题颜色") {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                                spacing: 16
                            ) {
                                ForEach(palette, id: \.self) { hex in
                                    Button {
                                        store.accentHex = hex
                                    } label: {
                                        ColorSwatch(
                                            color: Color(hex: hex) ?? .orange,
                                            selected: store.accentHex.caseInsensitiveCompare(hex) == .orderedSame
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity)
                                    .accessibilityLabel("主题色 \(hex)")
                                }
                            }
                        }

                        SettingsGroup("圆点着色") {
                            Picker("圆点着色", selection: $store.colorPastDots) {
                                Text("仅今天").tag(false)
                                Text("已过去的全部").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .accessibilityLabel("圆点着色")
                        }

                        SettingsGroup("网格排列") {
                            HStack(spacing: 12) {
                                ForEach(GridLayout.allCases) { layout in
                                    Button {
                                        store.gridLayout = layout
                                    } label: {
                                        LayoutCard(
                                            layout: layout,
                                            selected: store.gridLayout == layout,
                                            accent: store.accentColor,
                                            colorPastDots: store.colorPastDots
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(layout.title)
                                    .accessibilityAddTraits(store.gridLayout == layout ? .isSelected : [])
                                }
                            }
                        }

                        SettingsGroup("显示内容") {
                            VStack(spacing: 0) {
                                SettingsToggleRow(title: "圆环总览", isOn: $store.showRing)
                                Divider()
                                SettingsToggleRow(title: "年 / 月 / 周 / 日", isOn: $store.showRows)
                                Divider()
                                SettingsToggleRow(title: "圆点网格", isOn: $store.showGrid)
                            }
                        }

                        SettingsGroup("项目") {
                            Link(destination: URL(string: "https://github.com/ZJZBS666/flow")!) {
                                HStack(spacing: 12) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("ZJZBS666")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Text("github.com/ZJZBS666/flow")
                                            .font(.system(size: 12).monospaced())
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer(minLength: 0)

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        Text("Flow v\(Self.versionString)")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
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

private struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: FlowRadius.card, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
}

private struct ColorSwatch: View {
    let color: Color
    let selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)

            if selected {
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
        }
        .frame(width: 40, height: 40)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .frame(minHeight: 44)
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
            DotGrid(
                layout: layout,
                accent: accent,
                colorPastDots: colorPastDots,
                sequentialColumns: 24,
                monthsPerRow: 6
            )
            .frame(height: 56)
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Spacer(minLength: 8)

            Text(layout.title)
                .font(.system(size: 13, weight: .medium))
            Text(layout.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .background(
            RoundedRectangle(cornerRadius: FlowRadius.tile, style: .continuous)
                .fill(selected ? accent.opacity(0.08) : Color(.tertiarySystemGroupedBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: FlowRadius.tile, style: .continuous)
                .strokeBorder(selected ? accent : Color.primary.opacity(0.08), lineWidth: selected ? 1.5 : 1)
        }
        .contentShape(
            RoundedRectangle(cornerRadius: FlowRadius.tile, style: .continuous)
        )
    }
}

#Preview {
    SettingsView().environmentObject(FlowStore.shared)
}
