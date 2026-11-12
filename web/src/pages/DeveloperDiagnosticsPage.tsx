import { useAuth } from '../context/AuthContext'
import { isDeveloperEmail } from '../utils/developer'
import { Card } from '../components/ui/Card'
import { ErrorState } from '../components/ui/States'

export function DeveloperDiagnosticsPage() {
  const { user, currentBusiness, permissions } = useAuth()
  if (!isDeveloperEmail(user?.email)) {
    return <ErrorState title="Akses tidak tersedia" message="Halaman diagnostik hanya tersedia untuk akun developer." />
  }

  const rows = [
    ['Aplikasi', 'CatatUang Web'],
    ['Status sesi', user ? 'Terautentikasi' : 'Belum masuk'],
    ['ID pengguna', user?.id ?? 'Tidak tersedia'],
    ['Usaha aktif', currentBusiness?.business_name ?? 'Belum dipilih'],
    ['Peran usaha', permissions.role],
    ['Zona waktu browser', Intl.DateTimeFormat().resolvedOptions().timeZone],
    ['Browser', navigator.userAgent],
  ]

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">Developer Diagnostics</h1>
        <p className="mt-1 text-sm text-slate-500">Informasi runtime untuk membantu pemeriksaan aplikasi.</p>
      </div>
      <Card className="divide-y divide-slate-100">
        {rows.map(([label, value]) => (
          <div key={label} className="grid gap-1 p-4 sm:grid-cols-[220px_1fr] sm:gap-4">
            <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">{label}</span>
            <span className="break-all text-sm text-slate-800">{value}</span>
          </div>
        ))}
      </Card>
    </div>
  )
}
