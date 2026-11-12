import { useState } from 'react'
import { Save, Store } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useBusinessProfile, useUpdateBusinessProfile } from '../hooks/useBusinessProfile'
import type { BusinessProfileInput } from '../services/profile.service'
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
  const { permissions } = useAuth()
  const profileQuery = useBusinessProfile()
  const updateProfile = useUpdateBusinessProfile()
  const [form, setForm] = useState<BusinessProfileInput | null>(null)
  const [saved, setSaved] = useState(false)
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
    setForm((current) => ({ ...(current ?? values), [field]: value }))
  }

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSaved(false)
    try {
      await updateProfile.mutateAsync(values)
      setSaved(true)
    } catch {
      setSaved(false)
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
        <p className="mt-1 text-sm text-slate-500">Kelola informasi dasar usaha yang digunakan di aplikasi.</p>
      </div>
      {updateProfile.isError && <ErrorState title="Profil gagal disimpan" message={updateProfile.error instanceof Error ? updateProfile.error.message : 'Periksa koneksi lalu coba lagi.'} />}
      {saved && <p role="status" className="border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">Profil usaha berhasil disimpan.</p>}

      <Card className="p-5 sm:p-6">
        <form onSubmit={(event) => void handleSubmit(event)} className="space-y-4">
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
              <Button type="submit" icon={<Save className="h-4 w-4" />} disabled={updateProfile.isPending}>
                {updateProfile.isPending ? 'Menyimpan...' : 'Simpan profil'}
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
