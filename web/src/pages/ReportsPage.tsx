import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { BarChart3, Download, FileSpreadsheet, Loader2, ReceiptText } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useCategories } from '../hooks/useCategories'
import { listTransactionsForRange } from '../services/transactions.service'
import { categoryColor, categoryLabel, paymentMethodLabel, paymentMethods } from '../utils/categories'
import {
  addDays,
  formatCompactCurrency,
  formatCurrency,
  formatDate,
  formatDateInput,
  getPresetRange,
  parseDateInput,
  sanitizeFileName,
} from '../utils/format'
import { exportReportExcel, exportReportPdf } from '../utils/export'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'
import { EmptyState, ErrorState, LoadingState } from '../components/ui/States'

type Preset = 'today' | 'week' | 'month' | 'year' | 'custom'

const presetLabels: Array<{ value: Exclude<Preset, 'custom'>; label: string }> = [
  { value: 'today', label: 'Hari ini' },
  { value: 'week', label: 'Minggu ini' },
  { value: 'month', label: 'Bulan ini' },
  { value: 'year', label: 'Tahun ini' },
]

const initialRange = getPresetRange('month')

export function ReportsPage() {
  const { currentBusiness } = useAuth()
  const businessId = currentBusiness?.business_id
  const categoriesQuery = useCategories()
  const categories = categoriesQuery.data ?? []
  const [preset, setPreset] = useState<Preset>('month')
  const [startInput, setStartInput] = useState(() => formatDateInput(initialRange.start))
  const [endInput, setEndInput] = useState(() => formatDateInput(addDays(initialRange.end, -1)))
  const [exporting, setExporting] = useState<'pdf' | 'excel' | null>(null)
  const [exportError, setExportError] = useState<string | null>(null)

  const startDate = parseDateInput(startInput)
  const endDate = parseDateInput(endInput)
  const startIso = startDate?.toISOString()
  const endIso = endDate ? addDays(endDate, 1).toISOString() : undefined

  const reportQuery = useQuery({
    queryKey: ['reports', businessId, startIso, endIso],
    queryFn: () => listTransactionsForRange(businessId!, startIso!, endIso!),
    enabled: !!businessId && !!startIso && !!endIso && startDate! < endDate!,
  })

  const rows = reportQuery.data ?? []

  const summary = useMemo(() => {
    let income = 0
    let expense = 0
    let incomeCount = 0
    let expenseCount = 0
    for (const row of rows) {
      if (row.type === 'income') {
        income += row.amount
        incomeCount += 1
      } else {
        expense += row.amount
        expenseCount += 1
      }
    }
    return { income, expense, net: income - expense, incomeCount, expenseCount }
  }, [rows])

  const categoryBreakdown = useMemo(() => {
    const map = new Map<string, { id: string; name: string; color: string; type: 'income' | 'expense'; amount: number; count: number }>()
    for (const row of rows) {
      const key = `${row.type}:${row.category_id}`
      const existing = map.get(key)
      if (existing) {
        existing.amount += row.amount
        existing.count += 1
      } else {
        map.set(key, {
          id: row.category_id,
          name: categoryLabel(categories, row.category_id),
          color: categoryColor(categories, row.category_id),
          type: row.type,
          amount: row.amount,
          count: 1,
        })
      }
    }
    return [...map.values()].sort((a, b) => b.amount - a.amount)
  }, [rows, categories])

  const paymentBreakdown = useMemo(() => {
    const map = new Map<string, number>()
    for (const row of rows) {
      map.set(row.payment_method_id, (map.get(row.payment_method_id) ?? 0) + row.amount)
    }
    return paymentMethods.map((method) => ({ label: method.label, amount: map.get(method.id) ?? 0 }))
  }, [rows])

  const chartData = useMemo(() => {
    const spanDays = startDate && endDate
      ? Math.max(1, Math.round((endDate.getTime() - startDate.getTime()) / 86_400_000) + 1)
      : 1
    const monthly = spanDays > 62
    const map = new Map<string, { label: string; income: number; expense: number }>()
    const sorted = [...rows].sort((a, b) => new Date(a.transaction_date).getTime() - new Date(b.transaction_date).getTime())
    for (const row of sorted) {
      const date = new Date(row.transaction_date)
      if (Number.isNaN(date.getTime())) continue
      const key = monthly ? `${date.getFullYear()}-${date.getMonth()}` : formatDateInput(date)
      const label = monthly
        ? formatDate(date, { month: 'short', year: 'numeric' })
        : formatDate(date, { day: '2-digit', month: 'short' })
      const current = map.get(key) ?? { label, income: 0, expense: 0 }
      if (row.type === 'income') current.income += row.amount
      else current.expense += row.amount
      map.set(key, current)
    }
    return [...map.values()]
  }, [rows, startDate, endDate])

  const periodLabel = startDate && endDate
    ? `${formatDate(startDate, { dateStyle: 'medium' })} - ${formatDate(endDate, { dateStyle: 'medium' })}`
    : 'Periode tidak valid'

  const applyPreset = (nextPreset: Exclude<Preset, 'custom'>) => {
    const range = getPresetRange(nextPreset)
    setPreset(nextPreset)
    setStartInput(formatDateInput(range.start))
    setEndInput(formatDateInput(addDays(range.end, -1)))
  }

  const buildExportPayload = () => ({
    title: 'Laporan Keuangan',
    businessName: currentBusiness?.business_name || 'CatatUang',
    periodLabel,
    summaryLines: [
      `Total pemasukan: ${formatCurrency(summary.income)} (${summary.incomeCount} transaksi)`,
      `Total pengeluaran: ${formatCurrency(summary.expense)} (${summary.expenseCount} transaksi)`,
      `Arus kas bersih: ${formatCurrency(summary.net)}`,
      `Jumlah transaksi: ${rows.length}`,
    ],
    headers: ['Tanggal', 'Deskripsi', 'Kategori', 'Jenis', 'Metode', 'Nominal', 'Catatan'],
    rows: rows.map((row) => [
      formatDate(row.transaction_date, { dateStyle: 'medium' }),
      row.description,
      categoryLabel(categories, row.category_id),
      row.type === 'income' ? 'Pemasukan' : 'Pengeluaran',
      paymentMethodLabel(row.payment_method_id),
      row.type === 'income' ? row.amount : -row.amount,
      row.note,
    ]),
    fileName: `CatatUang-Laporan-${sanitizeFileName(startInput)}-${sanitizeFileName(endInput)}`,
  })

  const handleExportPdf = () => {
    setExportError(null)
    setExporting('pdf')
    try {
      exportReportPdf(buildExportPayload())
    } catch (error) {
      setExportError(error instanceof Error ? error.message : 'Gagal membuat PDF.')
    } finally {
      setExporting(null)
    }
  }

  const handleExportExcel = async () => {
    setExportError(null)
    setExporting('excel')
    try {
      await exportReportExcel(buildExportPayload())
    } catch (error) {
      setExportError(error instanceof Error ? error.message : 'Gagal membuat Excel.')
    } finally {
      setExporting(null)
    }
  }

  const canExport = rows.length > 0 && !reportQuery.isLoading

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">Laporan Keuangan</h1>
          <p className="mt-1 text-sm text-slate-500">
            Analisis pemasukan, pengeluaran, dan arus kas usaha per periode.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            variant="secondary"
            icon={exporting === 'pdf' ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
            disabled={!canExport || !!exporting}
            onClick={handleExportPdf}
          >
            PDF
          </Button>
          <Button
            variant="secondary"
            icon={exporting === 'excel' ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileSpreadsheet className="h-4 w-4" />}
            disabled={!canExport || !!exporting}
            onClick={() => void handleExportExcel()}
          >
            Excel
          </Button>
        </div>
      </div>

      {exportError && <ErrorState title="Ekspor gagal" message={exportError} onRetry={() => setExportError(null)} />}

      <Card className="p-4 sm:p-5">
        <div className="flex flex-wrap gap-2">
          {presetLabels.map((option) => (
            <button
              key={option.value}
              type="button"
              onClick={() => applyPreset(option.value)}
              className={`rounded-xl border px-3 py-2 text-xs font-semibold transition ${preset === option.value ? 'border-[#2563EB] bg-[#EFF6FF] text-[#2563EB]' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'}`}
            >
              {option.label}
            </button>
          ))}
          <Badge tone="slate">{periodLabel}</Badge>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <label className="text-xs font-semibold text-slate-600" htmlFor="report-start">Dari</label>
          <input
            id="report-start"
            type="date"
            value={startInput}
            onChange={(event) => {
              setPreset('custom')
              setStartInput(event.target.value)
            }}
            className="rounded-xl border border-slate-300 px-3 py-2 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
          />
          <label className="text-xs font-semibold text-slate-600" htmlFor="report-end">Sampai</label>
          <input
            id="report-end"
            type="date"
            value={endInput}
            min={startInput || undefined}
            onChange={(event) => {
              setPreset('custom')
              setEndInput(event.target.value)
            }}
            className="rounded-xl border border-slate-300 px-3 py-2 text-sm focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
          />
        </div>
      </Card>

      {!startDate || !endDate || startDate >= endDate ? (
        <ErrorState title="Periode tidak valid" message="Pastikan tanggal awal lebih kecil atau sama dengan tanggal akhir." />
      ) : reportQuery.isLoading ? (
        <LoadingState message="Menyusun laporan..." />
      ) : reportQuery.isError ? (
        <ErrorState
          message={reportQuery.error instanceof Error ? reportQuery.error.message : 'Gagal memuat laporan.'}
          onRetry={() => void reportQuery.refetch()}
        />
      ) : rows.length === 0 ? (
        <EmptyState
          title="Belum ada transaksi pada periode ini"
          description="Pilih periode lain atau catat transaksi terlebih dahulu."
          icon={<BarChart3 className="h-6 w-6" />}
        />
      ) : (
        <>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <SummaryCard label="Pemasukan" value={summary.income} tone="emerald" caption={`${summary.incomeCount} transaksi`} />
            <SummaryCard label="Pengeluaran" value={summary.expense} tone="rose" caption={`${summary.expenseCount} transaksi`} />
            <SummaryCard label="Arus kas bersih" value={summary.net} tone={summary.net >= 0 ? 'blue' : 'rose'} caption="Pemasukan - pengeluaran" />
            <SummaryCard label="Total transaksi" value={rows.length} tone="slate" caption="Tercatat pada periode" isCount />
          </div>

          <div className="grid gap-4 xl:grid-cols-3">
            <Card className="p-4 xl:col-span-2">
              <h2 className="text-sm font-bold text-slate-800">Tren pemasukan & pengeluaran</h2>
              <div className="mt-4 h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData} margin={{ top: 8, right: 8, left: -12, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                    <XAxis dataKey="label" tick={{ fontSize: 10, fill: '#64748B' }} interval="preserveStartEnd" />
                    <YAxis tickFormatter={(value: number) => formatCompactCurrency(Number(value))} tick={{ fontSize: 10, fill: '#64748B' }} />
                    <Tooltip
                      formatter={(value) => {
                        const numericValue = typeof value === 'number' ? value : Number(value ?? 0)
                        return formatCurrency(numericValue)
                      }}
                      contentStyle={{ borderRadius: 12, borderColor: '#E2E8F0', fontSize: 12 }}
                    />
                    <Legend wrapperStyle={{ fontSize: 12 }} />
                    <Bar dataKey="income" name="Pemasukan" fill="#16A34A" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="expense" name="Pengeluaran" fill="#DC2626" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card className="p-4">
              <h2 className="text-sm font-bold text-slate-800">Metode pembayaran</h2>
              <ul className="mt-3 space-y-2">
                {paymentBreakdown.map((method) => (
                  <li key={method.label} className="flex items-center justify-between gap-2 rounded-lg bg-slate-50 px-3 py-2 text-xs">
                    <span className="text-slate-600">{method.label}</span>
                    <span className="font-bold text-slate-800">{formatCurrency(method.amount)}</span>
                  </li>
                ))}
              </ul>
            </Card>
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Card className="p-4">
              <h2 className="text-sm font-bold text-slate-800">Rincian kategori</h2>
              <ul className="mt-3 space-y-3">
                {categoryBreakdown.map((item) => {
                  const total = item.type === 'income' ? summary.income : summary.expense
                  const percent = total > 0 ? (item.amount / total) * 100 : 0
                  return (
                    <li key={`${item.type}-${item.id}`}>
                      <div className="flex items-center justify-between gap-2 text-xs">
                        <span className="flex min-w-0 items-center gap-2">
                          <span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: item.color }} />
                          <span className="truncate text-slate-700">{item.name}</span>
                          <Badge tone={item.type === 'income' ? 'green' : 'red'}>{item.type === 'income' ? 'Masuk' : 'Keluar'}</Badge>
                        </span>
                        <span className="shrink-0 font-semibold text-slate-800">{formatCurrency(item.amount)}</span>
                      </div>
                      <div className="mt-1.5 h-1.5 overflow-hidden rounded-full bg-slate-100">
                        <div className="h-full rounded-full" style={{ width: `${percent}%`, backgroundColor: item.color }} />
                      </div>
                    </li>
                  )
                })}
              </ul>
            </Card>

            <Card className="p-4">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-800">Ringkasan periode</h2>
                <Badge tone="blue"><ReceiptText className="h-3 w-3" /> {rows.length} data</Badge>
              </div>
              <dl className="mt-3 space-y-2 text-sm">
                <div className="flex justify-between rounded-lg bg-emerald-50 px-3 py-2">
                  <dt className="text-emerald-700">Pemasukan</dt>
                  <dd className="font-bold text-emerald-800">{formatCurrency(summary.income)}</dd>
                </div>
                <div className="flex justify-between rounded-lg bg-rose-50 px-3 py-2">
                  <dt className="text-rose-700">Pengeluaran</dt>
                  <dd className="font-bold text-rose-800">{formatCurrency(summary.expense)}</dd>
                </div>
                <div className="flex justify-between rounded-lg bg-slate-50 px-3 py-2">
                  <dt className="text-slate-600">Arus kas bersih</dt>
                  <dd className={`font-bold ${summary.net >= 0 ? 'text-emerald-700' : 'text-rose-700'}`}>{formatCurrency(summary.net)}</dd>
                </div>
              </dl>
            </Card>
          </div>

          <Card className="overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] text-left text-sm">
                <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-4 py-3 font-semibold">Tanggal</th>
                    <th className="px-4 py-3 font-semibold">Deskripsi</th>
                    <th className="px-4 py-3 font-semibold">Kategori</th>
                    <th className="px-4 py-3 font-semibold">Metode</th>
                    <th className="px-4 py-3 text-right font-semibold">Nominal</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {rows.slice(0, 100).map((row) => (
                    <tr key={row.id} className="hover:bg-slate-50/60">
                      <td className="whitespace-nowrap px-4 py-2.5 text-xs text-slate-500">{formatDate(row.transaction_date, { dateStyle: 'medium' })}</td>
                      <td className="max-w-[280px] truncate px-4 py-2.5 text-slate-700">{row.description || '-'}</td>
                      <td className="px-4 py-2.5 text-xs text-slate-600">{categoryLabel(categories, row.category_id)}</td>
                      <td className="px-4 py-2.5 text-xs text-slate-600">{paymentMethodLabel(row.payment_method_id)}</td>
                      <td className={`whitespace-nowrap px-4 py-2.5 text-right font-semibold ${row.type === 'income' ? 'text-emerald-700' : 'text-rose-700'}`}>
                        {row.type === 'income' ? '+' : '-'}{formatCurrency(row.amount)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {rows.length > 100 && (
              <p className="border-t border-slate-100 px-4 py-3 text-xs text-slate-500">
                Menampilkan 100 dari {rows.length} transaksi. Ekspor PDF/Excel memuat seluruh data.
              </p>
            )}
          </Card>
        </>
      )}
    </div>
  )
}

function SummaryCard({
  label,
  value,
  tone,
  caption,
  isCount = false,
}: {
  label: string
  value: number
  tone: 'emerald' | 'rose' | 'blue' | 'slate'
  caption: string
  isCount?: boolean
}) {
  const tones = {
    emerald: 'text-emerald-700 bg-emerald-50',
    rose: 'text-rose-700 bg-rose-50',
    blue: 'text-[#2563EB] bg-[#EFF6FF]',
    slate: 'text-slate-700 bg-slate-100',
  }
  return (
    <Card className="p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{label}</p>
      <p className={`mt-2 inline-flex rounded-lg px-2 py-1 text-lg font-bold ${tones[tone]}`}>
        {isCount ? value : formatCurrency(value)}
      </p>
      <p className="mt-1 text-[11px] text-slate-500">{caption}</p>
    </Card>
  )
}
