import { useState } from 'react'
import { Link } from 'react-router-dom'
import { z } from 'zod'
import { authService } from '../services/auth.service'
import { Mail, AlertCircle, CheckCircle2, ArrowLeft, Loader2 } from 'lucide-react'
import { BrandLogo } from '../components/BrandLogo'

const schema = z.object({
  email: z.string().min(1, 'Email wajib diisi').email('Format email tidak valid'),
})

export function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)
    setSuccessMessage(null)

    const validation = schema.safeParse({ email })
    if (!validation.success) {
      setErrorMessage(validation.error.issues[0].message)
      return
    }

    setIsSubmitting(true)
    try {
      await authService.forgotPassword(email)
      setSuccessMessage(
        'Tautan instruksi reset password telah dikirim ke email Anda. Silakan periksa inbox/spam.'
      )
    } catch (err: unknown) {
      const error = err as { message?: string }
      setErrorMessage(error?.message || 'Gagal mengirim email reset password.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4 sm:p-6 lg:p-8">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center">
          <BrandLogo className="mx-auto h-12 w-12 rounded-lg" />
          <h1 className="mt-4 text-2xl font-bold tracking-tight text-slate-900">
            Lupa Password
          </h1>
          <p className="mt-1.5 text-sm text-slate-500">
            Masukkan email terdaftar untuk menerima tautan pemulihan
          </p>
        </div>

        <div className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
          {errorMessage && (
            <div className="mb-5 flex items-start gap-2.5 rounded-xl border border-rose-200 bg-rose-50/70 p-3.5 text-xs text-rose-700 animate-in fade-in">
              <AlertCircle className="h-4 w-4 shrink-0 text-rose-600 mt-0.5" />
              <p className="leading-relaxed">{errorMessage}</p>
            </div>
          )}

          {successMessage && (
            <div className="mb-5 flex items-start gap-2.5 rounded-xl border border-emerald-200 bg-emerald-50/70 p-3.5 text-xs text-emerald-800 animate-in fade-in">
              <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600 mt-0.5" />
              <p className="leading-relaxed">{successMessage}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Alamat Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nama@warung.com"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                  required
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
                  <span>Mengirim Tautan...</span>
                </>
              ) : (
                <span>Kirim Tautan Reset</span>
              )}
            </button>
          </form>

          <div className="mt-6 text-center">
            <Link
              to="/login"
              className="inline-flex items-center gap-1.5 text-xs font-medium text-slate-600 hover:text-slate-900"
            >
              <ArrowLeft className="h-3.5 w-3.5" />
              <span>Kembali ke halaman masuk</span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
