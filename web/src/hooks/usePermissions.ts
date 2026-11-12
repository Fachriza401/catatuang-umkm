import type { BusinessRole } from '../types/database.types'

export interface Permissions {
  role: BusinessRole
  isOwner: boolean
  canViewTransactions: boolean
  canCreateTransaction: boolean
  canEditTransaction: boolean
  canDeleteTransaction: boolean
  canViewDebts: boolean
  canCreateDebt: boolean
  canEditDebt: boolean
  canRecordDebtPayment: boolean
  canManageSettings: boolean
}

export function computePermissions(_role?: BusinessRole | null): Permissions {
  return {
    role: 'owner',
    isOwner: true,
    canViewTransactions: true,
    canCreateTransaction: true,
    canEditTransaction: true,
    canDeleteTransaction: true,
    canViewDebts: true,
    canCreateDebt: true,
    canEditDebt: true,
    canRecordDebtPayment: true,
    canManageSettings: true,
  }
}
