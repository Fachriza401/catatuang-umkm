import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { BusinessProfilePage } from '../pages/BusinessProfilePage'
import { uploadBusinessLogo } from '../services/profile.service'
import { useBusinessProfile, useUpdateBusinessProfile } from '../hooks/useBusinessProfile'

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    permissions: { canManageSettings: true },
    currentBusiness: { business_id: 'business-1' },
  }),
}))

vi.mock('../hooks/useBusinessProfile', () => ({
  useBusinessProfile: vi.fn(),
  useUpdateBusinessProfile: vi.fn(),
}))

vi.mock('../services/profile.service', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../services/profile.service')>()
  return { ...actual, uploadBusinessLogo: vi.fn() }
})

const profile = {
  business_name: 'Warung Contoh',
  owner_name: 'Pemilik',
  business_type: 'Kuliner',
  phone: '',
  address: '',
  description: '',
  logo_url: '',
}

describe('BusinessProfilePage', () => {
  const mutateAsync = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(useBusinessProfile).mockReturnValue({
      data: profile,
      isLoading: false,
      isError: false,
    } as ReturnType<typeof useBusinessProfile>)
    vi.mocked(useUpdateBusinessProfile).mockReturnValue({
      mutateAsync,
      isPending: false,
    } as never)
  })

  it('uploads a selected company logo and saves its URL with the profile', async () => {
    vi.mocked(uploadBusinessLogo).mockResolvedValue('https://cdn.example/logo.png')
    mutateAsync.mockResolvedValue({})
    render(<BusinessProfilePage />)

    const file = new File(['logo'], 'logo.png', { type: 'image/png' })
    fireEvent.change(screen.getByLabelText('Logo usaha'), {
      target: { files: [file] },
    })
    expect(screen.getByText('File dipilih: logo.png')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Simpan profil' }))

    await waitFor(() => {
      expect(uploadBusinessLogo).toHaveBeenCalledWith('business-1', file)
      expect(mutateAsync).toHaveBeenCalledWith({
        ...profile,
        logo_url: 'https://cdn.example/logo.png',
      })
    })
    expect(await screen.findByRole('status')).toHaveTextContent(
      'Profil usaha berhasil disimpan.',
    )
  })
})
