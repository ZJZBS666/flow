import SwiftUI
import UIKit

/// 一年 365 颗圆点的网格。
///
/// 性能上有两个关键处理，都是为了「深色/浅色切换时不卡」：
///
/// 1. **排布按年缓存**。365 颗点的 (列, 行) 只跟「哪一年 + 几列 + 几个月一行」有关，
///    跟今天几号无关。所以缓存的 `Cell` 里只存「这是今年的第几天」，颜色在绘制时
///    拿它跟今天比一下就有了。也就是说这套排布一年才算一次，不是每秒算一次。
///    （原来每次重绘都跑 12 个月 × 每月日数/首日星期/年内偏移，切外观时正好赶上
///    整棵树重建，那几十毫秒就表现成卡顿。）
///
/// 2. **按颜色合并成 3 条 Path**。365 次 `context.fill` 变成 3 次 fill，
///    每次处理一批椭圆。绘制调用少了两个数量级。
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
            let cells = Self.cachedCells(
                layout: layout,
                year: FlowMath.calendar.component(.year, from: now),
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
            let radius = diameter / 2
            let pastColor = colorPastDots ? accent : Color.primary.opacity(0.92)
            let futureColor = Color.primary.opacity(0.13)
            let todayIdx = FlowMath.todayIndex(now: now)

            // 三条 Path 分别收「已过 / 今天 / 未到」，最后各 fill 一次
            var pastPath = Path()
            var todayPath = Path()
            var futurePath = Path()

            for dot in cells.dots {
                let cx = originX + (CGFloat(dot.col) + 0.5) * unit
                let cy = originY + (CGFloat(dot.row) + 0.5) * unit
                let rect = CGRect(x: cx - radius, y: cy - radius,
                                  width: diameter, height: diameter)

                if dot.day < todayIdx {
                    pastPath.addEllipse(in: rect)
                } else if dot.day == todayIdx {
                    todayPath.addEllipse(in: rect)
                } else {
                    futurePath.addEllipse(in: rect)
                }
            }

            context.fill(pastPath, with: .color(pastColor))
            context.fill(futurePath, with: .color(futureColor))
            context.fill(todayPath, with: .color(accent))
        }
        .accessibilityLabel("\(FlowMath.dayCounterLabel(now: now))，今年进度 \(FlowMath.percent(FlowMath.yearProgress(now: now)))")
    }

    // MARK: - 排布计算（按年缓存）

    /// 一颗点：在网格里的位置 + 它是今年的第几天（0 起算）。不含颜色。
    struct Cell {
        let col: Int
        let row: Int
        let day: Int
    }

    struct Cells {
        var dots: [Cell]
        var unitColumns: Int
        var unitRows: Int
    }

    /// 缓存。键 = 排列方式 + 年份 + 列数 + 每行月数。
    /// 正常情况下只有 1~2 条（App 一条、小组件的几种尺寸各一条）。
    private static var cellsCache: [String: Cells] = [:]
    private static var cellsCacheKeys: [String] = []
    private static let cellsCacheLimit = 8

    static func cachedCells(layout: GridLayout,
                            year: Int,
                            sequentialColumns: Int,
                            monthsPerRow: Int) -> Cells {
        let key = "\(layout.rawValue)-\(year)-\(sequentialColumns)-\(monthsPerRow)"
        if let hit = cellsCache[key] { return hit }

        let made = layoutCells(layout: layout,
                              year: year,
                              sequentialColumns: sequentialColumns,
                              monthsPerRow: monthsPerRow)

        // 简单 FIFO，超过上限先丢最老的
        if cellsCacheKeys.count >= cellsCacheLimit, let oldest = cellsCacheKeys.first {
            cellsCache.removeValue(forKey: oldest)
            cellsCacheKeys.removeFirst()
        }
        cellsCache[key] = made
        cellsCacheKeys.append(key)
        return made
    }

    static func layoutCells(layout: GridLayout,
                            year: Int,
                            sequentialColumns: Int,
                            monthsPerRow: Int) -> Cells {

        let calendar = FlowMath.calendar
        let total = FlowMath.dayCount(year)

        switch layout {

        case .sequential:
            let cols = max(1, sequentialColumns)
            var dots: [Cell] = []
            dots.reserveCapacity(total)
            for i in 0..<total {
                dots.append(Cell(col: i % cols, row: i / cols, day: i))
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

            var dots: [Cell] = []
            dots.reserveCapacity(total)

            let jan1 = FlowMath.yearStart(year)

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

                let startDayIndex = calendar.dateComponents([.day], from: jan1, to: firstOfMonth).day ?? 0

                for d in 0..<daysInMonth {
                    let slot = mondayIndex + d
                    let col = originCol + slot % 7
                    let row = originRow + slot / 7
                    dots.append(Cell(col: col, row: row, day: startDayIndex + d))
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

    /// 卡片内侧留白。圆角 = 卡片圆角 - 内边距，这样弧线同心。
    private let inset: CGFloat = 16

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
        .padding(.horizontal, inset)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: FlowRadius.card, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
