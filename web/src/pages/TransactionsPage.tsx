import { useEffect, useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router-dom'
import {
  ArrowDownLeft,
  ArrowUpRight,
  CalendarRange,
  Edit3,
  Eye,
  Plus,
  ReceiptText,
  Search,
  Trash2,
  X,
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useCategories } from '../hooks/useCategories'
import { useTransactionMutations, useTransactions } from '../hooks/useTransactions'
import { getTransaction, type TransactionRow } from '../services/transactions.service'
import type { TransactionType } from '../types/database.types'
import { categoryColor, categoryLabel, paymentMethodLabel, paymentMethods } from '../utils/categories'
import { addDays, formatCurrency, formatDate, formatDateTime, parseDateInput } from '../utils/format'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'
import { Modal } from '../components/ui/Modal'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { EmptyState, ErrorState, LoadingState } from '../components/ui/States'
import { Pagination } from '../components/ui/Pagination'
import { TransactionFormModal } from '../components/transactions/TransactionFormModal'

const PAGE_SIZE = 10

function useDebouncedValue<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])
  return debounced
}

export function TransactionsPage() {
  const { currentBusiness, permissions } = useAuth()
  const businessId = currentBusiness?.business_id
  const [searchParams, setSearchParams] = useSearchParams()
  const txParam = searchParams.get('tx')
  const categoriesQuery = useCategories()
  const { remove } = useTransactionMutations()

  const [search, setSearch] = useState('')
  const debouncedSearch = useDebouncedValue(search)
  const [type, setType] = useState<TransactionType | 'all'>('all')
  const [categoryId, setCategoryId] = useState('')
  const [paymentMethodId, setPaymentMethodId] = useState('')
  const [startInput, setStartInput] = useState('')
  const [endInput, setEndInput] = useState('')
  const [page, setPage] = useState(1)

  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<TransactionRow | null>(null)
  const [defaultType, setDefaultType] = useState<TransactionType>('expense')
  const [deleteTarget, setDeleteTarget] = useState<TransactionRow | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const startDate = parseDateInput(startInput)
  const endDate = parseDateInput(endInput)

  const filters = useMemo(() => ({
    search: debouncedSearch || undefined,
    type,
    categoryId: categoryId || undefined,
    paymentMethodId: paymentMethodId || undefined,
    start: startDate ? startDate.toISOString() : undefined,
    end: endDate ? addDays(endDate, 1).toISOString() : undefined,
    page,
    pageSize: PAGE_SIZE,
  }), [debouncedSearch, type, categoryId, paymentMethodId, startDate?.getTime(), endDate?.getTime(), page])

  const transactions = useTransactions(filters)
  const categories = categoriesQuery.data ?? []

  const detailQuery = useQuery({
    queryKey: ['transaction-detail', businessId, txParam],
    queryFn: () => getTransaction(businessId!, txParam!),
    enabled: !!businessId && !!txParam,
  })

  useEffect(() => {
    setPage(1)
  }, [debouncedSearch, type, categoryId, paymentMethodId, startInput, endInput])

  const resetFilters = () => {
    setSearch('')
    setType('all')
    setCategoryId('')
    setPaymentMethodId('')
    setStartInput('')
    setEndInput('')
    setPage(1)
  }

  const openCreate = (nextType: TransactionType) => {
    setEditing(null)
    setDefaultType(nextType)
    setActionError(null)
    setFormOpen(true)
  }

  const openEdit = (transaction: TransactionRow) => {
    setEditing(transaction)
    setActionError(null)
    setFormOpen(true)
    if (txParam) setSearchParams({})
  }

  const closeDetail = () => setSearchParams({})

  const handleDelete = async () => {
    if (!deleteTarget) return
    setActionError(null)
    try {
      await remove.mutateAsync(deleteTarget.id)
      setDeleteTarget(null)
      if (txParam === deleteTarget.id) setSearchParams({})
    } catch (error) {
      setActionError(error instanceof Error ? error.message : 'Gagal menghapus transaksi.')
    }
  }

  const total = transactions.data?.count ?? 0
  const rows = transactions.data?.rows ?? []

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">Transaksi</h1>
          <p className="mt-1 text-sm text-slate-500">
            Catat dan kelola seluruh pemasukan serta pengeluaran usaha.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          {permissions.canCreateTransaction && (
            <>
              <Button variant="success" icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('income')}>
                Pemasukan
              </Button>
              <Button variant="danger" icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('expense')}>
                Pengeluaran
              </Button>
            </>
          )}
        </div>
      </div>

      {actionError && (
        <ErrorState title="Aksi gagal" message={actionError} onRetry={() => setActionError(null)} />
      )}

      <Card className="p-4 sm:p-5">
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-6">
          <div className="relative xl:col-span-2">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Cari deskripsi atau catatan..."
              className="w-full rounded-xl border border-slate-300 py-2.5 pl-9 pr-3 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              aria-label="Cari transaksi"
            />
          </div>
          <select
            value={type}
            onChange={(event) => setType(event.target.value as TransactionType | 'all')}
            className="rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            aria-label="Filter jenis transaksi"
          >
            <option value="all">Semua jenis</option>
            <option value="income">Pemasukan</option>
            <option value="expense">Pengeluaran</option>
          </select>
          <select
            value={categoryId}
            onChange={(event) => setCategoryId(event.target.value)}
            className="rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            aria-label="Filter kategori"
          >
            <option value="">Semua kategori</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>{category.name}</option>
            ))}
          </select>
          <select
            value={paymentMethodId}
            onChange={(event) => setPaymentMethodId(event.target.value)}
            className="rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            aria-label="Filter metode pembayaran"
          >
            <option value="">Semua metode</option>
            {paymentMethods.map((method) => (
              <option key={method.id} value={method.id}>{method.label}</option>
            ))}
          </select>
          <div className="flex items-center gap-2">
            <input
              type="date"
              value={startInput}
              onChange={(event) => setStartInput(event.target.value)}
              className="min-w-0 flex-1 rounded-xl border border-slate-300 px-2.5 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              aria-label="Tanggal awal"
            />
            <span className="text-xs text-slate-400">s/d</span>
            <input
              type="date"
              value={endInput}
              min={startInput || undefined}
              onChange={(event) => setEndInput(event.target.value)}
              className="min-w-0 flex-1 rounded-xl border border-slate-300 px-2.5 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              aria-label="Tanggal akhir"
            />
          </div>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <Badge tone="blue"><CalendarRange className="h-3 w-3" /> {total} transaksi</Badge>
          {(search || type !== 'all' || categoryId || paymentMethodId || startInput || endInput) && (
            <button
              type="button"
              onClick={resetFilters}
              className="inline-flex items-center gap-1 rounded-full border border-slate-200 px-2.5 py-1 text-[11px] font-semibold text-slate-600 hover:bg-slate-50"
            >
              <X className="h-3 w-3" /> Reset filter
            </button>
          )}
        </div>
      </Card>

      {transactions.isLoading ? (
        <LoadingState message="Memuat transaksi..." />
      ) : transactions.isError ? (
        <ErrorState
          message={transactions.error instanceof Error ? transactions.error.message : 'Gagal memuat transaksi.'}
          onRetry={() => void transactions.refetch()}
        />
      ) : rows.length === 0 ? (
        <EmptyState
          title="Belum ada transaksi"
          description={
            search || type !== 'all' || categoryId || paymentMethodId || startInput || endInput
              ? 'Tidak ada transaksi yang cocok dengan filter. Coba ubah atau reset filter.'
              : 'Mulai catat pemasukan atau pengeluaran pertama usaha Anda.'
          }
          icon={<ReceiptText className="h-6 w-6" />}
          action={permissions.canCreateTransaction ? (
            <Button icon={<Plus className="h-4 w-4" />} onClick={() => openCreate('income')}>Catat transaksi</Button>
          ) : undefined}
        />
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[860px] text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">Tanggal</th>
                  <th className="px-4 py-3 font-semibold">Keterangan</th>
                  <th className="px-4 py-3 font-semibold">Kategori</th>
                  <th className="px-4 py-3 font-semibold">Metode</th>
                  <th className="px-4 py-3 font-semibold">Jenis</th>
                  <th className="px-4 py-3 text-right font-semibold">Nominal</th>
                  <th className="px-4 py-3 text-right font-semibold">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((transaction) => (
                  <tr key={transaction.id} className="hover:bg-slate-50/60">
                    <td className="whitespace-nowrap px-4 py-3 text-xs text-slate-500">
                      {formatDate(transaction.transaction_date, { dateStyle: 'medium' })}
                    </td>
                    <td className="max-w-[240px] px-4 py-3">
                      <p className="truncate font-medium text-slate-800">{transaction.description || 'Transaksi'}</p>
                      {transaction.note && <p className="mt-0.5 truncate text-[11px] text-slate-400">{transaction.note}</p>}
                    </td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1.5 text-xs text-slate-600">
                        <span className="h-2 w-2 rounded-full" style={{ backgroundColor: categoryColor(categories, transaction.category_id) }} />
                        {categoryLabel(categories, transaction.category_id)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-600">{paymentMethodLabel(transaction.payment_method_id)}</td>
                    <td className="px-4 py-3">
                      <Badge tone={transaction.type === 'income' ? 'green' : 'red'}>
                        {transaction.type === 'income' ? <ArrowDownLeft className="h-3 w-3" /> : <ArrowUpRight className="h-3 w-3" />}
                        {transaction.type === 'income' ? 'Masuk' : 'Keluar'}
                      </Badge>
                    </td>
                    <td className={`whitespace-nowrap px-4 py-3 text-right font-bold ${transaction.type === 'income' ? 'text-emerald-700' : 'text-rose-700'}`}>
                      {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount)}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <button
                          type="button"
                          onClick={() => setSearchParams({ tx: transaction.id })}
                          className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
                          title="Lihat detail"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        {permissions.canEditTransaction && (
                          <button
                            type="button"
                            onClick={() => openEdit(transaction)}
                            className="rounded-lg p-1.5 text-slate-400 hover:bg-blue-50 hover:text-[#2563EB]"
                            title="Ubah"
                          >
                            <Edit3 className="h-4 w-4" />
                          </button>
                        )}
                        {permissions.canDeleteTransaction && (
                          <button
                            type="button"
                            onClick={() => setDeleteTarget(transaction)}
                            className="rounded-lg p-1.5 text-slate-400 hover:bg-rose-50 hover:text-rose-600"
                            title="Hapus"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="px-4 pb-4">
            <Pagination page={page} pageSize={PAGE_SIZE} total={total} onPageChange={setPage} />
          </div>
        </Card>
      )}

      <TransactionFormModal
        isOpen={formOpen}
        onClose={() => setFormOpen(false)}
        transaction={editing}
        defaultType={defaultType}
      />

      <Modal
        isOpen={!!txParam && !!detailQuery.data}
        onClose={closeDetail}
        title="Detail transaksi"
        size="md"
      >
        {detailQuery.data && (
          <div className="space-y-4">
            <div className={`rounded-2xl p-4 ${detailQuery.data.type === 'income' ? 'bg-emerald-50' : 'bg-rose-50'}`}>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                {detailQuery.data.type === 'income' ? 'Pemasukan' : 'Pengeluaran'}
              </p>
              <p className={`mt-1 text-2xl font-bold ${detailQuery.data.type === 'income' ? 'text-emerald-700' : 'text-rose-700'}`}>
                {detailQuery.data.type === 'income' ? '+' : '-'}{formatCurrency(detailQuery.data.amount)}
              </p>
              <p className="mt-1 text-sm font-medium text-slate-700">{detailQuery.data.description}</p>
            </div>
            <dl className="grid gap-3 text-sm sm:grid-cols-2">
              <DetailItem label="Tanggal" value={formatDateTime(detailQuery.data.transaction_date)} />
              <DetailItem label="Kategori" value={categoryLabel(categories, detailQuery.data.category_id)} />
              <DetailItem label="Metode pembayaran" value={paymentMethodLabel(detailQuery.data.payment_method_id)} />
              <DetailItem label="Status" value="Aktif" />
              <DetailItem label="Dibuat" value={formatDateTime(detailQuery.data.created_at)} />
              <DetailItem label="Terakhir diubah" value={formatDateTime(detailQuery.data.updated_at)} />
            </dl>
            {detailQuery.data.note && (
              <div className="rounded-xl bg-slate-50 p-3">
                <p className="text-xs font-semibold text-slate-500">Catatan</p>
                <p className="mt-1 whitespace-pre-wrap text-sm text-slate-700">{detailQuery.data.note}</p>
              </div>
            )}
            <div className="flex justify-end gap-2 pt-2">
              {permissions.canEditTransaction && (
                <Button variant="secondary" icon={<Edit3 className="h-4 w-4" />} onClick={() => { if (detailQuery.data) openEdit(detailQuery.data) }}>
                  Ubah
                </Button>
              )}
              {permissions.canDeleteTransaction && (
                <Button variant="danger" icon={<Trash2 className="h-4 w-4" />} onClick={() => { if (detailQuery.data) setDeleteTarget(detailQuery.data) }}>
                  Hapus
                </Button>
              )}
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void handleDelete()}
        title="Hapus transaksi?"
        description={`Transaksi "${deleteTarget?.description || 'ini'}" akan dihapus dari laporan. Data tidak dapat dikembalikan dari antarmuka web.`}
        confirmLabel="Hapus transaksi"
        isLoading={remove.isPending}
      />
    </div>
  )
}

function DetailItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-3">
      <dt className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">{label}</dt>
      <dd className="mt-1 font-medium text-slate-700">{value}</dd>
    </div>
  )
}
