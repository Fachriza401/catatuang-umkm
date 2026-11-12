import { z } from 'zod'
import { supabase } from '../lib/supabase'
import type { ChartBucket, DateRange } from '../utils/dashboardPeriod'
import { getTimezone } from '../utils/preferences'

const dashboardResponseSchema = z.object({
  cash_balance: z.number().int(),
  period_income: z.number().int(),
  period_expense: z.number().int(),
  period_net: z.number().int(),
  period_transaction_count: z.number().int(),
  previous_income: z.number().int(),
  previous_expense: z.number().int(),
  previous_net: z.number().int(),
  previous_transaction_count: z.number().int(),
  receivable_outstanding: z.number().int(),
  payable_outstanding: z.number().int(),
  receivable_unpaid_count: z.number().int(),
  payable_unpaid_count: z.number().int(),
  receivable_due_count: z.number().int(),
  payable_due_count: z.number().int(),
  chart_points: z.array(z.object({
    bucket_start: z.string(),
    income: z.number().int(),
    expense: z.number().int(),
    net: z.number().int(),
  })),
  recent_transactions: z.array(z.object({
    id: z.string(),
    type: z.enum(['income', 'expense']),
    amount: z.number().int(),
    transaction_date: z.string(),
    description: z.string(),
    category_id: z.string(),
    category_name: z.string(),
    category_color: z.string(),
    payment_method_id: z.string(),
  })),
  recent_activity: z.array(z.object({
    id: z.string(),
    action: z.string(),
    entity_type: z.string(),
    entity_id: z.string().nullable(),
    summary: z.string(),
    actor_user_id: z.string().nullable(),
    created_at: z.string(),
  })),
})

export interface DashboardData {
  cashBalance: number
  income: number
  expense: number
  netCashFlow: number
  transactionCount: number
  previousIncome: number
  previousExpense: number
  previousNetCashFlow: number
  previousTransactionCount: number
  receivableOutstanding: number
  payableOutstanding: number
  receivableUnpaidCount: number
  payableUnpaidCount: number
  receivableDueCount: number
  payableDueCount: number
  chartPoints: Array<{
    label: string
    income: number
    expense: number
    net: number
  }>
  recentTransactions: Array<{
    id: string
    type: 'income' | 'expense'
    amount: number
    transactionDate: Date
    description: string
    categoryId: string
    categoryName: string
    categoryColor: string
    paymentMethodId: string
  }>
  recentActivity: Array<{
    id: string
    action: string
    entityType: string
    entityId: string | null
    summary: string
    actorUserId: string | null
    createdAt: Date
  }>
}

export async function getDashboardData(
  businessId: string,
  summaryRange: DateRange,
  chartRange: DateRange,
  chartBuckets: ChartBucket[],
  chartUnit: 'hour' | 'day' | 'week' | 'month',
): Promise<DashboardData> {
  const { data, error } = await supabase.rpc('get_web_dashboard_summary', {
    p_business_id: businessId,
    p_start: summaryRange.start.toISOString(),
    p_end: summaryRange.end.toISOString(),
    p_chart_start: chartRange.start.toISOString(),
    p_chart_end: chartRange.end.toISOString(),
    p_chart_unit: chartUnit,
    p_timezone: getTimezone(),
  })

  if (error) throw error

  const parsed = dashboardResponseSchema.safeParse(data)
  if (!parsed.success) {
    throw new Error('Respons ringkasan dasbor dari server tidak valid.')
  }

  const response = parsed.data
  const chartPoints = chartBuckets.map(({ label }) => ({ label, income: 0, expense: 0, net: 0 }))

  for (const point of response.chart_points) {
    const bucketDate = new Date(point.bucket_start)
    const bucketIndex = chartUnit === 'month'
      ? chartBuckets.findIndex(({ start }) =>
        start.getFullYear() === bucketDate.getFullYear()
        && start.getMonth() === bucketDate.getMonth(),
      )
      : chartBuckets.findIndex(({ start, end }) => bucketDate >= start && bucketDate < end)

    if (bucketIndex === -1) continue
    chartPoints[bucketIndex].income += point.income
    chartPoints[bucketIndex].expense += point.expense
    chartPoints[bucketIndex].net += point.net
  }

  return {
    cashBalance: response.cash_balance,
    income: response.period_income,
    expense: response.period_expense,
    netCashFlow: response.period_net,
    transactionCount: response.period_transaction_count,
    previousIncome: response.previous_income,
    previousExpense: response.previous_expense,
    previousNetCashFlow: response.previous_net,
    previousTransactionCount: response.previous_transaction_count,
    receivableOutstanding: response.receivable_outstanding,
    payableOutstanding: response.payable_outstanding,
    receivableUnpaidCount: response.receivable_unpaid_count,
    payableUnpaidCount: response.payable_unpaid_count,
    receivableDueCount: response.receivable_due_count,
    payableDueCount: response.payable_due_count,
    chartPoints,
    recentTransactions: response.recent_transactions.map((transaction) => ({
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      transactionDate: new Date(transaction.transaction_date),
      description: transaction.description,
      categoryId: transaction.category_id,
      categoryName: transaction.category_name,
      categoryColor: transaction.category_color,
      paymentMethodId: transaction.payment_method_id,
    })),
    recentActivity: response.recent_activity.map((activity) => ({
      id: activity.id,
      action: activity.action,
      entityType: activity.entity_type,
      entityId: activity.entity_id,
      summary: activity.summary,
      actorUserId: activity.actor_user_id,
      createdAt: new Date(activity.created_at),
    })),
  }
}
