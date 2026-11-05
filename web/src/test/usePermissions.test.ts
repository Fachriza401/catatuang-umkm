import { describe, it, expect } from 'vitest'
import { computePermissions } from '../hooks/usePermissions'

describe('usePermissions / computePermissions', () => {
  it('memberikan seluruh hak akses penuh kepada role owner', () => {
    const perms = computePermissions('owner')
    expect(perms.role).toBe('owner')
    expect(perms.isOwner).toBe(true)
    expect(perms.isAdmin).toBe(false)
    expect(perms.isCashier).toBe(false)
    expect(perms.isViewer).toBe(false)

    // Transaksi
    expect(perms.canViewTransactions).toBe(true)
    expect(perms.canCreateTransaction).toBe(true)
    expect(perms.canEditTransaction).toBe(true)
    expect(perms.canDeleteTransaction).toBe(true)

    // Utang
    expect(perms.canViewDebts).toBe(true)
    expect(perms.canCreateDebt).toBe(true)
    expect(perms.canEditDebt).toBe(true)
    expect(perms.canRecordDebtPayment).toBe(true)

    // Manajemen
    expect(perms.canViewMembers).toBe(true)
    expect(perms.canManageMembers).toBe(true)
    expect(perms.canManageSettings).toBe(true)
  })

  it('memberikan hak akses operasional dan manajemen kepada role admin (manager)', () => {
    const perms = computePermissions('admin')
    expect(perms.role).toBe('admin')
    expect(perms.isOwner).toBe(false)
    expect(perms.isAdmin).toBe(true)

    // Transaksi & Utang
    expect(perms.canCreateTransaction).toBe(true)
    expect(perms.canEditTransaction).toBe(true)
    expect(perms.canDeleteTransaction).toBe(true)
    expect(perms.canCreateDebt).toBe(true)
    expect(perms.canRecordDebtPayment).toBe(true)

    // Manajemen
    expect(perms.canViewMembers).toBe(true)
    expect(perms.canManageMembers).toBe(true)
    expect(perms.canManageSettings).toBe(true)
  })

  it('membatasi hak akses untuk role cashier (hanya catat transaksi & cicilan)', () => {
    const perms = computePermissions('cashier')
    expect(perms.role).toBe('cashier')
    expect(perms.isCashier).toBe(true)

    // Transaksi
    expect(perms.canViewTransactions).toBe(true)
    expect(perms.canCreateTransaction).toBe(true)
    expect(perms.canEditTransaction).toBe(false)
    expect(perms.canDeleteTransaction).toBe(false)

    // Utang
    expect(perms.canViewDebts).toBe(true)
    expect(perms.canCreateDebt).toBe(false)
    expect(perms.canEditDebt).toBe(false)
    expect(perms.canRecordDebtPayment).toBe(true)

    // Manajemen (dilarang total)
    expect(perms.canViewMembers).toBe(false)
    expect(perms.canManageMembers).toBe(false)
    expect(perms.canManageSettings).toBe(false)
  })

  it('membatasi hak akses role viewer ke mode lihat saja (read-only)', () => {
    const perms = computePermissions('viewer')
    expect(perms.role).toBe('viewer')
    expect(perms.isViewer).toBe(true)

    // Transaksi
    expect(perms.canViewTransactions).toBe(true)
    expect(perms.canCreateTransaction).toBe(false)
    expect(perms.canEditTransaction).toBe(false)
    expect(perms.canDeleteTransaction).toBe(false)

    // Utang
    expect(perms.canViewDebts).toBe(true)
    expect(perms.canCreateDebt).toBe(false)
    expect(perms.canEditDebt).toBe(false)
    expect(perms.canRecordDebtPayment).toBe(false)

    // Manajemen
    expect(perms.canViewMembers).toBe(false)
    expect(perms.canManageMembers).toBe(false)
    expect(perms.canManageSettings).toBe(false)
  })

  it('menggunakan fallback viewer jika role bernilai null atau undefined', () => {
    const permsNull = computePermissions(null)
    expect(permsNull.role).toBe('viewer')
    expect(permsNull.canCreateTransaction).toBe(false)

    const permsUndef = computePermissions(undefined)
    expect(permsUndef.role).toBe('viewer')
    expect(permsUndef.canCreateTransaction).toBe(false)
  })
})

