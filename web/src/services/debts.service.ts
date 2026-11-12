import { supabase } from '../lib/supabase'
import type { Database, DebtType } from '../types/database.types'

export type DebtRow = Database['public']['Tables']['debts']['Row']
export type DebtPaymentRow = Database['public']['Tables']['debt_payments']['Row']

export interface DebtInput {
  businessId: string
  type: DebtType
  contactName: string
  phone: string
  amount: number
  transactionDate: string
  dueDate: string
  note: string
}

export interface DebtPaymentInput {
  paymentId: string
  ledgerTransactionId: string
  debtId: string
  amount: number
  paymentDate: string
  note: string
  ledgerDescription: string
}

export async function listDebts(
  businessId: string,
  options: { type?: DebtType | 'all'; status?: 'all' | 'unpaid' | 'paid' | 'overdue'; search?: string } = {},
): Promise<DebtRow[]> {
  let query = supabase
    .from('debts')
    .select('*')
    .eq('user_id', businessId)
    .order('due_date', { ascending: true })
    .order('created_at', { ascending: false })

  if (options.type && options.type !== 'all') query = query.eq('type', options.type)
  if (options.search?.trim()) {
    const term = options.search.replace(/[,%()]/g, ' ').trim()
    query = query.or(`contact_name.ilike.%${term}%,phone.ilike.%${term}%,note.ilike.%${term}%`)
  }

  const { data, error } = await query
  if (error) throw error
  const rows = (data ?? []) as DebtRow[]
  if (!options.status || options.status === 'all') return rows
  return rows.filter((debt) => {
    const status = debtStatus(debt)
    if (options.status === 'unpaid') return status !== 'paid'
    return status === options.status
  })
}

export async function getDebt(businessId: string, id: string): Promise<DebtRow | null> {
  const { data, error } = await supabase
    .from('debts')
    .select('*')
    .eq('user_id', businessId)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return (data as DebtRow | null) ?? null
}

export async function listDebtPayments(businessId: string, debtId: string): Promise<DebtPaymentRow[]> {
  const { data, error } = await supabase
    .from('debt_payments')
    .select('*')
    .eq('user_id', businessId)
    .eq('debt_id', debtId)
    .order('payment_date', { ascending: false })
  if (error) throw error
  return (data ?? []) as DebtPaymentRow[]
}

export async function createDebt(businessId: string, userId: string, input: DebtInput): Promise<DebtRow> {
  const { data, error } = await supabase
    .from('debts')
    .insert({
      id: crypto.randomUUID(),
      user_id: businessId,
      created_by: userId,
      type: input.type,
      contact_name: input.contactName.trim(),
      phone: input.phone.trim(),
      amount: input.amount,
      paid_amount: 0,
      transaction_date: input.transactionDate,
      due_date: input.dueDate,
      note: input.note.trim(),
    })
    .select('*')
    .single()
  if (error) throw error
  return data as DebtRow
}

export async function updateDebt(
  businessId: string,
  id: string,
  input: Omit<DebtInput, 'businessId'>,
): Promise<DebtRow> {
  const { data, error } = await supabase
    .from('debts')
    .update({
      type: input.type,
      contact_name: input.contactName.trim(),
      phone: input.phone.trim(),
      amount: input.amount,
      transaction_date: input.transactionDate,
      due_date: input.dueDate,
      note: input.note.trim(),
    })
    .eq('user_id', businessId)
    .eq('id', id)
    .select('*')
    .single()
  if (error) throw error
  return data as DebtRow
}

export async function recordDebtPayment(input: DebtPaymentInput): Promise<void> {
  const { error } = await supabase.rpc('record_debt_payment', {
    p_payment_id: input.paymentId,
    p_debt_id: input.debtId,
    p_amount: input.amount,
    p_payment_date: input.paymentDate,
    p_note: input.note,
    p_ledger_transaction_id: input.ledgerTransactionId,
    p_ledger_description: input.ledgerDescription,
  })
  if (error) throw error
}

export function debtRemaining(debt: DebtRow): number {
  return Math.max(0, debt.amount - debt.paid_amount)
}

export function debtStatus(debt: DebtRow): 'paid' | 'partial' | 'unpaid' | 'overdue' {
  if (debt.paid_amount >= debt.amount) return 'paid'
  if (new Date(debt.due_date).getTime() < Date.now()) return 'overdue'
  if (debt.paid_amount > 0) return 'partial'
  return 'unpaid'
}
