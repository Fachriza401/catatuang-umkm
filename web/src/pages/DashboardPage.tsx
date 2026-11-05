import { Navbar } from '../components/Navbar'
import { useAuth } from '../context/AuthContext'
import {
  ShieldCheck,
  CheckCircle,
  XCircle,
  TrendingUp,
  Receipt,
  Users,
  CreditCard,
  Building2,
} from 'lucide-react'

export function DashboardPage() {
  const { user, currentBusiness, businessAccess, permissions } = useAuth()

  return (
    <div className="min-h-screen bg-slate-50">
      <Navbar />

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8">
        {/* Welcome Banner */}
        <div className="rounded-3xl bg-linear-to-r from-[#004ac6] to-[#002f80] p-6 sm:p-8 text-white shadow-lg shadow-blue-900/10">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full bg-white/15 px-3 py-1 text-xs font-medium backdrop-blur-xs mb-3">
                <Building2 className="h-3.5 w-3.5" />
                <span>Profil Usaha Aktif</span>
              </div>
              <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">
                {currentBusiness?.business_name || 'Dasbor CatatUang'}
              </h1>
              <p className="mt-1 text-sm text-blue-100">
                Selamat datang kembali, <span className="font-semibold text-white">{user?.email}</span>. Anda terautentikasi sebagai{' '}
                <span className="font-bold underline uppercase">{permissions.role}</span>.
              </p>
            </div>

            <div className="flex items-center gap-3 self-start sm:self-center">
              <div className="rounded-2xl bg-white/10 p-3 backdrop-blur-md text-center border border-white/15">
                <p className="text-[10px] uppercase font-semibold text-blue-200">Paket Usaha</p>
                <p className="text-sm font-bold capitalize text-white">
                  {businessAccess?.plan || 'Free'}
                </p>
              </div>
              <div className="rounded-2xl bg-white/10 p-3 backdrop-blur-md text-center border border-white/15">
                <p className="text-[10px] uppercase font-semibold text-blue-200">Status Langganan</p>
                <p className="text-sm font-bold capitalize text-emerald-300">
                  {businessAccess?.subscription_status || 'Aktif'}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Permissions Verification Card (Langkah 1 Deliverable) */}
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-xs">
          <div className="flex items-center gap-2.5 pb-4 border-b border-slate-100">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-50 text-[#004ac6]">
              <ShieldCheck className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">Hak Akses Peran ({permissions.role.toUpperCase()})</h2>
              <p className="text-xs text-slate-500">
                Hak akses diverifikasi langsung oleh RLS database dan hook <code>usePermissions()</code>
              </p>
            </div>
          </div>

          <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Transaksi */}
            <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-4 space-y-3">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-700 uppercase tracking-wider">
                <Receipt className="h-4 w-4 text-[#004ac6]" />
                <span>Transaksi Kas</span>
              </div>
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Lihat Daftar Transaksi</span>
                  {permissions.canViewTransactions ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-slate-400 font-semibold"><XCircle className="h-3.5 w-3.5" /> Tidak</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Catat Transaksi Baru</span>
                  {permissions.canCreateTransaction ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-slate-400 font-semibold"><XCircle className="h-3.5 w-3.5" /> Tidak</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Ubah / Hapus Transaksi</span>
                  {permissions.canEditTransaction ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-rose-500 font-semibold"><XCircle className="h-3.5 w-3.5" /> Dilarang</span>
                  )}
                </div>
              </div>
            </div>

            {/* Utang-Piutang */}
            <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-4 space-y-3">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-700 uppercase tracking-wider">
                <CreditCard className="h-4 w-4 text-[#004ac6]" />
                <span>Utang & Piutang</span>
              </div>
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Lihat Daftar Utang</span>
                  {permissions.canViewDebts ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-slate-400 font-semibold"><XCircle className="h-3.5 w-3.5" /> Tidak</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Buat / Ubah Data Utang</span>
                  {permissions.canCreateDebt ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-rose-500 font-semibold"><XCircle className="h-3.5 w-3.5" /> Dilarang</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Catat Cicilan Pembayaran</span>
                  {permissions.canRecordDebtPayment ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-slate-400 font-semibold"><XCircle className="h-3.5 w-3.5" /> Tidak</span>
                  )}
                </div>
              </div>
            </div>

            {/* Pengaturan & Anggota */}
            <div className="rounded-xl border border-slate-100 bg-slate-50/60 p-4 space-y-3">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-700 uppercase tracking-wider">
                <Users className="h-4 w-4 text-[#004ac6]" />
                <span>Anggota & Pengaturan</span>
              </div>
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Lihat Anggota Tim</span>
                  {permissions.canViewMembers ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-rose-500 font-semibold"><XCircle className="h-3.5 w-3.5" /> Dilarang</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Kelola / Tambah Anggota</span>
                  {permissions.canManageMembers ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-rose-500 font-semibold"><XCircle className="h-3.5 w-3.5" /> Dilarang</span>
                  )}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-slate-600">Kelola Profil Usaha</span>
                  {permissions.canManageSettings ? (
                    <span className="flex items-center gap-1 text-emerald-600 font-semibold"><CheckCircle className="h-3.5 w-3.5" /> Boleh</span>
                  ) : (
                    <span className="flex items-center gap-1 text-rose-500 font-semibold"><XCircle className="h-3.5 w-3.5" /> Dilarang</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Info Setup Langkah 1 */}
        <div className="rounded-2xl border border-blue-100 bg-blue-50/60 p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="space-y-1">
            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-[#004ac6]" />
              Langkah 1: Setup, Auth, dan Pemilih Usaha Selesai
            </h3>
            <p className="text-xs text-slate-600">
              Scaffolding frontend, sesi Supabase terintegrasi, selektor usaha, dan hook izin akses telah siap untuk Langkah 2 (Dasbor & Recharts).
            </p>
          </div>
        </div>
      </main>
    </div>
  )
}
