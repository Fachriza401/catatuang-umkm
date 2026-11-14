import { supabase } from '../lib/supabase'
import type { Database } from '../types/database.types'

export type BusinessProfile = Database['public']['Tables']['business_profiles']['Row']

export interface BusinessProfileInput {
  business_name: string
  owner_name: string
  business_type: string
  phone: string
  address: string
  description: string
  logo_url: string
}

export const profileImageMaxBytes = 5 * 1024 * 1024

const imageExtensions = new Map([
  ['image/jpeg', 'jpg'],
  ['image/png', 'png'],
  ['image/webp', 'webp'],
])

export function profileImageValidationError(file: File): string | null {
  if (!imageExtensions.has(file.type)) {
    return 'Pilih gambar berformat JPG, PNG, atau WebP.'
  }
  if (file.size > profileImageMaxBytes) {
    return 'Ukuran gambar maksimal 5 MB.'
  }
  return null
}

export async function getBusinessProfile(businessId: string): Promise<BusinessProfile | null> {
  const { data, error } = await supabase
    .from('business_profiles')
    .select('*')
    .eq('user_id', businessId)
    .maybeSingle()
  if (error) throw error
  return (data as BusinessProfile | null) ?? null
}

export async function updateBusinessProfile(input: BusinessProfileInput): Promise<BusinessProfile> {
  const { data, error } = await supabase.rpc('update_business_profile_v2', {
    p_business_name: input.business_name,
    p_owner_name: input.owner_name,
    p_business_type: input.business_type,
    p_phone: input.phone,
    p_address: input.address,
    p_description: input.description,
    p_logo_url: input.logo_url,
  })
  if (error) throw error
  return data as BusinessProfile
}

export async function uploadBusinessLogo(businessId: string, file: File): Promise<string> {
  const validationError = profileImageValidationError(file)
  if (validationError) throw new Error(validationError)
  const extension = imageExtensions.get(file.type)
  if (!extension) throw new Error('Format gambar tidak didukung.')
  const path = `${businessId}/logo-${Date.now()}.${extension}`
  const { error } = await supabase.storage
    .from('business-logos')
    .upload(path, file, { upsert: true, cacheControl: '3600' })
  if (error) throw error
  const { data } = supabase.storage.from('business-logos').getPublicUrl(path)
  return data.publicUrl
}

export async function uploadAvatar(userId: string, file: File): Promise<string> {
  const validationError = profileImageValidationError(file)
  if (validationError) throw new Error(validationError)
  const extension = imageExtensions.get(file.type)
  if (!extension) throw new Error('Format gambar tidak didukung.')
  const path = `${userId}/avatar-${Date.now()}.${extension}`
  const { error } = await supabase.storage
    .from('profile-avatars')
    .upload(path, file, { upsert: true, cacheControl: '3600' })
  if (error) throw error
  const { data } = supabase.storage.from('profile-avatars').getPublicUrl(path)
  return data.publicUrl
}
