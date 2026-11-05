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
    const list: UserBusinessOption[] = []

    // 1. Cek bisnis milik sendiri (sebagai owner)
    const { data: owned, error: ownedErr } = await supabase
      .from('business_profiles')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle()

    if (ownedErr) {
      console.error('Error fetching owned business profile:', ownedErr)
    } else if (owned) {
      const ownedRow = owned as BusinessProfileRow
      list.push({
        business_id: ownedRow.user_id,
        business_name: ownedRow.business_name,
        owner_name: ownedRow.owner_name,
        role: 'owner',
        is_owner: true,
      })
    }

    // 2. Cek bisnis di mana user menjadi anggota
    const { data: memberships, error: memberErr } = await supabase
      .from('business_members')
      .select('business_id, role')
      .eq('member_user_id', userId)

    if (memberErr) {
      console.error('Error fetching memberships:', memberErr)
    } else if (memberships && memberships.length > 0) {
      for (const m of memberships as { business_id: string; role: BusinessRole }[]) {
        const { data: bProfile } = await supabase
          .from('business_profiles')
          .select('business_name, owner_name')
          .eq('user_id', m.business_id)
          .maybeSingle()

        const profileRow = bProfile as { business_name?: string; owner_name?: string } | null
        list.push({
          business_id: m.business_id,
          business_name: profileRow?.business_name || 'Usaha Rekanan',
          owner_name: profileRow?.owner_name || '',
          role: m.role,
          is_owner: false,
        })
      }
    }

    return list
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
