package com.zjzbs.flow.domain

import java.time.DayOfWeek
import java.time.Duration
import java.time.LocalDate
import java.time.ZonedDateTime
import java.time.temporal.TemporalAdjusters
import java.util.Locale

/**
 * 时间进度计算。App 与桌面小组件都从这里取数，保证两边永远一致。
 *
 * 全部基于 java.time（minSdk 26 起可用），并且始终用「带时区的时刻」算，
 * 这样夏令时、跨时区都不会把进度算歪。
 */
object FlowMath {

    // ---------- 基础 ----------

    fun now(): ZonedDateTime = ZonedDateTime.now()

    /** 某一年的 1 月 1 日 0 点 */
    fun yearStart(year: Int): ZonedDateTime =
        LocalDate.of(year, 1, 1).atStartOfDay(now().zone)

    /** 某一年的最后一天 0 点 */
    fun yearEnd(year: Int): ZonedDateTime =
        LocalDate.of(year, 12, 31).atStartOfDay(now().zone)

    /** 这一年一共有多少天（365 或 366） */
    fun dayCount(year: Int): Int = LocalDate.of(year, 1, 1).lengthOfYear()

    // ---------- 年进度 ----------

    /** 今年已经过去的比例 0...1，精确到秒 */
    fun yearProgress(now: ZonedDateTime = now()): Double {
        val start = yearStart(now.year)
        val end = LocalDate.of(now.year + 1, 1, 1).atStartOfDay(now.zone)
        val total = Duration.between(start, end).seconds.toDouble()
        if (total <= 0.0) return 0.0
        return (Duration.between(start, now).seconds / total).coerceIn(0.0, 1.0)
    }

    // ---------- 月 / 周 / 日 ----------

    fun monthProgress(now: ZonedDateTime = now()): Double {
        val start = now.toLocalDate().withDayOfMonth(1).atStartOfDay(now.zone)
        val end = start.plusMonths(1)
        return fraction(start, end, now)
    }

    /** 一周从周一开始，和 iOS 版一致 */
    fun weekProgress(now: ZonedDateTime = now()): Double {
        val monday = now.toLocalDate()
            .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val start = monday.atStartOfDay(now.zone)
        val end = start.plusWeeks(1)
        return fraction(start, end, now)
    }

    fun dayProgress(now: ZonedDateTime = now()): Double {
        val start = now.toLocalDate().atStartOfDay(now.zone)
        val end = start.plusDays(1)
        return fraction(start, end, now)
    }

    private fun fraction(start: ZonedDateTime, end: ZonedDateTime, now: ZonedDateTime): Double {
        val total = Duration.between(start, end).seconds.toDouble()
        if (total <= 0.0) return 0.0
        return (Duration.between(start, now).seconds / total).coerceIn(0.0, 1.0)
    }

    // ---------- 天数 ----------

    /** 今天是今年的第几天，从 1 开始 */
    fun dayOfYear(now: ZonedDateTime = now()): Int = now.dayOfYear

    /** 今年还剩多少天（不含今天） */
    fun daysRemaining(now: ZonedDateTime = now()): Int =
        dayCount(now.year) - dayOfYear(now)

    /** 今天还剩多少小时，0...23 */
    fun hoursRemainingToday(now: ZonedDateTime = now()): Int =
        (23 - now.hour).coerceAtLeast(0)

    /** 今天在圆点数组里的下标（0 开始） */
    fun todayIndex(now: ZonedDateTime = now()): Int = dayOfYear(now) - 1

    // ---------- 文字 ----------

    fun yearLabel(now: ZonedDateTime = now()): String = now.year.toString()

    /** "290/365 天" */
    fun dayCounterLabel(now: ZonedDateTime = now()): String =
        "${dayOfYear(now)}/${dayCount(now.year)} 天"

    /** "今年还剩 75 天 14 小时" */
    fun remainingLabel(now: ZonedDateTime = now()): String =
        "今年还剩 ${daysRemaining(now)} 天 ${hoursRemainingToday(now)} 小时"

    /** 百分比文字，如 "79.3%" */
    fun percent(v: Double, decimals: Int = 1): String =
        String.format(Locale.US, "%.${decimals}f%%", v * 100)
}
