import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { z } from 'zod'
import { businessService } from '../services/business.service'
import { useAuth } from '../context/AuthContext'
import { Store, User, Phone, MapPin, Tag, AlertCircle, Loader2 } from 'lucide-react'

const schema = z.object({
  businessName: z.string().min(2, 'Nama usaha minimal 2 karakter'),
  ownerName: z.string().min(2, 'Nama pemilik minimal 2 karakter'),
  businessType: z.string().min(1, 'Pilih kategori jenis usaha'),
  phone: z.string().optional(),
  address: z.string().optional(),
})

export function OnboardingBusinessPage() {
  const navigate = useNavigate()
  const { refreshBusinessAccess } = useAuth()
  const [businessName, setBusinessName] = useState('')
  const [ownerName, setOwnerName] = useState('')
  const [businessType, setBusinessType] = useState('Kuliner / Makanan')
  const [phone, setPhone] = useState('')
  const [address, setAddress] = useState('')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)

    const validation = schema.safeParse({
      businessName,
      ownerName,
      businessType,
      phone,
      address,
    })

    if (!validation.success) {
      setErrorMessage(validation.error.issues[0].message)
      return
    }

    setIsSubmitting(true)
    try {
      await businessService.createInitialBusinessProfile({
        business_name: businessName,
        owner_name: ownerName,
        business_type: businessType,
        phone,
        address,
      })
      await refreshBusinessAccess()
      navigate('/dashboard')
    } catch (err: unknown) {
      const error = err as { message?: string }
      setErrorMessage(error?.message || 'Gagal membuat profil usaha.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4 sm:p-6 lg:p-8">
      <div className="w-full max-w-lg space-y-6">
        <div className="text-center">
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-[#004ac6] text-white font-extrabold text-2xl shadow-md">
            <Store className="h-6 w-6 text-white" />
          </div>
          <h1 className="mt-4 text-2xl font-bold tracking-tight text-slate-900">
            Daftarkan Profil Usaha Anda
          </h1>
          <p className="mt-1.5 text-sm text-slate-500">
            Akun Anda belum memiliki data usaha. Lengkapi formulir berikut untuk memulai pembukuan.
          </p>
        </div>

        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
          {errorMessage && (
            <div className="mb-5 flex items-start gap-2.5 rounded-xl border border-rose-200 bg-rose-50/70 p-3.5 text-xs text-rose-700 animate-in fade-in">
              <AlertCircle className="h-4 w-4 shrink-0 text-rose-600 mt-0.5" />
              <p className="leading-relaxed">{errorMessage}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Nama Usaha / Toko <span className="text-rose-500">*</span>
              </label>
              <div className="relative">
                <Store className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={businessName}
                  onChange={(e) => setBusinessName(e.target.value)}
                  placeholder="Contoh: Warung Kopi Berkah"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Nama Pemilik <span className="text-rose-500">*</span>
              </label>
              <div className="relative">
                <User className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={ownerName}
                  onChange={(e) => setOwnerName(e.target.value)}
                  placeholder="Contoh: Budi Santoso"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                  required
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Jenis Usaha
              </label>
              <div className="relative">
                <Tag className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <select
                  value={businessType}
                  onChange={(e) => setBusinessType(e.target.value)}
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                >
                  <option value="Kuliner / Makanan">Kuliner / Makanan</option>
                  <option value="Kelontong / Retail">Kelontong / Retail</option>
                  <option value="Jasa / Servis">Jasa / Servis</option>
                  <option value="Fashion / Pakaian">Fashion / Pakaian</option>
                  <option value="Pertanian / Peternakan">Pertanian / Peternakan</option>
                  <option value="Lainnya">Lainnya</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Nomor WhatsApp / HP
              </label>
              <div className="relative">
                <Phone className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="081234567890"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Alamat Usaha
              </label>
              <div className="relative">
                <MapPin className="absolute left-3.5 top-3 h-4 w-4 text-slate-400" />
                <textarea
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  rows={2}
                  placeholder="Alamat lengkap lokasi usaha"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full flex items-center justify-center gap-2 rounded-xl bg-[#004ac6] py-3 text-sm font-semibold text-white shadow-sm hover:bg-[#003ca3] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/40 disabled:opacity-60 transition"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  <span>Menyimpan...</span>
                </>
              ) : (
                <span>Simpan & Masuk ke Dasbor</span>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
