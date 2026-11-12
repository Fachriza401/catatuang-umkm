import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowDownLeft,
  ArrowRight,
  ArrowUpRight,
  CalendarDays,
  CheckCircle2,
  Clock3,
  HandCoins,
  ReceiptText,
  TrendingDown,
  TrendingUp,
  Users,
  Wallet,
} from 'lucide-react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { useAuth } from '../context/AuthContext'
import { useDashboard } from '../hooks/useDashboard'
import { useBusinessProfile } from '../hooks/useBusinessProfile'
import type { DashboardPeriod } from '../utils/dashboardPeriod'
import { formatCompactCurrency, formatCurrency, formatDate, formatDateTime, parseDateInput, percentChange, addDays } from '../utils/format'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { EmptyState, ErrorState, LoadingState } from '../components/ui/States'

const periodOptions: Array<{ value: DashboardPeriod; label: string }> = [
  { value: 'daily', label: 'Hari ini' },
  { value: 'weekly', label: 'Minggu ini' },
  { value: 'monthly', label: 'Bulan ini' },
  { value: 'custom', label: 'Kustom' },
]

export function DashboardPage() {
  const { user, currentBusiness, businessAccess, isBusinessLoading } = useAuth()
  const [period, setPeriod] = useState<DashboardPeriod>('monthly')
  const [customStartInput, setCustomStartInput] = useState('')
  const [customEndInput, setCustomEndInput] = useState('')
  const customStart = parseDateInput(customStartInput)
  const customEndDate = parseDateInput(customEndInput)
  const customEnd = customEndDate ? addDays(customEndDate, 1) : undefined
  const validCustomRange = !!customStart && !!customEnd && customStart < customEnd
  const dashboard = useDashboard({
    businessId: currentBusiness?.business_id,
    period,
    customStart: period === 'custom' ? customStart : undefined,
    customEnd: period === 'custom' ? customEnd : undefined,
  })
  const profile = useBusinessProfile()
  const periodLabel = periodOptions.find((option) => option.value === period)?.label || ''

  return (
    <div className="space-y-6">
      <section className="overflow-hidden rounded-2xl border border-[#1E3A5F] bg-[#10243D] p-5 text-white shadow-[0_10px_24px_rgba(15,35,60,0.10)] sm:p-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-4">
            <div className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-white/20 bg-white/15 text-lg font-bold">
              {profile.data?.logo_url ? (
                <img src={profile.data.logo_url} alt="Logo usaha" className="h-full w-full object-cover" />
              ) : (
                (currentBusiness?.business_name || 'UM').slice(0, 2).toUpperCase()
              )}
            </div>
            <div>
              <p className="inline-flex items-center gap-1.5 rounded-full bg-white/15 px-2.5 py-1 text-[11px] font-medium">
                <CheckCircle2 className="h-3 w-3" />
                Profil usaha aktif
              </p>
              <h1 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl">
                {currentBusiness?.business_name || 'CatatUang'}
              </h1>
              <p className="mt-1 text-sm text-blue-100">
                Selamat datang, <span className="font-semibold text-white">{profile.data?.owner_name || user?.email}</span>
              </p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <div className="rounded-md border border-white/15 bg-white/10 px-4 py-2.5">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-blue-200">Paket usaha</p>
              <p className="text-sm font-bold capitalize">{businessAccess?.plan || 'free'}</p>
            </div>
            <div className="rounded-md border border-white/15 bg-white/10 px-4 py-2.5">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-blue-200">Status akun</p>
              <p className="text-sm font-bold capitalize text-emerald-300">
                {businessAccess?.subscription_status || 'aktif'}
              </p>
            </div>
          </div>
        </div>
      </section>

      <section aria-labelledby="summary-title" className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 id="summary-title" className="text-xl font-bold text-slate-900">Ringkasan keuangan</h2>
            <p className="mt-1 text-sm text-slate-500">
              Saldo kas mencakup seluruh transaksi aktif. Pemasukan, pengeluaran, dan laba mengikuti periode.
            </p>
          </div>
          <div className="flex flex-wrap gap-1 rounded-md border border-slate-200 bg-white p-1 shadow-xs" aria-label="Pilih periode ringkasan">
            {periodOptions.map((option) => (
              <button
                key={option.value}
                type="button"
                aria-pressed={period === option.value}
                onClick={() => setPeriod(option.value)}
                className={`rounded-sm px-3 py-2 text-xs font-semibold transition ${
                  period === option.value ? 'bg-[#2563EB] text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100'
                }`}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {period === 'custom' && (
          <div className="grid gap-3 rounded-lg border border-slate-200 bg-white p-4 sm:grid-cols-2">
            <div className="flex items-center gap-2 text-sm font-semibold text-slate-800 sm:col-span-2">
              <CalendarDays className="h-4 w-4 text-[#2563EB]" />
              Tentukan rentang tanggal
            </div>
            <div>
              <label htmlFor="dashboard-start-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Dari tanggal</label>
              <input
                id="dashboard-start-date"
                type="date"
                value={customStartInput}
                onChange={(event) => setCustomStartInput(event.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              />
            </div>
            <div>
              <label htmlFor="dashboard-end-date" className="mb-1.5 block text-xs font-semibold text-slate-700">Sampai tanggal</label>
              <input
                id="dashboard-end-date"
                type="date"
                value={customEndInput}
                min={customStartInput || undefined}
                onChange={(event) => setCustomEndInput(event.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-800 focus:border-[#2563EB] focus:outline-none focus:ring-2 focus:ring-blue-100"
              />
            </div>
          </div>
        )}

        {period === 'custom' && !validCustomRange ? (
          <p className="rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">
            Pilih tanggal awal dan akhir yang valid untuk menampilkan ringkasan.
          </p>
        ) : isBusinessLoading || dashboard.isLoading ? (
          <LoadingState message="Memuat ringkasan keuangan..." />
        ) : dashboard.isError ? (
          <ErrorState
            message={dashboard.error instanceof Error ? dashboard.error.message : 'Gagal memuat ringkasan.'}
            onRetry={() => void dashboard.refetch()}
          />
        ) : dashboard.data ? (
          <div className="grid gap-4 lg:grid-flow-row-dense lg:grid-cols-3">
            <div className="grid gap-4 sm:grid-cols-2 lg:col-span-2 lg:grid-cols-2">
              <SummaryCard
                title="Saldo kas"
                value={formatCurrency(dashboard.data.cashBalance)}
                detail="Seluruh transaksi aktif"
                icon={<Wallet className="h-5 w-5" />}
                tone="blue"
              />
              <SummaryCard
                title="Total pemasukan"
                value={formatCurrency(dashboard.data.income)}
                detail={`${periodLabel} · ${dashboard.data.transactionCount} transaksi`}
                icon={<ArrowDownLeft className="h-5 w-5" />}
                tone="green"
                change={percentChange(dashboard.data.income, dashboard.data.previousIncome)}
                positiveIsGood
              />
              <SummaryCard
                title="Total pengeluaran"
                value={formatCurrency(dashboard.data.expense)}
                detail={`${periodLabel} · ${dashboard.data.transactionCount} transaksi`}
                icon={<ArrowUpRight className="h-5 w-5" />}
                tone="red"
                change={percentChange(dashboard.data.expense, dashboard.data.previousExpense)}
                positiveIsGood={false}
              />
              <SummaryCard
                title="Laba bersih"
                value={formatCurrency(dashboard.data.netCashFlow)}
                detail="Pemasukan − pengeluaran"
                icon={dashboard.data.netCashFlow >= 0 ? <TrendingUp className="h-5 w-5" /> : <TrendingDown className="h-5 w-5" />}
                tone={dashboard.data.netCashFlow >= 0 ? 'green' : 'red'}
                change={percentChange(dashboard.data.netCashFlow, dashboard.data.previousNetCashFlow)}
                positiveIsGood
              />
            </div>

            <div className="contents">
              <Card className="p-5 sm:p-6">
                <div className="mb-5">
                  <h3 className="font-bold text-slate-900">Pemasukan & pengeluaran</h3>
                  <p className="mt-1 text-xs text-slate-500">Perbandingan arus kas menurut periode grafik.</p>
                </div>
                {dashboard.data.chartPoints.some((point) => point.income || point.expense) ? (
                  <div className="h-56 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={dashboard.data.chartPoints} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                        <CartesianGrid stroke="#e2e8f0" strokeDasharray="3 3" vertical={false} />
                        <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12 }} />
                        <YAxis axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 11 }} tickFormatter={(value: number) => formatCompactCurrency(value)} />
                        <Tooltip formatter={(value) => formatCurrency(Number(value ?? 0))} cursor={{ fill: '#f1f5f9' }} />
                        <Bar dataKey="income" name="Pemasukan" fill="#2563EB" radius={[4, 4, 0, 0]} />
                        <Bar dataKey="expense" name="Pengeluaran" fill="#93C5FD" radius={[4, 4, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <EmptyState title="Belum ada transaksi" description="Grafik akan terisi setelah transaksi dicatat pada rentang ini." />
                )}
              </Card>

              <Card className="p-5 sm:p-6 lg:col-start-3">
                <div className="mb-5">
                  <h3 className="font-bold text-slate-900">Perkembangan laba</h3>
                  <p className="mt-1 text-xs text-slate-500">Selisih pemasukan dan pengeluaran setiap periode.</p>
                </div>
                {dashboard.data.chartPoints.some((point) => point.net !== 0) ? (
                  <div className="h-56 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={dashboard.data.chartPoints} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                        <CartesianGrid stroke="#e2e8f0" strokeDasharray="3 3" vertical={false} />
                        <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12 }} />
                        <YAxis axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 11 }} tickFormatter={(value: number) => formatCompactCurrency(value)} />
                        <Tooltip formatter={(value) => formatCurrency(Number(value ?? 0))} />
                        <Line type="monotone" dataKey="net" name="Laba bersih" stroke="#2563EB" strokeWidth={3} dot={{ r: 3 }} activeDot={{ r: 5 }} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <EmptyState title="Belum ada laba tercatat" description="Grafik laba akan muncul setelah ada pemasukan atau pengeluaran." />
                )}
              </Card>
            </div>

            <div className="contents">
              <Card className="p-5 sm:p-6 lg:col-span-2">
                <div className="mb-4 flex items-center justify-between gap-3">
                  <div>
                    <h3 className="font-bold text-slate-900">Transaksi terbaru</h3>
                    <p className="mt-1 text-xs text-slate-500">Lima transaksi aktif terakhir.</p>
                  </div>
                  <Link to="/transactions" className="text-xs font-semibold text-[#2563EB] hover:underline">Lihat semua</Link>
                </div>
                {dashboard.data.recentTransactions.length > 0 ? (
                  <div className="overflow-x-auto">
                    <table className="w-full min-w-[560px] text-left text-sm">
                      <thead>
                        <tr className="border-b border-slate-100 text-xs uppercase tracking-wide text-slate-400">
                          <th className="pb-2 font-semibold">Tanggal</th>
                          <th className="pb-2 font-semibold">Keterangan</th>
                          <th className="pb-2 font-semibold">Kategori</th>
                          <th className="pb-2 text-right font-semibold">Nominal</th>
                          <th className="pb-2 text-right font-semibold">Aksi</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {dashboard.data.recentTransactions.map((transaction) => (
                          <tr key={transaction.id} className="text-slate-700">
                            <td className="whitespace-nowrap py-3 text-xs text-slate-500">{formatDate(transaction.transactionDate)}</td>
                            <td className="max-w-[200px] py-3">
                              <div className="flex items-center gap-2">
                                <span className={`rounded-lg p-1.5 ${transaction.type === 'income' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
                                  {transaction.type === 'income' ? <ArrowDownLeft className="h-3.5 w-3.5" /> : <ArrowUpRight className="h-3.5 w-3.5" />}
                                </span>
                                <span className="truncate font-medium text-slate-800">{transaction.description || 'Transaksi'}</span>
                              </div>
                            </td>
                            <td className="py-3">
                              <span className="inline-flex items-center gap-1.5 text-xs text-slate-600">
                                <span className="h-2 w-2 rounded-full" style={{ backgroundColor: transaction.categoryColor }} />
                                {transaction.categoryName}
                              </span>
                            </td>
                            <td className={`whitespace-nowrap py-3 text-right font-bold ${transaction.type === 'income' ? 'text-emerald-700' : 'text-rose-700'}`}>
                              {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount)}
                            </td>
                            <td className="py-3 text-right">
                              <Link to={`/transactions?tx=${transaction.id}`} className="text-xs font-semibold text-[#2563EB] hover:underline">Detail</Link>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <EmptyState
                    title="Belum ada transaksi"
                    description="Mulai catat pemasukan atau pengeluaran pertama usaha Anda."
                    icon={<ReceiptText className="h-6 w-6" />}
                  />
                )}
              </Card>

            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:col-span-3">
              <Card className="p-5 sm:p-6">
                <div className="flex items-center justify-between gap-2">
                  <div>
                    <h3 className="font-bold text-slate-900">Utang & piutang</h3>
                    <p className="mt-1 text-xs text-slate-500">Sisa kewajiban yang belum lunas.</p>
                  </div>
                  <HandCoins className="h-5 w-5 text-[#2563EB]" />
                </div>
                <div className="mt-4 grid grid-cols-2 gap-3">
                  <div className="rounded-xl bg-emerald-50 p-3">
                    <p className="text-[11px] font-semibold text-emerald-700">Piutang</p>
                    <p className="mt-1 text-sm font-bold text-emerald-800">{formatCurrency(dashboard.data.receivableOutstanding)}</p>
                    <p className="mt-1 text-[11px] text-emerald-700">{dashboard.data.receivableUnpaidCount} belum lunas</p>
                  </div>
                  <div className="rounded-xl bg-rose-50 p-3">
                    <p className="text-[11px] font-semibold text-rose-700">Utang</p>
                    <p className="mt-1 text-sm font-bold text-rose-800">{formatCurrency(dashboard.data.payableOutstanding)}</p>
                    <p className="mt-1 text-[11px] text-rose-700">{dashboard.data.payableUnpaidCount} belum lunas</p>
                  </div>
                </div>
                {(dashboard.data.receivableDueCount > 0 || dashboard.data.payableDueCount > 0) && (
                  <p className="mt-3 rounded-lg bg-amber-50 px-3 py-2 text-[11px] font-medium text-amber-800">
                    {dashboard.data.receivableDueCount + dashboard.data.payableDueCount} tagihan sudah jatuh tempo.
                  </p>
                )}
                <Link to="/debts" className="mt-4 inline-flex items-center gap-1 text-xs font-semibold text-[#2563EB] hover:underline">
                  Lihat detail <ArrowRight className="h-3.5 w-3.5" />
                </Link>
              </Card>

              <Card className="p-5 sm:p-6">
                <div className="mb-4 flex items-center justify-between gap-2">
                  <div>
                    <h3 className="font-bold text-slate-900">Aktivitas terbaru</h3>
                    <p className="mt-1 text-xs text-slate-500">Perubahan data penting pada usaha.</p>
                  </div>
                  <Clock3 className="h-5 w-5 text-slate-400" />
                </div>
                {dashboard.data.recentActivity.length > 0 ? (
                  <ul className="space-y-3">
                    {dashboard.data.recentActivity.slice(0, 5).map((activity) => (
                      <li key={activity.id} className="flex items-start gap-2.5">
                        <span className="mt-0.5 rounded-lg bg-slate-100 p-1.5 text-slate-500">
                          {activity.entityType === 'transaction' ? <ReceiptText className="h-3.5 w-3.5" />
                            : activity.entityType === 'business_member' ? <Users className="h-3.5 w-3.5" />
                              : <HandCoins className="h-3.5 w-3.5" />}
                        </span>
                        <div className="min-w-0">
                          <p className="text-xs font-medium text-slate-700">{activity.summary || activity.action}</p>
                          <p className="mt-0.5 text-[11px] text-slate-400">{formatDateTime(activity.createdAt)}</p>
                        </div>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="rounded-xl bg-slate-50 p-4 text-xs text-slate-500">
                    Belum ada aktivitas. Aktivitas akan tercatat saat data usaha berubah.
                  </p>
                )}
              </Card>
            </div>

            <div className="flex flex-wrap items-center gap-2 lg:col-span-3">
              <Badge tone="blue">{dashboard.data.previousTransactionCount} transaksi periode sebelumnya</Badge>
              <Badge tone="slate">Zona waktu: {Intl.DateTimeFormat().resolvedOptions().timeZone}</Badge>
            </div>
          </div>
        ) : (
          <EmptyState
            title="Ringkasan belum tersedia"
            description="Pilih atau buat profil usaha untuk melihat ringkasan keuangan."
          />
        )}
      </section>
    </div>
  )
}

function SummaryCard({
  title,
  value,
  detail,
  icon,
  tone,
  change,
  positiveIsGood = true,
}: {
  title: string
  value: string
  detail: string
  icon: React.ReactNode
  tone: 'blue' | 'green' | 'red'
  change?: number | null
  positiveIsGood?: boolean
}) {
  const toneClasses = {
    blue: 'bg-blue-50 text-[#2563EB]',
    green: 'bg-emerald-50 text-emerald-700',
    red: 'bg-rose-50 text-rose-700',
  }[tone]

  const isPositive = change !== null && change !== undefined && change >= 0
  const isGood = change === null || change === undefined ? null : positiveIsGood ? isPositive : !isPositive

  return (
    <Card className="rounded-lg p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-slate-500">{title}</p>
          <p className="mt-3 text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">{value}</p>
          <p className="mt-2 text-xs text-slate-500">{detail}</p>
        </div>
        <div className={`rounded-md p-3 ${toneClasses}`}>{icon}</div>
      </div>
      {change !== null && change !== undefined && (
        <p className={`mt-3 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-semibold ${
          isGood ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
        }`}>
          {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
          {Math.abs(change).toFixed(1)}% vs periode sebelumnya
        </p>
      )}
    </Card>
  )
}
