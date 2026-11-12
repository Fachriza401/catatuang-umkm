import { supabase } from '../lib/supabase'
import type { Database, TransactionType } from '../types/database.types'

export type CategoryRow = Database['public']['Tables']['categories']['Row']

export interface CategoryInput {
  name: string
  type: TransactionType
  icon: string
  color: string
}

export async function listCategories(businessId: string): Promise<CategoryRow[]> {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .eq('business_id', businessId)
    .order('type', { ascending: true })
    .order('is_default', { ascending: false })
    .order('name', { ascending: true })
  if (error) throw error
  return (data ?? []) as CategoryRow[]
}

export async function createCategory(
  businessId: string,
  userId: string,
  input: CategoryInput,
): Promise<CategoryRow> {
  const { data, error } = await supabase
    .from('categories')
    .insert({
      business_id: businessId,
      id: `custom_${crypto.randomUUID()}`,
      name: input.name.trim(),
      type: input.type,
      icon: input.icon,
      color: input.color,
      is_default: false,
      is_active: true,
      created_by: userId,
    })
    .select('*')
    .single()
  if (error) throw error
  return data as CategoryRow
}

export async function updateCategory(
  businessId: string,
  id: string,
  input: Partial<CategoryInput> & { is_active?: boolean },
): Promise<CategoryRow> {
  const { data, error } = await supabase
    .from('categories')
    .update({
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(input.type !== undefined ? { type: input.type } : {}),
      ...(input.icon !== undefined ? { icon: input.icon } : {}),
      ...(input.color !== undefined ? { color: input.color } : {}),
      ...(input.is_active !== undefined ? { is_active: input.is_active } : {}),
    })
    .eq('business_id', businessId)
    .eq('id', id)
    .select('*')
    .single()
  if (error) throw error
  return data as CategoryRow
}

export async function deleteCategory(businessId: string, id: string): Promise<void> {
  const { error } = await supabase
    .from('categories')
    .delete()
    .eq('business_id', businessId)
    .eq('id', id)
  if (error) throw error
}
