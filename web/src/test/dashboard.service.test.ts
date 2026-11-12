import { beforeEach, describe, expect, it, vi } from 'vitest'
import { supabase } from '../lib/supabase'
import { getDashboardData } from '../services/dashboard.service'
import { getChartBuckets, getSummaryRange } from '../utils/dashboardPeriod'

vi.mock('../lib/supabase', () => ({
  supabase: { rpc: vi.fn() },
}))

describe('getDashboardData', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('uses the dashboard RPC and maps the summary, chart, and recent transactions', async () => {
    vi.mocked(supabase.rpc).mockResolvedValueOnce({
      data: {
        cash_balance: 70_000,
        period_income: 100_000,
        period_expense: 50_000,
        period_net: 50_000,
        period_transaction_count: 1,
        previous_income: 80_000,
        previous_expense: 40_000,
        previous_net: 40_000,
        previous_transaction_count: 2,
        receivable_outstanding: 200_000,
        payable_outstanding: 75_000,
        receivable_unpaid_count: 1,
        payable_unpaid_count: 1,
        receivable_due_count: 0,
        payable_due_count: 0,
        chart_points: [{
          bucket_start: '2026-10-01T00:00:00',
          income: 100_000,
          expense: 50_000,
          net: 50_000,
        }],
        recent_transactions: [{
          id: 'transaction-1',
          type: 'income',
          amount: 100_000,
          transaction_date: '2026-10-31T02:00:00Z',
          description: 'Penjualan',
          category_id: 'sales',
          category_name: 'Penjualan',
          category_color: '#2563EB',
          payment_method_id: 'cash',
        }],
        recent_activity: [],
      },
      error: null,
      count: null,
      status: 200,
      statusText: 'OK',
      success: true,
    })

    const now = new Date(2026, 9, 31, 12)
    const summaryRange = getSummaryRange('monthly', now)
    const chartBuckets = getChartBuckets('monthly', now)
    const chartRange = {
      start: chartBuckets[0].start,
      end: chartBuckets.at(-1)!.end,
    }

    const result = await getDashboardData(
      'business-1',
      summaryRange,
      chartRange,
      chartBuckets,
      'month',
    )

    expect(supabase.rpc).toHaveBeenCalledWith(
      'get_web_dashboard_summary',
      expect.objectContaining({
        p_business_id: 'business-1',
        p_start: summaryRange.start.toISOString(),
        p_end: summaryRange.end.toISOString(),
        p_chart_unit: 'month',
      }),
    )
    expect(result).toMatchObject({
      cashBalance: 70_000,
      income: 100_000,
      expense: 50_000,
      netCashFlow: 50_000,
      receivableOutstanding: 200_000,
      payableOutstanding: 75_000,
      chartPoints: expect.arrayContaining([
        expect.objectContaining({ label: 'Okt', income: 100_000, expense: 50_000 }),
      ]),
      recentTransactions: [expect.objectContaining({
        id: 'transaction-1',
        description: 'Penjualan',
        amount: 100_000,
      })],
    })
  })

  it('surfaces an invalid server response instead of showing empty totals', async () => {
    vi.mocked(supabase.rpc).mockResolvedValueOnce({
      data: null,
      error: null,
      count: null,
      status: 200,
      statusText: 'OK',
      success: true,
    })
    const summaryRange = getSummaryRange('daily', new Date(2026, 9, 31))
    const chartBuckets = getChartBuckets('daily', new Date(2026, 9, 31))

    await expect(getDashboardData(
      'business-1',
      summaryRange,
      { start: chartBuckets[0].start, end: chartBuckets.at(-1)!.end },
      chartBuckets,
      'day',
    )).rejects.toThrow('Respons ringkasan dasbor dari server tidak valid.')
  })
})
