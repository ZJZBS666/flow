import SwiftUI

/// 环形进度：底环 + 进度弧 + 两端圆头
public struct RingProgress: View {
    let progress: Double
    let accent: Color
    let lineWidth: CGFloat

    public init(progress: Double, accent: Color, lineWidth: CGFloat = 15) {
        self.progress = progress
        self.accent = accent
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(accent,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeInOut(duration: 0.35), value: progress)
    }
}

/// 一条横向进度：标签 + 条 + 百分比
public struct ProgressRow: View {
    let label: String
    let progress: Double
    let accent: Color
    let labelWidth: CGFloat

    public init(label: String, progress: Double, accent: Color, labelWidth: CGFloat = 44) {
        self.label = label
        self.progress = progress
        self.accent = accent
        self.labelWidth = labelWidth
    }

    public var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13.5))
                .frame(width: labelWidth, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(7.5, geo.size.width * min(1, max(0, progress))))
                }
                .frame(height: 7.5)
                .frame(maxHeight: .infinity, alignment: .center)
                .animation(.easeInOut(duration: 0.5), value: progress)
            }
            .frame(height: 20)

            Text(FlowMath.percent(progress, decimals: 0))
                .font(.system(size: 13.5).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .trailing)
        }
    }
}
