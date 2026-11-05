import { useState } from 'react'
import { Store, ChevronDown, LogOut, ShieldCheck } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { BusinessSelectorModal } from './BusinessSelectorModal'

export function Navbar() {
  const { user, currentBusiness, userBusinesses, logout } = useAuth()
  const [isModalOpen, setIsModalOpen] = useState(false)

  return (
    <>
      <header className="sticky top-0 z-40 w-full border-b border-slate-200 bg-white/95 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#004ac6] text-white font-bold text-lg shadow-sm">
                CU
              </div>
              <span className="text-xl font-bold tracking-tight text-slate-900">
                Catat<span className="text-[#004ac6]">Uang</span>
              </span>
            </div>

            {/* Business Selector Pill */}
            {currentBusiness && (
              <button
                onClick={() => setIsModalOpen(true)}
                className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-100 hover:border-slate-300 transition"
                title="Ganti Usaha"
              >
                <Store className="h-4 w-4 text-[#004ac6]" />
                <span className="max-w-[140px] truncate">{currentBusiness.business_name}</span>
                <span className="rounded bg-blue-100 px-1.5 py-0.5 text-[10px] font-semibold text-[#004ac6] uppercase">
                  {currentBusiness.role}
                </span>
                {userBusinesses.length > 1 && (
                  <ChevronDown className="h-3.5 w-3.5 text-slate-400" />
                )}
              </button>
            )}
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex flex-col text-right">
              <span className="text-xs font-semibold text-slate-800">{user?.email}</span>
              <span className="flex items-center justify-end gap-1 text-[11px] text-slate-500">
                <ShieldCheck className="h-3 w-3 text-emerald-600" />
                Role: <span className="font-semibold text-slate-700 uppercase">{currentBusiness?.role || 'User'}</span>
              </span>
            </div>

            <button
              onClick={() => logout()}
              className="flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50 hover:border-rose-200 transition"
            >
              <LogOut className="h-4 w-4" />
              <span>Keluar</span>
            </button>
          </div>
        </div>
      </header>

      <BusinessSelectorModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
      />
    </>
  )
}

