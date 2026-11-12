import { useEffect, useMemo, useState } from 'react'
import { AlertCircle, Loader2 } from 'lucide-react'
import { Modal } from '../ui/Modal'
import { Button } from '../ui/Button'
import { useAuth } from '../../context/AuthContext'
import { useCategories } from '../../hooks/useCategories'
import { useTransactionMutations } from '../../hooks/useTransactions'
import type { TransactionRow } from '../../services/transactions.service'
import type { TransactionType } from '../../types/database.types'
import { formatDateTimeInput, formatNumber } from '../../utils/format'
import { fallbackCategories, paymentMethods } from '../../utils/categories'

interface Props {
  isOpen: boolean
  onClose: () => void
  transaction: TransactionRow | null
  defaultType?: TransactionType
}

export function TransactionFormModal({ isOpen, onClose, transaction, defaultType = 'expense' }: Props) {
  const { currentBusiness, user, permissions } = useAuth()
  const categoriesQuery = useCategories()
  const { create, update } = useTransactionMutations()
  const [type, setType] = useState<TransactionType>(transaction?.type || defaultType)
  const [dateInput, setDateInput] = useState(() => formatDateTimeInput(transaction?.transaction_date || new Date()))
  const [amountInput, setAmountInput] = useState(() => transaction ? formatNumber(transaction.amount) : '')
  const [categoryId, setCategoryId] = useState(transaction?.category_id || '')
  const [description, setDescription] = useState(transaction?.description || '')
  const [note, setNote] = useState(transaction?.note || '')
  const [paymentMethodId, setPaymentMethodId] = useState(transaction?.payment_method_id || 'cash')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!isOpen) return
    setType(transaction?.type || defaultType)
    setDateInput(formatDateTimeInput(transaction?.transaction_date || new Date()))
    setAmountInput(transaction ? formatNumber(transaction.amount) : '')
    setCategoryId(transaction?.category_id || '')
    setDescription(transaction?.description || '')
    setNote(transaction?.note || '')
    setPaymentMethodId(transaction?.payment_method_id || 'cash')
    setError(null)
  }, [isOpen, transaction, defaultType])

  const allCategories = categoriesQuery.data?.length
    ? categoriesQuery.data.map((category) => ({
      id: category.id,
      name: category.name,
      type: category.type,
      color: category.color,
      icon: category.icon,
      is_active: category.is_active,
    }))
    : fallbackCategories

  const categoryOptions = useMemo(() => {
    const active = allCategories.filter((category) => category.type === type && category.is_active !== false)
    if (categoryId && !active.some((category) => category.id === categoryId)) {
      const current = allCategories.find((category) => category.id === categoryId)
      if (current) return [current, ...active]
    }
    return active
  }, [allCategories, type, categoryId])

  useEffect(() => {
    if (!categoryId || !categoryOptions.some((category) => category.id === categoryId)) {
      setCategoryId(categoryOptions[0]?.id || '')
    }
  }, [categoryOptions, categoryId])

  const isEditing = !!transaction
  const canSubmit = isEditing ? permissions.canEditTransaction : permissions.canCreateTransaction
  const amount = Number(amountInput.replace(/\D/g, '')) || 0
  const isPending = create.isPending || update.isPending

  const handleAmountChange = (value: string) => {
    const digits = value.replace(/\D/g, '').slice(0, 15)
    setAmountInput(digits ? formatNumber(Number(digits)) : '')
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    setError(null)
    if (!canSubmit) {
      setError('Peran Anda tidak memiliki izin untuk menyimpan transaksi.')
      return
    }
    if (amount <= 0) {
      setError('Nominal transaksi harus lebih dari Rp 0.')
      return
    }
    if (!categoryId) {
      setError('Pilih kategori transaksi.')
      return
    }
    if (!description.trim()) {
      setError('Deskripsi transaksi wajib diisi.')
      return
    }
    const parsedDate = new Date(dateInput)
    if (Number.isNaN(parsedDate.getTime())) {
      setError('Tanggal transaksi tidak valid.')
      return
    }

    const payload = {
      type,
      amount,
      categoryId,
      paymentMethodId,
      transactionDate: parsedDate.toISOString(),
      description: description.trim(),
      note: note.trim(),
    }

    try {
      if (isEditing) {
        await update.mutateAsync({ id: transaction.id, input: payload })
      } else {
        await create.mutateAsync(payload)
      }
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal menyimpan transaksi.')
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'Ubah transaksi' : 'Catat transaksi baru'}
      description={currentBusiness?.business_name ? `Untuk ${currentBusiness.business_name}` : undefined}
      size="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div>
          <span className="mb-1.5 block text-xs font-semibold text-slate-700">Jenis transaksi</span>
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => setType('income')}
              className={`rounded-lg px-3 py-2 text-sm font-semibold transition ${type === 'income' ? 'bg-white text-emerald-700 shadow-sm' : 'text-slate-500'}`}
            >
              Pemasukan
            </button>
            <button
              type="button"
              onClick={() => setType('expense')}
              className={`rounded-lg px-3 py-2 text-sm font-semibold transition ${type === 'expense' ? 'bg-white text-rose-700 shadow-sm' : 'text-slate-500'}`}
            >
              Pengeluaran
            </button>
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="transaction-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Tanggal & waktu</label>
            <input
              id="transaction-date"
              type="datetime-local"
              value={dateInput}
              onChange={(event) => setDateInput(event.target.value)}
              required
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            />
          </div>
          <div>
            <label htmlFor="transaction-amount" className="mb-1.5 block text-xs font-semibold text-slate-700">Nominal</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm font-semibold text-slate-400">Rp</span>
              <input
                id="transaction-amount"
                type="text"
                inputMode="numeric"
                value={amountInput}
                onChange={(event) => handleAmountChange(event.target.value)}
                placeholder="0"
                required
                className="w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-3 text-sm font-semibold text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              />
            </div>
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="transaction-category" className="mb-1.5 block text-xs font-semibold text-slate-700">Kategori</label>
            <select
              id="transaction-category"
              value={categoryId}
              onChange={(event) => setCategoryId(event.target.value)}
              required
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            >
              {categoryOptions.length === 0 && <option value="">Belum ada kategori</option>}
              {categoryOptions.map((category) => (
                <option key={category.id} value={category.id}>
                  {category.name}{category.is_active === false ? ' (nonaktif)' : ''}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="transaction-method" className="mb-1.5 block text-xs font-semibold text-slate-700">Metode pembayaran</label>
            <select
              id="transaction-method"
              value={paymentMethodId}
              onChange={(event) => setPaymentMethodId(event.target.value)}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            >
              {paymentMethods.map((method) => (
                <option key={method.id} value={method.id}>{method.label}</option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <label htmlFor="transaction-description" className="mb-1.5 block text-xs font-semibold text-slate-700">Deskripsi</label>
          <input
            id="transaction-description"
            type="text"
            value={description}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="Contoh: Penjualan harian"
            maxLength={200}
            required
            className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
          />
        </div>

        <div>
          <label htmlFor="transaction-note" className="mb-1.5 block text-xs font-semibold text-slate-700">Catatan <span className="font-normal text-slate-400">(opsional)</span></label>
          <textarea
            id="transaction-note"
            value={note}
            onChange={(event) => setNote(event.target.value)}
            rows={2}
            maxLength={500}
            placeholder="Detail tambahan, nomor nota, atau keterangan lain"
            className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
          />
        </div>

        <p className="rounded-lg bg-slate-50 px-3 py-2 text-[11px] text-slate-500">
          Metode pembayaran hanya untuk pencatatan. CatatUang tidak memproses transfer uang.
          {user?.email ? ` Dicatat oleh ${user.email}.` : ''}
        </p>

        <div className="flex justify-end gap-2 pt-1">
          <Button variant="secondary" onClick={onClose} disabled={isPending}>Batal</Button>
          <Button type="submit" disabled={isPending || !canSubmit} icon={isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : undefined}>
            {isPending ? 'Menyimpan...' : isEditing ? 'Simpan perubahan' : 'Simpan transaksi'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
