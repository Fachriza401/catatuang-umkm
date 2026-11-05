import { Store, Check, X } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import type { UserBusinessOption } from '../services/business.service'

interface Props {
  isOpen: boolean
  onClose: () => void
}

export function BusinessSelectorModal({ isOpen, onClose }: Props) {
  const { userBusinesses, currentBusiness, selectBusiness } = useAuth()

  if (!isOpen) return null

  const handleSelect = (business: UserBusinessOption) => {
    selectBusiness(business)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4">
      <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div className="flex items-center gap-2.5">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-[#004ac6]">
              <Store className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-semibold text-slate-900">Pilih Usaha</h3>
              <p className="text-xs text-slate-500">Pilih data usaha yang ingin dikelola</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="mt-4 space-y-2 max-h-72 overflow-y-auto">
          {userBusinesses.map((b) => {
            const isSelected = currentBusiness?.business_id === b.business_id
            return (
              <button
                key={b.business_id}
                onClick={() => handleSelect(b)}
                className={`w-full flex items-center justify-between p-3.5 rounded-xl border text-left transition ${
                  isSelected
                    ? 'border-[#004ac6] bg-blue-50/50 ring-1 ring-[#004ac6]'
                    : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'
                }`}
              >
                <div>
                  <h4 className="font-medium text-slate-900 text-sm">{b.business_name}</h4>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs text-slate-500">Pemilik: {b.owner_name || 'Tidak ada nama'}</span>
                    <span className="text-[10px] uppercase font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">
                      {b.role}
                    </span>
                  </div>
                </div>
                {isSelected && <Check className="h-5 w-5 text-[#004ac6]" />}
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
