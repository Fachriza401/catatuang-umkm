import { supabase } from '../lib/supabase'
import type { Database, TransactionType } from '../types/database.types'

export type TransactionRow = Database['public']['Tables']['transactions']['Row']

export interface TransactionFilters {
  businessId: string
  search?: string
  type?: TransactionType | 'all'
  categoryId?: string
  paymentMethodId?: string
  start?: string
  end?: string
  page: number
  pageSize: number
}

export interface TransactionInput {
  businessId: string
  userId: string
  type: TransactionType
  amount: number
  categoryId: string
  paymentMethodId: string
  transactionDate: string
  description: string
  note: string
}

function escapeSearchTerm(value: string): string {
  return value.replace(/[,%()]/g, ' ').trim()
}

export async function listTransactions({
  businessId,
  search,
  type,
  categoryId,
  paymentMethodId,
  start,
  end,
  page,
  pageSize,
}: TransactionFilters): Promise<{ rows: TransactionRow[]; count: number }> {
  const from = (page - 1) * pageSize
  const to = from + pageSize - 1

  let query = supabase
    .from('transactions')
    .select('*', { count: 'exact' })
    .eq('user_id', businessId)
    .is('deleted_at', null)
    .order('transaction_date', { ascending: false })
    .order('created_at', { ascending: false })
    .range(from, to)

  if (type && type !== 'all') query = query.eq('type', type)
  if (categoryId) query = query.eq('category_id', categoryId)
  if (paymentMethodId) query = query.eq('payment_method_id', paymentMethodId)
  if (start) query = query.gte('transaction_date', start)
  if (end) query = query.lt('transaction_date', end)

  const term = search ? escapeSearchTerm(search) : ''
  if (term) {
    query = query.or(`description.ilike.%${term}%,note.ilike.%${term}%`)
  }

  const { data, error, count } = await query
  if (error) throw error
  return { rows: (data ?? []) as TransactionRow[], count: count ?? 0 }
}

export async function listTransactionsForRange(
  businessId: string,
  start: string,
  end: string,
  type?: TransactionType | 'all',
  categoryId?: string,
): Promise<TransactionRow[]> {
  let query = supabase
    .from('transactions')
    .select('*')
    .eq('user_id', businessId)
    .is('deleted_at', null)
    .gte('transaction_date', start)
    .lt('transaction_date', end)
    .order('transaction_date', { ascending: true })
    .limit(10_000)

  if (type && type !== 'all') query = query.eq('type', type)
  if (categoryId) query = query.eq('category_id', categoryId)

  const { data, error } = await query
  if (error) throw error
  return (data ?? []) as TransactionRow[]
}

export async function getTransaction(businessId: string, id: string): Promise<TransactionRow | null> {
  const { data, error } = await supabase
    .from('transactions')
    .select('*')
    .eq('user_id', businessId)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return (data as TransactionRow | null) ?? null
}

export async function createTransaction(input: TransactionInput): Promise<TransactionRow> {
  const { data, error } = await supabase
    .from('transactions')
    .insert({
      id: crypto.randomUUID(),
      user_id: input.businessId,
      created_by: input.userId,
      type: input.type,
      amount: input.amount,
      category_id: input.categoryId,
      payment_method_id: input.paymentMethodId,
      transaction_date: input.transactionDate,
      description: input.description,
      note: input.note,
    })
    .select('*')
    .single()
  if (error) throw error
  return data as TransactionRow
}

export async function updateTransaction(
  id: string,
  input: TransactionInput,
): Promise<TransactionRow> {
  const { data, error } = await supabase
    .from('transactions')
    .update({
      type: input.type,
      amount: input.amount,
      category_id: input.categoryId,
      payment_method_id: input.paymentMethodId,
      transaction_date: input.transactionDate,
      description: input.description,
      note: input.note,
    })
    .eq('id', id)
    .eq('user_id', input.businessId)
    .select('*')
    .single()
  if (error) throw error
  return data as TransactionRow
}

export async function deleteTransaction(businessId: string, id: string): Promise<void> {
  const { error } = await supabase
    .from('transactions')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .eq('user_id', businessId)
  if (error) throw error
}
