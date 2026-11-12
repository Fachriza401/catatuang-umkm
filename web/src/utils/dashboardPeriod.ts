export type DashboardPeriod = 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'
export type DashboardChartUnit = 'hour' | 'day' | 'week' | 'month'

export interface DateRange {
  start: Date
  end: Date
}

export interface ChartBucket extends DateRange {
  label: string
}

export function getSummaryRange(period: DashboardPeriod, now: Date): DateRange {
  const today = startOfDay(now)

  switch (period) {
    case 'daily':
      return { start: today, end: addDays(today, 1) }
    case 'weekly': {
      const start = startOfWeek(today)
      return { start, end: addDays(start, 7) }
    }
    case 'monthly':
      return {
        start: new Date(now.getFullYear(), now.getMonth(), 1),
        end: new Date(now.getFullYear(), now.getMonth() + 1, 1),
      }
    case 'yearly':
      return {
        start: new Date(now.getFullYear(), 0, 1),
        end: new Date(now.getFullYear() + 1, 0, 1),
      }
    case 'custom':
      throw new RangeError('Rentang khusus memerlukan tanggal awal dan akhir.')
  }
}

export function getChartBuckets(period: DashboardPeriod, now: Date): ChartBucket[] {
  switch (period) {
    case 'daily':
      return Array.from({ length: 7 }, (_, index) => {
        const start = addDays(startOfDay(now), index - 6)
        return { start, end: addDays(start, 1), label: weekdayLabel(start) }
      })
    case 'weekly':
      return Array.from({ length: 6 }, (_, index) => {
        const start = addDays(startOfWeek(now), (index - 5) * 7)
        return { start, end: addDays(start, 7), label: shortDateLabel(start) }
      })
    case 'monthly':
      return Array.from({ length: 6 }, (_, index) => {
        const start = new Date(now.getFullYear(), now.getMonth() - 5 + index, 1)
        const end = new Date(start.getFullYear(), start.getMonth() + 1, 1)
        return { start, end, label: monthLabel(start) }
      })
    case 'yearly':
      return Array.from({ length: 12 }, (_, index) => {
        const start = new Date(now.getFullYear(), now.getMonth() - 11 + index, 1)
        const end = new Date(start.getFullYear(), start.getMonth() + 1, 1)
        return { start, end, label: monthLabel(start) }
      })
    case 'custom':
      throw new RangeError('Rentang khusus memerlukan tanggal awal dan akhir.')
  }
}

export function getChartBucketsForRange(start: Date, end: Date): ChartBucket[] {
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || start >= end) {
    throw new RangeError('Tanggal akhir harus setelah tanggal awal.')
  }

  const duration = end.getTime() - start.getTime()
  if (duration <= 24 * 60 * 60 * 1000) {
    return fixedBuckets(start, end, 60 * 60 * 1000, hourLabel)
  }

  const durationInDays = Math.floor(duration / (24 * 60 * 60 * 1000))
  if (durationInDays <= 45) {
    return fixedBuckets(start, end, 24 * 60 * 60 * 1000, shortDateLabel)
  }
  if (durationInDays <= 140) {
    return fixedBuckets(start, end, 7 * 24 * 60 * 60 * 1000, shortDateLabel)
  }

  const buckets: ChartBucket[] = []
  let monthStart = new Date(start.getFullYear(), start.getMonth(), 1)
  while (monthStart < end) {
    const monthEnd = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 1)
    buckets.push({
      start: monthStart < start ? start : monthStart,
      end: monthEnd > end ? end : monthEnd,
      label: monthLabel(monthStart),
    })
    monthStart = monthEnd
  }
  return buckets
}

export function getDashboardChartUnit(
  period: DashboardPeriod,
  customRange?: DateRange,
): DashboardChartUnit {
  if (period === 'daily') return 'day'
  if (period === 'weekly') return 'week'
  if (period === 'monthly' || period === 'yearly') return 'month'
  if (!customRange || Number.isNaN(customRange.start.getTime())
    || Number.isNaN(customRange.end.getTime())
    || customRange.start >= customRange.end) {
    throw new RangeError('Rentang khusus memerlukan tanggal awal dan akhir.')
  }

  const duration = customRange.end.getTime() - customRange.start.getTime()
  if (duration <= 24 * 60 * 60 * 1000) return 'hour'

  const durationInDays = Math.floor(duration / (24 * 60 * 60 * 1000))
  return durationInDays <= 140 ? 'day' : 'month'
}

function fixedBuckets(
  start: Date,
  end: Date,
  intervalMs: number,
  labelFor: (date: Date) => string,
): ChartBucket[] {
  const buckets: ChartBucket[] = []
  for (let bucketStart = start; bucketStart < end;) {
    const bucketEnd = new Date(Math.min(bucketStart.getTime() + intervalMs, end.getTime()))
    buckets.push({ start: bucketStart, end: bucketEnd, label: labelFor(bucketStart) })
    bucketStart = bucketEnd
  }
  return buckets
}

function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function startOfWeek(date: Date): Date {
  const start = startOfDay(date)
  start.setDate(start.getDate() - ((start.getDay() + 6) % 7))
  return start
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date)
  result.setDate(result.getDate() + days)
  return result
}

function weekdayLabel(date: Date): string {
  return new Intl.DateTimeFormat('id-ID', { weekday: 'short' }).format(date)
}

function shortDateLabel(date: Date): string {
  return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(date)
}

function monthLabel(date: Date): string {
  return new Intl.DateTimeFormat('id-ID', { month: 'short' }).format(date)
}

function hourLabel(date: Date): string {
  return new Intl.DateTimeFormat('id-ID', { hour: '2-digit', minute: '2-digit' }).format(date)
}
