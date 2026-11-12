import { useState } from 'react'
import { Save, Settings } from 'lucide-react'
import { Button } from '../components/ui/Button'
import { Card } from '../components/ui/Card'
import { loadPreferences, savePreferences, type AppPreferences } from '../utils/preferences'

export function SettingsPage() {
  const [preferences, setPreferences] = useState<AppPreferences>(() => loadPreferences())
  const [saved, setSaved] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  const update = <K extends keyof AppPreferences>(key: K, value: AppPreferences[K]) => {
    setPreferences((current) => ({ ...current, [key]: value }))
    setSaved(false)
    setSaveError(null)
  }

  const handleSave = () => {
    try {
      savePreferences(preferences)
      setSaved(true)
    } catch (error) {
      console.error('Gagal menyimpan pengaturan:', error)
      setSaved(false)
      setSaveError(error instanceof Error ? error.message : 'Pengaturan gagal disimpan di browser ini.')
    }
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">Pengaturan</h1>
        <p className="mt-1 text-sm text-slate-500">Atur preferensi tampilan dan laporan untuk browser ini.</p>
      </div>
      {saved && <p role="status" className="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">Pengaturan berhasil disimpan.</p>}
      {saveError && <p role="alert" className="border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">{saveError}</p>}

      <Card className="p-5 sm:p-6">
        <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
          <span className="flex h-10 w-10 items-center justify-center rounded-md bg-blue-50 text-[#2563EB]"><Settings className="h-5 w-5" /></span>
          <div>
            <h2 className="font-bold text-slate-900">Preferensi aplikasi</h2>
            <p className="text-xs text-slate-500">Disimpan di browser yang sedang digunakan.</p>
          </div>
        </div>
        <div className="grid gap-5 sm:grid-cols-2">
          <label>
            <span className="mb-1.5 block text-sm font-medium text-slate-700">Zona waktu</span>
            <input value={preferences.timezone} onChange={(event) => update('timezone', event.target.value)} className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm" />
          </label>
          <label>
            <span className="mb-1.5 block text-sm font-medium text-slate-700">Format tanggal</span>
            <select value={preferences.dateFormat} onChange={(event) => update('dateFormat', event.target.value as AppPreferences['dateFormat'])} className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm">
              <option value="id-ID">Indonesia (DD/MM/YYYY)</option>
              <option value="en-GB">Internasional (DD/MM/YYYY)</option>
            </select>
          </label>
          <label>
            <span className="mb-1.5 block text-sm font-medium text-slate-700">Periode laporan default</span>
            <select value={preferences.reportPeriod} onChange={(event) => update('reportPeriod', event.target.value as AppPreferences['reportPeriod'])} className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm">
              <option value="weekly">Mingguan</option>
              <option value="monthly">Bulanan</option>
              <option value="yearly">Tahunan</option>
            </select>
          </label>
        </div>
        <div className="mt-5 space-y-3 border-t border-slate-100 pt-4">
          <PreferenceToggle label="Pengingat tagihan jatuh tempo" checked={preferences.notifyDueDates} onChange={(value) => update('notifyDueDates', value)} />
          <PreferenceToggle label="Pengingat laporan mingguan" checked={preferences.notifyWeeklyReport} onChange={(value) => update('notifyWeeklyReport', value)} />
          <PreferenceToggle label="Menu samping ringkas" checked={preferences.compactSidebar} onChange={(value) => update('compactSidebar', value)} />
        </div>
        <div className="mt-5 flex justify-end border-t border-slate-100 pt-4">
          <Button icon={<Save className="h-4 w-4" />} onClick={handleSave}>Simpan pengaturan</Button>
        </div>
      </Card>
    </div>
  )
}

function PreferenceToggle({
  label,
  checked,
  onChange,
}: {
  label: string
  checked: boolean
  onChange: (checked: boolean) => void
}) {
  return (
    <label className="flex items-center justify-between gap-4 text-sm text-slate-700">
      {label}
      <input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} className="h-4 w-4 accent-[#2563EB]" />
    </label>
  )
}
