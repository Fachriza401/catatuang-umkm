import { Store, LogOut, ShieldCheck } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { BrandLogo } from './BrandLogo'

export function Navbar() {
  const { user, currentBusiness, logout } = useAuth()

  return (
    <header className="sticky top-0 z-40 w-full border-b border-slate-200 bg-white/95 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2">
            <BrandLogo className="h-9 w-9 rounded-md" />
            <span className="text-xl font-bold tracking-tight text-slate-900">
              Catat<span className="text-[#004ac6]">Uang</span>
            </span>
          </div>

          {currentBusiness && (
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700">
              <Store className="h-4 w-4 text-[#004ac6]" />
              <span className="max-w-[140px] truncate">{currentBusiness.business_name}</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-4">
          <div className="hidden flex-col text-right sm:flex">
            <span className="text-xs font-semibold text-slate-800">{user?.email}</span>
            <span className="flex items-center justify-end gap-1 text-[11px] text-slate-500">
              <ShieldCheck className="h-3 w-3 text-emerald-600" />
              Pemilik usaha
            </span>
          </div>

          <button
            onClick={() => logout()}
            className="flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-rose-600 transition hover:border-rose-200 hover:bg-rose-50"
          >
            <LogOut className="h-4 w-4" />
            <span>Keluar</span>
          </button>
        </div>
      </div>
    </header>
  )
}
