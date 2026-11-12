import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import {
  createTransaction,
  deleteTransaction,
  listTransactions,
  updateTransaction,
  type TransactionFilters,
  type TransactionInput,
} from '../services/transactions.service'

export function useTransactions(filters: Omit<TransactionFilters, 'businessId'>) {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  return useQuery({
    queryKey: ['transactions', businessId, filters],
    queryFn: () => listTransactions({ ...filters, businessId: businessId! }),
    enabled: !!businessId,
    placeholderData: (previous) => previous,
  })
}

export function useTransactionMutations() {
  const { currentBusiness, user } = useAuth()
  const businessId = currentBusiness?.business_id
  const queryClient = useQueryClient()
  const invalidate = () => {
    void queryClient.invalidateQueries({ queryKey: ['transactions', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['dashboard', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['reports', businessId] })
  }

  const create = useMutation({
    mutationFn: (input: Omit<TransactionInput, 'businessId' | 'userId'>) =>
      createTransaction({ ...input, businessId: businessId!, userId: user!.id }),
    onSuccess: invalidate,
  })
  const update = useMutation({
    mutationFn: ({ id, input }: { id: string; input: Omit<TransactionInput, 'businessId' | 'userId'> }) =>
      updateTransaction(id, { ...input, businessId: businessId!, userId: user!.id }),
    onSuccess: invalidate,
  })
  const remove = useMutation({
    mutationFn: (id: string) => deleteTransaction(businessId!, id),
    onSuccess: invalidate,
  })

  return { create, update, remove }
}
