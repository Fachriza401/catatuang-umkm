import { useState } from 'react'
import { Camera, Save, Settings } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { authService } from '../services/auth.service'
import { profileImageValidationError, uploadAvatar } from '../services/profile.service'
import { Button } from '../components/ui/Button'
import { Card } from '../components/ui/Card'
import { loadPreferences, savePreferences, type AppPreferences } from '../utils/preferences'

export function SettingsPage() {
  const { user } = useAuth()
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
        <p className="mt-1 text-sm text-slate-600">
          Kelola foto akun dan preferensi penggunaan web. Pengaturan ini terpisah dari profil usaha dan data transaksi.
        </p>
      </div>
      <ProfilePhotoSettings userId={user?.id} avatarUrl={user?.user_metadata?.avatar_url} />
      {saved && <p role="status" className="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">Pengaturan berhasil disimpan.</p>}
      {saveError && <p role="alert" className="border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">{saveError}</p>}

      <Card className="p-5 sm:p-6">
        <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
          <span className="flex h-10 w-10 items-center justify-center rounded-md bg-blue-50 text-[#2563EB]"><Settings className="h-5 w-5" /></span>
          <div>
            <h2 className="font-bold text-slate-900">Preferensi aplikasi</h2>
            <p className="text-xs text-slate-600">
              Zona waktu dipakai untuk ringkasan dashboard. Preferensi menu tersimpan di browser ini, tidak tersinkron ke perangkat lain.
            </p>
          </div>
        </div>
        <div className="grid gap-5 sm:grid-cols-2">
          <label>
            <span className="mb-1.5 block text-sm font-medium text-slate-700">Zona waktu</span>
            <input value={preferences.timezone} onChange={(event) => update('timezone', event.target.value)} className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm" />
          </label>
        </div>
        <div className="mt-5 space-y-3 border-t border-slate-100 pt-4">
          <PreferenceToggle label="Menu samping ringkas" checked={preferences.compactSidebar} onChange={(value) => update('compactSidebar', value)} />
        </div>
        <div className="mt-5 flex justify-end border-t border-slate-100 pt-4">
          <Button icon={<Save className="h-4 w-4" />} onClick={handleSave}>Simpan pengaturan</Button>
        </div>
      </Card>
    </div>
  )
}

function ProfilePhotoSettings({
  userId,
  avatarUrl,
}: {
  userId?: string
  avatarUrl?: string | null
}) {
  const [file, setFile] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const [saving, setSaving] = useState(false)
  const [updatedAvatarUrl, setUpdatedAvatarUrl] = useState<string | null>(null)
  const currentAvatarUrl = avatarUrl || ''

  const handleFileChange = (nextFile: File | undefined) => {
    setError(null)
    setSaved(false)
    setUpdatedAvatarUrl(null)
    if (!nextFile) {
      setFile(null)
      return
    }
    const validationError = profileImageValidationError(nextFile)
    if (validationError) {
      setFile(null)
      setError(validationError)
      return
    }
    setFile(nextFile)
  }

  const handleSave = async () => {
    if (!userId || !file) return
    setError(null)
    setSaved(false)
    setSaving(true)
    try {
      const nextAvatarUrl = await uploadAvatar(userId, file)
      await authService.updateProfile({ avatar_url: nextAvatarUrl })
      setUpdatedAvatarUrl(nextAvatarUrl)
      setFile(null)
      setSaved(true)
    } catch (saveError) {
      console.error('Gagal memperbarui foto profil:', saveError)
      setError(saveError instanceof Error ? saveError.message : 'Foto profil gagal diperbarui.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Card className="p-5 sm:p-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
        <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-full border border-slate-200 bg-blue-50 text-2xl font-bold text-[#1D4ED8]">
          {updatedAvatarUrl || currentAvatarUrl ? (
            <img
              src={updatedAvatarUrl || currentAvatarUrl}
              alt="Pratinjau foto profil"
              width={80}
              height={80}
              className="h-full w-full object-cover"
            />
          ) : (
            <Camera className="h-7 w-7" aria-hidden="true" />
          )}
        </div>
        <div className="min-w-0 flex-1">
          <h2 className="font-bold text-slate-900">Foto profil akun</h2>
          <p className="mt-1 text-sm text-slate-600">
            Foto ini mewakili akun Anda di bagian atas aplikasi, bukan logo usaha.
            Gunakan JPG, PNG, atau WebP hingga 5 MB.
          </p>
          <label className="mt-3 block text-sm font-medium text-slate-700" htmlFor="account-avatar">
            Pilih foto profil
          </label>
          <input
            id="account-avatar"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            disabled={!userId || saving}
            onChange={(event) => handleFileChange(event.currentTarget.files?.[0])}
            className="mt-1 block min-h-11 w-full max-w-xl cursor-pointer rounded-md border border-slate-300 bg-white text-sm text-slate-700 file:mr-3 file:min-h-11 file:cursor-pointer file:border-0 file:border-r file:border-slate-300 file:bg-slate-50 file:px-3 file:font-semibold file:text-slate-700 hover:file:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-60"
          />
          {file && <p className="mt-1 text-xs text-slate-600">File dipilih: {file.name}</p>}
          {error && <p role="alert" className="mt-2 text-sm text-rose-700">{error}</p>}
          {saved && <p role="status" className="mt-2 text-sm text-emerald-800">Foto profil berhasil diperbarui.</p>}
          <div className="mt-3">
            <Button onClick={() => void handleSave()} disabled={!file || !userId || saving}>
              {saving ? 'Menyimpan foto...' : 'Simpan foto profil'}
            </Button>
          </div>
        </div>
      </div>
    </Card>
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
