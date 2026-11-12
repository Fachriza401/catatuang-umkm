import { describe, expect, it } from 'vitest'
import {
  getChartBuckets,
  getChartBucketsForRange,
  getDashboardChartUnit,
  getSummaryRange,
} from '../utils/dashboardPeriod'

describe('dashboard periods', () => {
  const now = new Date(2026, 9, 31, 12)

  it('uses the local calendar day for daily summaries and charts', () => {
    const range = getSummaryRange('daily', now)
    const buckets = getChartBuckets('daily', now)

    expect(range.start).toEqual(new Date(2026, 9, 31))
    expect(range.end).toEqual(new Date(2026, 10, 1))
    expect(buckets).toHaveLength(7)
    expect(buckets.at(-1)?.start).toEqual(new Date(2026, 9, 31))
    expect(getDashboardChartUnit('daily')).toBe('day')
  })

  it('starts weekly summaries on Monday and matches the mobile chart window', () => {
    const range = getSummaryRange('weekly', now)
    const buckets = getChartBuckets('weekly', now)

    expect(range.start).toEqual(new Date(2026, 9, 26))
    expect(range.end).toEqual(new Date(2026, 10, 2))
    expect(buckets).toHaveLength(6)
    expect(buckets.at(-1)?.start).toEqual(range.start)
    expect(getDashboardChartUnit('weekly')).toBe('week')
  })

  it('creates clipped weekly buckets for a custom range over 45 days', () => {
    const start = new Date(2026, 0, 3)
    const end = new Date(2026, 2, 1)
    const buckets = getChartBucketsForRange(start, end)

    expect(buckets[0].start).toEqual(start)
    expect(buckets.at(-1)?.end).toEqual(end)
    expect(buckets).toHaveLength(9)
    expect(getDashboardChartUnit('custom', { start, end })).toBe('day')
  })

  it('uses daily buckets through 45 full days, matching mobile duration rules', () => {
    const start = new Date(2026, 0, 1)
    const end = new Date(start.getTime() + 45 * 24 * 60 * 60 * 1000 + 1)

    expect(getChartBucketsForRange(start, end)).toHaveLength(46)
  })
})
