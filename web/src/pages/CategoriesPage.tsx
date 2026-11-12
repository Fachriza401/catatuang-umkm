import { useEffect, useMemo, useState } from 'react'
import { AlertCircle, Loader2, Pencil, Plus, Tags, Trash2 } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useCategories, useCategoryMutations } from '../hooks/useCategories'
import type { CategoryRow } from '../services/categories.service'
import type { TransactionType } from '../types/database.types'
import { categoryColorOptions, categoryIconOptions } from '../utils/categories'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'
import { Modal } from '../components/ui/Modal'
import { ConfirmDialog } from '../components/ui/ConfirmDialog'
import { EmptyState, ErrorState, LoadingState } from '../components/ui/States'

const iconLabels: Record<string, string> = {
  tag: 'Label',
  'shopping-bag': 'Belanja',
  landmark: 'Bank / Modal',
  'plus-circle': 'Pemasukan lain',
  package: 'Bahan baku',
  settings: 'Operasional',
  users: 'Karyawan',
  home: 'Tempat',
  truck: 'Transportasi',
  megaphone: 'Pemasaran',
  receipt: 'Struk',
  coffee: 'Kopi',
  utensils: 'Makanan',
  wrench: 'Perbaikan',
  'graduation-cap': 'Pendidikan',
  'heart-pulse': 'Kesehatan',
}

export function CategoriesPage() {
  const { permissions } = useAuth()
  const categoriesQuery = useCategories()
  const { update, remove } = useCategoryMutations()
  const [type, setType] = useState<TransactionType>('income')
  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<CategoryRow | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<CategoryRow | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const categories = categoriesQuery.data ?? []
  const filtered = useMemo(() => categories.filter((category) => category.type === type), [categories, type])
  const canManage = permissions.canManageSettings

  const openCreate = () => {
    setEditing(null)
    setActionError(null)
    setFormOpen(true)
  }

  const openEdit = (category: CategoryRow) => {
    setEditing(category)
    setActionError(null)
    setFormOpen(true)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setActionError(null)
    try {
      await remove.mutateAsync(deleteTarget.id)
      setDeleteTarget(null)
    } catch (error) {
      setDeleteTarget(null)
      setActionError(error instanceof Error ? error.message : 'Gagal menghapus kategori.')
    }
  }

  const toggleActive = async (category: CategoryRow) => {
    setActionError(null)
    try {
      await update.mutateAsync({ id: category.id, input: { is_active: !category.is_active } })
    } catch (error) {
      setActionError(error instanceof Error ? error.message : 'Gagal mengubah status kategori.')
    }
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">Kategori</h1>
          <p className="mt-1 text-sm text-slate-500">
            Kelompokkan pemasukan dan pengeluaran agar laporan lebih rapi.
          </p>
        </div>
        {canManage && (
          <Button icon={<Plus className="h-4 w-4" />} onClick={openCreate}>
            Tambah kategori
          </Button>
        )}
      </div>

      {actionError && (
        <ErrorState title="Aksi gagal" message={actionError} onRetry={() => setActionError(null)} />
      )}

      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => setType('income')}
          className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${type === 'income' ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'}`}
        >
          Pemasukan ({categories.filter((category) => category.type === 'income').length})
        </button>
        <button
          type="button"
          onClick={() => setType('expense')}
          className={`rounded-xl border px-4 py-2 text-sm font-semibold transition ${type === 'expense' ? 'border-rose-200 bg-rose-50 text-rose-700' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'}`}
        >
          Pengeluaran ({categories.filter((category) => category.type === 'expense').length})
        </button>
      </div>

      {categoriesQuery.isLoading ? (
        <LoadingState message="Memuat kategori..." />
      ) : categoriesQuery.isError ? (
        <ErrorState
          message={categoriesQuery.error instanceof Error ? categoriesQuery.error.message : 'Gagal memuat kategori.'}
          onRetry={() => void categoriesQuery.refetch()}
        />
      ) : filtered.length === 0 ? (
        <EmptyState
          title="Belum ada kategori"
          description={`Tambahkan kategori ${type === 'income' ? 'pemasukan' : 'pengeluaran'} pertama Anda.`}
          icon={<Tags className="h-6 w-6" />}
          action={canManage ? <Button icon={<Plus className="h-4 w-4" />} onClick={openCreate}>Tambah kategori</Button> : undefined}
        />
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {filtered.map((category) => (
            <Card key={category.id} className={`p-4 transition ${category.is_active ? '' : 'opacity-60'}`}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 items-center gap-3">
                  <span
                    className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-white"
                    style={{ backgroundColor: category.color }}
                  >
                    <Tags className="h-5 w-5" />
                  </span>
                  <div className="min-w-0">
                    <p className="truncate text-sm font-bold text-slate-800">{category.name}</p>
                    <div className="mt-1 flex flex-wrap gap-1">
                      {category.is_default && <Badge tone="slate">Bawaan</Badge>}
                      <Badge tone={category.is_active ? 'green' : 'amber'}>
                        {category.is_active ? 'Aktif' : 'Nonaktif'}
                      </Badge>
                    </div>
                  </div>
                </div>
                {canManage && (
                  <div className="flex shrink-0 gap-1">
                    <button
                      type="button"
                      onClick={() => openEdit(category)}
                      className="rounded-lg p-1.5 text-slate-400 hover:bg-blue-50 hover:text-[#2563EB]"
                      title="Ubah kategori"
                    >
                      <Pencil className="h-4 w-4" />
                    </button>
                    {!category.is_default && (
                      <button
                        type="button"
                        onClick={() => setDeleteTarget(category)}
                        className="rounded-lg p-1.5 text-slate-400 hover:bg-rose-50 hover:text-rose-600"
                        title="Hapus kategori"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                )}
              </div>
              <div className="mt-3 flex items-center justify-between border-t border-slate-100 pt-3">
                <span className="font-mono text-[10px] text-slate-400">{category.id}</span>
                {canManage && (
                  <button
                    type="button"
                    onClick={() => void toggleActive(category)}
                    disabled={update.isPending}
                    className="text-[11px] font-semibold text-[#2563EB] hover:underline disabled:opacity-50"
                  >
                    {category.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                  </button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      <CategoryFormModal
        isOpen={formOpen}
        onClose={() => setFormOpen(false)}
        category={editing}
        defaultType={type}
      />

      <ConfirmDialog
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void handleDelete()}
        title="Hapus kategori?"
        description={`Kategori "${deleteTarget?.name || ''}" akan dihapus permanen. Kategori yang sudah dipakai transaksi tidak dapat dihapus; nonaktifkan saja.`}
        confirmLabel="Hapus kategori"
        isLoading={remove.isPending}
      />
    </div>
  )
}

function CategoryFormModal({
  isOpen,
  onClose,
  category,
  defaultType,
}: {
  isOpen: boolean
  onClose: () => void
  category: CategoryRow | null
  defaultType: TransactionType
}) {
  const { create, update } = useCategoryMutations()
  const [name, setName] = useState('')
  const [type, setType] = useState<TransactionType>(defaultType)
  const [icon, setIcon] = useState('tag')
  const [color, setColor] = useState<string>(categoryColorOptions[0])
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!isOpen) return
    setName(category?.name || '')
    setType(category?.type || defaultType)
    setIcon(category?.icon || 'tag')
    setColor(category?.color || categoryColorOptions[0])
    setError(null)
  }, [isOpen, category, defaultType])

  const isPending = create.isPending || update.isPending

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    setError(null)
    if (name.trim().length < 2) {
      setError('Nama kategori minimal 2 karakter.')
      return
    }
    try {
      if (category) {
        await update.mutateAsync({ id: category.id, input: { name, type, icon, color } })
      } else {
        await create.mutateAsync({ name, type, icon, color })
      }
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Gagal menyimpan kategori.')
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={category ? 'Ubah kategori' : 'Tambah kategori'}
      description="Kategori berlaku khusus untuk usaha yang sedang dipilih."
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs text-rose-700">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}
        <div>
          <label htmlFor="category-name" className="mb-1.5 block text-xs font-semibold text-slate-700">Nama kategori</label>
          <input
            id="category-name"
            value={name}
            onChange={(event) => setName(event.target.value)}
            maxLength={50}
            required
            className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            placeholder="Contoh: Bahan Kemasan"
          />
        </div>
        <div>
          <span className="mb-1.5 block text-xs font-semibold text-slate-700">Jenis</span>
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1">
            <button type="button" onClick={() => setType('income')} className={`rounded-lg px-3 py-2 text-sm font-semibold ${type === 'income' ? 'bg-white text-emerald-700 shadow-sm' : 'text-slate-500'}`}>Pemasukan</button>
            <button type="button" onClick={() => setType('expense')} className={`rounded-lg px-3 py-2 text-sm font-semibold ${type === 'expense' ? 'bg-white text-rose-700 shadow-sm' : 'text-slate-500'}`}>Pengeluaran</button>
          </div>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="category-icon" className="mb-1.5 block text-xs font-semibold text-slate-700">Ikon</label>
            <select
              id="category-icon"
              value={icon}
              onChange={(event) => setIcon(event.target.value)}
              className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
            >
              {categoryIconOptions.map((option) => (
                <option key={option} value={option}>{iconLabels[option] || option}</option>
              ))}
            </select>
          </div>
          <div>
            <span className="mb-1.5 block text-xs font-semibold text-slate-700">Warna</span>
            <div className="flex flex-wrap gap-2 pt-1">
              {categoryColorOptions.map((option) => (
                <button
                  key={option}
                  type="button"
                  onClick={() => setColor(option)}
                  className={`h-8 w-8 rounded-full border-2 transition ${color === option ? 'border-slate-900 scale-110' : 'border-white'}`}
                  style={{ backgroundColor: option }}
                  aria-label={`Pilih warna ${option}`}
                  title={option}
                />
              ))}
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-slate-200 p-3">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">Pratinjau</p>
          <div className="mt-2 flex items-center gap-3">
            <span className="flex h-10 w-10 items-center justify-center rounded-xl text-white" style={{ backgroundColor: color }}>
              <Tags className="h-5 w-5" />
            </span>
            <div>
              <p className="text-sm font-bold text-slate-800">{name || 'Nama kategori'}</p>
              <p className="text-[11px] text-slate-500">{type === 'income' ? 'Pemasukan' : 'Pengeluaran'}</p>
            </div>
          </div>
        </div>
        <div className="flex justify-end gap-2 pt-1">
          <Button variant="secondary" onClick={onClose} disabled={isPending}>Batal</Button>
          <Button type="submit" disabled={isPending} icon={isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : undefined}>
            {isPending ? 'Menyimpan...' : 'Simpan kategori'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
