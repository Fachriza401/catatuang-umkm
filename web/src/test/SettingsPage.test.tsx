import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { SettingsPage } from '../pages/SettingsPage'
import { authService } from '../services/auth.service'
import { uploadAvatar } from '../services/profile.service'

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    user: { id: 'user-1', user_metadata: { avatar_url: '' } },
  }),
}))

vi.mock('../services/auth.service', () => ({
  authService: { updateProfile: vi.fn() },
}))

vi.mock('../services/profile.service', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../services/profile.service')>()
  return { ...actual, uploadAvatar: vi.fn() }
})

describe('SettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('uploads an account photo and updates account metadata', async () => {
    vi.mocked(uploadAvatar).mockResolvedValue('https://cdn.example/avatar.png')
    vi.mocked(authService.updateProfile).mockResolvedValue({} as Awaited<ReturnType<typeof authService.updateProfile>>)
    render(<SettingsPage />)

    const file = new File(['avatar'], 'avatar.png', { type: 'image/png' })
    fireEvent.change(screen.getByLabelText('Pilih foto profil'), {
      target: { files: [file] },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Simpan foto profil' }))

    await waitFor(() => {
      expect(uploadAvatar).toHaveBeenCalledWith('user-1', file)
      expect(authService.updateProfile).toHaveBeenCalledWith({
        avatar_url: 'https://cdn.example/avatar.png',
      })
    })
    expect(await screen.findByRole('status')).toHaveTextContent(
      'Foto profil berhasil diperbarui.',
    )
    expect(screen.getByAltText('Pratinjau foto profil')).toHaveAttribute(
      'src',
      'https://cdn.example/avatar.png',
    )
  })

  it('explains that notifications are not yet available instead of showing inactive toggles', () => {
    render(<SettingsPage />)
    expect(screen.queryByText('Pengingat tagihan jatuh tempo')).not.toBeInTheDocument()
    expect(screen.getByText(/Pengaturan ini terpisah dari profil usaha/)).toBeInTheDocument()
  })
})
