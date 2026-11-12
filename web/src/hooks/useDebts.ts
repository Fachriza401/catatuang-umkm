import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import {
  createDebt,
  listDebtPayments,
  listDebts,
  recordDebtPayment,
  updateDebt,
  type DebtInput,
  type DebtPaymentInput,
} from '../services/debts.service'
import type { DebtType } from '../types/database.types'

export function useDebts(options: {
  type?: DebtType | 'all'
  status?: 'all' | 'unpaid' | 'paid' | 'overdue'
  search?: string
} = {}) {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  return useQuery({
    queryKey: ['debts', businessId, options],
    queryFn: () => listDebts(businessId!, options),
    enabled: !!businessId,
  })
}

export function useDebtPayments(debtId: string | null) {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  return useQuery({
    queryKey: ['debt-payments', businessId, debtId],
    queryFn: () => listDebtPayments(businessId!, debtId!),
    enabled: !!businessId && !!debtId,
  })
}

export function useDebtMutations() {
  const { currentBusiness, user } = useAuth()
  const businessId = currentBusiness?.business_id
  const queryClient = useQueryClient()
  const invalidate = () => {
    void queryClient.invalidateQueries({ queryKey: ['debts', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['debt-payments', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['dashboard', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['transactions', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['reports', businessId] })
  }

  const create = useMutation({
    mutationFn: (input: DebtInput) => createDebt(businessId!, user!.id, input),
    onSuccess: invalidate,
  })
  const update = useMutation({
    mutationFn: ({ id, input }: { id: string; input: Omit<DebtInput, 'businessId'> }) =>
      updateDebt(businessId!, id, input),
    onSuccess: invalidate,
  })
  const pay = useMutation({
    mutationFn: (input: DebtPaymentInput) => recordDebtPayment(input),
    onSuccess: invalidate,
  })

  return { create, update, pay }
}
