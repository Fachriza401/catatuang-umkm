import { useMemo } from 'react'
import type { BusinessRole } from '../types/database.types'

export interface Permissions {
  role: BusinessRole
  isOwner: boolean
  isAdmin: boolean
  isCashier: boolean
  isViewer: boolean

  // Transaksi
  canViewTransactions: boolean
  canCreateTransaction: boolean
  canEditTransaction: boolean
  canDeleteTransaction: boolean

  // Utang-Piutang
  canViewDebts: boolean
  canCreateDebt: boolean
  canEditDebt: boolean
  canRecordDebtPayment: boolean

  // Anggota & Pengaturan
  canViewMembers: boolean
  canManageMembers: boolean
  canManageSettings: boolean
}

export function computePermissions(role: BusinessRole | null | undefined): Permissions {
  const currentRole: BusinessRole = role || 'viewer'

  const isOwner = currentRole === 'owner'
  const isAdmin = currentRole === 'admin'
  const isCashier = currentRole === 'cashier'
  const isViewer = currentRole === 'viewer'

  return {
    role: currentRole,
    isOwner,
    isAdmin,
    isCashier,
    isViewer,

    // Transaksi
    canViewTransactions: true,
    canCreateTransaction: isOwner || isAdmin || isCashier,
    canEditTransaction: isOwner || isAdmin,
    canDeleteTransaction: isOwner || isAdmin,

    // Utang-Piutang
    canViewDebts: true,
    canCreateDebt: isOwner || isAdmin,
    canEditDebt: isOwner || isAdmin,
    canRecordDebtPayment: isOwner || isAdmin || isCashier,

    // Anggota & Pengaturan
    canViewMembers: isOwner || isAdmin,
    canManageMembers: isOwner || isAdmin,
    canManageSettings: isOwner || isAdmin,
  }
}

export function usePermissions(role: BusinessRole | null | undefined): Permissions {
  return useMemo(() => computePermissions(role), [role])
}

