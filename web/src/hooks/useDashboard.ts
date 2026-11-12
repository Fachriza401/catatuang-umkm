import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { getDashboardData } from '../services/dashboard.service'
import {
  getChartBuckets,
  getChartBucketsForRange,
  getDashboardChartUnit,
  getSummaryRange,
  type DashboardPeriod,
} from '../utils/dashboardPeriod'

interface UseDashboardOptions {
  businessId: string | undefined
  period: DashboardPeriod
  customStart?: Date
  customEnd?: Date    // exclusive
}

export function useDashboard({ businessId, period, customStart, customEnd }: UseDashboardOptions) {
  const [now] = useState(() => new Date())
  const customRange = period === 'custom' && customStart && customEnd
    ? { start: customStart, end: customEnd }
    : null
  const validCustomRange = customRange !== null
    && Number.isFinite(customRange.start.getTime())
    && Number.isFinite(customRange.end.getTime())
    && customRange.start < customRange.end

  const summaryRange = period === 'custom'
    ? customRange
    : getSummaryRange(period, now)

  const chartBuckets = period === 'custom'
    ? validCustomRange && customRange
      ? getChartBucketsForRange(customRange.start, customRange.end)
      : null
    : getChartBuckets(period, now)
  const chartRange = chartBuckets
    ? { start: chartBuckets[0].start, end: chartBuckets[chartBuckets.length - 1].end }
    : null
  const chartUnit = period === 'custom' && validCustomRange && customRange
    ? getDashboardChartUnit(period, customRange)
    : period === 'custom'
      ? 'day'
      : getDashboardChartUnit(period)

  return useQuery({
    queryKey: [
      'dashboard',
      businessId,
      period,
      customStart && Number.isFinite(customStart.getTime()) ? customStart.toISOString() : undefined,
      customEnd && Number.isFinite(customEnd.getTime()) ? customEnd.toISOString() : undefined,
    ],
    queryFn: () => {
      if (!businessId || !summaryRange || !chartRange || !chartBuckets) {
        throw new Error('Usaha dan rentang tanggal yang valid diperlukan.')
      }
      return getDashboardData(businessId, summaryRange, chartRange, chartBuckets, chartUnit)
    },
    enabled: !!businessId && !!summaryRange && !!chartRange && !!chartBuckets,
    staleTime: 60_000,
    refetchOnWindowFocus: true,
  })
}
