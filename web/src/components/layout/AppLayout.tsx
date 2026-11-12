import { useEffect, useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { LogOut, Menu, ShieldCheck } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { Sidebar } from './Sidebar'
import { loadPreferences, savePreferences } from '../../utils/preferences'

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/transactions': 'Transaksi',
  '/categories': 'Kategori',
  '/debts': 'Utang & Piutang',
  '/reports': 'Laporan Keuangan',
  '/business-profile': 'Profil Usaha',
  '/settings': 'Pengaturan',
  '/developer-diagnostics': 'Developer Diagnostics',
}

export function AppLayout() {
  const { user, currentBusiness, businessAccess, logout } = useAuth()
  const [mobileOpen, setMobileOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(() => loadPreferences().compactSidebar)
  const location = useLocation()
  const navigate = useNavigate()

  useEffect(() => {
    const syncPreferences = () => setCollapsed(loadPreferences().compactSidebar)
    window.addEventListener('catatuang-preferences-updated', syncPreferences)
    return () => window.removeEventListener('catatuang-preferences-updated', syncPreferences)
  }, [])

  const toggleCollapsed = () => {
    const next = !collapsed
    setCollapsed(next)
    savePreferences({ ...loadPreferences(), compactSidebar: next })
  }

  const handleLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName = (user?.user_metadata?.full_name as string | undefined) || user?.email || 'Pengguna'
  const avatarUrl = user?.user_metadata?.avatar_url as string | undefined
  const pageTitle = pageTitles[location.pathname] || 'CatatUang'

  return (
    <div className="min-h-screen bg-[#F3F6FB]">
      <Sidebar
        mobileOpen={mobileOpen}
        onClose={() => setMobileOpen(false)}
        collapsed={collapsed}
        onToggleCollapse={toggleCollapsed}
      />

      <div className={collapsed ? 'lg:pl-16' : 'lg:pl-56'}>
        <header className="sticky top-0 z-30 border-b border-slate-200 bg-white">
          <div className="flex h-16 items-center justify-between gap-3 px-4 sm:px-6 lg:px-8">
            <div className="flex min-w-0 items-center gap-3">
              <button
                type="button"
                onClick={() => setMobileOpen(true)}
                className="rounded-md border border-slate-200 p-2 text-slate-600 hover:bg-slate-50 lg:hidden"
                aria-label="Buka menu"
              >
                <Menu className="h-5 w-5" />
              </button>
              <div className="min-w-0">
                <p className="truncate text-sm font-bold text-slate-900 sm:text-base">{pageTitle}</p>
                <p className="hidden truncate text-xs text-slate-500 sm:block">
                  {currentBusiness?.business_name || 'CatatUang'}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 sm:gap-3">
              <div className="hidden items-center gap-2 rounded-md border border-slate-200 px-2.5 py-1.5 md:flex">
                <ShieldCheck className="h-4 w-4 text-emerald-600" />
                <div className="text-right">
                  <p className="text-[10px] font-semibold uppercase text-slate-400">Paket</p>
                  <p className="text-xs font-bold capitalize text-slate-700">{businessAccess?.plan || 'free'}</p>
                </div>
              </div>

              <div className="hidden items-center gap-2 sm:flex">
                <div className="flex h-9 w-9 items-center justify-center overflow-hidden rounded-full bg-[#EFF6FF] text-xs font-bold text-[#2563EB]">
                  {avatarUrl ? (
                    <img src={avatarUrl} alt="Foto profil" className="h-full w-full object-cover" />
                  ) : (
                    displayName.slice(0, 1).toUpperCase()
                  )}
                </div>
                <div className="hidden max-w-[150px] text-right lg:block">
                  <p className="truncate text-xs font-semibold text-slate-800">{displayName}</p>
                  <p className="truncate text-[11px] text-slate-500">Pemilik usaha</p>
                </div>
              </div>

              <button
                type="button"
                onClick={() => void handleLogout()}
                className="flex items-center gap-1.5 rounded-md border border-slate-200 px-2.5 py-2 text-xs font-semibold text-rose-600 transition hover:border-rose-200 hover:bg-rose-50"
              >
                <LogOut className="h-4 w-4" />
                <span className="hidden sm:inline">Keluar</span>
              </button>
            </div>
          </div>
        </header>

        <main className="mx-auto max-w-[1440px] px-4 py-5 sm:px-6 sm:py-6 lg:px-6">
          <Outlet />
        </main>
      </div>

    </div>
  )
}
