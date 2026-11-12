import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import {
  getBusinessProfile,
  updateBusinessProfile,
  type BusinessProfileInput,
} from '../services/profile.service'

export function useBusinessProfile() {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  return useQuery({
    queryKey: ['business-profile', businessId],
    queryFn: () => getBusinessProfile(businessId!),
    enabled: !!businessId,
  })
}

export function useUpdateBusinessProfile() {
  const { currentBusiness, refreshBusinessAccess } = useAuth()
  const businessId = currentBusiness?.business_id
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (input: BusinessProfileInput) => updateBusinessProfile(input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['business-profile', businessId] })
      void queryClient.invalidateQueries({ queryKey: ['dashboard', businessId] })
      void refreshBusinessAccess()
    },
  })
}
