import { useState } from 'react'
import { ImagePlus, Save, Store } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useBusinessProfile, useUpdateBusinessProfile } from '../hooks/useBusinessProfile'
import {
  profileImageValidationError,
  uploadBusinessLogo,
  type BusinessProfileInput,
} from '../services/profile.service'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { ErrorState, LoadingState } from '../components/ui/States'

const emptyProfile: BusinessProfileInput = {
  business_name: '',
  owner_name: '',
  business_type: '',
  phone: '',
  address: '',
  description: '',
  logo_url: '',
}

export function BusinessProfilePage() {
  const { permissions, currentBusiness } = useAuth()
  const profileQuery = useBusinessProfile()
  const updateProfile = useUpdateBusinessProfile()
  const [form, setForm] = useState<BusinessProfileInput | null>(null)
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [saved, setSaved] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [isSaving, setIsSaving] = useState(false)
  const businessId = currentBusiness?.business_id
  const profile = profileQuery.data
  const values = form ?? (profile ? {
    business_name: profile.business_name,
    owner_name: profile.owner_name,
    business_type: profile.business_type,
    phone: profile.phone,
    address: profile.address,
    description: profile.description,
    logo_url: profile.logo_url,
  } : emptyProfile)

  const updateField = (field: keyof BusinessProfileInput, value: string) => {
    setSaved(false)
    setSaveError(null)
    setForm((current) => ({ ...(current ?? values), [field]: value }))
  }

  const handleLogoChange = (file: File | undefined) => {
    setSaved(false)
    setSaveError(null)
    if (!file) {
      setLogoFile(null)
      return
    }
    const validationError = profileImageValidationError(file)
    if (validationError) {
      setLogoFile(null)
      setSaveError(validationError)
      return
    }
    setLogoFile(file)
  }

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaved(false)
    setSaveError(null)
    if (logoFile && !businessId) {
      setSaveError('Usaha aktif tidak ditemukan. Muat ulang halaman lalu coba kembali.')
      return
    }
    setIsSaving(true)
    try {
      let logoUrl = values.logo_url
      if (logoFile) {
        if (!businessId) throw new Error('Usaha aktif tidak ditemukan.')
        logoUrl = await uploadBusinessLogo(businessId, logoFile)
      }
      await updateProfile.mutateAsync({ ...values, logo_url: logoUrl })
      setForm({ ...values, logo_url: logoUrl })
      setLogoFile(null)
      setSaved(true)
    } catch (error) {
      console.error('Gagal menyimpan profil usaha:', error)
      setSaveError(error instanceof Error ? error.message : 'Profil usaha gagal disimpan.')
    } finally {
      setIsSaving(false)
    }
  }

  if (profileQuery.isLoading) return <LoadingState message="Memuat profil usaha..." />
  if (profileQuery.isError) {
    return <ErrorState message={profileQuery.error instanceof Error ? profileQuery.error.message : 'Gagal memuat profil usaha.'} onRetry={() => void profileQuery.refetch()} />
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">Profil Usaha</h1>
        <p className="mt-1 text-sm text-slate-600">
          Kelola identitas usaha dan logo yang tampil pada dashboard. Foto profil akun diatur terpisah melalui Pengaturan.
        </p>
      </div>
      {saveError && <ErrorState title="Profil gagal disimpan" message={saveError} />}
      {saved && <p role="status" className="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">Profil usaha berhasil disimpan.</p>}

      <Card className="p-5 sm:p-6">
        <form onSubmit={(event) => void handleSubmit(event)} className="space-y-4">
          <div className="flex flex-col gap-4 border-b border-slate-100 pb-5 sm:flex-row sm:items-center">
            <div className="flex h-24 w-24 shrink-0 items-center justify-center overflow-hidden rounded-md border border-slate-200 bg-slate-50 text-slate-500">
              {values.logo_url ? (
                <img
                  src={values.logo_url}
                  alt="Pratinjau logo usaha"
                  width={96}
                  height={96}
                  className="h-full w-full object-cover"
                />
              ) : (
                <ImagePlus className="h-7 w-7" aria-hidden="true" />
              )}
            </div>
            <div className="min-w-0 flex-1">
              <label htmlFor="business-logo" className="block text-sm font-semibold text-slate-800">
                Logo usaha
              </label>
              <p className="mt-1 text-sm text-slate-600">
                Pilih logo untuk identitas usaha di dashboard. JPG, PNG, atau WebP, maksimal 5 MB.
              </p>
              <input
                id="business-logo"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                disabled={!permissions.canManageSettings || isSaving}
                onChange={(event) => handleLogoChange(event.currentTarget.files?.[0])}
                className="mt-2 block min-h-11 w-full max-w-xl cursor-pointer rounded-md border border-slate-300 bg-white text-sm text-slate-700 file:mr-3 file:min-h-11 file:cursor-pointer file:border-0 file:border-r file:border-slate-300 file:bg-slate-50 file:px-3 file:font-semibold file:text-slate-700 hover:file:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-60"
              />
              {logoFile && <p className="mt-1 text-xs text-slate-600">File dipilih: {logoFile.name}</p>}
            </div>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Nama usaha" value={values.business_name} onChange={(value) => updateField('business_name', value)} disabled={!permissions.canManageSettings} required />
            <Field label="Nama pemilik" value={values.owner_name} onChange={(value) => updateField('owner_name', value)} disabled={!permissions.canManageSettings} required />
            <Field label="Jenis usaha" value={values.business_type} onChange={(value) => updateField('business_type', value)} disabled={!permissions.canManageSettings} />
            <Field label="Nomor telepon" value={values.phone} onChange={(value) => updateField('phone', value)} disabled={!permissions.canManageSettings} type="tel" />
            <Field label="Alamat" value={values.address} onChange={(value) => updateField('address', value)} disabled={!permissions.canManageSettings} />
            <label className="sm:col-span-2">
              <span className="mb-1.5 block text-sm font-medium text-slate-700">Deskripsi</span>
              <textarea
                value={values.description}
                onChange={(event) => updateField('description', event.target.value)}
                disabled={!permissions.canManageSettings}
                rows={4}
                className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-50"
              />
            </label>
          </div>
          {permissions.canManageSettings && (
            <div className="flex justify-end border-t border-slate-100 pt-4">
              <Button type="submit" icon={<Save className="h-4 w-4" />} disabled={isSaving}>
                {isSaving ? 'Menyimpan...' : 'Simpan profil'}
              </Button>
            </div>
          )}
        </form>
        {!profileQuery.data && (
          <div className="mt-4 flex items-center gap-2 text-sm text-slate-500"><Store className="h-4 w-4" /> Profil usaha belum tersedia.</div>
        )}
      </Card>
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  disabled,
  required = false,
  type = 'text',
}: {
  label: string
  value: string
  onChange: (value: string) => void
  disabled: boolean
  required?: boolean
  type?: string
}) {
  return (
    <label>
      <span className="mb-1.5 block text-sm font-medium text-slate-700">{label}</span>
      <input
        type={type}
        required={required}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        disabled={disabled}
        className="w-full rounded-md border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-50"
      />
    </label>
  )
}
