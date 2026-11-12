import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import {
  createCategory,
  deleteCategory,
  listCategories,
  updateCategory,
  type CategoryInput,
} from '../services/categories.service'

export function useCategories() {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  return useQuery({
    queryKey: ['categories', businessId],
    queryFn: () => listCategories(businessId!),
    enabled: !!businessId,
    staleTime: 120_000,
  })
}

export function useCategoryMutations() {
  const { currentBusiness, user } = useAuth()
  const businessId = currentBusiness?.business_id
  const queryClient = useQueryClient()
  const invalidate = () => {
    void queryClient.invalidateQueries({ queryKey: ['categories', businessId] })
    void queryClient.invalidateQueries({ queryKey: ['dashboard', businessId] })
  }

  const create = useMutation({
    mutationFn: (input: CategoryInput) => createCategory(businessId!, user!.id, input),
    onSuccess: invalidate,
  })
  const update = useMutation({
    mutationFn: ({ id, input }: { id: string; input: Partial<CategoryInput> & { is_active?: boolean } }) =>
      updateCategory(businessId!, id, input),
    onSuccess: invalidate,
  })
  const remove = useMutation({
    mutationFn: (id: string) => deleteCategory(businessId!, id),
    onSuccess: invalidate,
  })

  return { create, update, remove }
}
