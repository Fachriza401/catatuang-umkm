import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { z } from 'zod'
import { authService } from '../services/auth.service'
import { Lock, Mail, AlertCircle, Eye, EyeOff, Loader2 } from 'lucide-react'

const loginSchema = z.object({
  email: z.string().min(1, 'Email wajib diisi').email('Format email tidak valid'),
  password: z.string().min(6, 'Password minimal 6 karakter'),
})

export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setErrorMessage(null)

    const validation = loginSchema.safeParse({ email, password })
    if (!validation.success) {
      setErrorMessage(validation.error.issues[0].message)
      return
    }

    setIsSubmitting(true)
    try {
      await authService.login({ email, password })
      navigate('/dashboard')
    } catch (err: unknown) {
      const error = err as { message?: string }
      if (error?.message?.toLowerCase().includes('invalid login credentials')) {
        setErrorMessage('Email atau password salah. Silakan coba lagi.')
      } else if (error?.message?.toLowerCase().includes('email not confirmed')) {
        setErrorMessage('Email Anda belum dikonfirmasi. Silakan periksa inbox/spam email Anda.')
      } else {
        setErrorMessage(error?.message || 'Gagal masuk. Periksa koneksi internet Anda.')
      }
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4 sm:p-6 lg:p-8">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center">
          <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-[#004ac6] text-white font-extrabold text-2xl shadow-md">
            CU
          </div>
          <h1 className="mt-4 text-2xl font-bold tracking-tight text-slate-900">
            Masuk ke Catat<span className="text-[#004ac6]">Uang</span>
          </h1>
          <p className="mt-1.5 text-sm text-slate-500">
            Gunakan akun yang sama dengan aplikasi mobile CatatUang
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

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-semibold text-slate-700">
                  Password
                </label>
                <Link
                  to="/forgot-password"
                  className="text-xs font-medium text-[#004ac6] hover:underline"
                >
                  Lupa password?
                </Link>
              </div>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full rounded-xl border border-slate-300 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-900 placeholder-slate-400 focus:border-[#004ac6] focus:outline-none focus:ring-2 focus:ring-[#004ac6]/15 transition"
                  disabled={isSubmitting}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
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
                  <span>Memproses...</span>
                </>
              ) : (
                <span>Masuk Sekarang</span>
              )}
            </button>
          </form>

          <div className="mt-6 text-center text-xs text-slate-500">
            Belum punya akun?{' '}
            <Link to="/register" className="font-semibold text-[#004ac6] hover:underline">
              Daftar akun baru
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
