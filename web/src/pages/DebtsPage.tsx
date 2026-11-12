import { useEffect, useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  AlertCircle,
  CalendarClock,
  CheckCircle2,
  HandCoins,
  Loader2,
  Pencil,
  Plus,
  Search,
  WalletCards,
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useDebtMutations, useDebtPayments, useDebts } from '../hooks/useDebts'
import { debtRemaining, debtStatus, getDebt, type DebtRow } from '../services/debts.service'
import type { DebtType } from '../types/database.types'
import { addDays, formatCurrency, formatDate, formatDateTime, formatDateInput, formatNumber, parseDateInput } from '../utils/format'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'
import { Modal } from '../components/ui/Modal'
import { EmptyState, ErrorState, LoadingState } from '../components/ui/States'

const statusLabels = {
  paid: 'Lunas',
  partial: 'Sebagian',
  unpaid: 'Belum bayar',
  overdue: 'Jatuh tempo',
} as const

const statusTones = {
  paid: 'green',
  partial: 'blue',
  unpaid: 'slate',
  overdue: 'red',
} as const

function useDebouncedValue<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])
  return debounced
}

export function DebtsPage() {
  const { currentBusiness, permissions } = useAuth()
  const businessId = currentBusiness?.business_id
  const [type, setType] = useState<DebtType | 'all'>('all')
  const [status, setStatus] = useState<'all' | 'unpaid' | 'paid' | 'overdue'>('all')
  const [search, setSearch] = useState('')
  const debouncedSearch = useDebouncedValue(search)
  const debtsQuery = useDebts({ type, status, search: debouncedSearch })
  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<DebtRow | null>(null)
  const [detailId, setDetailId] = useState<string | null>(null)
  const [payTarget, setPayTarget] = useState<DebtRow | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const detailQuery = useQuery({
    queryKey: ['debt', businessId, detailId],
    queryFn: () => getDebt(businessId!, detailId!),
    enabled: !!businessId && !!detailId,
  })
  const paymentsQuery = useDebtPayments(detailId)

  const debts = debtsQuery.data ?? []
  const summary = useMemo(() => {
    let receivable = 0
    let payable = 0
    let overdue = 0
    for (const debt of debts) {
      const remaining = debtRemaining(debt)
      if (debt.type === 'receivable') receivable += remaining
      else payable += remaining
      if (debtStatus(debt) === 'overdue') overdue += 1
    }
    return { receivable, payable, overdue }
  }, [debts])

  const openCreate = (nextType: DebtType) => {
    setEditing(null)
    setActionError(null)
    setFormOpen(true)
    setType(nextType)
  }

  const openEdit = (debt: DebtRow) => {
    setEditing(debt)
    setActionError(null)
    setFormOpen(true)
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">Utang & Piutang</h1>
          <p className="mt-1 text-sm text-slate-500">
            Pantau uang yang harus ditagih dan kewajiban yang harus dibayar.
          </p>
        </div>
        {permissions.canCreateDebt && (
          <div className="flex flex-wrap gap-2">
            <Button variant="success" icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('receivable')}>
              Piutang
            </Button>
            <Button variant="danger" icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('payable')}>
              Utang
            </Button>
          </div>
        )}
      </div>

      {actionError && (
        <ErrorState title="Aksi gagal" message={actionError} onRetry={() => setActionError(null)} />
      )}

      <div className="grid gap-3 sm:grid-cols-3">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Piutang belum tertagih</p>
            <HandCoins className="h-4 w-4 text-emerald-600" />
          </div>
          <p className="mt-2 text-xl font-bold text-emerald-700">{formatCurrency(summary.receivable)}</p>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Utang belum dibayar</p>
            <WalletCards className="h-4 w-4 text-rose-600" />
          </div>
          <p className="mt-2 text-xl font-bold text-rose-700">{formatCurrency(summary.payable)}</p>
        </Card>
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Jatuh tempo</p>
            <CalendarClock className="h-4 w-4 text-amber-600" />
          </div>
          <p className="mt-2 text-xl font-bold text-amber-700">{summary.overdue} catatan</p>
        </Card>
      </div>

      <Card className="p-4 sm:p-5">
        <div className="grid gap-3 md:grid-cols-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Cari nama, telepon, catatan..."
              className="w-full rounded-xl border border-slate-300 py-2.5 pl-9 pr-3 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              aria-label="Cari utang atau piutang"
            />
          </div>
          <select
            value={type}
            onChange={(event) => setType(event.target.value as DebtType | 'all')}
            className="rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            aria-label="Filter jenis"
          >
            <option value="all">Semua jenis</option>
            <option value="receivable">Piutang (dapat ditagih)</option>
            <option value="payable">Utang (harus dibayar)</option>
          </select>
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value as typeof status)}
            className="rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            aria-label="Filter status"
          >
            <option value="all">Semua status</option>
            <option value="unpaid">Belum lunas</option>
            <option value="overdue">Jatuh tempo</option>
            <option value="paid">Lunas</option>
          </select>
        </div>
      </Card>

      {debtsQuery.isLoading ? (
        <LoadingState message="Memuat utang dan piutang..." />
      ) : debtsQuery.isError ? (
        <ErrorState
          message={debtsQuery.error instanceof Error ? debtsQuery.error.message : 'Gagal memuat data.'}
          onRetry={() => void debtsQuery.refetch()}
        />
      ) : debts.length === 0 ? (
        <EmptyState
          title="Belum ada catatan"
          description={search || type !== 'all' || status !== 'all' ? 'Tidak ada data yang cocok dengan filter.' : 'Catat piutang atau utang agar arus kas usaha tetap terkendali.'}
          icon={<HandCoins className="h-6 w-6" />}
          action={permissions.canCreateDebt ? <Button icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('receivable')}>Tambah catatan</Button> : undefined}
        />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {debts.map((debt) => {
            const remaining = debtRemaining(debt)
            const state = debtStatus(debt)
            const progress = debt.amount > 0 ? Math.min(100, (debt.paid_amount / debt.amount) * 100) : 0
            return (
              <Card key={debt.id} className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge tone={debt.type === 'receivable' ? 'green' : 'red'}>
                        {debt.type === 'receivable' ? 'Piutang' : 'Utang'}
                      </Badge>
                      <Badge tone={statusTones[state]}>{statusLabels[state]}</Badge>
                    </div>
                    <p className="mt-2 truncate text-sm font-bold text-slate-800">{debt.contact_name}</p>
                    <p className="text-xs text-slate-500">{debt.phone || 'Tanpa nomor telepon'}</p>
                  </div>
                  <div className="shrink-0 text-right">
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Sisa</p>
                    <p className={`text-base font-bold ${debt.type === 'receivable' ? 'text-emerald-700' : 'text-rose-700'}`}>
                      {formatCurrency(remaining)}
                    </p>
                  </div>
                </div>
                <div className="mt-3">
                  <div className="h-1.5 overflow-hidden rounded-full bg-slate-100">
                    <div className={`h-full rounded-full ${state === 'paid' ? 'bg-emerald-500' : debt.type === 'receivable' ? 'bg-emerald-400' : 'bg-rose-400'}`} style={{ width: `${progress}%` }} />
                  </div>
                  <div className="mt-2 flex flex-wrap justify-between gap-1 text-[11px] text-slate-500">
                    <span>Dibayar {formatCurrency(debt.paid_amount)} dari {formatCurrency(debt.amount)}</span>
                    <span>Jatuh tempo {formatDate(debt.due_date, { dateStyle: 'medium' })}</span>
                  </div>
                </div>
                <div className="mt-3 flex flex-wrap justify-end gap-2 border-t border-slate-100 pt-3">
                  <Button variant="secondary" size="sm" onClick={() => setDetailId(debt.id)}>
                    Lihat detail
                  </Button>
                  {permissions.canRecordDebtPayment && remaining > 0 && (
                    <Button size="sm" icon={<WalletCards className="h-3.5 w-3.5" />} onClick={() => setPayTarget(debt)}>
                      Catat pembayaran
                    </Button>
                  )}
                  {permissions.canEditDebt && (
                    <Button variant="ghost" size="sm" icon={<Pencil className="h-3.5 w-3.5" />} onClick={() => openEdit(debt)}>
                      Ubah
                    </Button>
                  )}
                </div>
              </Card>
            )
          })}
        </div>
      )}

      <DebtFormModal
        isOpen={formOpen}
        onClose={() => setFormOpen(false)}
        debt={editing}
        defaultType={type === 'all' ? 'receivable' : type}
      />

      <PaymentModal
        isOpen={!!payTarget}
        onClose={() => setPayTarget(null)}
        debt={payTarget}
      />

      <Modal
        isOpen={!!detailId && !!detailQuery.data}
        onClose={() => setDetailId(null)}
        title="Detail utang & piutang"
        size="lg"
      >
        {detailQuery.data && (
          <DebtDetail
            debt={detailQuery.data}
            payments={paymentsQuery.data ?? []}
            paymentsLoading={paymentsQuery.isLoading}
            canPay={permissions.canRecordDebtPayment && debtRemaining(detailQuery.data) > 0}
            canEdit={permissions.canEditDebt}
            onPay={() => {
              setPayTarget(detailQuery.data)
              setDetailId(null)
            }}
            onEdit={() => {
              openEdit(detailQuery.data!)
              setDetailId(null)
            }}
          />
        )}
      </Modal>
    </div>
  )
}

function DebtDetail({
  debt,
  payments,
  paymentsLoading,
  canPay,
  canEdit,
  onPay,
  onEdit,
}: {
  debt: DebtRow
  payments: Array<{ id: string; amount: number; payment_date: string; note: string }>
  paymentsLoading: boolean
  canPay: boolean
  canEdit: boolean
  onPay: () => void
  onEdit: () => void
}) {
  const remaining = debtRemaining(debt)
  const state = debtStatus(debt)
  return (
    <div className="space-y-4">
      <div className={`rounded-2xl p-4 ${debt.type === 'receivable' ? 'bg-emerald-50' : 'bg-rose-50'}`}>
        <div className="flex flex-wrap items-center gap-2">
          <Badge tone={debt.type === 'receivable' ? 'green' : 'red'}>{debt.type === 'receivable' ? 'Piutang' : 'Utang'}</Badge>
          <Badge tone={statusTones[state]}>{statusLabels[state]}</Badge>
        </div>
        <p className="mt-2 text-lg font-bold text-slate-900">{debt.contact_name}</p>
        <p className="text-sm text-slate-600">{debt.phone || 'Tanpa nomor telepon'}</p>
        <div className="mt-3 grid gap-2 sm:grid-cols-3">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Total</p>
            <p className="text-sm font-bold text-slate-800">{formatCurrency(debt.amount)}</p>
          </div>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Dibayar</p>
            <p className="text-sm font-bold text-slate-800">{formatCurrency(debt.paid_amount)}</p>
          </div>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Sisa</p>
            <p className="text-sm font-bold text-slate-900">{formatCurrency(remaining)}</p>
          </div>
        </div>
      </div>

      <dl className="grid gap-3 text-sm sm:grid-cols-2">
        <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-3">
          <dt className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Tanggal transaksi</dt>
          <dd className="mt-1 font-medium text-slate-700">{formatDate(debt.transaction_date, { dateStyle: 'long' })}</dd>
        </div>
        <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-3">
          <dt className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Jatuh tempo</dt>
          <dd className="mt-1 font-medium text-slate-700">{formatDate(debt.due_date, { dateStyle: 'long' })}</dd>
        </div>
      </dl>

      {debt.note && (
        <div className="rounded-xl bg-slate-50 p-3">
          <p className="text-xs font-semibold text-slate-500">Catatan</p>
          <p className="mt-1 whitespace-pre-wrap text-sm text-slate-700">{debt.note}</p>
        </div>
      )}

      <div>
        <div className="mb-2 flex items-center justify-between">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Riwayat pembayaran</p>
          <span className="text-[11px] text-slate-400">{payments.length} pembayaran</span>
        </div>
        {paymentsLoading ? (
          <LoadingState message="Memuat pembayaran..." />
        ) : payments.length === 0 ? (
          <p className="rounded-xl border border-dashed border-slate-200 p-4 text-center text-xs text-slate-500">Belum ada pembayaran.</p>
        ) : (
          <ul className="space-y-2">
            {payments.map((payment) => (
              <li key={payment.id} className="flex items-start justify-between gap-3 rounded-xl border border-slate-100 p-3">
                <div>
                  <p className="text-sm font-semibold text-slate-800">{formatCurrency(payment.amount)}</p>
                  <p className="text-[11px] text-slate-500">{formatDateTime(payment.payment_date)}</p>
                  {payment.note && <p className="mt-1 text-xs text-slate-600">{payment.note}</p>}
                </div>
                <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-500" />
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="flex flex-wrap justify-end gap-2 pt-2">
        {canEdit && <Button variant="secondary" icon={<Pencil className="h-4 w-4" />} onClick={onEdit}>Ubah</Button>}
        {canPay && <Button icon={<WalletCards className="h-4 w-4" />} onClick={onPay}>Catat pembayaran</Button>}
      </div>
    </div>
  )
}

function DebtFormModal({
  isOpen,
  onClose,
  debt,
  defaultType,
}: {
  isOpen: boolean
  onClose: () => void
  debt: DebtRow | null
  defaultType: DebtType
}) {
  const { create, update } = useDebtMutations()
  const [type, setType] = useState<DebtType>(defaultType)
  const [contactName, setContactName] = useState('')
  const [phone, setPhone] = useState('')
  const [amountInput, setAmountInput] = useState('')
  const [transactionDate, setTransactionDate] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!isOpen) return
    setType(debt?.type || defaultType)
    setContactName(debt?.contact_name || '')
    setPhone(debt?.phone || '')
    setAmountInput(debt ? formatNumber(debt.amount) : '')
    setTransactionDate(formatDateInput(debt?.transaction_date || new Date()))
    setDueDate(formatDateInput(debt?.due_date || addDays(new Date(), 7)))
    setNote(debt?.note || '')
    setError(null)
  }, [isOpen, debt, defaultType])

  const isPending = create.isPending || update.isPending
  const amount = Number(amountInput.replace(/\D/g, '')) || 0

  const handleAmountChange = (value: string) => {
    const digits = value.replace(/\D/g, '').slice(0, 15)
    setAmountInput(digits ? formatNumber(Number(digits)) : '')
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    setError(null)
    if (!contactName.trim()) {
      setError('Nama kontak wajib diisi.')
      return
    }
    if (amount <= 0) {
      setError('Nominal harus lebih dari Rp 0.')
      return
    }
    if (debt && amount < debt.paid_amount) {
      setError(`Nominal tidak boleh lebih kecil dari total yang sudah dibayar (${formatCurrency(debt.paid_amount)}).`)
      return
    }
    const start = parseDateInput(transactionDate)
    const due = parseDateInput(dueDate)
    if (!start || !due) {
      setError('Tanggal transaksi dan jatuh tempo wajib valid.')
      return
    }
    if (due < start) {
      setError('Jatuh tempo tidak boleh sebelum tanggal transaksi.')
      return
    }

    const payload = {
      type,
      contactName,
      phone,
      amount,
      transactionDate: start.toISOString(),
      dueDate: due.toISOString(),
      note,
    }

    try {
      if (debt) {
        await update.mutateAsync({ id: debt.id, input: payload })
      } else {
        await create.mutateAsync({ ...payload, businessId: '' })
      }
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal menyimpan catatan.')
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={debt ? 'Ubah utang / piutang' : 'Catat utang / piutang'}
      description="Pembayaran yang dicatat akan otomatis masuk ke transaksi kas."
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}
        <div>
          <span className="mb-1.5 block text-xs font-semibold text-slate-700">Jenis</span>
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1">
            <button type="button" onClick={() => setType('receivable')} className={`rounded-lg px-3 py-2 text-sm font-semibold ${type === 'receivable' ? 'bg-white text-emerald-700 shadow-sm' : 'text-slate-500'}`}>Piutang</button>
            <button type="button" onClick={() => setType('payable')} className={`rounded-lg px-3 py-2 text-sm font-semibold ${type === 'payable' ? 'bg-white text-rose-700 shadow-sm' : 'text-slate-500'}`}>Utang</button>
          </div>
          <p className="mt-1 text-[11px] text-slate-500">
            {type === 'receivable' ? 'Uang yang harus Anda tagih dari pelanggan.' : 'Uang yang harus Anda bayar kepada pihak lain.'}
          </p>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="debt-contact" className="mb-1.5 block text-xs font-semibold text-slate-700">Nama kontak</label>
            <input id="debt-contact" value={contactName} onChange={(event) => setContactName(event.target.value)} maxLength={100} required className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" placeholder="Contoh: Bu Siti" />
          </div>
          <div>
            <label htmlFor="debt-phone" className="mb-1.5 block text-xs font-semibold text-slate-700">Nomor telepon <span className="font-normal text-slate-400">(opsional)</span></label>
            <input id="debt-phone" type="tel" value={phone} onChange={(event) => setPhone(event.target.value)} maxLength={30} className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" placeholder="081234567890" />
          </div>
        </div>
        <div>
          <label htmlFor="debt-amount" className="mb-1.5 block text-xs font-semibold text-slate-700">Nominal</label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm font-semibold text-slate-400">Rp</span>
            <input id="debt-amount" type="text" inputMode="numeric" value={amountInput} onChange={(event) => handleAmountChange(event.target.value)} required className="w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-3 text-sm font-semibold focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" placeholder="0" />
          </div>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="debt-transaction-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Tanggal transaksi</label>
            <input id="debt-transaction-date" type="date" value={transactionDate} onChange={(event) => setTransactionDate(event.target.value)} required className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" />
          </div>
          <div>
            <label htmlFor="debt-due-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Jatuh tempo</label>
            <input id="debt-due-date" type="date" value={dueDate} min={transactionDate || undefined} onChange={(event) => setDueDate(event.target.value)} required className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" />
          </div>
        </div>
        <div>
          <label htmlFor="debt-note" className="mb-1.5 block text-xs font-semibold text-slate-700">Catatan <span className="font-normal text-slate-400">(opsional)</span></label>
          <textarea id="debt-note" value={note} onChange={(event) => setNote(event.target.value)} rows={2} maxLength={500} className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" placeholder="Detail barang, kesepakatan, atau keterangan lain" />
        </div>
        <div className="flex justify-end gap-2 pt-1">
          <Button variant="secondary" onClick={onClose} disabled={isPending}>Batal</Button>
          <Button type="submit" disabled={isPending} icon={isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : undefined}>
            {isPending ? 'Menyimpan...' : 'Simpan catatan'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}

function PaymentModal({
  isOpen,
  onClose,
  debt,
}: {
  isOpen: boolean
  onClose: () => void
  debt: DebtRow | null
}) {
  const { pay } = useDebtMutations()
  const [amountInput, setAmountInput] = useState('')
  const [paymentDate, setPaymentDate] = useState('')
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)

  const remaining = debt ? debtRemaining(debt) : 0

  useEffect(() => {
    if (!isOpen || !debt) return
    setAmountInput(formatNumber(remaining))
    setPaymentDate(formatDateInput(new Date()))
    setNote('')
    setError(null)
  }, [isOpen, debt, remaining])

  const isPending = pay.isPending
  const amount = Number(amountInput.replace(/\D/g, '')) || 0

  const handleAmountChange = (value: string) => {
    const digits = value.replace(/\D/g, '').slice(0, 15)
    setAmountInput(digits ? formatNumber(Number(digits)) : '')
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    setError(null)
    if (!debt) return
    if (amount <= 0) {
      setError('Nominal pembayaran harus lebih dari Rp 0.')
      return
    }
    if (amount > remaining) {
      setError(`Pembayaran melebihi sisa tagihan (${formatCurrency(remaining)}).`)
      return
    }
    const date = parseDateInput(paymentDate)
    if (!date) {
      setError('Tanggal pembayaran tidak valid.')
      return
    }
    const label = debt.type === 'receivable' ? 'piutang' : 'utang'
    try {
      await pay.mutateAsync({
        paymentId: crypto.randomUUID(),
        ledgerTransactionId: crypto.randomUUID(),
        debtId: debt.id,
        amount,
        paymentDate: date.toISOString(),
        note,
        ledgerDescription: `Pembayaran ${label} - ${debt.contact_name}`,
      })
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal mencatat pembayaran.')
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Catat pembayaran"
      description={debt ? `${debt.contact_name} · sisa ${formatCurrency(remaining)}` : undefined}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}
        <div>
          <label htmlFor="payment-amount" className="mb-1.5 block text-xs font-semibold text-slate-700">Nominal pembayaran</label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm font-semibold text-slate-400">Rp</span>
            <input id="payment-amount" type="text" inputMode="numeric" value={amountInput} onChange={(event) => handleAmountChange(event.target.value)} required className="w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-3 text-sm font-semibold focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" />
          </div>
          <p className="mt-1 text-[11px] text-slate-500">Sisa tagihan saat ini {formatCurrency(remaining)}.</p>
        </div>
        <div>
          <label htmlFor="payment-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Tanggal pembayaran</label>
          <input id="payment-date" type="date" value={paymentDate} onChange={(event) => setPaymentDate(event.target.value)} required className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" />
        </div>
        <div>
          <label htmlFor="payment-note" className="mb-1.5 block text-xs font-semibold text-slate-700">Catatan <span className="font-normal text-slate-400">(opsional)</span></label>
          <input id="payment-note" value={note} onChange={(event) => setNote(event.target.value)} maxLength={200} className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100" placeholder="Contoh: Transfer BCA" />
        </div>
        <p className="rounded-lg bg-blue-50 px-3 py-2 text-[11px] text-blue-700">
          Pembayaran otomatis dicatat sebagai transaksi {debt?.type === 'receivable' ? 'pemasukan' : 'pengeluaran'} tunai.
        </p>
        <div className="flex justify-end gap-2 pt-1">
          <Button variant="secondary" onClick={onClose} disabled={isPending}>Batal</Button>
          <Button type="submit" disabled={isPending} icon={isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : undefined}>
            {isPending ? 'Menyimpan...' : 'Simpan pembayaran'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
