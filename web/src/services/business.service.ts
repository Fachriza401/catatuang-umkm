import { supabase } from '../lib/supabase'
import type { Database, GetMyBusinessAccessResult, BusinessRole } from '../types/database.types'

export interface UserBusinessOption {
  business_id: string
  business_name: string
  owner_name: string
  role: BusinessRole
  is_owner: boolean
}

type BusinessProfileRow = Database['public']['Tables']['business_profiles']['Row']

export const businessService = {
  async getMyBusinessAccess(): Promise<GetMyBusinessAccessResult> {
    const { data, error } = await supabase.rpc('get_my_business_access')
    if (error) throw error
    return data as GetMyBusinessAccessResult
  },

  async getBusinessProfile(businessId: string): Promise<BusinessProfileRow | null> {
    const { data, error } = await supabase
      .from('business_profiles')
      .select('*')
      .eq('user_id', businessId)
      .maybeSingle()
    if (error) throw error
    return data as BusinessProfileRow | null
  },

  async listUserBusinesses(userId: string): Promise<UserBusinessOption[]> {
    const { data: owned, error: ownedErr } = await supabase
      .from('business_profiles')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle()

    if (ownedErr) throw ownedErr
    if (!owned) return []

    const ownedRow = owned as BusinessProfileRow
    return [{
      business_id: ownedRow.user_id,
      business_name: ownedRow.business_name,
      owner_name: ownedRow.owner_name,
      role: 'owner',
      is_owner: true,
    }]
  },

  async createInitialBusinessProfile(params: {
    business_name: string
    owner_name?: string
    business_type?: string
    phone?: string
    address?: string
  }): Promise<BusinessProfileRow> {
    const user = (await supabase.auth.getUser()).data.user
    if (!user) throw new Error('Pengguna belum login')

    const { data, error } = await supabase
      .from('business_profiles')
      .insert({
        user_id: user.id,
        business_name: params.business_name,
        owner_name: params.owner_name || '',
        business_type: params.business_type || '',
        phone: params.phone || '',
        address: params.address || '',
      })
      .select('*')
      .single()

    if (error) throw error
    return data as BusinessProfileRow
  },
}
