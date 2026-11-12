import { describe, it, expect } from 'vitest'
import { computePermissions } from '../hooks/usePermissions'

describe('usePermissions / computePermissions', () => {
  it('memberikan hak akses pemilik usaha pada akun yang terautentikasi', () => {
    const perms = computePermissions()
    expect(perms.role).toBe('owner')
    expect(perms.isOwner).toBe(true)
    expect(perms.canViewTransactions).toBe(true)
    expect(perms.canCreateTransaction).toBe(true)
    expect(perms.canEditTransaction).toBe(true)
    expect(perms.canDeleteTransaction).toBe(true)
    expect(perms.canViewDebts).toBe(true)
    expect(perms.canCreateDebt).toBe(true)
    expect(perms.canEditDebt).toBe(true)
    expect(perms.canRecordDebtPayment).toBe(true)
    expect(perms.canManageSettings).toBe(true)
  })

  it('tidak membawa pembatasan peran lama dari data sesi yang tersimpan', () => {
    const perms = computePermissions('owner')
    expect(perms.role).toBe('owner')
    expect(perms.canCreateTransaction).toBe(true)
    expect(perms.canManageSettings).toBe(true)
  })
})
