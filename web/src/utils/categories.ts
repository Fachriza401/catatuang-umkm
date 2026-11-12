import type { TransactionType } from '../types/database.types'

export interface CategoryOption {
  id: string
  name: string
  type: TransactionType
  color: string
  icon: string
  is_active?: boolean
  is_default?: boolean
}

export const fallbackCategories: CategoryOption[] = [
  { id: 'sales', name: 'Penjualan', type: 'income', color: '#16A34A', icon: 'shopping-bag' },
  { id: 'capital', name: 'Modal Usaha', type: 'income', color: '#2563EB', icon: 'landmark' },
  { id: 'other_income', name: 'Pemasukan Lain', type: 'income', color: '#0891B2', icon: 'plus-circle' },
  { id: 'ingredients', name: 'Bahan Baku', type: 'expense', color: '#F59E0B', icon: 'package' },
  { id: 'operations', name: 'Operasional', type: 'expense', color: '#2563EB', icon: 'settings' },
  { id: 'salary', name: 'Gaji Karyawan', type: 'expense', color: '#7C3AED', icon: 'users' },
  { id: 'rent', name: 'Sewa Tempat', type: 'expense', color: '#DC2626', icon: 'home' },
  { id: 'transport', name: 'Transportasi', type: 'expense', color: '#EA580C', icon: 'truck' },
  { id: 'marketing', name: 'Pemasaran', type: 'expense', color: '#DB2777', icon: 'megaphone' },
  { id: 'other_expense', name: 'Pengeluaran Lain', type: 'expense', color: '#64748B', icon: 'receipt' },
]

export const paymentMethods = [
  { id: 'cash', label: 'Tunai' },
  { id: 'bank_transfer', label: 'Transfer Bank' },
  { id: 'qris', label: 'QRIS' },
  { id: 'ewallet', label: 'E-Wallet' },
  { id: 'other', label: 'Lainnya' },
] as const

export function paymentMethodLabel(id: string): string {
  return paymentMethods.find((method) => method.id === id)?.label || id || 'Lainnya'
}

export function categoryLabel(categories: CategoryOption[], id: string): string {
  return categories.find((category) => category.id === id)?.name
    || fallbackCategories.find((category) => category.id === id)?.name
    || id
}

export function categoryColor(categories: CategoryOption[], id: string): string {
  return categories.find((category) => category.id === id)?.color
    || fallbackCategories.find((category) => category.id === id)?.color
    || '#64748B'
}

export const categoryIconOptions = [
  'tag',
  'shopping-bag',
  'landmark',
  'plus-circle',
  'package',
  'settings',
  'users',
  'home',
  'truck',
  'megaphone',
  'receipt',
  'coffee',
  'utensils',
  'wrench',
  'graduation-cap',
  'heart-pulse',
] as const

export const categoryColorOptions = [
  '#2563EB',
  '#123B70',
  '#16A34A',
  '#DC2626',
  '#F59E0B',
  '#7C3AED',
  '#0891B2',
  '#EA580C',
  '#DB2777',
  '#64748B',
] as const
