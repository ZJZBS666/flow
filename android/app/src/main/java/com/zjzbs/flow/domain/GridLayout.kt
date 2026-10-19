package com.zjzbs.flow.domain

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** 365 颗圆点的两种排布方式 */
enum class GridLayout(val key: String, val title: String, val subtitle: String) {
    Sequential("sequential", "顺序排列", "从 1 月 1 日铺满"),
    Calendar("calendar", "日历排列", "12 个月块");

    companion object {
        fun fromKey(k: String?): GridLayout =
            entries.firstOrNull { it.key == k } ?: Sequential
    }
}

/** 一颗点：在网格里的位置 + 它是今年的第几天（0 起算）。不含颜色。 */
data class DotCell(val col: Int, val row: Int, val day: Int)

data class GridCells(
    val dots: List<DotCell>,
    val unitColumns: Int,
    val unitRows: Int,
)

/**
 * 圆点排布计算。
 *
 * 排布只跟「哪一年 + 几列 + 几月一行」有关，跟今天几号无关，所以结果按年缓存：
 * 一年只算一次，不是每帧算一次。颜色在绘制时拿 day 跟今天比一下即可。
 */
object DotGridLayout {

    /** 点直径占格子边长的比例。参考图实测 0.39，这是它显得疏松有质感的关键。 */
    const val DOT_SCALE = 0.39f

    private const val CACHE_LIMIT = 8
    private val cache = object : LinkedHashMap<String, GridCells>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, GridCells>?) =
            size > CACHE_LIMIT
    }

    @Synchronized
    fun cells(
        layout: GridLayout,
        year: Int,
        sequentialColumns: Int,
        monthsPerRow: Int,
    ): GridCells {
        val key = "${layout.key}-$year-$sequentialColumns-$monthsPerRow"
        cache[key]?.let { return it }
        val made = build(layout, year, sequentialColumns, monthsPerRow)
        cache[key] = made
        return made
    }

    private fun build(
        layout: GridLayout,
        year: Int,
        sequentialColumns: Int,
        monthsPerRow: Int,
    ): GridCells {
        val total = FlowMath.dayCount(year)
        return when (layout) {
            GridLayout.Sequential -> {
                val cols = sequentialColumns.coerceAtLeast(1)
                val dots = ArrayList<DotCell>(total)
                for (i in 0 until total) {
                    dots.add(DotCell(col = i % cols, row = i / cols, day = i))
                }
                val rows = (total + cols - 1) / cols
                GridCells(dots, cols, rows)
            }

            GridLayout.Calendar -> {
                // 12 个月块，每块 7 列（周一至周日）× 最多 6 行
                val blockCols = 7
                val blockRows = 6
                val gapUnits = 2
                val perRow = monthsPerRow.coerceAtLeast(1)
                val blockRowsCount = (12 + perRow - 1) / perRow

                val dots = ArrayList<DotCell>(total)
                val jan1 = LocalDate.of(year, 1, 1)

                for (month in 1..12) {
                    val blockIndex = month - 1
                    val blockCol = blockIndex % perRow
                    val blockRow = blockIndex / perRow

                    val originCol = blockCol * (blockCols + gapUnits)
                    val originRow = blockRow * (blockRows + gapUnits)

                    val firstOfMonth = LocalDate.of(year, month, 1)
                    val daysInMonth = firstOfMonth.lengthOfMonth()

                    // DayOfWeek: 周一 = 1 ... 周日 = 7，减 1 得到「周一 = 0」
                    val mondayIndex = firstOfMonth.dayOfWeek.value - 1

                    val startDayIndex =
                        ChronoUnit.DAYS.between(jan1, firstOfMonth).toInt()

                    for (d in 0 until daysInMonth) {
                        val slot = mondayIndex + d
                        dots.add(
                            DotCell(
                                col = originCol + slot % 7,
                                row = originRow + slot / 7,
                                day = startDayIndex + d,
                            )
                        )
                    }
                }

                val unitCols = perRow * (blockCols + gapUnits) - gapUnits
                val unitRows = blockRowsCount * (blockRows + gapUnits) - gapUnits
                GridCells(dots, unitCols, unitRows)
            }
        }
    }
}
