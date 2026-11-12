import { NavLink } from 'react-router-dom'
import {
  BarChart3,
  ChevronsLeft,
  ChevronsRight,
  HandCoins,
  LayoutDashboard,
  ReceiptText,
  Settings,
  ShieldAlert,
  Store,
  Tags,
  X,
} from 'lucide-react'
import clsx from 'clsx'
import { useAuth } from '../../context/AuthContext'
import { isDeveloperEmail } from '../../utils/developer'
import { BrandLogo } from '../BrandLogo'
interface NavItem {
  to: string
  label: string
  icon: typeof LayoutDashboard
  visible: boolean
}

export function Sidebar({
  mobileOpen,
  onClose,
  collapsed,
  onToggleCollapse,
}: {
  mobileOpen: boolean
  onClose: () => void
  collapsed: boolean
  onToggleCollapse: () => void
}) {
  const { user } = useAuth()

  const items: NavItem[] = [
    { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard, visible: true },
    { to: '/transactions', label: 'Transaksi', icon: ReceiptText, visible: true },
    { to: '/categories', label: 'Kategori', icon: Tags, visible: true },
    { to: '/debts', label: 'Utang & Piutang', icon: HandCoins, visible: true },
    { to: '/reports', label: 'Laporan Keuangan', icon: BarChart3, visible: true },
    { to: '/business-profile', label: 'Profil Usaha', icon: Store, visible: true },
    { to: '/settings', label: 'Pengaturan', icon: Settings, visible: true },
    {
      to: '/developer-diagnostics',
      label: 'Developer Diagnostics',
      icon: ShieldAlert,
      visible: isDeveloperEmail(user?.email),
    },
  ]

  return (
    <>
      {mobileOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-900/50 backdrop-blur-xs lg:hidden"
          onClick={onClose}
          role="presentation"
        />
      )}
      <aside
        className={clsx(
          'fixed inset-y-0 left-0 z-50 flex flex-col border-r border-slate-200 bg-[#F8FAFC] transition-all duration-200 lg:z-30',
          collapsed ? 'lg:w-16' : 'lg:w-56',
          'w-72',
          mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0',
        )}
      >
        <div className={clsx('flex h-16 items-center border-b border-slate-100 px-4', collapsed ? 'lg:justify-center' : 'justify-between')}>
          <NavLink to="/dashboard" className="flex items-center gap-2.5 overflow-hidden" onClick={onClose}>
            <BrandLogo className="h-9 w-9 shrink-0 rounded-md" />
            <span className={clsx('text-lg font-bold tracking-tight text-slate-900', collapsed && 'lg:hidden')}>
              Catat<span className="text-[#2563EB]">Uang</span>
            </span>
          </NavLink>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 lg:hidden"
            aria-label="Tutup menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4" aria-label="Navigasi utama">
          {items.filter((item) => item.visible).map((item) => {
            const Icon = item.icon
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onClose}
                title={collapsed ? item.label : undefined}
                className={({ isActive }) => clsx(
                  'group relative flex items-center gap-3 rounded-md border px-3 py-2.5 text-sm font-medium transition',
                  isActive
                    ? 'border-[#D9E7FF] bg-[#EFF6FF] text-[#0F172A] shadow-sm'
                    : 'border-transparent text-slate-600 hover:border-slate-200 hover:bg-white hover:text-slate-900',
                  collapsed && 'lg:justify-center',
                )}
              >
                {({ isActive }) => (
                  <>
                    <span className={clsx('absolute left-0 h-5 w-1 rounded-r-full bg-[#2563EB] transition', isActive ? 'opacity-100' : 'opacity-0')} />
                    <Icon className="h-5 w-5 shrink-0" />
                    <span className={clsx('truncate', collapsed && 'lg:hidden')}>{item.label}</span>
                  </>
                )}
              </NavLink>
            )
          })}
        </nav>

        <div className="border-t border-slate-100 p-3">
          <button
            type="button"
            onClick={onToggleCollapse}
            className={clsx(
              'hidden w-full items-center gap-2 rounded-md px-3 py-2 text-xs font-semibold text-slate-500 transition hover:bg-slate-50 hover:text-slate-700 lg:flex',
              collapsed && 'lg:justify-center',
            )}
          >
            {collapsed ? <ChevronsRight className="h-4 w-4" /> : <ChevronsLeft className="h-4 w-4" />}
            {!collapsed && <span>Perkecil menu</span>}
          </button>
          <div className={clsx('mt-2 rounded-md bg-slate-50 px-3 py-2 text-[11px] text-slate-500', collapsed && 'lg:hidden')}>
            <p className="font-semibold text-slate-700">CatatUang Web</p>
            <p>Kelola Uang, Kembangkan Usaha.</p>
          </div>
        </div>
      </aside>
    </>
  )
}
