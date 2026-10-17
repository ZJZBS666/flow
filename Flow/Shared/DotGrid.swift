import SwiftUI
import UIKit

/// 一年 365 颗圆点的网格。
/// 用 Canvas 绘制，365 个圆一次画完，性能没有压力。
public struct DotGrid: View {

    public let layout: GridLayout
    public let accent: Color
    public let colorPastDots: Bool
    public let now: Date

    /// 顺序排列时一行放几颗点
    public let sequentialColumns: Int

    /// 日历排列时一行放几个月
    public let monthsPerRow: Int

    /// 点直径占格子边长的比例。参考图实测为 0.39，这是它显得疏松有质感的关键。
    public var dotScale: CGFloat = 0.39

    public init(layout: GridLayout,
                accent: Color,
                colorPastDots: Bool,
                now: Date = Date(),
                sequentialColumns: Int = 24,
                monthsPerRow: Int = 4) {
        self.layout = layout
        self.accent = accent
        self.colorPastDots = colorPastDots
        self.now = now
        self.sequentialColumns = sequentialColumns
        self.monthsPerRow = monthsPerRow
    }

    public var body: some View {
        Canvas { context, size in
            let cells = Self.layoutCells(
                layout: layout,
                now: now,
                sequentialColumns: sequentialColumns,
                monthsPerRow: monthsPerRow
            )
            guard cells.unitColumns > 0, cells.unitRows > 0 else { return }

            let unit = min(size.width / CGFloat(cells.unitColumns),
                           size.height / CGFloat(cells.unitRows))
            guard unit > 0 else { return }

            let gridW = unit * CGFloat(cells.unitColumns)
            let gridH = unit * CGFloat(cells.unitRows)
            let originX = (size.width - gridW) / 2
            let originY = (size.height - gridH) / 2

            let diameter = max(0.8, unit * dotScale)
            let pastColor = colorPastDots ? accent : Color.primary.opacity(0.92)
            let futureColor = Color.primary.opacity(0.13)

            for dot in cells.dots {
                let cx = originX + (CGFloat(dot.col) + 0.5) * unit
                let cy = originY + (CGFloat(dot.row) + 0.5) * unit
                let rect = CGRect(x: cx - diameter / 2,
                                  y: cy - diameter / 2,
                                  width: diameter,
                                  height: diameter)
                let color: Color
                switch dot.state {
                case .past:   color = pastColor
                case .today:  color = accent
                case .future: color = futureColor
                }
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
        .accessibilityLabel("\(FlowMath.dayCounterLabel(now: now))，今年进度 \(FlowMath.percent(FlowMath.yearProgress(now: now)))")
    }

    // MARK: - 排布计算

    struct Dot {
        let col: Int
        let row: Int
        let state: FlowMath.DotState
    }

    struct Cells {
        var dots: [Dot]
        var unitColumns: Int
        var unitRows: Int
    }

    static func layoutCells(layout: GridLayout,
                            now: Date,
                            sequentialColumns: Int,
                            monthsPerRow: Int) -> Cells {

        let calendar = FlowMath.calendar
        let year = calendar.component(.year, from: now)
        let total = FlowMath.dayCount(year)
        let todayIdx = FlowMath.todayIndex(now: now)

        func state(_ i: Int) -> FlowMath.DotState {
            if i < todayIdx { return .past }
            if i == todayIdx { return .today }
            return .future
        }

        switch layout {

        case .sequential:
            let cols = max(1, sequentialColumns)
            var dots: [Dot] = []
            dots.reserveCapacity(total)
            for i in 0..<total {
                dots.append(Dot(col: i % cols, row: i / cols, state: state(i)))
            }
            let rows = (total + cols - 1) / cols
            return Cells(dots: dots, unitColumns: cols, unitRows: rows)

        case .calendar:
            // 12 个月块，每块 7 列（周一至周日）x 最多 6 行
            let blockCols = 7
            let blockRows = 6
            let gapUnits = 2          // 月份块之间空 2 个格子的距离
            let perRow = max(1, monthsPerRow)
            let blockRowsCount = (12 + perRow - 1) / perRow

            var dots: [Dot] = []
            dots.reserveCapacity(total)

            for month in 1...12 {
                let blockIndex = month - 1
                let blockCol = blockIndex % perRow
                let blockRow = blockIndex / perRow

                let originCol = blockCol * (blockCols + gapUnits)
                let originRow = blockRow * (blockRows + gapUnits)

                guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                      let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
                else { continue }

                let daysInMonth = range.count
                // Calendar.component(.weekday): 1 = 周日 ... 7 = 周六
                // 转成「周一 = 0」
                let weekday = calendar.component(.weekday, from: firstOfMonth)
                let mondayIndex = (weekday + 5) % 7

                let startDayIndex = calendar.dateComponents([.day], from: FlowMath.yearStart(year), to: firstOfMonth).day ?? 0

                for d in 0..<daysInMonth {
                    let slot = mondayIndex + d
                    let col = originCol + slot % 7
                    let row = originRow + slot / 7
                    dots.append(Dot(col: col, row: row, state: state(startDayIndex + d)))
                }
            }

            // 用整数运算，避免编译器在长表达式上超时
            let unitCols = perRow * (blockCols + gapUnits) - gapUnits
            let unitRows = blockRowsCount * (blockRows + gapUnits) - gapUnits
            return Cells(dots: dots, unitColumns: unitCols, unitRows: unitRows)
        }
    }
}

// MARK: - 带表头的圆点卡片（App 里用）

public struct DotCard: View {
    let layout: GridLayout
    let accent: Color
    let colorPastDots: Bool
    let now: Date
    let height: CGFloat
    var columns: Int = 24
    var monthsPerRow: Int = 4

    public init(layout: GridLayout, accent: Color, colorPastDots: Bool,
                now: Date = Date(), height: CGFloat, columns: Int = 24, monthsPerRow: Int = 4) {
        self.layout = layout
        self.accent = accent
        self.colorPastDots = colorPastDots
        self.now = now
        self.height = height
        self.columns = columns
        self.monthsPerRow = monthsPerRow
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(FlowMath.yearLabel(now: now))
                Spacer()
                Text(FlowMath.dayCounterLabel(now: now))
            }
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)

            DotGrid(layout: layout,
                    accent: accent,
                    colorPastDots: colorPastDots,
                    now: now,
                    sequentialColumns: columns,
                    monthsPerRow: monthsPerRow)
                .frame(height: height)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
